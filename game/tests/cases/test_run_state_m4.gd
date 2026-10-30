extends TestCase


func test_run_state_snapshot() -> void:
	var state := RunState.new()
	state.seed_value = 42
	state.floor = 2
	state.gold = 30
	state.build_points = 7
	state.blueprints.append(&"combat_room")
	state.cleared_slots.append(0)
	var snapshot := state.snapshot()
	assert_eq(snapshot["seed"], 42)
	assert_eq(snapshot["floor"], 2)
	assert_eq(snapshot["gold"], 30)
	assert_eq(snapshot["build_points"], 7)
	assert_eq(snapshot["cleared_slots"], [0])
	assert_eq(snapshot["blueprints"], [&"combat_room"])


func test_floor_plan_is_deterministic() -> void:
	var first := FloorPlan.generate(123, 1)
	var second := FloorPlan.generate(123, 1)
	assert_eq(JSON.stringify(first.snapshot()), JSON.stringify(second.snapshot()), "same seed/floor identical")
	assert_eq(first.slots.size(), 7, "M4 slice has 7 content slots")
	assert_eq(first.slots[first.slots.size() - 1]["type"], FloorPlan.SlotType.BOSS, "boss slot last")
	var battle_count := 0
	for slot in first.slots:
		var slot_type: int = slot["type"]
		if FloorPlan.type_name(slot_type) == &"battle":
			battle_count += 1
	assert_true(battle_count >= 2, "floor has normal battles")
	assert_eq(FloorPlan.type_name(FloorPlan.SlotType.ELITE), &"elite")
