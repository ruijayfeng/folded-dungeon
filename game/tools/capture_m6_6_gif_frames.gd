extends SceneTree
## M6-6: capture a clean frame sequence of a real automated run for the README GIF.
## Offscreen window; frames saved to .tmp/m6_6_frames/ then composed with Pillow.

const FRAME_DIR := "/Users/softbook/dev/gmNew/.tmp/m6_6_frames/"
var mode: Node3D = null
var run: RunController = null
var index := 0

func _initialize() -> void:
	var safety := create_timer(240.0)
	safety.timeout.connect(func() -> void:
		print("SAFETY-QUIT")
		quit())
	_drive.call_deferred()

func _pump(frames: int) -> void:
	for i in frames:
		await process_frame
		if index % 2 == 0:
			await RenderingServer.frame_post_draw
			var img: Image = root.get_texture().get_image()
			img.resize(880, int(880.0 * float(img.get_height()) / float(img.get_width())), Image.INTERPOLATE_BILINEAR)
			img.save_png(FRAME_DIR + "%04d.png" % (index / 2))
		index += 1

func _drive() -> void:
	await process_frame
	var title: Node = (load("res://presentation/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _pump(44)
	title.queue_free()
	await process_frame
	var ps: PackedScene = load("res://presentation/run_mode/run_mode_3d.tscn")
	mode = ps.instantiate() as Node3D
	root.add_child(mode)
	await process_frame
	await _pump(12)
	run = mode.run
	var steps := 0
	while run.phase != RunController.Phase.SETTLED and steps < 30:
		steps += 1
		match run.phase:
			RunController.Phase.BUILD:
				mode._default_preview()
				mode._sync()
				await _pump(24)
				var cell: Vector2i = run.auto_build_adjacent()
				if cell == Vector2i(-1, -1):
					break
				await _pump(8)
				run.auto_walk_into(cell)
				mode._room_key = ""
				mode._sync()
				await _pump(22)
			RunController.Phase.ENCOUNTER:
				mode._sync()
				await _pump(18)
				run.combat.auto_resolve(80)
				run.sync_combat_result()
				mode._sync()
				await _pump(14)
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				mode._sync()
				await _pump(16)
				run.resolve_choice(0)
				mode._sync()
				await _pump(10)
			_:
				break
	mode._sync()
	await _pump(40)
	print("FRAMES_DONE ", index / 2)
	quit()
