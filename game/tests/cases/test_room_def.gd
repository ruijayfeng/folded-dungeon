extends TestCase


func test_sample_room_data_loads() -> void:
	for path in ["res://data/rooms/start_room.tres", "res://data/rooms/combat_room.tres"]:
		var def := load(path) as RoomDef
		assert_true(def != null, "load %s" % path)
		if def == null:
			continue
		var def_errors := def.validate()
		assert_true(def_errors.is_empty(), "%s validates: %s" % [path, "; ".join(def_errors)])
		assert_true(def.layout != null, "%s has layout" % path)
		if def.layout == null:
			continue
		var layout_errors := def.layout.validate()
		assert_true(layout_errors.is_empty(), "%s layout validates: %s" % [path, "; ".join(layout_errors)])
		assert_eq(def.layout.size, Vector2i(9, 9), "%s layout size" % path)
		assert_eq(def.layout.terrain.size(), 81, "%s terrain size" % path)
		assert_true(def.layout.is_walkable(Vector2i(4, 4)), "%s center walkable" % path)
		assert_false(def.layout.is_walkable(Vector2i(0, 0)), "%s corner is wall" % path)


func test_room_def_has_no_scene_dependency() -> void:
	var def := load("res://data/rooms/start_room.tres") as RoomDef
	assert_true(def != null, "start room loaded")
	if def == null:
		return
	for property in def.get_property_list():
		var property_name: String = property["name"]
		var property_type: int = property["type"]
		assert_ne(property_name, "interior_scene", "RoomDef must not hold interior_scene")
		if property_type == TYPE_OBJECT:
			var value: Variant = def.get(property_name)
			assert_false(value is PackedScene, "RoomDef property %s must not be PackedScene" % property_name)


func test_invalid_room_def_reports_errors() -> void:
	var bad := RoomDef.new()
	var errors := bad.validate()
	assert_true(errors.size() >= 2, "empty RoomDef reports errors: %s" % "; ".join(errors))
	assert_true(_has_error(errors, "ROOM_ID_EMPTY"), "missing id reported")
	assert_true(_has_error(errors, "ROOM_LAYOUT_MISSING"), "missing layout reported")
	var bad_emitter := ChannelEmitter.new()
	bad_emitter.channel = 99
	bad_emitter.rate_per_turn = -1
	assert_true(bad_emitter.validate().size() >= 2, "invalid emitter reports errors")


func _has_error(errors: PackedStringArray, needle: String) -> bool:
	for error in errors:
		if error.contains(needle):
			return true
	return false
