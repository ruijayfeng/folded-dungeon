extends TestCase

const RULE_ROOM_IDS: Array[StringName] = [
	&"forge_room", &"toxin_room", &"frost_room", &"storm_room",
	&"mirror_room", &"gravity_room", &"accumulator_room", &"echo_room",
	&"conduit_room", &"ballista_room", &"vault_room", &"fold_room",
]


func test_all_room_pairs_are_deterministic_and_error_free() -> void:
	var recipes := RuleEngine.load_recipe_library()
	assert_eq(recipes.size(), 3, "recipe library loaded")
	var pairs := 0
	for left_id in RULE_ROOM_IDS:
		for right_id in RULE_ROOM_IDS:
			var left := _compatible(load("res://data/rooms/%s.tres" % left_id) as RoomDef)
			var right := _compatible(load("res://data/rooms/%s.tres" % right_id) as RoomDef)
			var grid := DungeonGrid.new()
			grid.set_budget(999, 25)
			assert_valid(grid.place_start(left, Vector2i(2, 2)), "start %s" % left_id)
			assert_valid(grid.place_room(right, Vector2i(3, 2)), "neighbour %s" % right_id)
			var first := RuleEngine.new()
			first.setup(grid, recipes, [], 1)
			var second := RuleEngine.new()
			second.setup(grid, recipes, [], 1)
			for i in 5:
				first.tick()
				second.tick()
			assert_eq(JSON.stringify(first.snapshot()), JSON.stringify(second.snapshot()), "deterministic pair %s+%s" % [left_id, right_id])
			pairs += 1
	assert_eq(pairs, RULE_ROOM_IDS.size() * RULE_ROOM_IDS.size(), "all pairs covered")


func test_known_combo_forge_plus_toxin_still_trigger() -> void:
	var forge := _compatible(load("res://data/rooms/forge_room.tres") as RoomDef)
	var toxin := _compatible(load("res://data/rooms/toxin_room.tres") as RoomDef)
	var grid := DungeonGrid.new()
	grid.set_budget(999, 25)
	assert_valid(grid.place_start(forge, Vector2i(1, 2)), "forge")
	assert_valid(grid.place_room(toxin, Vector2i(2, 2)), "toxin")
	var engine := RuleEngine.new()
	engine.setup(grid, RuleEngine.load_recipe_library(), [], 1)
	var combustion := false
	for i in 5:
		var events := engine.tick()
		for event in events:
			if event["type"] == &"reaction_triggered" and event["recipe"] == &"combustion":
				combustion = true
	assert_true(combustion, "forge+toxin triggers combustion within 5 turns")


func _compatible(def: RoomDef) -> RoomDef:
	var copy := def.duplicate() as RoomDef
	copy.door_mask = DoorSpec.Dir.W | DoorSpec.Dir.E
	return copy
