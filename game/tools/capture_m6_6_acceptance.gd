extends SceneTree
## M6-6 acceptance: real automated run (build -> explore -> combat -> boss -> settlement)
## plus offscreen screenshots. Runs with --position 9000,9000 in a background job.

const OUT := "res://../docs/screenshots/"

var mode: Node3D = null
var run: RunController = null
var captured := {}

func _initialize() -> void:
	var safety := create_timer(240.0)
	safety.timeout.connect(func() -> void:
		print("SAFETY-QUIT")
		quit())
	_drive.call_deferred()

func _shot(name: String) -> void:
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("SAVED ", name)

func _drive() -> void:
	await process_frame
	var title: Node = (load("res://presentation/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await process_frame
	await _shot("m6-6-title")
	title.queue_free()
	await process_frame

	var ps: PackedScene = load("res://presentation/run_mode/run_mode_3d.tscn")
	mode = ps.instantiate() as Node3D
	root.add_child(mode)
	await process_frame
	await process_frame
	run = mode.run
	mode._default_preview()
	mode._sync()
	await _shot("m6-6-build")

	var steps := 0
	while run.phase != RunController.Phase.SETTLED and steps < 500:
		steps += 1
		match run.phase:
			RunController.Phase.BUILD:
				var cell: Vector2i = run.auto_build_adjacent()
				if cell == Vector2i(-1, -1):
					break
				run.auto_walk_into(cell)
				mode._room_key = ""
				mode._sync()
				await process_frame
			RunController.Phase.ENCOUNTER:
				if run.combat != null and run.combat.state != null:
					var boss_here := false
					for unit in run.combat.state.units:
						if unit.unit_id == &"boss":
							boss_here = true
					mode._sync()
					if not captured.has("battle"):
						captured["battle"] = true
						await _shot("m6-6-battle")
					if boss_here and not captured.has("boss"):
						captured["boss"] = true
						await _shot("m6-6-boss")
				run.combat.auto_resolve(80)
				run.sync_combat_result()
				mode._sync()
				await process_frame
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
				mode._sync()
				await process_frame
			_:
				break

	mode._sync()
	await _shot("m6-6-settle")
	var summary := {
		"phase": RunController.Phase.keys()[run.phase] if run.phase <= RunController.Phase.SETTLED else str(run.phase),
		"victory": run.state.victory,
		"floor": run.state.floor,
		"gold": run.state.gold,
		"rooms": run.session.grid.room_count(),
		"steps": steps,
		"slots_cleared": run.state.cleared_slots.size(),
		"slots_total": run.plan.slots.size(),
		"boss_seen": captured.has("boss"),
	}
	print("ACCEPTANCE_JSON ", JSON.stringify(summary))
	var ok: bool = run.phase == RunController.Phase.SETTLED and run.state.victory
	print("ACCEPTANCE_OK ", ok)
	quit(0 if ok else 1)
