extends TestCase
## M0 acceptance scenario: build a legal 5x5 layout, rotate a room, set a boss,
## and prove failed mutations do not change state.


func test_build_layout_with_rotation_and_boss() -> void:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	assert_valid(grid.place_start(_make_def(&"start", DoorSpec.Dir.E | DoorSpec.Dir.S, 0), Vector2i(2, 2)), "start room")
	assert_valid(grid.place_room(_make_def(&"cross", 15, 1), Vector2i(3, 2)), "cross room east")
	assert_valid(grid.place_room(_make_def(&"boss", DoorSpec.Dir.W, 1), Vector2i(4, 2)), "boss room east")
	assert_valid(grid.place_room(_make_def(&"south", DoorSpec.Dir.N, 1), Vector2i(2, 3)), "south room")
	assert_eq(grid.room_count(), 4, "four rooms built")
	assert_eq(grid.build_points, 7, "three rooms cost 1 each from 10")
	assert_eq(grid.edges().size(), 3, "three door connections")
	assert_valid(grid.set_boss(Vector2i(4, 2)), "boss accepted")
	assert_valid(grid.validate_state(), "layout state valid")

	var start_room := grid.start_room()
	var cross_room := grid.get_room(Vector2i(3, 2))
	var boss_room := grid.get_room(Vector2i(4, 2))
	assert_true(
		start_room.world_door_anchor(DoorSpec.Dir.E).is_equal_approx(cross_room.world_door_anchor(DoorSpec.Dir.W)),
		"start/cross door anchors coincide"
	)
	assert_true(
		cross_room.world_door_anchor(DoorSpec.Dir.E).is_equal_approx(boss_room.world_door_anchor(DoorSpec.Dir.W)),
		"cross/boss door anchors coincide"
	)

	assert_valid(grid.rotate_room(Vector2i(3, 2), 1), "rotate cross room keeping all doors")
	assert_eq(grid.get_room(Vector2i(3, 2)).orientation, 1, "cross room rotated")
	assert_has_code(
		grid.rotate_room(Vector2i(2, 3), 1),
		DungeonGrid.ROTATION_BREAKS_CONNECTION,
		"south room rotation would break its only door"
	)
	assert_eq(grid.get_room(Vector2i(2, 3)).orientation, 0, "failed rotation does not commit")

	print("[M0] layout snapshot: " + JSON.stringify(_snapshot_text(grid)))


func _snapshot_text(grid: DungeonGrid) -> Dictionary:
	var rooms: Array = []
	for room in grid.all_rooms():
		rooms.append({
			"id": String(room.instance_id),
			"def": String(room.definition.id),
			"cell": str(room.cell),
			"orientation": room.orientation,
		})
	return {
		"rooms": rooms,
		"edges": grid.edges().size(),
		"build_points": grid.build_points,
		"start": str(grid.start_cell),
		"boss": str(grid.boss_cell),
	}


func _make_def(room_id: StringName, mask: int, cost: int = 1) -> RoomDef:
	var def := RoomDef.new()
	def.id = room_id
	def.display_name = String(room_id)
	def.door_mask = mask
	def.build_cost = cost
	var layout := RoomLayout.new()
	layout.size = Vector2i(9, 9)
	layout.terrain = RoomLayout.make_border_terrain()
	var spawns: Array[Vector2i] = [Vector2i(4, 4)]
	layout.spawn_cells = spawns
	layout.fill_derived_door_data()
	def.layout = layout
	return def
