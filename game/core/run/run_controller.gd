class_name RunController
extends RefCounted
## M4 vertical-slice driver: deterministic floor plan -> build rooms -> walk in ->
## encounter/event/rest/shop -> rewards -> boss -> settlement.
## Core-only (no scenes); the presentation layer drives it through this API.

enum Phase { BUILD, EXPLORE, ENCOUNTER, EVENT, REST, SHOP, SETTLED }

const START_CELL := Vector2i(2, 2)
const START_ROOM_ID := &"start_room"
const BOSS_ROOM_ID := &"boss_room"
const POOL_IDS: Array[StringName] = [
	&"combat_room", &"forge_room", &"toxin_room", &"frost_room",
	&"mirror_room", &"accumulator_room", &"ballista_room",
]
const CORRIDOR_ROOM_ID := &"corridor_room"
const RANDOM_OFFER_COUNT := 2
const SHOP_PRICE := 20
const SHOP_BUILD_POINTS := 3
const REST_HEAL := 6

var state: RunState = null
var plan: FloorPlan = null
var session: DungeonSession = null
var engine: RuleEngine = null
var build_controller: BuildController = null
var combat: CombatController = null
var phase: int = Phase.SETTLED
var current_offer: Array[RoomDef] = []
var slot_bindings: Dictionary = {}   # Vector2i -> slot index
var slot_cleared: Dictionary = {}    # slot index -> true
var active_slot_index: int = -1
var rng: RngStreams = null
var last_error: StringName = &""

var _def_cache: Dictionary = {}


func start(seed_value: int = 0, total_floors: int = 2) -> void:
	state = RunState.new()
	state.seed_value = seed_value
	state.total_floors = maxi(1, total_floors)
	rng = RngStreams.new(seed_value)
	plan = FloorPlan.generate(seed_value, 1)
	_start_floor()
	_log(&"run_started", {"seed": seed_value, "total_floors": state.total_floors})


func _start_floor() -> void:
	session = DungeonSession.new()
	var start_def := _room_def(START_ROOM_ID)
	var report := session.start_run(start_def, START_CELL, 0, state.seed_value + state.floor * 1000, state.build_points)
	if not report.is_valid():
		push_error("RunController: cannot start floor: %s" % report.summary())
		phase = Phase.SETTLED
		return
	session.player.max_hp = 16
	session.player.hp = 16
	engine = RuleEngine.new()
	engine.setup(session.grid, RuleEngine.load_recipe_library(), [], state.seed_value + state.floor)
	build_controller = BuildController.new(session)
	combat = CombatController.new(session, engine)
	slot_bindings.clear()
	slot_cleared.clear()
	active_slot_index = -1
	state.slot_index = 0
	state.phase = &"build"
	phase = Phase.BUILD
	_open_build_node()


func offer_blueprints() -> Array[RoomDef]:
	return current_offer


func _open_build_node() -> void:
	if phase == Phase.SETTLED:
		return
	if session.phase == DungeonSession.Phase.EXPLORE:
		session.enter_build_node()
	phase = Phase.BUILD
	state.phase = &"build"
	current_offer = _make_offer()
	_log(&"build_node_opened", {"slot": state.slot_index, "offers": _offer_ids()})


func _make_offer() -> Array[RoomDef]:
	var offer: Array[RoomDef] = []
	if state.slot_index >= plan.slots.size():
		return offer
	var slot_type: int = plan.slots[state.slot_index]["type"]
	if slot_type == FloorPlan.SlotType.BOSS:
		var boss := _room_def(BOSS_ROOM_ID)
		if boss != null:
			offer.append(boss)
		var corridor := _room_def(CORRIDOR_ROOM_ID)
		if corridor != null:
			offer.append(corridor)
		return offer
	var random_count := 0
	while random_count < RANDOM_OFFER_COUNT:
		var pick := rng.stream(RngStreams.STREAM_FLOOR).next_int(POOL_IDS.size())
		var picked_id: StringName = POOL_IDS[pick]
		var picked_def := _room_def(picked_id)
		if picked_def != null and not offer.has(picked_def):
			offer.append(picked_def)
			random_count += 1
	var corridor := _room_def(CORRIDOR_ROOM_ID)
	if corridor != null:
		offer.append(corridor)
	return offer


## Builds the offered room in a cell. Returns the placement report; on success
## the slot is bound to the cell and the run returns to EXPLORE.
func build_and_place(offer_index: int, cell: Vector2i, orientation: int) -> ValidationReport:
	var report := ValidationReport.new()
	if phase != Phase.BUILD:
		report.add_error(&"WRONG_PHASE", "not in build phase")
		return report
	if offer_index < 0 or offer_index >= current_offer.size():
		report.add_error(&"INVALID_DEF", "offer index %d" % offer_index)
		return report
	var def := current_offer[offer_index]
	if def == null:
		report.add_error(&"INVALID_DEF", "null RoomDef")
		return report
	if not session.has_blueprint(def.id):
		session.acquire_blueprint(def)
	report = session.build_room(def, cell, orientation)
	if not report.is_valid():
		return report
	var slot_index := state.slot_index
	slot_bindings[cell] = slot_index
	state.slot_index += 1
	state.build_points = session.grid.build_points
	if not state.blueprints.has(def.id):
		state.blueprints.append(def.id)
	engine.sync_rooms()
	session.leave_build_node()
	phase = Phase.EXPLORE
	state.phase = &"explore"
	_log(&"room_built", {"room_def": def.id, "cell": cell, "orientation": orientation, "slot_index": slot_index})
	return report


## Automation helper (M4 acceptance): tries offers/cells/orientations until one
## valid placement is made. Returns the built cell or (-1,-1).
func auto_build_adjacent() -> Vector2i:
	if phase != Phase.BUILD:
		last_error = &"WRONG_PHASE"
		return Vector2i(-1, -1)
	var free_cells := _free_cells_sorted()
	for offer_index in current_offer.size():
		for cell in free_cells:
			if not _has_adjacent_room(cell):
				continue
			for orientation in 4:
				var report := build_and_place(offer_index, cell, orientation)
				if report.is_valid():
					return cell
	last_error = &"NO_VALID_PLACEMENT"
	return Vector2i(-1, -1)


## Automation helper: walks from the current room into the adjacent room at
## target_cell through a door and triggers its slot content.
func auto_walk_into(target_cell: Vector2i) -> bool:
	if phase != Phase.EXPLORE:
		last_error = &"WRONG_PHASE"
		return false
	if session.current_room_cell() == target_cell:
		return on_room_entered(target_cell)
	var room_path := _room_path(session.current_room_cell(), target_cell)
	if room_path.size() < 2:
		last_error = &"NO_ROOM_PATH"
		return false
	for index in range(1, room_path.size()):
		var next_room_cell: Vector2i = room_path[index]
		var dir := DoorSpec.dir_towards(session.current_room_cell(), next_room_cell)
		if dir == 0:
			last_error = &"NOT_ADJACENT"
			return false
		var room := session.current_room()
		if room == null:
			last_error = &"NO_ROOM"
			return false
		var door_local := DoorSpec.local_door_cell(dir, room.orientation)
		var guard := 0
		while session.player.local_cell != door_local and guard < 40:
			guard += 1
			if session.player.move_points <= 0:
				session.end_turn()
				continue
			var step_dir := _local_step_toward(session.player.local_cell, door_local, room)
			if step_dir == 0:
				last_error = &"NO_STEP"
				return false
			var move := session.try_move(step_dir)
			if not move["ok"]:
				last_error = move["reason"]
				return false
		if session.player.local_cell != door_local:
			last_error = &"DOOR_UNREACHABLE"
			return false
		if session.player.move_points <= 0:
			session.end_turn()
		var crossed := session.try_move(dir)
		if not crossed["ok"]:
			last_error = crossed["reason"]
			return false
		if next_room_cell == target_cell:
			return on_room_entered(target_cell)
	return false


func on_room_entered(cell: Vector2i) -> bool:
	if phase != Phase.EXPLORE:
		return false
	if not slot_bindings.has(cell):
		return false
	var slot_index: int = slot_bindings[cell]
	if slot_cleared.has(slot_index):
		return false
	active_slot_index = slot_index
	var slot: Dictionary = plan.slots[slot_index]
	var slot_type: int = slot["type"]
	var type_name := FloorPlan.type_name(slot_type)
	match type_name:
		&"battle", &"elite", &"boss":
			return _start_encounter(cell, slot_type)
		&"event":
			phase = Phase.EVENT
			state.phase = &"event"
			_log(&"event_entered", {"slot": slot_index})
			return true
		&"rest":
			phase = Phase.REST
			state.phase = &"rest"
			_log(&"rest_entered", {"slot": slot_index})
			return true
		&"shop":
			phase = Phase.SHOP
			state.phase = &"shop"
			_log(&"shop_entered", {"slot": slot_index})
			return true
	return false


func _start_encounter(cell: Vector2i, slot_type: int) -> bool:
	var room := session.grid.get_room(cell)
	if room == null:
		return false
	var enemies := _create_enemies(room, slot_type)
	if enemies.is_empty():
		return false
	combat = CombatController.new(session, engine)
	if not combat.start_encounter(cell, enemies):
		return false
	phase = Phase.ENCOUNTER
	state.phase = &"encounter"
	_log(&"encounter_started", {
		"cell": cell,
		"slot_type": FloorPlan.type_name(slot_type),
		"enemies": enemies.size(),
	})
	return true


func _create_enemies(room: RoomInstance, slot_type: int) -> Array[Unit]:
	var count := 2
	if slot_type == FloorPlan.SlotType.ELITE:
		count = 2
	elif slot_type == FloorPlan.SlotType.BOSS:
		count = 2
	var cells := _encounter_cells(room, count)
	var enemies: Array[Unit] = []
	var floor_bonus := state.floor - 1
	for index in cells.size():
		var enemy := Unit.new(StringName("enemy_%d" % (index + 1)), Unit.TEAM_ENEMY)
		enemy.room_cell = room.cell
		enemy.local_cell = cells[index]
		enemy.move_points = 2
		enemy.attack_damage = 1
		match slot_type:
			FloorPlan.SlotType.ELITE:
				enemy.max_hp = 2 + floor_bonus
				enemy.display_name = "精英 %d" % (index + 1)
			FloorPlan.SlotType.BOSS:
				if index == 0:
					enemy.unit_id = &"boss"
					enemy.display_name = "地牢核心守卫"
					enemy.max_hp = 4 + floor_bonus
					enemy.ability = &"boss_heat"
					enemy.hazard_resist = [Channels.Channel.HEAT]
				else:
					enemy.max_hp = 1 + floor_bonus
					enemy.display_name = "守卫随从"
			_:
				enemy.max_hp = 2 + floor_bonus
				enemy.display_name = "敌人 %d" % (index + 1)
		enemy.hp = enemy.max_hp
		enemies.append(enemy)
	return enemies


func _encounter_cells(room: RoomInstance, count: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var layout := room.layout()
	for y in DoorSpec.ROOM_SIZE:
		for x in DoorSpec.ROOM_SIZE:
			var cell := Vector2i(x, y)
			if cell == session.player.local_cell:
				continue
			if layout.is_walkable(cell):
				cells.append(cell)
			if cells.size() >= count:
				return cells
	return cells


func sync_combat_result() -> StringName:
	if phase != Phase.ENCOUNTER or combat == null:
		return &""
	var outcome := combat.result
	if outcome == &"":
		return &""
	if outcome == &"victory":
		_log(&"combat_won", {"slot": active_slot_index, "floor": state.floor})
		_apply_slot_rewards(active_slot_index)
		_complete_slot()
	else:
		_log(&"combat_lost", {"slot": active_slot_index})
		state.run_over = true
		state.phase = &"run_over"
		phase = Phase.SETTLED
		_log(&"run_failed", {"floor": state.floor})
		state.events.append({"type": &"run_over", "floor": state.floor})
	return outcome


## Resolves EVENT / REST / SHOP slots with a choice index (0-based).
func resolve_choice(choice: int = 0) -> bool:
	if phase == Phase.EVENT:
		match choice:
			0:
				var healed := session.player.heal(5)
				_log(&"event_resolved", {"choice": choice, "heal": healed})
			1:
				state.gold += 25
				_log(&"event_resolved", {"choice": choice, "gold": 25})
			_:
				session.grid.build_points += 2
				state.build_points = session.grid.build_points
				_log(&"event_resolved", {"choice": choice, "build_points": 2})
		_complete_slot()
		return true
	if phase == Phase.REST:
		var healed := session.player.heal(REST_HEAL)
		_log(&"rest_resolved", {"heal": healed})
		_complete_slot()
		return true
	if phase == Phase.SHOP:
		if choice == 0:
			var healed := session.player.heal(10)
			_log(&"shop_healed", {"heal": healed})
		elif choice == 1 and state.gold >= SHOP_PRICE:
			state.gold -= SHOP_PRICE
			session.grid.build_points += SHOP_BUILD_POINTS
			state.build_points = session.grid.build_points
			_log(&"shop_purchased", {"gold_spent": SHOP_PRICE, "build_points": SHOP_BUILD_POINTS})
		else:
			_log(&"shop_left", {"choice": choice})
		_complete_slot()
		return true
	return false


func settle_run(outcome: StringName = &"victory") -> void:
	state.phase = &"settled"
	state.victory = outcome == &"victory"
	state.run_over = outcome == &"defeat"
	phase = Phase.SETTLED
	_log(&"run_settled", {"outcome": outcome, "floor": state.floor})


func event_types() -> Array[StringName]:
	var result: Array[StringName] = []
	for event in state.events:
		result.append(event["type"])
	return result


func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"state": state.snapshot(),
		"plan": plan.snapshot() if plan != null else {},
		"slot_bindings": _slot_bindings_snapshot(),
		"slot_cleared": slot_cleared.keys(),
		"session": session.snapshot() if session != null else {},
		"offer": _offer_ids(),
	}


# --- internals -------------------------------------------------------------

func _complete_slot() -> void:
	slot_cleared[active_slot_index] = true
	state.cleared_slots.append(active_slot_index)
	_log(&"slot_cleared", {"slot": active_slot_index, "floor": state.floor})
	var slot_type: int = plan.slots[active_slot_index]["type"]
	active_slot_index = -1
	if slot_type == FloorPlan.SlotType.BOSS:
		if state.floor < state.total_floors:
			_advance_floor()
		else:
			settle_run(&"victory")
		return
	session.phase = DungeonSession.Phase.EXPLORE
	_open_build_node()


func _advance_floor() -> void:
	state.floor += 1
	plan = FloorPlan.generate(state.seed_value, state.floor)
	_log(&"floor_advanced", {"floor": state.floor})
	_start_floor()


func _apply_slot_rewards(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= plan.slots.size():
		return
	var slot_type: int = plan.slots[slot_index]["type"]
	var gold := 0
	var build_points := 0
	match slot_type:
		FloorPlan.SlotType.ELITE:
			gold = 40
			build_points = 3
		FloorPlan.SlotType.BATTLE, FloorPlan.SlotType.BATTLE_ALT:
			gold = 15
			build_points = 2
		FloorPlan.SlotType.BOSS:
			gold = 100
			build_points = 5
		_:
			return
	state.gold += gold
	session.grid.build_points += build_points
	state.build_points = session.grid.build_points
	_log(&"rewards_granted", {"gold": gold, "build_points": build_points, "slot": slot_index})


func _slot_bindings_snapshot() -> Dictionary:
	var result := {}
	for cell in slot_bindings.keys():
		result[str(cell)] = slot_bindings[cell]
	return result


func _offer_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for def in current_offer:
		if def != null:
			ids.append(def.id)
	return ids


func _free_cells_sorted() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in DungeonGrid.SIZE_Y:
		for x in DungeonGrid.SIZE_X:
			var cell := Vector2i(x, y)
			if session.grid.get_room(cell) == null:
				cells.append(cell)
	return cells


func _has_adjacent_room(cell: Vector2i) -> bool:
	for dir in DoorSpec.all_dirs():
		if session.grid.get_room(cell + DoorSpec.delta(dir)) != null:
			return true
	return false


func _room_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if from_cell == to_cell:
		result.append(from_cell)
		return result
	var adjacency := {}
	for edge in session.grid.edges():
		var cells: Array = edge["cells"]
		_add_room_neighbor(adjacency, cells[0], cells[1])
		_add_room_neighbor(adjacency, cells[1], cells[0])
	var visited := {from_cell: true}
	var queue: Array[Vector2i] = [from_cell]
	var previous := {}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var neighbors: Array = adjacency.get(current, [])
		neighbors.sort_custom(_compare_cells)
		for next_cell in neighbors:
			if visited.has(next_cell):
				continue
			visited[next_cell] = true
			previous[next_cell] = current
			if next_cell == to_cell:
				queue.clear()
				break
			queue.append(next_cell)
	if not previous.has(to_cell):
		return result
	var cursor := to_cell
	while cursor != from_cell:
		result.push_front(cursor)
		cursor = previous[cursor]
	result.push_front(from_cell)
	return result


func _add_room_neighbor(adjacency: Dictionary, from_cell: Vector2i, to_cell: Vector2i) -> void:
	var list: Array = adjacency.get(from_cell, [])
	if not list.has(to_cell):
		list.append(to_cell)
	adjacency[from_cell] = list


static func _compare_cells(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	return a.x < b.x


func _local_step_toward(from_cell: Vector2i, to_cell: Vector2i, room: RoomInstance) -> int:
	if from_cell == to_cell or room == null or room.layout() == null:
		return 0
	var layout := room.layout()
	var visited := {from_cell: true}
	var queue: Array[Vector2i] = [from_cell]
	var previous := {}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for dir in DoorSpec.all_dirs():
			var next_cell := current + DoorSpec.delta(dir)
			if visited.has(next_cell):
				continue
			if not layout.is_walkable(next_cell) and next_cell != to_cell:
				continue
			visited[next_cell] = true
			previous[next_cell] = current
			if next_cell == to_cell:
				queue.clear()
				break
			queue.append(next_cell)
	if not previous.has(to_cell):
		return 0
	var cursor := to_cell
	while previous.has(cursor) and previous[cursor] != from_cell:
		cursor = previous[cursor]
	if not previous.has(cursor):
		return 0
	return DoorSpec.dir_towards(from_cell, cursor)


func _room_def(room_id: StringName) -> RoomDef:
	if _def_cache.has(room_id):
		return _def_cache[room_id]
	var path := "res://data/rooms/%s.tres" % String(room_id)
	var def := load(path) as RoomDef
	if def != null:
		_def_cache[room_id] = def
	return def


func _log(event_type: StringName, data: Dictionary) -> void:
	var event := {"type": event_type, "floor": state.floor, "slot": state.slot_index}
	for key in data:
		event[key] = data[key]
	state.events.append(event)
	if session != null:
		session.record_event(event_type, data)
