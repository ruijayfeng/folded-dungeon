extends TestCase
## M2 acceptance: 熔炉 -> 毒雾 -> 镜面 组合链。
## Verifies the docs/01 §5.4 turn table, combustion at turn 3, and a mirror
## redirecting the fire wave into another room.

const FORGE_CELL := Vector2i(1, 2)
const TOXIN_CELL := Vector2i(2, 2)
const MIRROR_CELL := Vector2i(3, 2)
const TARGET_CELL := Vector2i(3, 3)


func test_combo_chain_with_mirror_redirect() -> void:
	var grid := _build_chain()
	var engine := RuleEngine.new()
	engine.setup(grid, RuleEngine.load_recipe_library(), [], 20261030)

	var turn1 := engine.tick()
	var turn2 := engine.tick()
	assert_eq(engine.get_channel(TOXIN_CELL, Channels.Channel.HEAT), 300, "turn2 toxin room heat")
	assert_eq(engine.get_channel(TOXIN_CELL, Channels.Channel.TOXIN), 400, "turn2 toxin")
	assert_false(_has_recipe_event(turn1, &"combustion"), "no combustion on turn 1")
	assert_false(_has_recipe_event(turn2, &"combustion"), "no combustion on turn 2")

	var turn3 := engine.tick()
	var combustion := _find_recipe_event(turn3, &"combustion")
	assert_true(not combustion.is_empty(), "combustion at turn 3")
	assert_eq(engine.get_channel(TOXIN_CELL, Channels.Channel.HEAT), 900, "combustion adds heat")
	assert_eq(engine.get_channel(TOXIN_CELL, Channels.Channel.TOXIN), 100, "combustion consumes toxin")
	assert_true(engine.room_state(TOXIN_CELL).has_state(&"burning"), "burning state")
	assert_eq(engine.get_channel(MIRROR_CELL, Channels.Channel.HEAT), 160, "mirror received heat from toxin room")

	var mirror_events := _wave_events(turn3)
	assert_eq(mirror_events["emitted"], TOXIN_CELL, "wave emitted from toxin room")
	assert_eq(mirror_events["first_entered"], MIRROR_CELL, "wave enters mirror room")
	assert_eq(mirror_events["redirected_dir"], DoorSpec.Dir.S, "mirror redirects east to south")
	assert_eq(mirror_events["second_entered"], TARGET_CELL, "redirected wave reaches target room")

	var preview_engine := _build_and_engine()
	var preview := preview_engine.preview_turns(3)
	assert_eq(JSON.stringify(preview["events"]), JSON.stringify(engine.events), "preview matches tick events")

	print("[M2] combo snapshot: " + JSON.stringify({
		"turn": engine.turn,
		"toxin_heat": engine.get_channel(TOXIN_CELL, Channels.Channel.HEAT),
		"toxin_toxin": engine.get_channel(TOXIN_CELL, Channels.Channel.TOXIN),
		"mirror_heat": engine.get_channel(MIRROR_CELL, Channels.Channel.HEAT),
		"events": engine.events.size(),
	}))


func _build_chain() -> DungeonGrid:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	var forge := load("res://data/rooms/forge_room.tres") as RoomDef
	var toxin := load("res://data/rooms/toxin_room.tres") as RoomDef
	var mirror := load("res://data/rooms/mirror_room.tres") as RoomDef
	var target := load("res://data/rooms/combat_room.tres") as RoomDef
	assert_valid(grid.place_start(forge, FORGE_CELL), "forge as start")
	assert_valid(grid.place_room(toxin, TOXIN_CELL), "toxin room")
	assert_valid(grid.place_room(mirror, MIRROR_CELL), "mirror room")
	assert_valid(grid.place_room(target, TARGET_CELL), "target room")
	return grid


func _build_and_engine() -> RuleEngine:
	var engine := RuleEngine.new()
	engine.setup(_build_chain(), RuleEngine.load_recipe_library(), [], 20261030)
	return engine


func _wave_events(turn_events: Array) -> Dictionary:
	var result := {"emitted": Vector2i(-1, -1), "first_entered": Vector2i(-1, -1), "redirected_dir": 0, "second_entered": Vector2i(-1, -1)}
	var entered_count := 0
	for event in turn_events:
		match event["type"]:
			&"wave_emitted":
				result["emitted"] = event["cell"]
			&"wave_entered":
				entered_count += 1
				if entered_count == 1:
					result["first_entered"] = event["cell"]
				elif entered_count == 2:
					result["second_entered"] = event["cell"]
			&"wave_redirected":
				result["redirected_dir"] = event["new_dir"]
	return result


func _find_recipe_event(events_list: Array, recipe_id: StringName) -> Dictionary:
	for event in events_list:
		if event["type"] == &"reaction_triggered" and event["recipe"] == recipe_id:
			return event
	return {}


func _has_recipe_event(events_list: Array, recipe_id: StringName) -> bool:
	return not _find_recipe_event(events_list, recipe_id).is_empty()
