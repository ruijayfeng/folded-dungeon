extends TestCase


func test_preview_and_phase_gate() -> void:
	var session := _new_session(DoorSpec.Dir.E)
	var blueprint := _make_def(&"room", DoorSpec.Dir.W | DoorSpec.Dir.E, 1)
	session.acquire_blueprint(blueprint)
	var controller := BuildController.new(session)
	assert_true(controller.begin(blueprint), "begin preview")
	controller.set_cell(Vector2i(3, 2))
	assert_true(controller.preview_valid(), "preview valid before build node")

	var before := JSON.stringify(session.snapshot())
	var wrong_phase := controller.confirm()
	assert_has_code(wrong_phase, &"WRONG_PHASE", "cannot build during explore phase")
	assert_true(controller.active, "controller stays active after failed confirm")
	assert_eq(JSON.stringify(session.snapshot()), before, "failed confirm does not change state")

	assert_true(session.enter_build_node(), "enter build node")
	var report := controller.confirm()
	assert_valid(report, "build succeeds during build node")
	assert_false(controller.active, "controller closed after success")
	assert_eq(session.grid.room_count(), 2, "room added")
	assert_eq(session.grid.build_points, 9, "cost deducted")
	assert_true(session.event_types().has(&"build_placed"), "build_placed logged")


func test_rotation_invalidates_preview_without_mutation() -> void:
	var session := _new_session(DoorSpec.Dir.E)
	var blueprint := _make_def(&"room", DoorSpec.Dir.W | DoorSpec.Dir.E, 1)
	session.acquire_blueprint(blueprint)
	var controller := BuildController.new(session)
	assert_true(session.enter_build_node())
	assert_true(controller.begin(blueprint))
	controller.set_cell(Vector2i(3, 2))
	assert_true(controller.preview_valid(), "initial preview valid")

	var before := JSON.stringify(session.snapshot())
	controller.rotate()
	assert_false(controller.preview_valid(), "rotation loses the matching west door")
	assert_has_code(controller.preview, DungeonGrid.DOOR_SEALED, "preview reports sealed door")
	assert_eq(JSON.stringify(session.snapshot()), before, "preview/rotation never mutates the run")
	assert_eq(controller.orientation, 1, "preview orientation updated")

	for i in 3:
		controller.rotate()
	assert_true(controller.preview_valid(), "four rotations return to valid orientation")


func test_build_requires_blueprint_and_valid_cell() -> void:
	var session := _new_session(DoorSpec.Dir.E)
	var unbound := _make_def(&"unbound", DoorSpec.Dir.W, 1)
	assert_true(session.enter_build_node())
	var no_blueprint := session.build_room(unbound, Vector2i(3, 2), 0)
	assert_has_code(no_blueprint, &"NO_BLUEPRINT", "blueprint required")

	session.acquire_blueprint(unbound)
	var rooms_before := session.grid.room_count()
	var points_before := session.grid.build_points
	var occupied := session.build_room(unbound, Vector2i(2, 2), 0)
	assert_has_code(occupied, DungeonGrid.CELL_OCCUPIED, "cannot build on start room")
	assert_eq(session.grid.room_count(), rooms_before, "failed build keeps rooms")
	assert_eq(session.grid.build_points, points_before, "failed build keeps budget")


func _new_session(start_mask: int, budget: int = 10) -> DungeonSession:
	var session := DungeonSession.new()
	var start_def := _make_def(&"start", start_mask, 0)
	var report := session.start_run(start_def, Vector2i(2, 2), 0, 99, budget)
	assert_valid(report, "start session")
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
