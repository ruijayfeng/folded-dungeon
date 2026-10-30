extends TestCase


func test_room_scenes_instantiate() -> void:
	var paths := [
		"res://presentation/rooms/room_template.tscn",
		"res://presentation/rooms/start_room.tscn",
		"res://presentation/rooms/combat_room.tscn",
	]
	for path in paths:
		var packed := load(path) as PackedScene
		assert_true(packed != null, "load %s" % path)
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		assert_true(instance != null, "instantiate %s" % path)
		assert_true(instance.has_method("local_door_cells"), "RoomView script on %s" % path)
		instance.free()


func test_data_bound_room_scenes_match_layout() -> void:
	var pairs := [
		["res://presentation/rooms/start_room.tscn", "res://data/rooms/start_room.tres"],
		["res://presentation/rooms/combat_room.tscn", "res://data/rooms/combat_room.tres"],
	]
	for pair in pairs:
		var packed := load(pair[0]) as PackedScene
		var instance: Node = packed.instantiate()
		var def: RoomDef = instance.call("get_room_def")
		assert_true(def != null, "room def loaded for %s" % pair[0])
		if def == null:
			instance.free()
			continue
		assert_eq(String(def.id), String((load(pair[1]) as RoomDef).id), "scene bound to expected data")
		var doors: Dictionary = instance.call("local_door_cells")
		for dir in def.door_dirs():
			assert_eq(doors[dir], DoorSpec.local_door_cell(dir, 0), "door cell matches for dir %d" % dir)
		instance.free()


func test_main_scene_instantiates() -> void:
	var packed := load("res://presentation/main.tscn") as PackedScene
	assert_true(packed != null, "main scene loads")
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	assert_true(instance != null, "main scene instantiates")
	assert_true(instance.has_method("_ready"), "main scene has script")
	instance.free()
