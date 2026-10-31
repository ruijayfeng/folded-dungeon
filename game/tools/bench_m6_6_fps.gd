extends SceneTree
var mode: Node3D = null
func _initialize() -> void:
	_drive.call_deferred()
func _drive() -> void:
	await process_frame
	var ps: PackedScene = load("res://presentation/run_mode/run_mode_3d.tscn")
	mode = ps.instantiate() as Node3D
	root.add_child(mode)
	await process_frame
	await process_frame
	for i in 120:
		await process_frame
	var t0 := Time.get_ticks_msec()
	var f0 := Engine.get_frames_drawn()
	var samples: Array[float] = []
	for i in 300:
		await process_frame
		samples.append(Engine.get_frames_per_second())
	var elapsed := float(Time.get_ticks_msec() - t0) / 1000.0
	var drawn := Engine.get_frames_drawn() - f0
	var avg := float(drawn) / maxf(elapsed, 0.001)
	var total := 0.0
	for v in samples:
		total += v
	print("FPS_AVG ", avg, " FPS_SAMPLE_AVG ", total / float(samples.size()), " SECONDS ", elapsed)
	quit()
