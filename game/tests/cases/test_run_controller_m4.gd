extends TestCase


func test_start_and_first_build() -> void:
	var run := RunController.new()
	run.start(20261030, 1)
	assert_eq(run.state.floor, 1)
	assert_eq(run.phase, RunController.Phase.BUILD)
	assert_eq(run.offer_blueprints().size(), 3, "three blueprint offers")
	assert_eq(run.session.phase, DungeonSession.Phase.BUILD)
	var cell := run.auto_build_adjacent()
	assert_true(cell != Vector2i(-1, -1), "auto build succeeds: %s" % String(run.last_error))
	assert_eq(run.phase, RunController.Phase.EXPLORE, "back to exploring after build")
	assert_eq(run.session.grid.room_count(), 2, "start room + built room")
	assert_true(run.auto_walk_into(cell), "walk into built room")
	assert_eq(run.phase, RunController.Phase.ENCOUNTER, "first slot is a battle")
	assert_true(run.combat != null)


func test_combat_rewards_and_next_build() -> void:
	var run := RunController.new()
	run.start(7, 1)
	var first_cell := run.auto_build_adjacent()
	assert_true(first_cell != Vector2i(-1, -1), "build")
	assert_true(run.auto_walk_into(first_cell), "enter")
	run.combat.auto_resolve(60)
	var outcome := run.sync_combat_result()
	assert_eq(outcome, &"victory", "first battle won: player hp=%d" % run.session.player.hp)
	assert_true(run.state.gold >= 15, "battle grants gold")
	assert_true(run.state.build_points > 0, "battle grants build points")
	assert_eq(run.phase, RunController.Phase.BUILD, "next build node")
	assert_eq(run.state.cleared_slots.size(), 1, "slot cleared")
	var types := run.event_types()
	assert_true(types.has(&"rewards_granted"), "reward event")
	assert_true(types.has(&"slot_cleared"), "slot cleared event")


func test_floor_advance_after_boss() -> void:
	var run := RunController.new()
	run.start(20261030, 2)
	_auto_play_until(run, 800)
	assert_eq(run.state.floor, 2, "run reaches floor 2 after first boss: floor=%d phase=%d" % [run.state.floor, run.phase])
	assert_eq(run.phase, RunController.Phase.SETTLED, "two-floor run settles after the second boss")
	assert_true(run.state.victory, "two-floor run victory")
	var floor_advanced := false
	for event in run.state.events:
		if event["type"] == &"floor_advanced" and int(event["floor"]) == 2:
			floor_advanced = true
	assert_true(floor_advanced, "floor_advanced event present")


func _auto_play_until(run: RunController, max_steps: int) -> void:
	var steps := 0
	while run.phase != RunController.Phase.SETTLED and steps < max_steps and not run.state.run_over:
		steps += 1
		match run.phase:
			RunController.Phase.BUILD:
				var cell := run.auto_build_adjacent()
				if cell == Vector2i(-1, -1) or not run.auto_walk_into(cell):
					run.settle_run(&"defeat")
					return
			RunController.Phase.ENCOUNTER:
				run.combat.auto_resolve(80)
				run.sync_combat_result()
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
			_:
				return
