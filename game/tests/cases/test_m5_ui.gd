extends TestCase


func test_run_mode_scene_instantiates() -> void:
	var packed := load("res://presentation/run_mode/run_mode.tscn") as PackedScene
	assert_true(packed != null, "run mode scene loads")
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	assert_true(instance != null, "run mode scene instantiates")
	assert_true(instance.has_method("_ready"), "run mode has ready hook")
	if instance.get("run") == null:
		instance.call("_ready")
	assert_true(instance.get("run") != null, "RunController created by the run layer")
	instance.free()


func test_grid_preview_does_not_mutate_grid() -> void:
	var view := GridMapView.new()
	var grid := DungeonGrid.new()
	view.setup(grid)
	view.set_preview(Vector2i(3, 2), true)
	assert_eq(view.preview_cell, Vector2i(3, 2))
	assert_true(view.preview_valid)
	assert_eq(grid.room_count(), 0, "preview is visual only")
	view.free()


func test_palette_defined() -> void:
	assert_eq(Palette.DOOR, Color("c9a227"))
	assert_eq(Palette.ENEMY, Color("e05555"))
