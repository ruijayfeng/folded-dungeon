extends TestCase


func test_damage_healing_and_death() -> void:
	var unit := Unit.new(&"u", Unit.TEAM_ENEMY)
	unit.max_hp = 5
	unit.hp = 5
	assert_eq(unit.take_damage(3, &"test"), 3, "damage applied")
	assert_eq(unit.hp, 2)
	assert_eq(unit.take_damage(5, &"test"), 2, "damage clamped to remaining hp")
	assert_false(unit.alive, "unit dies")
	assert_eq(unit.take_damage(1), 0, "dead unit takes no more damage")
	var heal_target := Unit.new(&"h", Unit.TEAM_PLAYER)
	heal_target.max_hp = 10
	heal_target.hp = 9
	assert_eq(heal_target.heal(5), 1, "heal clamps at max hp")


func test_statuses_and_chilled_movement() -> void:
	var unit := Unit.new(&"u", Unit.TEAM_PLAYER)
	unit.add_status(&"chilled", 2)
	assert_true(unit.has_status(&"chilled"))
	unit.reset_turn(4)
	assert_eq(unit.move_points, 3, "chilled reduces move points")
	var expired := unit.advance_statuses()
	assert_true(expired.is_empty(), "status still active")
	assert_eq(unit.status_turns(&"chilled"), 1)
	expired = unit.advance_statuses()
	assert_true(expired.has(&"chilled"), "status expires")
	assert_false(unit.has_status(&"chilled"))
	unit.reset_turn(4)
	assert_eq(unit.move_points, 4, "movement restored after chill expires")


func test_clone_is_independent() -> void:
	var unit := Unit.new(&"u", Unit.TEAM_ENEMY)
	unit.hp = 4
	unit.add_status(&"burning", 1)
	var copy := unit.clone()
	copy.hp = 1
	copy.add_status(&"poisoned", 2)
	assert_eq(unit.hp, 4, "original hp unchanged")
	assert_false(unit.has_status(&"poisoned"), "original statuses unchanged")
	assert_true(copy.has_status(&"poisoned"), "clone has own statuses")
