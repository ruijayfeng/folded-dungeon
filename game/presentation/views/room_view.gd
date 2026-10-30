class_name RoomView
extends Node2D
## Placeholder-color renderer for one 9x9 room (replaced by real art in M5).
## Reads pure RoomLayout data; never mutates the simulation.

const TILE_SIZE: float = 16.0
const COLOR_FLOOR := Color("2b2b3d")
const COLOR_WALL := Color("111119")
const COLOR_DOOR := Color("c9a227")
const COLOR_SPAWN := Color("3fa34d")
const COLOR_PLAYER := Color("72d4ff")
const COLOR_GRID := Color(1.0, 1.0, 1.0, 0.06)

@export var room_def_path: String = ""

var room_def: RoomDef = null
var room_instance: RoomInstance = null
var player_local: Vector2i = Vector2i(-1, -1)
var rule_engine: RuleEngine = null


func _ready() -> void:
	_ensure_loaded()


func _ensure_loaded() -> void:
	if room_def == null and not room_def_path.is_empty():
		room_def = load(room_def_path) as RoomDef


func setup(instance: RoomInstance, player: Vector2i = Vector2i(-1, -1)) -> void:
	room_instance = instance
	if instance != null:
		room_def = instance.definition
	player_local = player
	queue_redraw()


func set_player_cell(cell: Vector2i) -> void:
	player_local = cell
	queue_redraw()


func set_rule_engine(engine: RuleEngine) -> void:
	rule_engine = engine
	queue_redraw()


func get_room_def() -> RoomDef:
	_ensure_loaded()
	return room_def


## Returns {world-facing door dir -> local door cell} for the current orientation.
func local_door_cells() -> Dictionary:
	var result := {}
	var def := get_room_def()
	if def == null:
		return result
	var orientation := 0
	if room_instance != null:
		orientation = room_instance.orientation
	var mask := DoorSpec.rotate_mask(def.door_mask, orientation)
	for dir in DoorSpec.all_dirs():
		if mask & dir:
			result[dir] = DoorSpec.local_door_cell(dir, orientation)
	return result


func tile_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell.x * TILE_SIZE, cell.y * TILE_SIZE), Vector2(TILE_SIZE, TILE_SIZE))


func tile_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE_SIZE, (cell.y + 0.5) * TILE_SIZE)


func _draw() -> void:
	var def := get_room_def()
	if def == null or def.layout == null:
		return
	var layout := def.layout
	for y in DoorSpec.ROOM_SIZE:
		for x in DoorSpec.ROOM_SIZE:
			var cell := Vector2i(x, y)
			var color := COLOR_FLOOR if layout.is_walkable(cell) else COLOR_WALL
			draw_rect(tile_rect(cell), color, true)
	for i in DoorSpec.ROOM_SIZE + 1:
		var offset := float(i) * TILE_SIZE
		draw_line(Vector2(offset, 0.0), Vector2(offset, DoorSpec.ROOM_SIZE * TILE_SIZE), COLOR_GRID)
		draw_line(Vector2(0.0, offset), Vector2(DoorSpec.ROOM_SIZE * TILE_SIZE, offset), COLOR_GRID)
	for dir in local_door_cells():
		draw_rect(tile_rect(local_door_cells()[dir]), COLOR_DOOR, false, 2.0)
	for spawn in layout.spawn_cells:
		draw_rect(Rect2(tile_rect(spawn).position + Vector2(4, 4), tile_rect(spawn).size - Vector2(8, 8)), COLOR_SPAWN, false, 2.0)
	if rule_engine != null and room_instance != null:
		_draw_channel_overlay()
	if player_local.x >= 0:
		draw_circle(tile_center(player_local), TILE_SIZE * 0.32, COLOR_PLAYER)


func _draw_channel_overlay() -> void:
	var state := rule_engine.room_state(room_instance.cell)
	if state == null:
		return
	var tints := {
		Channels.Channel.HEAT: Color(1.0, 0.25, 0.1),
		Channels.Channel.TOXIN: Color(0.3, 0.9, 0.2),
		Channels.Channel.COLD: Color(0.3, 0.8, 1.0),
		Channels.Channel.CHARGE: Color(1.0, 0.9, 0.2),
		Channels.Channel.AIRFLOW: Color(0.8, 0.8, 1.0),
	}
	var overlay_size := Vector2(DoorSpec.ROOM_SIZE * TILE_SIZE, DoorSpec.ROOM_SIZE * TILE_SIZE)
	for channel in tints:
		var value := state.get_channel(channel)
		if value <= 0:
			continue
		var tint: Color = tints[channel]
		tint.a = clampf(float(value) / float(Channels.MAX_VALUE) * 0.45, 0.05, 0.5)
		draw_rect(Rect2(Vector2.ZERO, overlay_size), tint, true)
