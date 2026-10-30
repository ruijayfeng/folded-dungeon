extends TestCase


func test_move_inside_room_and_wall_block() -> void:
	var session := _new_session(DoorSpec.Dir.E)
	assert_eq(session.player.local_cell, Vector2i(4, 4), "spawn cell")
	var moved := session.try_move(DoorSpec.Dir.W)
	assert_true(moved["ok"], "move west")
	assert_eq(session.player.local_cell, Vector2i(3, 4), "position after move")
	assert_eq(session.player.move_points, 3, "move point consumed")
	assert_true(session.try_move(DoorSpec.Dir.W)["ok"], "second west step")
	assert_true(session.try_move(DoorSpec.Dir.W)["ok"], "third west step")
	assert_eq(session.player.local_cell, Vector2i(1, 4), "at west interior")
	var blocked := session.try_move(DoorSpec.Dir.W)
	assert_false(blocked["ok"], "wall blocks")
	assert_eq(blocked["reason"], &"BLOCKED")
	assert_eq(session.player.local_cell, Vector2i(1, 4), "blocked move keeps position")


func test_door_without_neighbor_room() -> void:
	var session := _new_session(DoorSpec.Dir.E)
	for i in 4:
		assert_true(session.try_move(DoorSpec.Dir.E)["ok"], "east step %d" % i)
	assert_eq(session.player.local_cell, Vector2i(8, 4), "standing on east door cell")
	assert_eq(session.player.move_points, 0, "move points exhausted")
	var no_points := session.try_move(DoorSpec.Dir.E)
	assert_eq(no_points["reason"], &"NO_MOVE_POINTS")
	session.end_turn()
	var no_neighbor := session.try_move(DoorSpec.Dir.E)
	assert_false(no_neighbor["ok"], "door without neighbor cannot be crossed")
	assert_eq(no_neighbor["reason"], &"NO_NEIGHBOR_ROOM")


func test_cross_into_neighbor_room() -> void:
	var session := _new_session(DoorSpec.Dir.E)
	var neighbor_def := _make_def(&"neighbor", DoorSpec.Dir.W, 1)
	assert_valid(session.grid.place_room(neighbor_def, Vector2i(3, 2), 0), "place neighbor")
	for i in 4:
		assert_true(session.try_move(DoorSpec.Dir.E)["ok"], "east step %d" % i)
	session.end_turn()
	var crossed := session.try_move(DoorSpec.Dir.E)
	assert_true(crossed["ok"], "cross into neighbor")
	assert_true(crossed["room_changed"], "room changed flag")
	assert_eq(session.player.room_cell, Vector2i(3, 2), "new macro cell")
	assert_eq(session.player.local_cell, Vector2i(0, 4), "arrive on neighbour door cell")
	assert_true(session.try_move(DoorSpec.Dir.E)["ok"], "step inside neighbour")
	assert_eq(session.player.local_cell, Vector2i(1, 4), "inside neighbour room")

	var found_room_entered := false
	for event in session.events:
		if event["type"] == &"room_entered":
			found_room_entered = true
			assert_true(String(event["to_room"]).begins_with("neighbor#"), "room_entered targets neighbour")
	assert_true(found_room_entered, "room_entered event logged")


func test_wrong_phase_and_turn_reset() -> void:
	var session := _new_session(DoorSpec.Dir.E)
	assert_true(session.enter_build_node(), "enter build node")
	var move_in_build := session.try_move(DoorSpec.Dir.E)
	assert_eq(move_in_build["reason"], &"WRONG_PHASE")
	assert_true(session.leave_build_node(), "leave build node")
	var turn_before := session.turn
	session.end_turn()
	assert_eq(session.turn, turn_before + 1, "turn advanced")
	assert_eq(session.player.move_points, Unit.DEFAULT_MOVE_POINTS, "move points refilled")
	var invalid_dir := session.try_move(0)
	assert_eq(invalid_dir["reason"], &"INVALID_DIRECTION")


func _new_session(start_mask: int, budget: int = 10) -> DungeonSession:
	var session := DungeonSession.new()
	var start_def := _make_def(&"start", start_mask, 0)
	var report := session.start_run(start_def, Vector2i(2, 2), 0, 42, budget)
	assert_valid(report, "start M1 session")
	return session


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
