extends TestCase


func test_gravity_room_overrides_knockback_direction() -> void:
	var gravity_def := (load("res://data/rooms/gravity_room.tres") as RoomDef).duplicate() as RoomDef
	gravity_def.gravity_dir = DoorSpec.Dir.W
	var session := DungeonSession.new()
	assert_valid(session.start_run(gravity_def, Vector2i(2, 2), 0, 1, 10), "gravity arena")
	session.player.local_cell = Vector2i(4, 4)
	var enemy := Unit.new(&"enemy_1", Unit.TEAM_ENEMY)
	enemy.max_hp = 5
	enemy.hp = 5
	enemy.attack_damage = 1
	enemy.local_cell = Vector2i(4, 5)
	var controller := CombatController.new(session, null)
	assert_true(controller.start_encounter(Vector2i(2, 2), [enemy]), "combat starts")
	var attack := controller.player_attack(&"enemy_1")
	assert_true(attack["ok"], "attack succeeds")
	assert_eq(enemy.local_cell, Vector2i(3, 5), "knockback follows gravity west instead of away from attacker")


func test_vault_room_grants_gold_on_build() -> void:
	var run := RunController.new()
	run.start(5, 1)
	var vault := load("res://data/rooms/vault_room.tres") as RoomDef
	run.current_offer = [vault]
	var cell := run.auto_build_adjacent()
	assert_true(cell != Vector2i(-1, -1), "vault room built: %s" % String(run.last_error))
	assert_eq(run.state.gold, 25, "vault grants 25 gold")
	assert_true(run.event_types().has(&"vault_bonus"), "vault bonus event")
