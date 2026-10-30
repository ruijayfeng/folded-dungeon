extends TestCase


func test_priority_order_and_effects() -> void:
	var grid := _two_room_grid()
	var low := _recipe(&"low", 5, [_condition_heat(100)], [_channel_effect(Channels.Channel.COLD, 100)])
	var high := _recipe(&"high", 20, [_condition_heat(100)], [_channel_effect(Channels.Channel.COLD, 200)])
	var recipes: Array[ReactionRecipe] = [high, low]
	var engine := RuleEngine.new()
	engine.setup(grid, recipes, [], 1)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 300)
	var turn_events := engine.tick()
	var order: Array = []
	for event in turn_events:
		if event["type"] == &"reaction_triggered":
			order.append(String(event["recipe"]))
	assert_eq(order.slice(0, 2), ["low", "high"], "lower priority value resolves first (per room)")
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.COLD), 300, "both effects applied")


func test_cooldown_blocks_for_one_turn() -> void:
	var grid := _two_room_grid()
	var recipe := _recipe(&"pulse", 10, [_condition_heat(100)], [_channel_effect(Channels.Channel.HEAT, -100)])
	recipe.cooldown_turns = 1
	var recipes: Array[ReactionRecipe] = [recipe]
	var engine := RuleEngine.new()
	engine.setup(grid, recipes, [], 1)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 500)
	engine.tick()
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.HEAT), 400, "turn1 triggers")
	engine.tick()
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.HEAT), 400, "cooldown blocks turn2")
	engine.tick()
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.HEAT), 300, "turn3 triggers again")


func test_neighbor_scope_condition() -> void:
	var grid := _two_room_grid()
	var condition := _condition_heat(300)
	condition.scope = ConditionDef.Scope.NEIGHBOR_ANY
	var recipe := _recipe(&"neighbor_heat", 10, [condition], [_channel_effect(Channels.Channel.COLD, 100)])
	var recipes: Array[ReactionRecipe] = [recipe]
	var engine := RuleEngine.new()
	engine.setup(grid, recipes, [], 1)
	engine.set_channel(Vector2i(3, 2), Channels.Channel.HEAT, 400)
	engine.tick()
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.COLD), 100, "self room reacts to neighbor heat")
	assert_eq(engine.get_channel(Vector2i(3, 2), Channels.Channel.COLD), 0, "neighbor room has no matching neighbor above threshold")


func test_thermal_neutralize_recipe() -> void:
	var grid := _two_room_grid()
	var recipes := _recipes_with_id(&"thermal_neutralize")
	var engine := RuleEngine.new()
	engine.setup(grid, recipes, [], 1)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 500)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.COLD, 500)
	engine.tick()
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.HEAT), 300, "heat reduced by 200")
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.COLD), 300, "cold reduced by 200")


func test_accumulator_absorbs_and_releases() -> void:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	var source := _room_def(&"source", DoorSpec.Dir.E)
	assert_valid(grid.place_start(source, Vector2i(2, 2)), "source placed")
	var accumulator_def := _room_def(&"accumulator", DoorSpec.Dir.W)
	accumulator_def.tags = _tags([&"charge_storage"])
	accumulator_def.absorb_channel = Channels.Channel.CHARGE
	accumulator_def.absorb_percent = 50
	assert_valid(grid.place_room(accumulator_def, Vector2i(3, 2)), "accumulator placed")
	var recipes := _recipes_with_id(&"charge_release")
	var engine := RuleEngine.new()
	engine.setup(grid, recipes, [], 1)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.CHARGE, 800)
	var turn_events := engine.tick()
	assert_eq(engine.get_channel(Vector2i(3, 2), Channels.Channel.CHARGE), 0, "charge released after absorption")
	assert_eq(engine.get_channel(Vector2i(2, 2), Channels.Channel.CHARGE), 300, "source keeps remainder plus release bonus")
	assert_true(_has_event_type(turn_events, &"charge_burst"), "charge burst event emitted")
	assert_true(_has_event_type(turn_events, &"channel_absorbed"), "absorption event emitted")


func _two_room_grid() -> DungeonGrid:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	assert_valid(grid.place_start(_room_def(&"a", DoorSpec.Dir.E), Vector2i(2, 2)), "a placed")
	assert_valid(grid.place_room(_room_def(&"b", DoorSpec.Dir.W), Vector2i(3, 2)), "b placed")
	return grid


func _recipes_with_id(recipe_id: StringName) -> Array[ReactionRecipe]:
	var result: Array[ReactionRecipe] = []
	for recipe in RuleEngine.load_recipe_library():
		if recipe.id == recipe_id:
			result.append(recipe)
	return result


func _recipe(recipe_id: StringName, priority: int, conditions: Array, effects: Array) -> ReactionRecipe:
	var recipe := ReactionRecipe.new()
	recipe.id = recipe_id
	recipe.display_name = String(recipe_id)
	recipe.priority = priority
	var typed_conditions: Array[ConditionDef] = []
	for condition in conditions:
		typed_conditions.append(condition)
	recipe.conditions = typed_conditions
	var typed_effects: Array[EffectDef] = []
	for effect in effects:
		typed_effects.append(effect)
	recipe.effects = typed_effects
	return recipe


func _condition_heat(threshold: int) -> ConditionDef:
	var condition := ConditionDef.new()
	condition.kind = ConditionDef.Kind.CHANNEL_AT_LEAST
	condition.channel = Channels.Channel.HEAT
	condition.threshold = threshold
	return condition


func _channel_effect(channel: int, amount: int) -> EffectDef:
	var effect := EffectDef.new()
	effect.kind = EffectDef.Kind.ADD_CHANNEL
	effect.channel = channel
	effect.amount = amount
	return effect


func _room_def(room_id: StringName, mask: int) -> RoomDef:
	var def := RoomDef.new()
	def.id = room_id
	def.display_name = String(room_id)
	def.door_mask = mask
	def.build_cost = 0
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


func _has_event_type(events_list: Array, event_type: StringName) -> bool:
	for event in events_list:
		if event["type"] == event_type:
			return true
	return false
