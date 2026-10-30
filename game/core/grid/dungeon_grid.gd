class_name DungeonGrid
extends RefCounted
## 5x5 macro room grid: placement, rotation, replacement and connectivity (M0).
## All mutations build a tentative layout first and commit only when validation
## passes, so a failed mutation never changes real state (docs/03 §5.1).

const SIZE_X: int = 5
const SIZE_Y: int = 5
const MAX_ROOMS: int = SIZE_X * SIZE_Y

# Stable reason codes (UI + tests).
const CELL_OUT_OF_BOUNDS := &"CELL_OUT_OF_BOUNDS"
const CELL_OCCUPIED := &"CELL_OCCUPIED"
const ROOM_NOT_FOUND := &"ROOM_NOT_FOUND"
const INVALID_ORIENTATION := &"INVALID_ORIENTATION"
const INVALID_DEF := &"INVALID_DEF"
const INVALID_INSTANCE := &"INVALID_INSTANCE"
const START_ALREADY_PLACED := &"START_ALREADY_PLACED"
const NO_START_ROOM := &"NO_START_ROOM"
const START_ROOM_REQUIRED := &"START_ROOM_REQUIRED"
const NO_CONNECTION := &"NO_CONNECTION"
const DOOR_SEALED := &"DOOR_SEALED"
const DOOR_TO_WALL := &"DOOR_TO_WALL"
const DOOR_TO_BOUNDARY := &"DOOR_TO_BOUNDARY"
const ROTATION_BREAKS_CONNECTION := &"ROTATION_BREAKS_CONNECTION"
const DISCONNECTED := &"DISCONNECTED"
const REQUIRED_PATH_BROKEN := &"REQUIRED_PATH_BROKEN"
const ROOM_LIMIT := &"ROOM_LIMIT"
const NO_BUILD_RESOURCE := &"NO_BUILD_RESOURCE"

var rooms: Dictionary = {}  # Vector2i -> RoomInstance
var start_cell: Vector2i = Vector2i(-1, -1)
var boss_cell: Vector2i = Vector2i(-1, -1)
var build_points: int = 9999
var room_limit: int = MAX_ROOMS

var _serial: int = 0


func reset() -> void:
	rooms.clear()
	start_cell = Vector2i(-1, -1)
	boss_cell = Vector2i(-1, -1)
	build_points = 9999
	room_limit = MAX_ROOMS
	_serial = 0


func set_budget(points: int, limit: int = MAX_ROOMS) -> void:
	build_points = points
	room_limit = clampi(limit, 0, MAX_ROOMS)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE_X and cell.y < SIZE_Y


func is_empty() -> bool:
	return rooms.is_empty()


func room_count() -> int:
	return rooms.size()


func get_room(cell: Vector2i) -> RoomInstance:
	return rooms.get(cell, null)


func get_room_by_id(instance_id: StringName) -> RoomInstance:
	for cell in rooms:
		if rooms[cell].instance_id == instance_id:
			return rooms[cell]
	return null


func start_room() -> RoomInstance:
	return get_room(start_cell)


func boss_room() -> RoomInstance:
	return get_room(boss_cell)


func sorted_cells() -> Array[Vector2i]:
	return _sorted_cells_of(rooms)


func all_rooms() -> Array[RoomInstance]:
	var result: Array[RoomInstance] = []
	for cell in sorted_cells():
		result.append(rooms[cell])
	return result


## Connected physical edges (both rooms have matching doors on the shared side).
func edges() -> Array[Dictionary]:
	return _collect_connected_edges(rooms)


func build_graph() -> RoomGraph:
	var graph := RoomGraph.new()
	for edge in edges():
		graph.add_edge(edge["a"], edge["b"], RoomGraph.KIND_PHYSICAL, int(edge["dir"]), edge["anchor"])
	return graph


func place_start(def: RoomDef, cell: Vector2i, orientation: int = 0) -> ValidationReport:
	var report := ValidationReport.new()
	if not rooms.is_empty():
		report.add_error(START_ALREADY_PLACED, "start room already placed at %s" % str(start_cell))
		return report
	_check_basic(def, cell, orientation, report)
	if not report.is_valid():
		return report
	var instance := _new_instance(def, cell, orientation)
	_check_door_boundary(instance, report)
	if not report.is_valid():
		return report
	rooms[cell] = instance
	start_cell = cell
	_serial += 1
	return report


func place_room(def: RoomDef, cell: Vector2i, orientation: int = 0) -> ValidationReport:
	var report := ValidationReport.new()
	if rooms.is_empty():
		report.add_error(NO_START_ROOM, "place_start() must be called first")
		return report
	report = validate_placement(def, cell, orientation)
	if not report.is_valid():
		return report
	var instance := _new_instance(def, cell, orientation)
	rooms[cell] = instance
	build_points -= def.build_cost
	_serial += 1
	return report


func validate_placement(def: RoomDef, cell: Vector2i, orientation: int = 0) -> ValidationReport:
	var report := ValidationReport.new()
	if rooms.is_empty():
		# Treat as a start-room probe: only bounds/definition/geometry matter.
		_check_basic(def, cell, orientation, report)
		if not report.is_valid():
			return report
		_check_door_boundary(_new_instance(def, cell, orientation), report)
		return report
	_check_basic(def, cell, orientation, report)
	if not report.is_valid():
		return report
	var instance := _new_instance(def, cell, orientation)
	var tentative := _clone_rooms()
	tentative[cell] = instance
	report.merge(_validate_tentative(tentative, start_cell, boss_cell, instance.instance_id, true))
	if not report.is_valid():
		return report
	if rooms.size() >= room_limit:
		report.add_error(ROOM_LIMIT, "%d of %d rooms placed" % [rooms.size(), room_limit])
	if def.build_cost > build_points:
		report.add_error(NO_BUILD_RESOURCE, "cost %d, available %d" % [def.build_cost, build_points])
	return report


func remove_room(cell: Vector2i) -> ValidationReport:
	var report := ValidationReport.new()
	if not rooms.has(cell):
		report.add_error(ROOM_NOT_FOUND, str(cell))
		return report
	if cell == start_cell:
		report.add_error(START_ROOM_REQUIRED, "cannot remove the start room")
		return report
	var tentative := _clone_rooms()
	tentative.erase(cell)
	var next_boss := boss_cell
	if cell == boss_cell:
		next_boss = Vector2i(-1, -1)
	report.merge(_validate_tentative(tentative, start_cell, next_boss, &"", false))
	if not report.is_valid():
		return report
	rooms = tentative
	boss_cell = next_boss
	return report


func validate_rotation(cell: Vector2i, new_orientation: int) -> ValidationReport:
	var report := ValidationReport.new()
	if not rooms.has(cell):
		report.add_error(ROOM_NOT_FOUND, str(cell))
		return report
	if new_orientation < 0 or new_orientation > 3:
		report.add_error(INVALID_ORIENTATION, str(new_orientation))
		return report
	var old_room: RoomInstance = rooms[cell]
	var rotated := old_room.clone()
	rotated.orientation = new_orientation
	for dir in DoorSpec.all_dirs():
		var neighbor_cell := cell + DoorSpec.delta(dir)
		if not rooms.has(neighbor_cell):
			continue
		var neighbor: RoomInstance = rooms[neighbor_cell]
		var old_edge := old_room.has_door(dir) and neighbor.has_door(DoorSpec.opposite(dir))
		var new_edge := rotated.has_door(dir) and neighbor.has_door(DoorSpec.opposite(dir))
		if old_edge != new_edge:
			report.add_error(ROTATION_BREAKS_CONNECTION, "%s dir=%d" % [old_room.instance_id, dir])
	if not report.is_valid():
		return report
	var tentative := _clone_rooms()
	tentative[cell] = rotated
	report.merge(_validate_tentative(tentative, start_cell, boss_cell, old_room.instance_id, false))
	return report


func rotate_room(cell: Vector2i, new_orientation: int) -> ValidationReport:
	var report := validate_rotation(cell, new_orientation)
	if not report.is_valid():
		return report
	rooms[cell].orientation = new_orientation
	return report


func validate_replace(cell: Vector2i, new_def: RoomDef, new_orientation: int = 0) -> ValidationReport:
	var report := ValidationReport.new()
	if not rooms.has(cell):
		report.add_error(ROOM_NOT_FOUND, str(cell))
		return report
	if new_orientation < 0 or new_orientation > 3:
		report.add_error(INVALID_ORIENTATION, str(new_orientation))
		return report
	if new_def == null:
		report.add_error(INVALID_DEF, "null RoomDef")
		return report
	for def_error in new_def.validate():
		report.add_error(INVALID_DEF, def_error)
	if not report.is_valid():
		return report
	var old_room: RoomInstance = rooms[cell]
	var refund := old_room.definition.build_cost / 2
	var tentative_points := build_points + refund
	if new_def.build_cost > tentative_points:
		report.add_error(NO_BUILD_RESOURCE, "cost %d, available %d (refund %d)" % [new_def.build_cost, tentative_points, refund])
		return report
	var replacement := RoomInstance.new(old_room.instance_id, new_def, cell, new_orientation)
	var tentative := _clone_rooms()
	tentative[cell] = replacement
	report.merge(_validate_tentative(tentative, start_cell, boss_cell, old_room.instance_id, false))
	return report


func replace_room(cell: Vector2i, new_def: RoomDef, new_orientation: int = 0) -> ValidationReport:
	var report := validate_replace(cell, new_def, new_orientation)
	if not report.is_valid():
		return report
	var old_room: RoomInstance = rooms[cell]
	var refund := old_room.definition.build_cost / 2
	rooms[cell] = RoomInstance.new(old_room.instance_id, new_def, cell, new_orientation)
	build_points = build_points + refund - new_def.build_cost
	return report


func set_boss(cell: Vector2i) -> ValidationReport:
	var report := ValidationReport.new()
	if not rooms.has(cell):
		report.add_error(ROOM_NOT_FOUND, str(cell))
		return report
	var probe := _validate_tentative(rooms, start_cell, cell, &"", false)
	report.merge(probe)
	if not report.is_valid():
		return report
	boss_cell = cell
	return report


func clear_boss() -> void:
	boss_cell = Vector2i(-1, -1)


func validate_state() -> ValidationReport:
	var report := ValidationReport.new()
	if rooms.is_empty():
		return report
	report.merge(_validate_tentative(rooms, start_cell, boss_cell, &"", false))
	var seen := {}
	for cell in _sorted_cells_of(rooms):
		var instance: RoomInstance = rooms[cell]
		for instance_error in instance.validate():
			report.add_error(INVALID_INSTANCE, instance_error)
		if seen.has(instance.instance_id):
			report.add_error(INVALID_INSTANCE, "duplicate instance id %s" % instance.instance_id)
		seen[instance.instance_id] = true
	return report


func snapshot() -> Dictionary:
	var room_list: Array[Dictionary] = []
	for instance in all_rooms():
		room_list.append({
			"id": instance.instance_id,
			"def": instance.definition.id if instance.definition != null else &"<null>",
			"cell": instance.cell,
			"orientation": instance.orientation,
			"door_mask": instance.door_mask(),
		})
	return {
		"rooms": room_list,
		"start": start_cell,
		"boss": boss_cell,
		"build_points": build_points,
		"edges": edges(),
	}


# --- internals -------------------------------------------------------------

func _new_instance(def: RoomDef, cell: Vector2i, orientation: int) -> RoomInstance:
	var instance_id := StringName("%s#%d" % [String(def.id), _serial + 1])
	return RoomInstance.new(instance_id, def, cell, orientation)


func _clone_rooms() -> Dictionary:
	var copy := {}
	for cell in rooms:
		copy[cell] = rooms[cell].clone()
	return copy


func _check_basic(def: RoomDef, cell: Vector2i, orientation: int, report: ValidationReport) -> void:
	if not in_bounds(cell):
		report.add_error(CELL_OUT_OF_BOUNDS, str(cell))
	if rooms.has(cell):
		report.add_error(CELL_OCCUPIED, str(cell))
	if orientation < 0 or orientation > 3:
		report.add_error(INVALID_ORIENTATION, str(orientation))
	if def == null:
		report.add_error(INVALID_DEF, "null RoomDef")
		return
	for def_error in def.validate():
		report.add_error(INVALID_DEF, def_error)


func _check_door_boundary(instance: RoomInstance, report: ValidationReport) -> void:
	for dir in instance.door_dirs():
		var target := instance.cell + DoorSpec.delta(dir)
		if not in_bounds(target):
			report.add_error(DOOR_TO_BOUNDARY, "%s dir=%d target=%s" % [instance.instance_id, dir, str(target)])


func _validate_tentative(trooms: Dictionary, p_start: Vector2i, p_boss: Vector2i, new_room_id: StringName = &"", require_connection: bool = false) -> ValidationReport:
	var report := ValidationReport.new()
	if trooms.is_empty():
		return report
	var cells := _sorted_cells_of(trooms)
	for cell in cells:
		_check_door_boundary(trooms[cell], report)
	var edges := _collect_connected_edges(trooms)
	var pair_dirs: Array[int] = [DoorSpec.Dir.E, DoorSpec.Dir.S]
	for cell in cells:
		var a: RoomInstance = trooms[cell]
		for dir in pair_dirs:
			var neighbor_cell := cell + DoorSpec.delta(dir)
			if not trooms.has(neighbor_cell):
				continue
			var b: RoomInstance = trooms[neighbor_cell]
			var a_has := a.has_door(dir)
			var b_has := b.has_door(DoorSpec.opposite(dir))
			if a_has == b_has:
				continue
			_report_door_mismatch(report, a, b, new_room_id, a_has, b_has)
	if require_connection and new_room_id != &"":
		var connected := false
		for edge in edges:
			if edge["a"] == new_room_id or edge["b"] == new_room_id:
				connected = true
				break
		if not connected:
			report.add_error(NO_CONNECTION, new_room_id)
	var start_id: StringName = &""
	if trooms.has(p_start):
		start_id = trooms[p_start].instance_id
	else:
		report.add_error(NO_START_ROOM, "no start room in layout")
	if start_id != &"":
		var adjacency := {}
		for edge in edges:
			_add_neighbor(adjacency, edge["a"], edge["b"])
			_add_neighbor(adjacency, edge["b"], edge["a"])
		var reachable := _bfs(adjacency, start_id)
		var unreachable := PackedStringArray()
		for cell in cells:
			var instance: RoomInstance = trooms[cell]
			if not reachable.has(instance.instance_id):
				unreachable.append(String(instance.instance_id))
		if not unreachable.is_empty():
			report.add_error(DISCONNECTED, ", ".join(unreachable))
		if trooms.has(p_boss):
			var boss_id: StringName = trooms[p_boss].instance_id
			if not reachable.has(boss_id):
				report.add_error(REQUIRED_PATH_BROKEN, String(boss_id))
	return report


func _report_door_mismatch(report: ValidationReport, a: RoomInstance, b: RoomInstance, new_room_id: StringName, a_has: bool, b_has: bool) -> void:
	var code := DOOR_SEALED
	var detail := "%s <-> %s" % [a.instance_id, b.instance_id]
	if new_room_id != &"":
		if a.instance_id == new_room_id:
			if a_has and not b_has:
				code = DOOR_TO_WALL
			else:
				code = DOOR_SEALED
		elif b.instance_id == new_room_id:
			if b_has and not a_has:
				code = DOOR_TO_WALL
			else:
				code = DOOR_SEALED
	report.add_error(code, detail)


func _collect_connected_edges(trooms: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var pair_dirs: Array[int] = [DoorSpec.Dir.E, DoorSpec.Dir.S]
	for cell in _sorted_cells_of(trooms):
		var a: RoomInstance = trooms[cell]
		for dir in pair_dirs:
			var neighbor_cell := cell + DoorSpec.delta(dir)
			if not trooms.has(neighbor_cell):
				continue
			var b: RoomInstance = trooms[neighbor_cell]
			if a.has_door(dir) and b.has_door(DoorSpec.opposite(dir)):
				result.append({
					"a": a.instance_id,
					"b": b.instance_id,
					"dir": dir,
					"anchor": a.world_door_anchor(dir),
					"cells": [cell, neighbor_cell],
				})
	return result


func _add_neighbor(adjacency: Dictionary, from_id: StringName, to_id: StringName) -> void:
	var list: Array = adjacency.get(from_id, [])
	if not list.has(to_id):
		list.append(to_id)
	adjacency[from_id] = list


func _bfs(adjacency: Dictionary, start_id: StringName) -> Dictionary:
	var reachable := {start_id: true}
	var queue: Array[StringName] = [start_id]
	while not queue.is_empty():
		var current: StringName = queue.pop_front()
		var next_list: Array = adjacency.get(current, [])
		for next_id in next_list:
			if reachable.has(next_id):
				continue
			reachable[next_id] = true
			queue.append(next_id)
	return reachable


func _sorted_cells_of(trooms: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in trooms:
		cells.append(cell)
	cells.sort_custom(_compare_cells)
	return cells


static func _compare_cells(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	return a.x < b.x
