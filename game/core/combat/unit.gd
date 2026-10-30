class_name Unit
extends RefCounted
## Minimal unit for M1 exploration; combat stats arrive in M3.

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1
const DEFAULT_MOVE_POINTS: int = 4

var unit_id: StringName = &"player"
var team: int = TEAM_PLAYER
var room_cell: Vector2i = Vector2i(-1, -1)
var local_cell: Vector2i = Vector2i(4, 4)
var move_points: int = DEFAULT_MOVE_POINTS


func _init(p_unit_id: StringName = &"player", p_team: int = TEAM_PLAYER) -> void:
	unit_id = p_unit_id
	team = p_team


func reset_move_points(points: int = DEFAULT_MOVE_POINTS) -> void:
	move_points = points


func can_move() -> bool:
	return move_points > 0
