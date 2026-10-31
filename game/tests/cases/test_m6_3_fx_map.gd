extends TestCase
## M6-3: combat/rule event -> presentation FX descriptors (pure mapping).


func test_wave_events_map() -> void:
	var emitted := CombatFx.map_engine_event({"type": &"wave_emitted", "wave": &"heat_wave", "dir": DoorSpec.Dir.E})
	assert_eq(emitted.get("kind"), "wave")
	assert_eq(emitted.get("dir"), DoorSpec.Dir.E)
	assert_eq(CombatFx.wave_color(&"heat_wave").r > 0.8, true)
	var redirect := CombatFx.map_engine_event({"type": &"wave_redirected", "new_dir": DoorSpec.Dir.S, "wave": &"heat_wave"})
	assert_eq(redirect.get("kind"), "wave_redirect")
	assert_eq(redirect.get("dir"), DoorSpec.Dir.S)


func test_reaction_colors() -> void:
	var combustion := CombatFx.map_engine_event({"type": &"reaction_triggered", "recipe": &"combustion", "cell": Vector2i(4, 4)})
	assert_eq(combustion.get("kind"), "reaction")
	assert_eq(combustion.get("recipe"), &"combustion")
	assert_true(CombatFx.reaction_color(&"combustion").r > 0.9)
	assert_true(CombatFx.reaction_color(&"thermal_neutralize").b > 0.8)
	assert_true(CombatFx.reaction_color(&"charge_release").g > 0.7)


func test_combat_events_map() -> void:
	var hit := CombatFx.map_combat_event({"type": &"unit_attacked", "attacker": &"player", "defender": &"enemy_1", "damage": 2})
	assert_eq(hit.get("kind"), "hit")
	assert_eq(hit.get("defender"), &"enemy_1")
	var died := CombatFx.map_combat_event({"type": &"unit_died", "unit": &"enemy_1", "team": 1})
	assert_eq(died.get("kind"), "death")
	var boss := CombatFx.map_combat_event({"type": &"boss_ability", "unit": &"boss", "ability": &"boss_heat"})
	assert_eq(boss.get("kind"), "boss_ability")


func test_turret_periodic_maps() -> void:
	var turret := CombatFx.map_engine_event({"type": &"room_periodic", "event_id": &"turret_fire"})
	assert_eq(turret.get("kind"), "turret")
	var other := CombatFx.map_engine_event({"type": &"room_periodic", "event_id": &"something_else"})
	assert_true(other.is_empty())
