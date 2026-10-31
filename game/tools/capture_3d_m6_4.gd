extends SceneTree
## Dev-only: M6-4 UI screenshots (title / build / event / settlement).
## Runs with an offscreen window in a background job; no foreground interaction.

const OUT := "res://../docs/screenshots/"
var mode: Node3D = null
var run: RunController = null

func _initialize() -> void:
	var safety := create_timer(120.0)
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
	await _shot("m6-4-title")
	title.queue_free()
	await process_frame
	var ps: PackedScene = load("res://presentation/run_mode/run_mode_3d.tscn")
	mode = ps.instantiate()
	root.add_child(mode)
	await process_frame
	await process_frame
	run = mode.run
	mode._default_preview()
	mode._sync()
	await _shot("m6-4-build")
	run.phase = RunController.Phase.EVENT
	mode._sync()
	await _shot("m6-4-event")
	run.phase = RunController.Phase.SETTLED
	mode._sync()
	await _shot("m6-4-settle")
	quit()
