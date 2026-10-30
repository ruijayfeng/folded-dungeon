extends TestCase
## M4 acceptance: automated vertical slice. Drives the same loop a player would:
## build rooms from blueprint offers, walk in, fight/event/rest/shop, collect
## rewards, and defeat the boss. Reproduces docs/01 §2.1 steps 1-7.

const SEED := 20261030


func test_vertical_slice_floor_completion() -> void:
	var run := RunController.new()
	run.start(SEED, 1)
	var steps := 0
	while run.phase != RunController.Phase.SETTLED and steps < 500:
		steps += 1
		match run.phase:
			RunController.Phase.BUILD:
				var cell := run.auto_build_adjacent()
				assert_true(cell != Vector2i(-1, -1), "auto build at slot %d" % run.state.slot_index)
				if cell == Vector2i(-1, -1):
					break
				assert_true(run.auto_walk_into(cell), "walk into room at %s" % str(cell))
			RunController.Phase.ENCOUNTER:
				run.combat.auto_resolve(80)
				var outcome := run.sync_combat_result()
				if outcome != &"victory":
					break
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
			_:
				break

	assert_true(run.state.victory, "vertical slice boss cleared (floor=%d slots=%d/%d hp=%d)" % [
		run.state.floor, run.state.cleared_slots.size(), run.plan.slots.size(), run.session.player.hp
	])
	assert_eq(run.phase, RunController.Phase.SETTLED)
	assert_eq(run.state.cleared_slots.size(), run.plan.slots.size(), "all content slots resolved")
	assert_true(run.state.gold > 0, "run earned gold")

	var types := run.event_types()
	for expected in [&"run_started", &"build_node_opened", &"room_built", &"encounter_started", &"combat_won", &"rewards_granted", &"slot_cleared", &"run_settled"]:
		assert_true(types.has(expected), "event present: %s" % expected)
	var boss_seen := false
	for event in run.state.events:
		if event["type"] == &"encounter_started" and event.get("slot_type", &"") == &"boss":
			boss_seen = true
	assert_true(boss_seen, "boss encounter happened")
	var boss_ability_seen := false
	if run.combat != null:
		for event in run.combat.events:
			if event["type"] == &"boss_ability":
				boss_ability_seen = true
	assert_true(boss_ability_seen, "boss used its room-heat ability")
	var built_defs := {}
	for room in run.session.grid.all_rooms():
		if room.definition != null:
			built_defs[room.definition.id] = true
	assert_true(built_defs.size() >= 3, "multiple room types built: %s" % str(built_defs.keys()))

	print("[M4] vertical slice snapshot: " + JSON.stringify(run.snapshot()))


func _auto_step(run: RunController) -> bool:
	match run.phase:
		RunController.Phase.BUILD:
			var cell := run.auto_build_adjacent()
			if cell == Vector2i(-1, -1):
				return false
			return run.auto_walk_into(cell)
		RunController.Phase.ENCOUNTER:
			run.combat.auto_resolve(80)
			return run.sync_combat_result() == &"victory"
		RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
			return run.resolve_choice(0)
	return false
