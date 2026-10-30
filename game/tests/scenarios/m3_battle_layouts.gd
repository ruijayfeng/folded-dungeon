extends TestCase
## M3 acceptance: the same battle behaves differently depending on the spatial
## layout / room synergies around the arena (docs principle 4).


func test_same_battle_two_layouts_differ() -> void:
	var plain := _run_layout(false)
	var combo := _run_layout(true)
	assert_true(plain["enemy_hp"] > combo["enemy_hp"], "room combo damages enemies through the environment")

	# Round 2: the toxic/forge layout finishes the enemy; the plain layout does not.
	plain["controller"].player_wait()
	plain["controller"].end_player_turn()
	combo["controller"].player_wait()
	combo["controller"].end_player_turn()
	assert_eq(combo["controller"].result, &"victory", "combo layout wins via environment")
	assert_eq(plain["controller"].result, &"", "plain layout still fighting")
	assert_eq(combo["controller"].session.player.hp < plain["controller"].session.player.hp, true, "hazards also hurt the player")

	print("[M3] layouts: plain=%s combo=%s" % [
		JSON.stringify(plain["snapshot"]),
		JSON.stringify(combo["snapshot"]),
	])


func _run_layout(with_combo: bool) -> Dictionary:
	var session := DungeonSession.new()
	var arena := _def(&"arena", 15)
	assert_valid(session.start_run(arena, Vector2i(2, 2), 0, 7, 10), "start session")
	var engine := RuleEngine.new()
	if with_combo:
		var forge := load("res://data/rooms/forge_room.tres") as RoomDef
		var toxin := load("res://data/rooms/toxin_room.tres") as RoomDef
		assert_valid(session.grid.place_room(forge, Vector2i(1, 2)), "forge")
		assert_valid(session.grid.place_room(toxin, Vector2i(3, 2)), "toxin")
		engine.setup(session.grid, RuleEngine.load_recipe_library(), [], 7)
		for i in 3:
			engine.tick()
		var arena_state := engine.room_state(Vector2i(2, 2))
		assert_true(arena_state.get_channel(Channels.Channel.HEAT) >= Channels.HEAT_THRESHOLD, "arena is hot")
		assert_true(arena_state.get_channel(Channels.Channel.TOXIN) >= Channels.TOXIN_THRESHOLD, "arena is toxic")
	else:
		engine.setup(session.grid, [], [], 7)
	session.player.local_cell = Vector2i(4, 4)
	var enemy := Unit.new(&"enemy_1", Unit.TEAM_ENEMY)
	enemy.max_hp = 4
	enemy.hp = 4
	enemy.attack_damage = 1
	enemy.move_points = 2
	enemy.local_cell = Vector2i(4, 2)
	var controller := CombatController.new(session, engine)
	assert_true(controller.start_encounter(Vector2i(2, 2), [enemy]), "combat starts")
	controller.player_wait()
	controller.end_player_turn()
	return {
		"session": session,
		"engine": engine,
		"controller": controller,
		"enemy_hp": enemy.hp,
		"snapshot": {
			"enemy_hp": enemy.hp,
			"player_hp": session.player.hp,
			"round": controller.state.round,
			"result": controller.result,
		},
	}


func _def(room_id: StringName, mask: int) -> RoomDef:
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
