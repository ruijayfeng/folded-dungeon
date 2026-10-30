extends TestCase


func test_determinism_and_preview_match() -> void:
	var first := _make_engine()
	var second := _make_engine()
	var first_events: Array = []
	var second_events: Array = []
	for i in 3:
		first_events.append_array(first.tick())
		second_events.append_array(second.tick())
	assert_eq(JSON.stringify(first_events), JSON.stringify(second_events), "two engines produce identical events")
	assert_eq(JSON.stringify(first.snapshot()), JSON.stringify(second.snapshot()), "two engines produce identical state")

	var preview_engine := _make_engine()
	var preview := preview_engine.preview_turns(3)
	assert_eq(JSON.stringify(preview["events"]), JSON.stringify(first_events), "preview events match real ticks")
	assert_eq(JSON.stringify(preview["state"]), JSON.stringify(first.snapshot()), "preview state matches real state")
	assert_eq(preview_engine.turn, 0, "preview does not advance the original engine")
	assert_eq(preview_engine.get_channel(Vector2i(2, 2), Channels.Channel.HEAT), 0, "preview does not mutate channels")


func test_phase_order() -> void:
	var engine := _make_engine()
	var turn1 := engine.tick()
	assert_true(_index_of(turn1, &"channel_emitted") < _index_of(turn1, &"channel_transferred"), "emitters before propagation")
	engine.tick()
	var turn3 := engine.tick()
	var emitted := _index_of(turn3, &"channel_emitted")
	var transferred := _index_of(turn3, &"channel_transferred")
	var reacted := _index_of(turn3, &"reaction_triggered")
	assert_true(emitted >= 0 and transferred > emitted, "emitters before propagation on turn 3")
	assert_true(reacted > transferred, "reactions after propagation on turn 3")
	assert_true(_index_of(turn3, &"wave_emitted") > reacted, "wave resolves with the reaction effect")


func test_decay_and_periodic() -> void:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	var ballista := load("res://data/rooms/ballista_room.tres") as RoomDef
	assert_valid(grid.place_start(ballista, Vector2i(2, 2)), "ballista placed")
	var engine := RuleEngine.new()
	engine.setup(grid, [], [], 1)
	engine.set_channel_params(Channels.Channel.HEAT, 40, 10)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 500)
	var turn1 := engine.tick()
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.HEAT), 490, "heat decays by 10 per turn")
	assert_false(_has_event_type(turn1, &"room_periodic"), "no periodic event on turn 1")
	var turn2 := engine.tick()
	assert_true(_has_event_type(turn2, &"room_periodic"), "periodic event on turn 2")
	var periodic := _find_event(turn2, &"room_periodic")
	assert_eq(periodic.get("event_id", &""), &"turret_fire", "ballista periodic event id")


func _make_engine() -> RuleEngine:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	var forge := load("res://data/rooms/forge_room.tres") as RoomDef
	var toxin := load("res://data/rooms/toxin_room.tres") as RoomDef
	assert_valid(grid.place_start(forge, Vector2i(1, 2)), "forge placed")
	assert_valid(grid.place_room(toxin, Vector2i(2, 2)), "toxin placed")
	var engine := RuleEngine.new()
	engine.setup(grid, RuleEngine.load_recipe_library(), [], 1234)
	return engine


func _index_of(events_list: Array, event_type: StringName) -> int:
	for index in events_list.size():
		if events_list[index]["type"] == event_type:
			return index
	return -1


func _find_event(events_list: Array, event_type: StringName) -> Dictionary:
	for event in events_list:
		if event["type"] == event_type:
			return event
	return {}


func _has_event_type(events_list: Array, event_type: StringName) -> bool:
	return not _find_event(events_list, event_type).is_empty()
