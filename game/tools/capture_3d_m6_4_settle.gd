extends SceneTree
## Dev-only: isolated settlement screenshot (fresh process avoids stale frames).

const OUT := "res://../docs/screenshots/"
var mode: Node3D = null

func _initialize() -> void:
	var safety := create_timer(90.0)
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
	var ps: PackedScene = load("res://presentation/run_mode/run_mode_3d.tscn")
	mode = ps.instantiate() as Node3D
	root.add_child(mode)
	await process_frame
	await process_frame
	var run: RunController = mode.run
	run.phase = RunController.Phase.SETTLED
	mode._sync()
	await _shot("m6-4-settle")
	quit()
