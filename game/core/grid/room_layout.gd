class_name RoomLayout
extends Resource
## Pure-data interior layout for one room (B3 fix). No scene/node references.
## Door cells/anchors are derived caches: when present they must match DoorSpec.

const ROOM_SIZE: int = 9
const TILE_WALKABLE: int = 0
const TILE_WALL: int = 1

@export var size: Vector2i = Vector2i(ROOM_SIZE, ROOM_SIZE)
@export var terrain: PackedInt32Array = PackedInt32Array()
@export var door_cells: Dictionary = {}
@export var door_anchors: Dictionary = {}
@export var spawn_cells: Array[Vector2i] = []
@export var hazard_cells: Dictionary = {}


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if size != Vector2i(ROOM_SIZE, ROOM_SIZE):
		errors.append("LAYOUT_SIZE_INVALID: %s (expected %dx%d)" % [str(size), ROOM_SIZE, ROOM_SIZE])
	if terrain.size() != ROOM_SIZE * ROOM_SIZE:
		errors.append("LAYOUT_TERRAIN_SIZE_INVALID: %d" % terrain.size())
	else:
		if not _has_border_walls():
			errors.append("LAYOUT_BORDER_NOT_WALL")
	if spawn_cells.is_empty():
		errors.append("LAYOUT_SPAWN_MISSING")
	for spawn in spawn_cells:
		if not is_walkable(spawn):
			errors.append("LAYOUT_SPAWN_NOT_WALKABLE: %s" % str(spawn))
	for key in door_cells:
		var dir := int(key)
		if not DoorSpec.is_door_dir(dir):
			errors.append("LAYOUT_DOOR_DIR_INVALID: %s" % str(key))
			continue
		var cell: Variant = door_cells[key]
		if not (cell is Vector2i) or cell != DoorSpec.base_door_cell(dir):
			errors.append("LAYOUT_DOOR_CELL_MISMATCH: dir=%d" % dir)
	for key in door_anchors:
		var dir := int(key)
		if not DoorSpec.is_door_dir(dir):
			errors.append("LAYOUT_ANCHOR_DIR_INVALID: %s" % str(key))
			continue
		var anchor: Variant = door_anchors[key]
		if not (anchor is Vector2) or not (anchor as Vector2).is_equal_approx(DoorSpec.base_door_anchor(dir)):
			errors.append("LAYOUT_DOOR_ANCHOR_MISMATCH: dir=%d" % dir)
	for key in hazard_cells:
		if not Channels.is_valid(int(key)):
			errors.append("LAYOUT_HAZARD_CHANNEL_INVALID: %s" % str(key))
			continue
		var cells: Variant = hazard_cells[key]
		if not (cells is Array):
			errors.append("LAYOUT_HAZARD_CELLS_INVALID: channel=%d" % int(key))
			continue
		for cell in cells:
			if not (cell is Vector2i) or not is_walkable(cell):
				errors.append("LAYOUT_HAZARD_CELL_INVALID: channel=%d cell=%s" % [int(key), str(cell)])
	return errors


func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= ROOM_SIZE or cell.y >= ROOM_SIZE:
		return false
	return terrain[cell.y * ROOM_SIZE + cell.x] == TILE_WALKABLE


func door_cell_for(dir: int) -> Vector2i:
	if door_cells.has(dir):
		return door_cells[dir]
	return DoorSpec.base_door_cell(dir)


func door_anchor_for(dir: int) -> Vector2:
	if door_anchors.has(dir):
		return door_anchors[dir]
	return DoorSpec.base_door_anchor(dir)


func _has_border_walls() -> bool:
	for i in ROOM_SIZE:
		if terrain[i] != TILE_WALL:
			return false
		if terrain[(ROOM_SIZE - 1) * ROOM_SIZE + i] != TILE_WALL:
			return false
		if terrain[i * ROOM_SIZE] != TILE_WALL:
			return false
		if terrain[i * ROOM_SIZE + (ROOM_SIZE - 1)] != TILE_WALL:
			return false
	return true


## Creates a border-walled, otherwise walkable 9x9 terrain buffer.
static func make_border_terrain() -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(ROOM_SIZE * ROOM_SIZE)
	result.fill(TILE_WALKABLE)
	for i in ROOM_SIZE:
		result[i] = TILE_WALL
		result[(ROOM_SIZE - 1) * ROOM_SIZE + i] = TILE_WALL
		result[i * ROOM_SIZE] = TILE_WALL
		result[i * ROOM_SIZE + (ROOM_SIZE - 1)] = TILE_WALL
	return result


## Populates the derived door caches from DoorSpec (used by data generation).
func fill_derived_door_data() -> void:
	door_cells.clear()
	door_anchors.clear()
	for dir in DoorSpec.all_dirs():
		door_cells[dir] = DoorSpec.base_door_cell(dir)
		door_anchors[dir] = DoorSpec.base_door_anchor(dir)
