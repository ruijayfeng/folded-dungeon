extends SceneTree
## Dev-only: M6-3 quality screenshots (hit FX / reaction / wave / boss aura).

const OUT := "res://../docs/screenshots/"
var mode: Node3D = null
var run: RunController = null

func _initialize() -> void:
	var safety := create_timer(180.0)
	safety.timeout.connect(func() -> void:
		print("SAFETY-QUIT")
		quit())
	var ps: PackedScene = load("res://presentation/run_mode/run_mode_3d.tscn")
	mode = ps.instantiate()
	root.add_child(mode)
	_drive.call_deferred()

func _shot(name: String) -> void:
	for i in 10:
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("SAVED ", name)

func _enter_encounter() -> bool:
	var guard := 0
	while guard < 80:
		guard += 1
		match run.phase:
			RunController.Phase.BUILD:
				var cell: Vector2i = run.auto_build_adjacent()
				if cell == Vector2i(-1, -1):
					return false
				run.auto_walk_into(cell)
				mode._room_key = ""
				mode._sync()
			RunController.Phase.ENCOUNTER:
				return true
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
				mode._sync()
			_:
				mode._sync()
				await process_frame
	return false

func _drive() -> void:
	await process_frame
	await process_frame
	run = mode.run
	if not await _enter_encounter():
		print("NO ENCOUNTER")
		quit()
		return
	await _shot("m6-3-battle")
	var enemies := run.combat.state.living_enemies()
	if enemies.is_empty():
		quit()
		return
	var target: Unit = enemies[0]
	var player := run.combat.state.player_unit()
	var candidates := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	for d in candidates:
		var cell: Vector2i = target.local_cell + d
		if run.combat.state.walkable_cell(cell) and run.combat.state.unit_at(cell) == null:
			player.local_cell = cell
			break
	run.combat.player_attack(target.unit_id)
	run.sync_combat_result()
	mode._sync()
	await _shot("m6-3-hit")
	# Synthetic rule/combat events for FX QA
	run.engine.events.append({"type": &"reaction_triggered", "recipe": &"combustion", "cell": Vector2i(4, 4)})
	run.engine.events.append({"type": &"wave_emitted", "wave": &"heat_wave", "dir": DoorSpec.Dir.E, "cell": Vector2i(4, 4)})
	run.engine.events.append({"type": &"wave_redirected", "wave": &"heat_wave", "new_dir": DoorSpec.Dir.S})
	run.engine.events.append({"type": &"room_periodic", "event_id": &"turret_fire", "cell": Vector2i(4, 4)})
	run.combat.state.events.append({"type": &"boss_ability", "unit": &"boss", "ability": &"boss_heat"})
	mode._drain_events()
	await _shot("m6-3-fx")
	# Boss aura QA: promote one living enemy to boss
	var boss: Unit = enemies[0]
	boss.unit_id = &"boss"
	boss.display_name = "地牢核心守卫"
	boss.max_hp = 4
	boss.hp = 4
	boss.ability = &"boss_heat"
	mode._sync()
	await _shot("m6-3-boss")
	quit()
