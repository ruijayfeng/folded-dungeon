extends TestCase
## M2-7 presentation wiring is headless-safe: overlay/debug panel accept engine refs.

func test_debug_panel_and_room_overlay_accept_engine() -> void:
	var session := DungeonSession.new()
	var room := _def(&"room", DoorSpec.Dir.E, 0)
	assert_valid(session.start_run(room, Vector2i(2, 2), 0, 3, 10), "start session")
	var engine := RuleEngine.new()
	engine.setup(session.grid, [], [], 3)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 400)

	var panel := DebugPanel.new()
	panel.setup(engine, session)
	assert_true(panel.text.contains("RuleEngine turn=0"), "debug panel renders engine state")
	assert_true(panel.text.contains("heat=400"), "debug panel renders channel values")
	panel.free()

	var view := RoomView.new()
	view.setup(session.current_room(), Vector2i(4, 4))
	view.set_rule_engine(engine)
	assert_true(view.rule_engine != null, "room view accepts rule engine")
	view.free()


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
