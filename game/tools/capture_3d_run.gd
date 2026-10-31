extends SceneTree
## Dev-only: drive the 2.5D run layer and capture M6 quality-gate screenshots.

const OUT_DIR := "res://../docs/screenshots/"

var mode: Node3D = null

func _initialize() -> void:
	var safety := create_timer(120.0)
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
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + name + ".png"))
	print("SAVED ", name, " ", img.get_width(), "x", img.get_height())

func _drive() -> void:
	await process_frame
	await process_frame
	var run: RunController = mode.run
	mode._default_preview()
	mode._sync()
	await _shot("m6-1-build")
	var rooms := 0
	var guard := 0
	while guard < 120:
		guard += 1
		match run.phase:
			RunController.Phase.BUILD:
				var cell: Vector2i = run.auto_build_adjacent()
				if cell == Vector2i(-1, -1):
					break
				rooms += 1
				if not run.auto_walk_into(cell):
					break
				mode._room_key = ""
				mode._sync()
				if rooms == 1:
					await _shot("m6-1-explore")
			RunController.Phase.ENCOUNTER:
				if rooms >= 2:
					break
				run.combat.auto_resolve(60)
				if run.sync_combat_result() != &"victory":
					break
				rooms += 1
				mode._sync()
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
				rooms += 1
				mode._sync()
			_:
				break
	# move player away from the door so the battle shot is readable
	if run.phase == RunController.Phase.ENCOUNTER:
		for i in 2:
			run.combat.player_move(DoorSpec.Dir.W)
			mode._sync()
			await process_frame
	mode._sync()
	await _shot("m6-1-battle")
	# attack pose QA shot: trigger enemy attack frames
	for v in mode._unit_views.values():
		if v != null and not v.is_player:
			v.play_attack()
	await _shot("m6-1-attack")
	quit()
