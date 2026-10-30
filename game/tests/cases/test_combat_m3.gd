extends TestCase


func test_attack_knockback_collision_and_action_limit() -> void:
	var context := _setup_combat()
	var session: DungeonSession = context["session"]
	var controller: CombatController = context["controller"]
	session.player.local_cell = Vector2i(4, 2)
	var enemy := _enemy(&"enemy_1", Vector2i(4, 1), 5)
	assert_true(controller.start_encounter(Vector2i(2, 2), [enemy]), "combat starts")
	assert_eq(session.phase, DungeonSession.Phase.COMBAT)

	var attack := controller.player_attack(&"enemy_1")
	assert_true(attack["ok"], "attack succeeds")
	assert_eq(enemy.hp, 2, "2 damage + 1 knockback collision")
	assert_eq(enemy.local_cell, Vector2i(4, 1), "blocked knockback keeps position")
	assert_true(_has_event_in(controller.state.events, &"knockback_collision"), "collision event emitted")

	var second_attack := controller.player_attack(&"enemy_1")
	assert_eq(second_attack["reason"], &"ALREADY_ACTED", "one action per turn")


func test_out_of_range_and_victory() -> void:
	var context := _setup_combat()
	var session: DungeonSession = context["session"]
	var controller: CombatController = context["controller"]
	session.player.local_cell = Vector2i(4, 4)
	var enemy := _enemy(&"enemy_1", Vector2i(4, 1), 2)
	assert_true(controller.start_encounter(Vector2i(2, 2), [enemy]))
	var out_of_range := controller.player_attack(&"enemy_1")
	assert_eq(out_of_range["reason"], &"OUT_OF_RANGE", "range checked")
	assert_true(controller.player_move(DoorSpec.Dir.N)["ok"], "move 1")
	assert_true(controller.player_move(DoorSpec.Dir.N)["ok"], "move 2")
	assert_eq(session.player.local_cell, Vector2i(4, 2))
	var attack := controller.player_attack(&"enemy_1")
	assert_true(attack["ok"], "attack kills enemy")
	assert_false(enemy.alive, "enemy dead")
	assert_eq(controller.result, &"victory", "combat won")
	assert_eq(session.phase, DungeonSession.Phase.EXPLORE, "control returns to exploration")
	assert_true(session.event_types().has(&"combat_won"), "combat_won logged")


func test_enemy_ai_moves_then_attacks() -> void:
	var context := _setup_combat()
	var session: DungeonSession = context["session"]
	var controller: CombatController = context["controller"]
	session.player.local_cell = Vector2i(4, 4)
	var enemy := _enemy(&"enemy_1", Vector2i(4, 1), 5)
	assert_true(controller.start_encounter(Vector2i(2, 2), [enemy]))
	controller.player_wait()
	controller.end_player_turn()
	assert_eq(enemy.local_cell, Vector2i(4, 3), "enemy advanced two steps")
	assert_eq(session.player.hp, 9, "enemy attacked after moving")
	assert_eq(controller.state.round, 2, "round advanced")
	assert_eq(controller.state.phase, CombatState.PHASE_PLAYER, "player phase again")


func test_hazard_damage_and_statuses() -> void:
	var context := _setup_combat(true)
	var session: DungeonSession = context["session"]
	var engine: RuleEngine = context["engine"]
	var controller: CombatController = context["controller"]
	engine.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 600)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.TOXIN, 300)
	session.player.local_cell = Vector2i(4, 4)
	var enemy := _enemy(&"enemy_1", Vector2i(4, 2), 5)
	assert_true(controller.start_encounter(Vector2i(2, 2), [enemy]))
	controller.player_wait()
	controller.end_player_turn()
	assert_eq(enemy.hp, 2, "enemy took 3 hazard damage (after its attack)")
	assert_eq(session.player.hp, 6, "player took 1 attack + 3 hazard damage")
	assert_true(session.player.has_status(&"burning"), "heat applies burning")
	assert_true(session.player.has_status(&"poisoned"), "toxin applies poisoned")


func test_environment_can_end_combat() -> void:
	var context := _setup_combat(true)
	var session: DungeonSession = context["session"]
	var engine: RuleEngine = context["engine"]
	var controller: CombatController = context["controller"]
	engine.set_channel(Vector2i(2, 2), Channels.Channel.HEAT, 600)
	engine.set_channel(Vector2i(2, 2), Channels.Channel.TOXIN, 300)
	session.player.local_cell = Vector2i(4, 4)
	var enemy := _enemy(&"enemy_1", Vector2i(4, 2), 1)
	assert_true(controller.start_encounter(Vector2i(2, 2), [enemy]))
	controller.player_wait()
	controller.end_player_turn()
	assert_eq(controller.result, &"victory", "environment damage kills the enemy")
	assert_eq(session.phase, DungeonSession.Phase.EXPLORE, "combat closed")


func _setup_combat(with_engine: bool = false) -> Dictionary:
	var session := DungeonSession.new()
	var arena := _def(&"arena", 15)
	var report := session.start_run(arena, Vector2i(2, 2), 0, 1, 10)
	assert_valid(report, "start session")
	var engine: RuleEngine = null
	if with_engine:
		engine = RuleEngine.new()
		engine.setup(session.grid, [], [], 1)
	var controller := CombatController.new(session, engine)
	return {"session": session, "controller": controller, "engine": engine}


func _enemy(unit_id: StringName, cell: Vector2i, hp: int) -> Unit:
	var enemy := Unit.new(unit_id, Unit.TEAM_ENEMY)
	enemy.max_hp = hp
	enemy.hp = hp
	enemy.attack_damage = 1
	enemy.move_points = 2
	enemy.local_cell = cell
	return enemy


func _has_event_in(events_list: Array, event_type: StringName) -> bool:
	for event in events_list:
		if event["type"] == event_type:
			return true
	return false


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
