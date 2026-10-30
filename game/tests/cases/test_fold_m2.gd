extends TestCase
## M2-8 (D1 light version): fold chamber grants a fold charge; a fold creates a
## virtual propagation edge between two non-adjacent rooms.


func test_fold_grants_virtual_edge() -> void:
	var session := DungeonSession.new()
	var start_def := _def(&"start", 15, 0)
	assert_valid(session.start_run(start_def, Vector2i(2, 2), 0, 5, 10), "start run")

	var room_a := _def(&"a", DoorSpec.Dir.W | DoorSpec.Dir.E, 0)
	var room_c := _def(&"c", DoorSpec.Dir.W, 0)
	var fold_room := _def(&"fold_chamber", DoorSpec.Dir.S, 0)
	fold_room.tags = _tags([&"fold_chamber"])
	session.acquire_blueprint(room_a)
	session.acquire_blueprint(room_c)
	session.acquire_blueprint(fold_room)

	var wrong_phase := session.activate_fold(Vector2i(2, 2), Vector2i(4, 2))
	assert_has_code(wrong_phase, &"WRONG_PHASE", "fold requires a build node")
	assert_true(session.enter_build_node(), "build node entered")
	assert_valid(session.build_room(fold_room, Vector2i(2, 1), 0), "fold chamber built")
	assert_eq(session.fold_charges, 1, "fold charge granted")
	assert_valid(session.build_room(room_a, Vector2i(3, 2), 0), "room a built")
	assert_valid(session.build_room(room_c, Vector2i(4, 2), 0), "room c built")
	assert_eq(session.folded_edges.size(), 0, "no fold yet")

	var folded := session.activate_fold(Vector2i(2, 2), Vector2i(4, 2))
	assert_valid(folded, "fold activated between non-adjacent rooms")
	assert_eq(session.fold_charges, 0, "fold charge consumed")
	assert_eq(session.folded_edges.size(), 1, "virtual edge recorded")
	assert_has_code(session.activate_fold(Vector2i(2, 2), Vector2i(4, 2)), &"NO_FOLD_CHARGE", "second fold needs a charge")

	var engine := RuleEngine.new()
	engine.setup(session.grid, [], session.propagation_virtual_edges(), 1)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 400)
	engine.tick()
	assert_eq(engine.get_channel(Vector2i(3, 2), Channels.Channel.HEAT), 160, "room a receives via physical edge")
	assert_eq(engine.get_channel(Vector2i(4, 2), Channels.Channel.HEAT), 160, "room c receives via folded virtual edge")

	assert_true(session.release_fold(0), "fold released")
	var engine_no_fold := RuleEngine.new()
	engine_no_fold.setup(session.grid, [], session.propagation_virtual_edges(), 1)
	engine_no_fold.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 400)
	engine_no_fold.tick()
	assert_eq(engine_no_fold.get_channel(Vector2i(4, 2), Channels.Channel.HEAT), 0, "no propagation without fold")


func _def(room_id: StringName, mask: int, cost: int) -> RoomDef:
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


func _tags(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(value)
	return result
