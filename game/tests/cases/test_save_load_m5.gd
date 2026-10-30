extends TestCase


func test_save_load_round_trip_and_continue() -> void:
	var run := RunController.new()
	run.start(20261030, 1)
	_auto_play_until_slots(run, 2)
	assert_eq(run.phase, RunController.Phase.BUILD, "save at a build node")
	var json := run.save_to_json()
	assert_false(json.is_empty(), "save JSON produced")
	var offers_before := _offer_ids(run)
	var state_before := run.state.snapshot()
	var rooms_before := run.session.grid.room_count()

	var loaded := RunController.new()
	assert_true(loaded.load_from_json(json), "snapshot loads")
	assert_eq(loaded.state.snapshot(), state_before, "state restored")
	assert_eq(loaded.session.grid.room_count(), rooms_before, "rooms restored")
	assert_eq(_offer_ids(loaded), offers_before, "blueprint offers restored")
	assert_eq(loaded.session.player.hp, run.session.player.hp, "player hp restored")
	assert_true(loaded.engine != null and loaded.engine.turn == run.engine.turn, "engine turn restored")

	_auto_play_until_settled(loaded, 500)
	assert_true(loaded.state.victory, "run continues from save to victory")


func test_seed_reproducibility() -> void:
	var first := RunController.new()
	first.start(424242, 1)
	var second := RunController.new()
	second.start(424242, 1)
	assert_eq(JSON.stringify(first.plan.snapshot()), JSON.stringify(second.plan.snapshot()), "same seed -> same floor plan")
	assert_eq(_offer_ids(first), _offer_ids(second), "same seed -> same initial offers")


func _offer_ids(run: RunController) -> Array[String]:
	var ids: Array[String] = []
	for def in run.current_offer:
		ids.append(String(def.id))
	return ids


func _auto_play_until_slots(run: RunController, target_slots: int) -> void:
	var steps := 0
	while run.phase != RunController.Phase.SETTLED and run.state.cleared_slots.size() < target_slots and steps < 300:
		steps += 1
		match run.phase:
			RunController.Phase.BUILD:
				var cell := run.auto_build_adjacent()
				if cell == Vector2i(-1, -1) or not run.auto_walk_into(cell):
					return
			RunController.Phase.ENCOUNTER:
				run.combat.auto_resolve(80)
				run.sync_combat_result()
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
			_:
				return


func _auto_play_until_settled(run: RunController, max_steps: int) -> void:
	var steps := 0
	while run.phase != RunController.Phase.SETTLED and steps < max_steps:
		steps += 1
		match run.phase:
			RunController.Phase.BUILD:
				var cell := run.auto_build_adjacent()
				if cell == Vector2i(-1, -1) or not run.auto_walk_into(cell):
					return
			RunController.Phase.ENCOUNTER:
				run.combat.auto_resolve(80)
				run.sync_combat_result()
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
			_:
				return
