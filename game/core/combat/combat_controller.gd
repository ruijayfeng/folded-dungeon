class_name CombatController
extends RefCounted
## M3 combat loop: player phase -> enemy AI phase -> environment phase.
## Environmental effects come from the RuleEngine (channels + recipes) and from
## room channels damaging units; defeat/victory returns control to exploration.

const TURRET_PROJECTILE_DAMAGE: int = 2
const HEAT_HAZARD_DAMAGE: int = 2
const TOXIN_HAZARD_DAMAGE: int = 1

var session: DungeonSession = null
var rule_engine: RuleEngine = null
var state: CombatState = null
var projectiles: ProjectileSystem = null
var events: Array[Dictionary] = []
var result: StringName = &""


func _init(session_ref: DungeonSession = null, engine_ref: RuleEngine = null) -> void:
	session = session_ref
	rule_engine = engine_ref


func start_encounter(room_cell: Vector2i, enemy_units: Array[Unit]) -> bool:
	if session == null or session.phase != DungeonSession.Phase.EXPLORE:
		return false
	var room := session.grid.get_room(room_cell)
	if room == null:
		return false
	var player := session.player
	if player == null or not player.alive:
		return false
	player.room_cell = room_cell
	player.reset_move_points(3)
	state = CombatState.new()
	state.setup(room, player, enemy_units)
	projectiles = ProjectileSystem.new(session.grid)
	result = &""
	events.clear()
	session.phase = DungeonSession.Phase.COMBAT
	session.record_event(&"combat_started", {"room": room_cell, "enemies": enemy_units.size()})
	return true


func player_move(dir: int) -> Dictionary:
	if not _player_can_act():
		return {"ok": false, "reason": &"WRONG_PHASE"}
	var move_result := state.move_unit(state.player_unit(), dir)
	if move_result["ok"]:
		session.player.local_cell = state.player_unit().local_cell
		_emit(&"player_moved", {"to": state.player_unit().local_cell})
	return move_result


func player_attack(target_id: StringName) -> Dictionary:
	if not _player_can_act():
		return {"ok": false, "reason": &"WRONG_PHASE"}
	var target := state.unit_by_id(target_id)
	if target == null or target.team != Unit.TEAM_ENEMY:
		return {"ok": false, "reason": &"INVALID_TARGET"}
	var attack_result := state.attack(state.player_unit(), target)
	if attack_result["ok"]:
		_emit(&"player_attacked", {"target": target_id, "damage": attack_result["damage"]})
		_check_result()
	return attack_result


func player_wait() -> Dictionary:
	if not _player_can_act():
		return {"ok": false, "reason": &"WRONG_PHASE"}
	state.player_unit().has_acted = true
	_emit(&"player_waited", {})
	return {"ok": true, "reason": &"OK"}


func end_player_turn() -> Array[Dictionary]:
	if state == null or result != &"" or state.phase != CombatState.PHASE_PLAYER:
		return []
	var start_index := events.size()
	state.begin_enemy_phase()
	_enemy_phase([])
	if result == &"":
		state.begin_environment_phase()
		_environment_phase([])
	if result == &"":
		state.round += 1
		state.begin_player_phase()
	return events.slice(start_index, events.size())


func snapshot() -> Dictionary:
	return {
		"result": result,
		"round": state.round if state != null else 0,
		"combat": state.snapshot() if state != null else {},
		"events": events.size(),
	}


# --- phases ----------------------------------------------------------------

func _enemy_phase(turn_events: Array[Dictionary]) -> void:
	var enemies := state.living_enemies()
	enemies.sort_custom(_compare_units)
	for enemy in enemies:
		if result != &"" or not enemy.alive:
			break
		if enemy.has_status(&"stunned"):
			enemy.remove_status(&"stunned")
			_emit(&"enemy_stunned", {"unit": enemy.unit_id})
			continue
		if state.distance(enemy, state.player_unit()) <= enemy.attack_range:
			_enemy_attack(enemy)
			continue
		_move_enemy_towards_player(enemy)
		if enemy.alive and state.player_unit() != null and state.distance(enemy, state.player_unit()) <= enemy.attack_range:
			_enemy_attack(enemy)


func _enemy_attack(enemy: Unit) -> void:
	var attack_result := state.attack(enemy, state.player_unit())
	if attack_result["ok"]:
		_emit(&"enemy_attacked", {"unit": enemy.unit_id, "damage": attack_result["damage"]})
		_check_result()


func _move_enemy_towards_player(enemy: Unit) -> void:
	var target_cell := state.player_unit().local_cell
	for _step in enemy.move_points:
		if enemy.local_cell == target_cell:
			break
		var next_cell := _next_step_toward(enemy, target_cell)
		if next_cell == Vector2i.ZERO:
			break
		var dir := DoorSpec.dir_towards(enemy.local_cell, next_cell)
		if dir == 0:
			break
		var move_result := state.move_unit(enemy, dir)
		if not move_result["ok"]:
			break
		_emit(&"enemy_moved", {"unit": enemy.unit_id, "to": enemy.local_cell})


func _next_step_toward(enemy: Unit, target_cell: Vector2i) -> Vector2i:
	var start := enemy.local_cell
	if start == target_cell:
		return Vector2i.ZERO
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	var previous := {}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for dir in DoorSpec.all_dirs():
			var next_cell := current + DoorSpec.delta(dir)
			if visited.has(next_cell) or not state.walkable_cell(next_cell):
				continue
			var occupant := state.unit_at(next_cell)
			if occupant != null and occupant != enemy and next_cell != target_cell:
				continue
			if _is_lethal_hazard(next_cell, enemy):
				continue
			visited[next_cell] = true
			previous[next_cell] = current
			if next_cell == target_cell:
				queue.clear()
				break
			queue.append(next_cell)
	if not previous.has(target_cell):
		return Vector2i.ZERO
	var cursor := target_cell
	while previous.has(cursor) and previous[cursor] != start:
		cursor = previous[cursor]
	if not previous.has(cursor):
		return Vector2i.ZERO
	return cursor


func _environment_phase(turn_events: Array[Dictionary]) -> void:
	if rule_engine != null:
		rule_engine.sync_rooms()
		var engine_events := rule_engine.tick()
		_resolve_turret_fire(engine_events, turn_events)
	_apply_hazard_damage(turn_events)
	_check_result()


func _resolve_turret_fire(engine_events: Array[Dictionary], turn_events: Array[Dictionary]) -> void:
	for engine_event in engine_events:
		if engine_event["type"] != &"room_periodic" or engine_event.get("event_id", &"") != &"turret_fire":
			continue
		var room := session.grid.get_room(engine_event["cell"])
		if room == null:
			continue
		var dir := _first_door_dir(room)
		if dir == 0:
			continue
		var shot := projectiles.fire(room.cell, dir, TURRET_PROJECTILE_DAMAGE, state.units)
		turn_events.append_array(shot)
		for shot_event in shot:
			if shot_event["type"] == &"projectile_hit":
				_emit(&"turret_hit", {"unit": shot_event["unit"], "damage": shot_event["damage"]})
		_check_result()
		if result != &"":
			return


func _apply_hazard_damage(turn_events: Array[Dictionary]) -> void:
	var heat := 0
	var toxin := 0
	if rule_engine != null:
		var room_state := rule_engine.room_state(state.room_cell)
		if room_state != null:
			heat = room_state.get_channel(Channels.Channel.HEAT)
			toxin = room_state.get_channel(Channels.Channel.TOXIN)
	for unit in state.living_units():
		var damage := 0
		var sources: Array[StringName] = []
		if heat >= Channels.HEAT_THRESHOLD:
			damage += HEAT_HAZARD_DAMAGE
			sources.append(&"heat")
		if toxin >= Channels.TOXIN_THRESHOLD:
			damage += TOXIN_HAZARD_DAMAGE
			sources.append(&"toxin")
		if unit.has_status(&"burning"):
			damage += 1
			sources.append(&"burning")
		if unit.has_status(&"poisoned"):
			damage += 1
			sources.append(&"poisoned")
		if damage > 0:
			var applied := unit.take_damage(damage, &"environment")
			_emit(&"hazard_damage", {"unit": unit.unit_id, "damage": applied, "sources": sources})
			if not unit.alive:
				_emit(&"unit_died", {"unit": unit.unit_id, "team": unit.team})
	for unit in state.living_units():
		var expired := unit.advance_statuses()
		for status_name in expired:
			_emit(&"status_expired", {"unit": unit.unit_id, "status": status_name})
	if heat >= Channels.HEAT_THRESHOLD:
		for unit in state.living_units():
			unit.add_status(&"burning", 2)
	if toxin >= Channels.TOXIN_THRESHOLD:
		for unit in state.living_units():
			unit.add_status(&"poisoned", 2)


func _is_lethal_hazard(cell: Vector2i, unit: Unit) -> bool:
	if rule_engine == null:
		return false
	var room_state := rule_engine.room_state(state.room_cell)
	if room_state == null:
		return false
	var damage := 0
	if room_state.get_channel(Channels.Channel.HEAT) >= Channels.HEAT_THRESHOLD:
		damage += HEAT_HAZARD_DAMAGE
	if room_state.get_channel(Channels.Channel.TOXIN) >= Channels.TOXIN_THRESHOLD:
		damage += TOXIN_HAZARD_DAMAGE
	if unit.has_status(&"burning"):
		damage += 1
	if unit.has_status(&"poisoned"):
		damage += 1
	return damage >= unit.hp


func _player_can_act() -> bool:
	if state == null or result != &"":
		return false
	if session == null or session.phase != DungeonSession.Phase.COMBAT:
		return false
	return state.phase == CombatState.PHASE_PLAYER and state.player_unit() != null


func _check_result() -> void:
	if state == null:
		return
	var outcome := state.check_result()
	if outcome == &"":
		return
	_finish(outcome)


func _finish(outcome: StringName) -> void:
	result = outcome
	state.result = outcome
	state.phase = CombatState.PHASE_FINISHED
	if session == null:
		return
	session.phase = DungeonSession.Phase.EXPLORE
	if outcome == &"victory":
		session.player.reset_move_points(DungeonSession.DEFAULT_MOVE_POINTS)
		session.record_event(&"combat_won", {"room": state.room_cell})
	else:
		session.run_over = true
		session.record_event(&"combat_lost", {"room": state.room_cell})


func _emit(event_type: StringName, data: Dictionary) -> void:
	var event := {"type": event_type, "round": state.round if state != null else 0}
	for key in data:
		event[key] = data[key]
	events.append(event)
	if session != null:
		session.events.append(event)
	if state != null:
		state.events.append(event)


func _first_door_dir(room: RoomInstance) -> int:
	for dir in DoorSpec.all_dirs():
		if room.has_door(dir):
			return dir
	return 0


static func _compare_units(a: Unit, b: Unit) -> bool:
	return String(a.unit_id) < String(b.unit_id)
