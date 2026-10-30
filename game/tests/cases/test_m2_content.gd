extends TestCase


func test_m2_room_data_loads_and_validates() -> void:
	var expected := {
		"forge_room": {&"tag": &"heat_source", &"channel": Channels.Channel.HEAT, &"rate": 250},
		"toxin_room": {&"tag": &"gas_source", &"channel": Channels.Channel.TOXIN, &"rate": 200},
		"frost_room": {&"tag": &"cold_source", &"channel": Channels.Channel.COLD, &"rate": 200},
	}
	for room_id in expected:
		var def := load("res://data/rooms/%s.tres" % room_id) as RoomDef
		assert_true(def != null, "load %s" % room_id)
		if def == null:
			continue
		assert_eq(String(def.id), room_id, "room id %s" % room_id)
		assert_true(def.validate().is_empty(), "room validates: %s" % room_id)
		var info: Dictionary = expected[room_id]
		assert_true(def.tags.has(info["tag"]), "tag for %s" % room_id)
		assert_eq(def.emitters.size(), 1, "emitter count for %s" % room_id)
		if def.emitters.size() == 1:
			assert_eq(def.emitters[0].channel, info["channel"], "emitter channel for %s" % room_id)
			assert_eq(def.emitters[0].rate_per_turn, info["rate"], "emitter rate for %s" % room_id)

	var mirror := load("res://data/rooms/mirror_room.tres") as RoomDef
	assert_true(mirror != null and mirror.validate().is_empty(), "mirror room valid")
	assert_eq(mirror.wave_redirect_steps, 1, "mirror redirects waves")
	assert_true(mirror.tags.has(&"mirror"), "mirror tag")
	var accumulator := load("res://data/rooms/accumulator_room.tres") as RoomDef
	assert_true(accumulator != null and accumulator.validate().is_empty(), "accumulator valid")
	assert_eq(accumulator.absorb_channel, Channels.Channel.CHARGE, "accumulator absorbs charge")
	assert_eq(accumulator.absorb_percent, 50, "accumulator absorb percent")
	var ballista := load("res://data/rooms/ballista_room.tres") as RoomDef
	assert_true(ballista != null and ballista.validate().is_empty(), "ballista valid")
	assert_eq(ballista.periodic_turns, 2, "ballista period")
	assert_eq(ballista.periodic_event, &"turret_fire", "ballista event")


func test_recipe_library_loads_and_validates() -> void:
	var recipes := RuleEngine.load_recipe_library()
	assert_eq(recipes.size(), 3, "three M2 recipes")
	var ids: Array[String] = []
	for recipe in recipes:
		ids.append(String(recipe.id))
		assert_true(recipe.validate().is_empty(), "recipe validates: %s" % recipe.id)
	assert_true(ids.has("combustion"), "combustion present")
	assert_true(ids.has("thermal_neutralize"), "thermal_neutralize present")
	assert_true(ids.has("charge_release"), "charge_release present")
