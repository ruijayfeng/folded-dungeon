extends TestCase
## M1 acceptance: explore -> acquire blueprint -> build node -> place rotated room
## -> walk through the new door. Asserts event log and final state.


func test_m1_build_and_enter() -> void:
	var session := DungeonSession.new()
	var start_def := _make_def(&"start", DoorSpec.Dir.E, 0)
	assert_valid(session.start_run(start_def, Vector2i(2, 2), 0, 7, 10), "start run")

	var blueprint := _make_def(&"room", DoorSpec.Dir.W | DoorSpec.Dir.E, 1)
	session.acquire_blueprint(blueprint)
	assert_true(session.has_blueprint(&"room"), "blueprint acquired")

	var controller := BuildController.new(session)
	assert_true(session.enter_build_node(), "build node entered")
	assert_true(controller.begin(blueprint), "begin preview")
	controller.set_cell(Vector2i(3, 2))
	assert_true(controller.preview_valid(), "preview valid")
	assert_valid(controller.confirm(), "place blueprint")
	assert_true(session.leave_build_node(), "build node left")
	assert_eq(session.grid.room_count(), 2, "two rooms built")
	assert_eq(session.grid.build_points, 9, "build cost deducted")
	var start_room := session.grid.start_room()
	var new_room := session.grid.get_room(Vector2i(3, 2))
	assert_true(
		start_room.world_door_anchor(DoorSpec.Dir.E).is_equal_approx(new_room.world_door_anchor(DoorSpec.Dir.W)),
		"new room door anchors align"
	)

	for i in 4:
		assert_true(session.try_move(DoorSpec.Dir.E)["ok"], "walk to door step %d" % i)
	assert_eq(session.player.local_cell, Vector2i(8, 4), "at east door")
	session.end_turn()
	var crossed := session.try_move(DoorSpec.Dir.E)
	assert_true(crossed["ok"], "cross into new room")
	assert_eq(session.player.room_cell, Vector2i(3, 2), "player room changed")
	assert_eq(session.player.local_cell, Vector2i(0, 4), "arrive at new room west door")
	assert_true(session.try_move(DoorSpec.Dir.E)["ok"], "step into new room")
	assert_eq(session.player.local_cell, Vector2i(1, 4), "inside new room")

	var types := session.event_types()
	assert_true(types.has(&"blueprint_acquired"), "blueprint event")
	assert_true(types.has(&"build_node_entered"), "build node event")
	assert_true(types.has(&"build_placed"), "build placed event")
	assert_true(types.has(&"room_entered"), "room entered event")

	var rooms_before := session.grid.room_count()
	var bp_before := session.grid.build_points
	assert_true(session.enter_build_node(), "re-enter build node for negative test")
	var invalid := session.build_room(blueprint, Vector2i(2, 2), 0)
	assert_has_code(invalid, DungeonGrid.CELL_OCCUPIED, "cannot overwrite occupied cell")
	assert_eq(session.grid.room_count(), rooms_before, "failed build keeps rooms")
	assert_eq(session.grid.build_points, bp_before, "failed build keeps budget")

	print("[M1] session snapshot: " + JSON.stringify(session.snapshot()))


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
