class_name CombatState
extends RefCounted
## Battlefield state for one room: units, round, phase, attacks and knockback.
## Deterministic: unit order comes from insertion order / sorted ids at call sites.

const PHASE_PLAYER: int = 0
const PHASE_ENEMY: int = 1
const PHASE_ENVIRONMENT: int = 2
const PHASE_FINISHED: int = 3

var room_cell: Vector2i = Vector2i(-1, -1)
var room: RoomInstance = null
var units: Array[Unit] = []
var round: int = 1
var phase: int = PHASE_PLAYER
var result: StringName = &""
var events: Array[Dictionary] = []


func setup(p_room: RoomInstance, player_unit: Unit, enemy_units: Array[Unit]) -> void:
	room = p_room
	room_cell = p_room.cell
	units.clear()
	units.append(player_unit)
	for enemy in enemy_units:
		enemy.room_cell = room_cell
		units.append(enemy)
	for unit in units:
		unit.room_cell = room_cell
	round = 1
	result = &""
	events.clear()
	begin_player_phase()


func begin_player_phase() -> void:
	phase = PHASE_PLAYER
	var player := player_unit()
	if player != null:
		player.reset_turn(3)


func begin_enemy_phase() -> void:
	phase = PHASE_ENEMY
	for enemy in living_enemies():
		enemy.reset_turn(2)


func begin_environment_phase() -> void:
	phase = PHASE_ENVIRONMENT


func player_unit() -> Unit:
	for unit in units:
		if unit.team == Unit.TEAM_PLAYER and unit.alive:
			return unit
	return null


func enemies() -> Array[Unit]:
	var result_list: Array[Unit] = []
	for unit in units:
		if unit.team == Unit.TEAM_ENEMY:
			result_list.append(unit)
	return result_list


func living_enemies() -> Array[Unit]:
	var result_list: Array[Unit] = []
	for unit in enemies():
		if unit.alive:
			result_list.append(unit)
	return result_list


func living_units() -> Array[Unit]:
	var result_list: Array[Unit] = []
	for unit in units:
		if unit.alive:
			result_list.append(unit)
	return result_list


func unit_by_id(unit_id: StringName) -> Unit:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null


func unit_at(cell: Vector2i) -> Unit:
	for unit in living_units():
		if unit.local_cell == cell:
			return unit
	return null


func walkable_cell(cell: Vector2i) -> bool:
	if room == null or room.layout() == null:
		return false
	return room.layout().is_walkable(cell)


func distance(a: Unit, b: Unit) -> int:
	var delta := a.local_cell - b.local_cell
	return absi(delta.x) + absi(delta.y)


func move_unit(unit: Unit, dir: int) -> Dictionary:
	if unit == null or not unit.alive:
		return {"ok": false, "reason": &"NO_UNIT"}
	if unit.move_points <= 0:
		return {"ok": false, "reason": &"NO_MOVE_POINTS"}
	var delta := DoorSpec.delta(dir)
	if delta == Vector2i.ZERO:
		return {"ok": false, "reason": &"INVALID_DIRECTION"}
	var next_cell := unit.local_cell + delta
	if not walkable_cell(next_cell):
		return {"ok": false, "reason": &"BLOCKED", "cell": next_cell}
	var occupant := unit_at(next_cell)
	if occupant != null and occupant != unit:
		return {"ok": false, "reason": &"OCCUPIED", "cell": next_cell}
	var from_cell := unit.local_cell
	unit.local_cell = next_cell
	unit.move_points -= 1
	_emit(&"unit_moved", {"unit": unit.unit_id, "from": from_cell, "to": next_cell, "team": unit.team})
	return {"ok": true, "reason": &"OK", "from": from_cell, "to": next_cell}


func attack(attacker: Unit, defender: Unit) -> Dictionary:
	if attacker == null or defender == null or not attacker.alive or not defender.alive:
		return {"ok": false, "reason": &"NO_UNIT"}
	if attacker.has_acted:
		return {"ok": false, "reason": &"ALREADY_ACTED"}
	var range_needed := distance(attacker, defender)
	if range_needed > attacker.attack_range:
		return {"ok": false, "reason": &"OUT_OF_RANGE", "distance": range_needed}
	var damage := attacker.attack_damage
	if attacker.has_status(&"charged"):
		damage += 1
		attacker.remove_status(&"charged")
	var applied := defender.take_damage(damage, attacker.unit_id)
	attacker.has_acted = true
	_emit(&"unit_attacked", {"attacker": attacker.unit_id, "defender": defender.unit_id, "damage": applied})
	var knockback := _knockback(attacker, defender)
	if not defender.alive:
		_emit(&"unit_died", {"unit": defender.unit_id, "team": defender.team})
	return {"ok": true, "reason": &"OK", "damage": applied, "knockback": knockback}


func _knockback(attacker: Unit, defender: Unit) -> Dictionary:
	if not defender.alive:
		return {}
	var delta := defender.local_cell - attacker.local_cell
	if delta == Vector2i.ZERO:
		return {}
	var dir := 0
	if absi(delta.x) >= absi(delta.y) and delta.x != 0:
		dir = DoorSpec.Dir.E if delta.x > 0 else DoorSpec.Dir.W
	elif delta.y != 0:
		dir = DoorSpec.Dir.S if delta.y > 0 else DoorSpec.Dir.N
	var target := defender.local_cell + DoorSpec.delta(dir)
	var blocked := not walkable_cell(target)
	if not blocked and unit_at(target) != null:
		blocked = true
	if blocked:
		var collision := defender.take_damage(1, &"collision")
		_emit(&"knockback_collision", {"unit": defender.unit_id, "damage": collision})
		if not defender.alive:
			_emit(&"unit_died", {"unit": defender.unit_id, "team": defender.team})
		return {"blocked": true, "damage": collision}
	defender.local_cell = target
	_emit(&"unit_knockback", {"unit": defender.unit_id, "to": target})
	return {"blocked": false, "to": target}


func check_result() -> StringName:
	var player := player_unit()
	if player == null:
		return &"defeat"
	if living_enemies().is_empty():
		return &"victory"
	return &""


func snapshot() -> Dictionary:
	var unit_snapshots: Array[Dictionary] = []
	for unit in units:
		unit_snapshots.append(unit.snapshot())
	return {
		"round": round,
		"phase": phase,
		"room": room_cell,
		"result": result,
		"units": unit_snapshots,
	}


func _emit(event_type: StringName, data: Dictionary) -> void:
	var event := {"type": event_type, "round": round}
	for key in data:
		event[key] = data[key]
	events.append(event)
