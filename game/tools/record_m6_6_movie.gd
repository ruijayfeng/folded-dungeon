extends SceneTree
## M6-6: records a real gameplay movie (PNG frame sequence) for the README GIF.
## Run with:
##   godot --position 9000,9000 --write-movie .tmp/m6_6_movie/frame.png --fixed-fps 30 ...

var mode: Node3D = null
var run: RunController = null

func _initialize() -> void:
	var safety := create_timer(120.0)
	safety.timeout.connect(func() -> void:
		print("SAFETY-QUIT")
		quit())
	_drive.call_deferred()

func _wait(frames: int) -> void:
	for i in frames:
		await process_frame

func _drive() -> void:
	await process_frame
	var title: Node = (load("res://presentation/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _wait(36)
	title.queue_free()
	await process_frame
	var ps: PackedScene = load("res://presentation/run_mode/run_mode_3d.tscn")
	mode = ps.instantiate() as Node3D
	root.add_child(mode)
	await process_frame
	await process_frame
	run = mode.run
	var steps := 0
	while run.phase != RunController.Phase.SETTLED and steps < 40:
		steps += 1
		match run.phase:
			RunController.Phase.BUILD:
				mode._default_preview()
				mode._sync()
				await _wait(20)
				var cell: Vector2i = run.auto_build_adjacent()
				if cell == Vector2i(-1, -1):
					break
				await _wait(8)
				run.auto_walk_into(cell)
				mode._room_key = ""
				mode._sync()
				await _wait(18)
			RunController.Phase.ENCOUNTER:
				mode._sync()
				await _wait(16)
				run.combat.auto_resolve(80)
				run.sync_combat_result()
				mode._sync()
				await _wait(10)
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				mode._sync()
				await _wait(16)
				run.resolve_choice(0)
				mode._sync()
				await _wait(8)
			_:
				break
	mode._sync()
	await _wait(30)
	quit()
