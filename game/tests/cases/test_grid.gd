extends TestCase


func test_place_start_and_connected_room() -> void:
	var grid := _grid()
	var start_report := grid.place_start(_make_def(&"start", DoorSpec.Dir.E | DoorSpec.Dir.S, 0), Vector2i(2, 2))
	assert_valid(start_report, "place start room")
	assert_eq(grid.room_count(), 1, "one room")
	assert_eq(grid.start_cell, Vector2i(2, 2), "start cell recorded")
	assert_eq(grid.build_points, 10, "start room is free")

	var room_report := grid.place_room(_make_def(&"room_a", DoorSpec.Dir.W | DoorSpec.Dir.E, 1), Vector2i(3, 2))
	assert_valid(room_report, "place connected room")
	assert_eq(grid.room_count(), 2, "two rooms")
	assert_eq(grid.build_points, 9, "cost deducted")
	assert_eq(grid.edges().size(), 1, "one physical edge")

	var start_room := grid.start_room()
	var a_room := grid.get_room(Vector2i(3, 2))
	assert_true(
		start_room.world_door_anchor(DoorSpec.Dir.E).is_equal_approx(a_room.world_door_anchor(DoorSpec.Dir.W)),
		"neighbour door anchors coincide"
	)
	var graph := grid.build_graph()
	assert_eq(graph.physical_edges().size(), 1, "graph has physical edge")
	assert_eq(graph.find_path(start_room.instance_id, a_room.instance_id).size(), 2, "path start -> a")
	assert_valid(grid.validate_state(), "state valid after placement")


func test_place_failures() -> void:
	var empty_grid := _grid()
	var no_start := empty_grid.place_room(_make_def(&"solo", 15, 1), Vector2i(0, 0))
	assert_has_code(no_start, DungeonGrid.NO_START_ROOM, "start room required first")

	var grid := _grid()
	grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	var before_rooms := grid.room_count()
	var before_points := grid.build_points

	assert_has_code(grid.place_room(_make_def(&"far", 15, 1), Vector2i(0, 0)), DungeonGrid.NO_CONNECTION, "must be adjacent")
	assert_has_code(grid.place_room(_make_def(&"oob", 15, 1), Vector2i(5, 2)), DungeonGrid.CELL_OUT_OF_BOUNDS, "outside grid")
	assert_has_code(grid.place_room(_make_def(&"occupied", 15, 1), Vector2i(2, 2)), DungeonGrid.CELL_OCCUPIED, "cell occupied")
	assert_has_code(grid.place_room(_make_def(&"rot", DoorSpec.Dir.W, 1), Vector2i(3, 2), 7), DungeonGrid.INVALID_ORIENTATION, "bad orientation")
	assert_has_code(grid.place_room(RoomDef.new(), Vector2i(3, 2)), DungeonGrid.INVALID_DEF, "invalid definition")
	assert_eq(grid.room_count(), before_rooms, "failed placements leave rooms unchanged")
	assert_eq(grid.build_points, before_points, "failed placements leave budget unchanged")


func test_door_mismatch_codes() -> void:
	var sealed_grid := _grid()
	sealed_grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	assert_has_code(
		sealed_grid.place_room(_make_def(&"a", DoorSpec.Dir.E, 1), Vector2i(3, 2)),
		DungeonGrid.DOOR_SEALED,
		"new room seals existing door"
	)

	var to_wall_grid := _grid()
	to_wall_grid.place_start(_make_def(&"start", DoorSpec.Dir.S, 0), Vector2i(2, 2))
	assert_has_code(
		to_wall_grid.place_room(_make_def(&"a", DoorSpec.Dir.W, 1), Vector2i(3, 2)),
		DungeonGrid.DOOR_TO_WALL,
		"new door faces existing wall"
	)

	var boundary_grid := _grid()
	boundary_grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(3, 2))
	assert_has_code(
		boundary_grid.place_room(_make_def(&"edge", DoorSpec.Dir.W | DoorSpec.Dir.E, 1), Vector2i(4, 2)),
		DungeonGrid.DOOR_TO_BOUNDARY,
		"door points outside map"
	)

	var open_grid := _grid()
	open_grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	assert_valid(
		open_grid.place_room(_make_def(&"open", DoorSpec.Dir.W, 1), Vector2i(3, 2)),
		"door may face an empty interior cell"
	)


func test_rotation_rules() -> void:
	var failing_grid := _grid()
	failing_grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	failing_grid.place_room(_make_def(&"a", DoorSpec.Dir.W | DoorSpec.Dir.E, 1), Vector2i(3, 2))
	var failed := failing_grid.rotate_room(Vector2i(3, 2), 1)
	assert_has_code(failed, DungeonGrid.ROTATION_BREAKS_CONNECTION, "rotation that loses a door fails")
	assert_eq(failing_grid.get_room(Vector2i(3, 2)).orientation, 0, "failed rotation does not commit")

	var ok_grid := _grid()
	ok_grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	ok_grid.place_room(_make_def(&"a", 15, 1), Vector2i(3, 2))
	var ok := ok_grid.rotate_room(Vector2i(3, 2), 1)
	assert_valid(ok, "rotation keeping all doors succeeds")
	assert_eq(ok_grid.get_room(Vector2i(3, 2)).orientation, 1, "orientation committed")
	assert_valid(ok_grid.validate_state(), "state valid after rotation")


func test_replace_and_budget() -> void:
	var grid := _grid(10)
	grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	grid.place_room(_make_def(&"a", DoorSpec.Dir.W | DoorSpec.Dir.E, 1), Vector2i(3, 2))
	assert_eq(grid.build_points, 9, "initial build points")
	var old_instance_id := grid.get_room(Vector2i(3, 2)).instance_id
	var replaced := grid.replace_room(Vector2i(3, 2), _make_def(&"b", DoorSpec.Dir.W | DoorSpec.Dir.E, 2), 0)
	assert_valid(replaced, "replace succeeds")
	assert_eq(grid.build_points, 7, "refund 0 for cost 1, pay 2")
	assert_eq(grid.get_room(Vector2i(3, 2)).definition.id, &"b", "definition replaced")
	assert_eq(grid.get_room(Vector2i(3, 2)).instance_id, old_instance_id, "instance id preserved")

	var failed_replace := grid.replace_room(Vector2i(3, 2), _make_def(&"c", DoorSpec.Dir.E, 1), 0)
	assert_has_code(failed_replace, DungeonGrid.DOOR_SEALED, "replace that seals a door fails")
	assert_eq(grid.get_room(Vector2i(3, 2)).definition.id, &"b", "failed replace leaves state")
	assert_eq(grid.build_points, 7, "failed replace leaves budget")

	var poor_grid := _grid(0)
	poor_grid.place_start(_make_def(&"s", DoorSpec.Dir.E, 0), Vector2i(0, 0))
	assert_has_code(
		poor_grid.place_room(_make_def(&"a", DoorSpec.Dir.W, 1), Vector2i(1, 0)),
		DungeonGrid.NO_BUILD_RESOURCE,
		"not enough build points"
	)

	var limited_grid := DungeonGrid.new()
	limited_grid.set_budget(10, 1)
	limited_grid.place_start(_make_def(&"s", DoorSpec.Dir.E, 0), Vector2i(0, 0))
	assert_has_code(
		limited_grid.place_room(_make_def(&"a", DoorSpec.Dir.W, 1), Vector2i(1, 0)),
		DungeonGrid.ROOM_LIMIT,
		"room limit enforced"
	)


func test_remove_and_connectivity() -> void:
	var grid := _grid()
	grid.place_start(_make_def(&"start", DoorSpec.Dir.E | DoorSpec.Dir.S, 0), Vector2i(2, 2))
	grid.place_room(_make_def(&"a", DoorSpec.Dir.W | DoorSpec.Dir.E, 1), Vector2i(3, 2))
	grid.place_room(_make_def(&"b", DoorSpec.Dir.W, 1), Vector2i(4, 2))
	var before_rooms := grid.room_count()
	var before_points := grid.build_points
	assert_has_code(grid.remove_room(Vector2i(3, 2)), DungeonGrid.DISCONNECTED, "removing bridge disconnects")
	assert_eq(grid.room_count(), before_rooms, "failed removal leaves rooms")
	assert_eq(grid.build_points, before_points, "failed removal leaves budget")
	assert_valid(grid.remove_room(Vector2i(4, 2)), "removing leaf room succeeds")
	assert_eq(grid.room_count(), 2, "leaf room removed")
	assert_has_code(grid.remove_room(Vector2i(2, 2)), DungeonGrid.START_ROOM_REQUIRED, "start room protected")


func test_boss_path_and_state() -> void:
	var grid := _grid()
	grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	grid.place_room(_make_def(&"a", DoorSpec.Dir.W | DoorSpec.Dir.E, 1), Vector2i(3, 2))
	grid.place_room(_make_def(&"b", DoorSpec.Dir.W, 1), Vector2i(4, 2))
	assert_valid(grid.set_boss(Vector2i(4, 2)), "set boss room")
	assert_eq(grid.boss_cell, Vector2i(4, 2), "boss cell recorded")
	assert_valid(grid.validate_state(), "state valid with boss")
	var graph := grid.build_graph()
	assert_eq(
		graph.find_path(grid.start_room().instance_id, grid.boss_room().instance_id).size(),
		3,
		"start -> boss path exists"
	)
	assert_has_code(grid.remove_room(Vector2i(3, 2)), DungeonGrid.DISCONNECTED, "boss path cannot be broken")
	assert_eq(grid.boss_cell, Vector2i(4, 2), "failed mutation keeps boss")


func test_room_graph_physical_and_virtual_edges() -> void:
	var grid := _grid()
	grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	grid.place_room(_make_def(&"a", DoorSpec.Dir.W, 1), Vector2i(3, 2))
	var graph := grid.build_graph()
	var start_id := grid.start_room().instance_id
	var a_id := grid.get_room(Vector2i(3, 2)).instance_id
	assert_eq(graph.node_ids().size(), 2, "two graph nodes")
	assert_true(graph.has_edge(start_id, a_id), "physical edge exists")
	assert_eq(graph.find_path(start_id, a_id).size(), 2, "path start -> a")

	var standalone := RoomGraph.new()
	standalone.add_edge(&"a", &"b")
	assert_true(standalone.connect_virtual(&"b", &"c"), "virtual edge connects")
	assert_true(standalone.has_edge(&"b", &"c"), "virtual edge present")
	assert_eq(standalone.find_path(&"a", &"c").size(), 3, "path through virtual edge")
	assert_true(standalone.disconnect_virtual(&"b", &"c"), "virtual edge disconnects")
	assert_eq(standalone.find_path(&"a", &"c").size(), 0, "no path after disconnect")


func test_same_operations_produce_same_ids() -> void:
	var a := _build_chain()
	var b := _build_chain()
	assert_eq(_room_id_signature(a), _room_id_signature(b), "deterministic instance ids")
	assert_eq(a.build_points, b.build_points, "deterministic budget")
	assert_eq(a.edges().size(), b.edges().size(), "deterministic edge count")


func _build_chain() -> DungeonGrid:
	var grid := _grid()
	grid.place_start(_make_def(&"start", DoorSpec.Dir.E, 0), Vector2i(2, 2))
	grid.place_room(_make_def(&"a", DoorSpec.Dir.W | DoorSpec.Dir.E, 1), Vector2i(3, 2))
	return grid


func _room_id_signature(grid: DungeonGrid) -> String:
	var ids: Array[String] = []
	for room in grid.all_rooms():
		ids.append(String(room.instance_id))
	return JSON.stringify(ids)


func _grid(points: int = 10) -> DungeonGrid:
	var grid := DungeonGrid.new()
	grid.set_budget(points, 25)
	return grid


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
