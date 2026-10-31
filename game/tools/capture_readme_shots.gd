extends SceneTree
## Dev-only helper: drives the M5 run layer with the automated test helpers and
## saves a screenshot for assets/readme/. Not used at runtime and not part of
## gameplay; run with:
##   Godot --path game --script res://tools/capture_readme_shots.gd -- ##         --mode=battle --out=/abs/path/shot.png --resolution 2200x1520

var mode: Node = null
var out_path := ""
var capture_mode := "battle"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_path = arg.substr(6)
		elif arg.begins_with("--mode="):
			capture_mode = arg.substr(7)
	var safety := create_timer(40.0)
	safety.timeout.connect(func() -> void:
		print("SAFETY-QUIT")
		quit())
	var packed: PackedScene = load("res://presentation/run_mode/run_mode.tscn")
	mode = packed.instantiate()
	root.add_child(mode)
	_drive.call_deferred()

func _drive() -> void:
	await process_frame
	await process_frame
	var run = mode.run
	var rooms_built := 0
	var guard := 0
	while guard < 120:
		guard += 1
		match run.phase:
			RunController.Phase.BUILD:
				if capture_mode == "build" and rooms_built >= 3:
					break
				var cell: Vector2i = run.auto_build_adjacent()
				if cell == Vector2i(-1, -1):
					break
				rooms_built += 1
				if not run.auto_walk_into(cell):
					break
			RunController.Phase.ENCOUNTER:
				if capture_mode == "battle" and rooms_built >= 3:
					break
				run.combat.auto_resolve(80)
				if run.sync_combat_result() != &"victory":
					break
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
			_:
				break
	if capture_mode == "battle" and run.phase == RunController.Phase.ENCOUNTER:
		for i in 1:
			if run.combat == null or run.combat.result != &"":
				break
			run.combat.end_player_turn()
	mode._refresh()
	for i in 10:
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(out_path)
	print("SAVED ", out_path, " phase=", run.phase, " rooms=", run.session.grid.all_rooms().size(), " ", img.get_width(), "x", img.get_height())
	quit()
