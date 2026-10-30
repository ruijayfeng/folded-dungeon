extends TestCase


func test_doc_example_propagation_and_combustion() -> void:
	var grid := _build_forge_toxin_grid()
	var recipes := RuleEngine.load_recipe_library()
	var engine := RuleEngine.new()
	engine.setup(grid, recipes, [], 1234)
	var forge_cell := Vector2i(1, 2)
	var toxin_cell := Vector2i(2, 2)

	engine.tick()
	assert_eq(engine.get_channel(forge_cell, Channels.Channel.HEAT), 250, "turn1 forge heat")
	assert_eq(engine.get_channel(toxin_cell, Channels.Channel.HEAT), 100, "turn1 toxin room heat (250*40%)")
	assert_eq(engine.get_channel(toxin_cell, Channels.Channel.TOXIN), 200, "turn1 toxin emitted")
	assert_false(_has_recipe_event(engine.events, &"combustion", 1), "no combustion on turn 1")

	engine.tick()
	assert_eq(engine.get_channel(toxin_cell, Channels.Channel.HEAT), 300, "turn2 toxin room heat")
	assert_eq(engine.get_channel(toxin_cell, Channels.Channel.TOXIN), 400, "turn2 toxin")

	var turn3_events := engine.tick()
	assert_eq(engine.get_channel(toxin_cell, Channels.Channel.HEAT), 900, "combustion adds +300 heat")
	assert_eq(engine.get_channel(toxin_cell, Channels.Channel.TOXIN), 100, "combustion consumes 500 toxin")
	var toxin_state := engine.room_state(toxin_cell)
	assert_true(toxin_state.has_state(&"burning"), "burning state set")
	var combustion := _find_recipe_event(turn3_events, &"combustion", toxin_cell)
	assert_true(not combustion.is_empty(), "combustion triggered on turn 3")
	if not combustion.is_empty():
		var before: Array = combustion["channels_before"]
		assert_eq(before[Channels.Channel.HEAT], 600, "channels before: heat 600")
		assert_eq(before[Channels.Channel.TOXIN], 600, "channels before: toxin 600")
	var wave_emitted := false
	for event in turn3_events:
		if event["type"] == &"wave_emitted" and event["cell"] == toxin_cell:
			wave_emitted = true
	assert_true(wave_emitted, "combustion emits a fire wave from the gas room")


func test_one_hop_per_turn() -> void:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	assert_valid(grid.place_start(_room_def(&"a", DoorSpec.Dir.E, 0, Channels.Channel.HEAT, 250), Vector2i(0, 2)), "a")
	assert_valid(grid.place_room(_room_def(&"b", DoorSpec.Dir.W | DoorSpec.Dir.E), Vector2i(1, 2)), "b")
	assert_valid(grid.place_room(_room_def(&"c", DoorSpec.Dir.W), Vector2i(2, 2)), "c")
	var engine := RuleEngine.new()
	engine.setup(grid, [], [], 1)
	engine.tick()
	assert_eq(engine.get_channel(Vector2i(1, 2), Channels.Channel.HEAT), 100, "b receives from a in turn 1")
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.HEAT), 0, "c does not receive in turn 1 (no two-hop transfer)")
	engine.tick()
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.HEAT), 40, "c receives from b in turn 2")


func _build_forge_toxin_grid() -> DungeonGrid:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	var forge := load("res://data/rooms/forge_room.tres") as RoomDef
	var toxin := load("res://data/rooms/toxin_room.tres") as RoomDef
	assert_valid(grid.place_start(forge, Vector2i(1, 2), 0), "place forge")
	assert_valid(grid.place_room(toxin, Vector2i(2, 2), 0), "place toxin")
	return grid


func _room_def(room_id: StringName, mask: int, cost: int = 1, channel: int = -1, rate: int = 0) -> RoomDef:
	var def := RoomDef.new()
	def.id = room_id
	def.display_name = String(room_id)
	def.door_mask = mask
	def.build_cost = cost
	if channel >= 0:
		var emitter := ChannelEmitter.new()
		emitter.channel = channel
		emitter.rate_per_turn = rate
		var emitters: Array[ChannelEmitter] = [emitter]
		def.emitters = emitters
	var layout := RoomLayout.new()
	layout.size = Vector2i(9, 9)
	layout.terrain = RoomLayout.make_border_terrain()
	var spawns: Array[Vector2i] = [Vector2i(4, 4)]
	layout.spawn_cells = spawns
	layout.fill_derived_door_data()
	def.layout = layout
	return def


func _find_recipe_event(events_list: Array, recipe_id: StringName, cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	for event in events_list:
		if event["type"] != &"reaction_triggered" or event["recipe"] != recipe_id:
			continue
		if cell != Vector2i(-1, -1) and event["cell"] != cell:
			continue
		return event
	return {}


func _has_recipe_event(events_list: Array, recipe_id: StringName, _turn: int) -> bool:
	return not _find_recipe_event(events_list, recipe_id).is_empty()


func _has_event_type(events_list: Array, event_type: StringName) -> bool:
	for event in events_list:
		if event["type"] == event_type:
			return true
	return false
