class_name DoorSpec
extends RefCounted
## Door geometry for the frozen 9x9 room model (P0-1).
##
## A room occupies a 9x9 tile footprint. Door tiles sit on the outer wall ring at
## wall midpoints; door anchors are the wall-edge midpoints in room-local space
## ([0,9]x[0,9]). Two adjacent rooms' anchors coincide exactly in world space.
##
##   N: cell (4,0) anchor (4.5, 0.0)     E: cell (8,4) anchor (9.0, 4.5)
##   S: cell (4,8) anchor (4.5, 9.0)     W: cell (0,4) anchor (0.0, 4.5)

enum Dir { N = 1, E = 2, S = 4, W = 8 }

const ROOM_SIZE: int = 9
const CENTER: float = 4.5


static func all_dirs() -> Array[int]:
	var dirs: Array[int] = [Dir.N, Dir.E, Dir.S, Dir.W]
	return dirs


static func is_door_dir(dir: int) -> bool:
	return dir == Dir.N or dir == Dir.E or dir == Dir.S or dir == Dir.W


static func opposite(dir: int) -> int:
	match dir:
		Dir.N:
			return Dir.S
		Dir.E:
			return Dir.W
		Dir.S:
			return Dir.N
		Dir.W:
			return Dir.E
	return 0


static func dir_index(dir: int) -> int:
	match dir:
		Dir.N:
			return 0
		Dir.E:
			return 1
		Dir.S:
			return 2
		Dir.W:
			return 3
	return -1


static func index_dir(index: int) -> int:
	match index:
		0:
			return Dir.N
		1:
			return Dir.E
		2:
			return Dir.S
		3:
			return Dir.W
	return 0


static func _norm_steps(steps: int) -> int:
	return ((steps % 4) + 4) % 4


static func rotate_dir(dir: int, steps: int) -> int:
	var index := dir_index(dir)
	if index < 0:
		return 0
	return index_dir((index + _norm_steps(steps)) % 4)


static func rotate_mask(mask: int, steps: int) -> int:
	var result := 0
	var normalized := _norm_steps(steps)
	for index in 4:
		var door := index_dir(index)
		if mask & door:
			result |= index_dir((index + normalized) % 4)
	return result


static func delta(dir: int) -> Vector2i:
	match dir:
		Dir.N:
			return Vector2i(0, -1)
		Dir.E:
			return Vector2i(1, 0)
		Dir.S:
			return Vector2i(0, 1)
		Dir.W:
			return Vector2i(-1, 0)
	return Vector2i.ZERO


static func base_door_cell(dir: int) -> Vector2i:
	match dir:
		Dir.N:
			return Vector2i(4, 0)
		Dir.E:
			return Vector2i(8, 4)
		Dir.S:
			return Vector2i(4, 8)
		Dir.W:
			return Vector2i(0, 4)
	return Vector2i(-1, -1)


static func base_door_anchor(dir: int) -> Vector2:
	match dir:
		Dir.N:
			return Vector2(4.5, 0.0)
		Dir.E:
			return Vector2(9.0, 4.5)
		Dir.S:
			return Vector2(4.5, 9.0)
		Dir.W:
			return Vector2(0.0, 4.5)
	return Vector2(-1.0, -1.0)


## Rotates a tile/grid coordinate clockwise around the room center.
static func rotate_cell(cell: Vector2i, steps: int) -> Vector2i:
	var result := cell
	for _i in _norm_steps(steps):
		result = Vector2i(ROOM_SIZE - 1 - result.y, result.x)
	return result


## Rotates a continuous room-local point clockwise around the room center.
static func rotate_anchor(anchor: Vector2, steps: int) -> Vector2:
	var result := anchor
	for _i in _norm_steps(steps):
		var relative := result - Vector2(CENTER, CENTER)
		result = Vector2(-relative.y, relative.x) + Vector2(CENTER, CENTER)
	return result


## dir arguments below are WORLD-facing door directions (the room's current
## orientation frame), matching RoomInstance.has_door()/door_mask().
static func local_door_cell(dir: int, orientation: int) -> Vector2i:
	var base_dir := rotate_dir(dir, -orientation)
	return rotate_cell(base_door_cell(base_dir), orientation)


static func local_door_anchor(dir: int, orientation: int) -> Vector2:
	var base_dir := rotate_dir(dir, -orientation)
	return rotate_anchor(base_door_anchor(base_dir), orientation)


static func world_room_origin(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * ROOM_SIZE, cell.y * ROOM_SIZE)


static func world_door_cell(cell: Vector2i, dir: int, orientation: int) -> Vector2i:
	var local := local_door_cell(dir, orientation)
	return Vector2i(cell.x * ROOM_SIZE + local.x, cell.y * ROOM_SIZE + local.y)


static func world_door_anchor(cell: Vector2i, dir: int, orientation: int) -> Vector2:
	return world_room_origin(cell) + local_door_anchor(dir, orientation)


static func dir_towards(from_cell: Vector2i, to_cell: Vector2i) -> int:
	var offset := to_cell - from_cell
	match offset:
		Vector2i(0, -1):
			return Dir.N
		Vector2i(1, 0):
			return Dir.E
		Vector2i(0, 1):
			return Dir.S
		Vector2i(-1, 0):
			return Dir.W
	return 0
