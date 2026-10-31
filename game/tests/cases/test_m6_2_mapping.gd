extends TestCase
## M6-2: 3D macro map mapping + per-room theme coverage (presentation pure data).


func test_macro_cell_world_roundtrip() -> void:
	for y in MacroMap3D.GRID:
		for x in MacroMap3D.GRID:
			var cell := Vector2i(x, y)
			var world := MacroMap3D.cell_to_world(cell)
			assert_eq(MacroMap3D.world_to_cell(world), cell, "macro cell roundtrip %s" % str(cell))


func test_every_room_has_theme() -> void:
	var files := DirAccess.get_files_at("res://data/rooms")
	var count := 0
	for file in files:
		if not file.ends_with(".tres"):
			continue
		var def: RoomDef = load("res://data/rooms/" + file) as RoomDef
		assert_true(def != null, "load room %s" % file)
		if def == null:
			continue
		assert_true(RoomTheme.THEMES.has(def.id), "theme exists for %s" % def.id)
		var theme := RoomTheme.for_id(def.id)
		assert_true(theme.has("tint"), "tint for %s" % def.id)
		assert_true(String(theme.get("label", "")).length() > 0, "label for %s" % def.id)
		count += 1
	assert_eq(count, 16, "16 room defs themed")


func test_theme_accents_are_distinct() -> void:
	var seen: Array[Color] = []
	for id in RoomTheme.THEMES:
		var accent: Color = RoomTheme.accent_for(id)
		assert_false(seen.has(accent), "accent should be unique-ish: %s" % id)
		seen.append(accent)
