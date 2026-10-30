class_name ProjectileSystem
extends RefCounted
## Macro-level projectiles: travel room-to-room through matched doors, reflect in
## mirror rooms, and hit the first living unit of the entered room.
## M3 abstraction (tile-level trajectory can replace it later without changing callers).

const MAX_BOUNCES: int = 2

var grid: DungeonGrid = null
var events: Array[Dictionary] = []


func _init(p_grid: DungeonGrid = null) -> void:
	grid = p_grid


func fire(origin_cell: Vector2i, dir: int, damage: int, units: Array[Unit], max_steps: int = 4) -> Array[Dictionary]:
	var shot_events: Array[Dictionary] = []
	if grid == null:
		return shot_events
	var current := grid.get_room(origin_cell)
	if current == null or not DoorSpec.is_door_dir(dir):
		return shot_events
	var direction := dir
	var bounces := 0
	_emit(shot_events, &"projectile_fired", {"from": origin_cell, "dir": direction, "damage": damage})
	for _step in max_steps:
		if not current.has_door(direction):
			break
		var next_cell := current.cell + DoorSpec.delta(direction)
		var next_room := grid.get_room(next_cell)
		if next_room == null:
			break
		current = next_room
		_emit(shot_events, &"projectile_entered", {"room": current.instance_id, "cell": next_cell, "dir": direction})
		var target := _first_target(units, next_cell)
		if target != null:
			var applied := target.take_damage(damage, &"projectile")
			_emit(shot_events, &"projectile_hit", {"unit": target.unit_id, "cell": next_cell, "damage": applied})
			break
		var redirect := current.definition.wave_redirect_steps
		if redirect != 0 and bounces < MAX_BOUNCES:
			direction = DoorSpec.rotate_dir(direction, redirect)
			bounces += 1
			_emit(shot_events, &"projectile_redirected", {"room": current.instance_id, "new_dir": direction})
	_emit(shot_events, &"projectile_ended", {"bounces": bounces})
	events.append_array(shot_events)
	return shot_events


func _first_target(units: Array[Unit], room_cell: Vector2i) -> Unit:
	var candidates: Array[Unit] = []
	for unit in units:
		if unit.alive and unit.room_cell == room_cell:
			candidates.append(unit)
	if candidates.is_empty():
		return null
	candidates.sort_custom(_compare_units)
	return candidates[0]


static func _compare_units(a: Unit, b: Unit) -> bool:
	return String(a.unit_id) < String(b.unit_id)


func _emit(shot_events: Array[Dictionary], event_type: StringName, data: Dictionary) -> void:
	var event := {"type": event_type}
	for key in data:
		event[key] = data[key]
	shot_events.append(event)
