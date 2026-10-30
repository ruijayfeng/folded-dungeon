class_name DungeonSession
extends RefCounted
## M1 exploration + build loop over the M0 DungeonGrid.
## Owns the player unit, current room, phase, turn counter and event log.
## All logic is headless-testable; presentation only reads this object.

enum Phase { EXPLORE, BUILD, COMBAT, REST }

const DEFAULT_MOVE_POINTS: int = 4

var grid: DungeonGrid = null
var player: Unit = null
var phase: int = Phase.EXPLORE
var turn: int = 0
var blueprints: Array[RoomDef] = []
var events: Array[Dictionary] = []
var run_seed: int = 0
var rng_streams: RngStreams = null


func start_run(start_def: RoomDef, start_cell: Vector2i, orientation: int, seed_value: int, starting_bp: int = 10) -> ValidationReport:
	events.clear()
	blueprints.clear()
	grid = DungeonGrid.new()
	grid.set_budget(starting_bp, DungeonGrid.MAX_ROOMS)
	var report := grid.place_start(start_def, start_cell, orientation)
	if not report.is_valid():
		return report
	run_seed = seed_value
	rng_streams = RngStreams.new(seed_value)
	player = Unit.new()
	player.room_cell = start_cell
	var layout := start_def.layout
	if layout != null and not layout.spawn_cells.is_empty():
		player.local_cell = layout.spawn_cells[0]
	player.reset_move_points(DEFAULT_MOVE_POINTS)
	phase = Phase.EXPLORE
	turn = 1
	_log("run_started", {"seed": seed_value, "start_cell": start_cell})
	return report


func current_room() -> RoomInstance:
	if grid == null:
		return null
	return grid.get_room(player.room_cell)


func current_room_cell() -> Vector2i:
	return player.room_cell


func is_at_door() -> bool:
	var room := current_room()
	if room == null:
		return false
	return _is_door_cell(room, player.local_cell)


## Attempts one 4-direction step. Returns a result dictionary with stable reason codes.
func try_move(dir: int) -> Dictionary:
	if grid == null or player == null:
		return _result(false, &"NO_RUN")
	if phase != Phase.EXPLORE:
		return _result(false, &"WRONG_PHASE")
	if player.move_points <= 0:
		return _result(false, &"NO_MOVE_POINTS")
	if DoorSpec.delta(dir) == Vector2i.ZERO:
		return _result(false, &"INVALID_DIRECTION")
	var room := current_room()
	if room == null:
		return _result(false, &"NO_ROOM")
	var next_local := player.local_cell + DoorSpec.delta(dir)
	if not _local_in_bounds(next_local):
		return _cross_room(room, dir)
	if not _is_local_walkable(room, next_local):
		_log("move_blocked", {"reason": "BLOCKED", "from": player.local_cell, "to": next_local})
		return _result(false, &"BLOCKED", {"from_cell": player.local_cell, "to_cell": next_local})
	var from_local := player.local_cell
	player.local_cell = next_local
	player.move_points -= 1
	_log("player_moved", {"room": room.instance_id, "from": from_local, "to": next_local, "dir": dir})
	return _result(true, &"OK", {
		"from_cell": from_local,
		"to_cell": next_local,
		"room_changed": false,
		"room_cell": player.room_cell,
	})


func end_turn() -> void:
	turn += 1
	player.reset_move_points(DEFAULT_MOVE_POINTS)
	_log("turn_ended", {"turn": turn})


func acquire_blueprint(def: RoomDef) -> void:
	if def == null:
		return
	blueprints.append(def)
	_log("blueprint_acquired", {"room_def": def.id})


func has_blueprint(def_id: StringName) -> bool:
	for def in blueprints:
		if def != null and def.id == def_id:
			return true
	return false


func enter_build_node() -> bool:
	if phase != Phase.EXPLORE:
		return false
	phase = Phase.BUILD
	_log("build_node_entered", {"room": current_room().instance_id if current_room() != null else &""})
	return true


func leave_build_node() -> bool:
	if phase != Phase.BUILD:
		return false
	phase = Phase.EXPLORE
	_log("build_node_left", {})
	return true


## Builds a room during a build node. Delegates placement/rules to DungeonGrid.
func build_room(def: RoomDef, cell: Vector2i, orientation: int = 0) -> ValidationReport:
	var report := ValidationReport.new()
	if phase != Phase.BUILD:
		report.add_error(&"WRONG_PHASE", "room can only be built during a build node")
		return report
	if def == null:
		report.add_error(&"INVALID_DEF", "null RoomDef")
		return report
	if not has_blueprint(def.id):
		report.add_error(&"NO_BLUEPRINT", String(def.id))
		return report
	if grid == null:
		report.add_error(&"NO_RUN", "no dungeon grid")
		return report
	report = grid.place_room(def, cell, orientation)
	if report.is_valid():
		_log("build_placed", {
			"room_def": def.id,
			"cell": cell,
			"orientation": orientation,
			"cost": def.build_cost,
		})
	return report


func event_types() -> Array[StringName]:
	var result: Array[StringName] = []
	for event in events:
		result.append(event["type"])
	return result


func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"turn": turn,
		"build_points": grid.build_points if grid != null else -1,
		"rooms": grid.room_count() if grid != null else 0,
		"player_room": player.room_cell if player != null else Vector2i(-1, -1),
		"player_local": player.local_cell if player != null else Vector2i(-1, -1),
		"move_points": player.move_points if player != null else 0,
		"blueprints": blueprints.size(),
		"events": events.size(),
	}


# --- internals -------------------------------------------------------------

func _cross_room(room: RoomInstance, dir: int) -> Dictionary:
	if not room.has_door(dir):
		return _result(false, &"NO_DOOR")
	var door_local := DoorSpec.local_door_cell(dir, room.orientation)
	if player.local_cell != door_local:
		return _result(false, &"NOT_AT_DOOR")
	var neighbor_cell := room.cell + DoorSpec.delta(dir)
	var neighbor := grid.get_room(neighbor_cell)
	if neighbor == null:
		return _result(false, &"NO_NEIGHBOR_ROOM", {"door_cell": neighbor_cell})
	var back_dir := DoorSpec.opposite(dir)
	if not neighbor.has_door(back_dir):
		return _result(false, &"DOOR_MISMATCH", {"door_cell": neighbor_cell})
	player.room_cell = neighbor_cell
	player.local_cell = DoorSpec.local_door_cell(back_dir, neighbor.orientation)
	player.move_points -= 1
	_log("room_entered", {
		"from_room": room.instance_id,
		"to_room": neighbor.instance_id,
		"room_cell": neighbor_cell,
		"local_cell": player.local_cell,
		"dir": dir,
	})
	return _result(true, &"OK", {
		"room_changed": true,
		"from_room_cell": room.cell,
		"to_room_cell": neighbor_cell,
		"to_cell": player.local_cell,
	})


func _is_local_walkable(room: RoomInstance, cell: Vector2i) -> bool:
	var layout := room.layout()
	if layout == null:
		return false
	if layout.is_walkable(cell):
		return true
	return _is_door_cell(room, cell)


func _is_door_cell(room: RoomInstance, cell: Vector2i) -> bool:
	for dir in room.door_dirs():
		if DoorSpec.local_door_cell(dir, room.orientation) == cell:
			return true
	return false


func _local_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < DoorSpec.ROOM_SIZE and cell.y < DoorSpec.ROOM_SIZE


func _result(ok: bool, reason: StringName, extra: Dictionary = {}) -> Dictionary:
	var result := {"ok": ok, "reason": reason}
	for key in extra:
		result[key] = extra[key]
	return result


func _log(event_type: StringName, data: Dictionary) -> void:
	var event := {"type": event_type, "turn": turn}
	for key in data:
		event[key] = data[key]
	events.append(event)
