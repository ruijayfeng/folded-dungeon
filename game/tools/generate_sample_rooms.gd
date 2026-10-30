extends SceneTree
## Generates the M0 sample RoomDef resources through ResourceSaver
## (never hand-edit .tres files). Run with: game/tools/godot gen-data

const START_PATH := "res://data/rooms/start_room.tres"
const COMBAT_PATH := "res://data/rooms/combat_room.tres"


func _initialize() -> void:
	var errors := 0
	errors += _save_room(_make_start_room(), START_PATH)
	errors += _save_room(_make_combat_room(), COMBAT_PATH)
	if errors > 0:
		push_error("sample room generation failed: %d error(s)" % errors)
		quit(1)
		return
	print("[M0] sample rooms generated: %s, %s" % [START_PATH, COMBAT_PATH])
	quit(0)


func _make_base_layout() -> RoomLayout:
	var layout := RoomLayout.new()
	layout.size = Vector2i(DoorSpec.ROOM_SIZE, DoorSpec.ROOM_SIZE)
	layout.terrain = RoomLayout.make_border_terrain()
	var spawns: Array[Vector2i] = [Vector2i(4, 4)]
	layout.spawn_cells = spawns
	layout.fill_derived_door_data()
	return layout


func _make_start_room() -> RoomDef:
	var def := RoomDef.new()
	def.id = &"start_room"
	def.display_name = "起始房间"
	def.category = RoomDef.Category.SPECIAL
	def.door_mask = DoorSpec.Dir.N | DoorSpec.Dir.E
	def.build_cost = 0
	def.layout = _make_base_layout()
	var tags: Array[StringName] = [&"start"]
	def.tags = tags
	def.description = "玩家进入本层的位置；带北门与东门。"
	return def


func _make_combat_room() -> RoomDef:
	var def := RoomDef.new()
	def.id = &"combat_room"
	def.display_name = "战斗房间"
	def.category = RoomDef.Category.COMBAT
	def.door_mask = DoorSpec.Dir.N | DoorSpec.Dir.E | DoorSpec.Dir.S | DoorSpec.Dir.W
	def.build_cost = 1
	def.layout = _make_base_layout()
	var tags: Array[StringName] = [&"combat"]
	def.tags = tags
	def.description = "普通战斗房间；四面均有门，便于构筑连接。"
	return def


func _save_room(def: RoomDef, path: String) -> int:
	var def_errors := def.validate()
	if not def_errors.is_empty():
		push_error("invalid room '%s': %s" % [path, "; ".join(def_errors)])
		return 1
	var result := ResourceSaver.save(def, path)
	if result != OK:
		push_error("ResourceSaver.save failed for %s: %d" % [path, result])
		return 1
	return 0
