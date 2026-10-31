extends TestCase
## M6-1: 2.5D asset manifest and presentation scripts load in headless mode.


func test_manifest_files_exist() -> void:
	var path := "res://assets/art3d/manifests/art3d.json"
	assert_true(FileAccess.file_exists(path), "art3d manifest exists")
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(data is Dictionary, "manifest parses as dictionary")
	if not (data is Dictionary):
		return
	var items: Array = (data as Dictionary).get("items", [])
	assert_true(items.size() >= 10, "manifest has at least 10 items")
	for item in items:
		var file := String((item as Dictionary).get("file", ""))
		var full := "res://assets/art3d/" + file
		assert_true(ResourceLoader.exists(full), "asset exists: " + file)


func test_material_normals_exist() -> void:
	assert_true(ResourceLoader.exists("res://assets/art3d/materials/floor-stone-n.png"), "floor normal exists")
	assert_true(ResourceLoader.exists("res://assets/art3d/materials/wall-stone-n.png"), "wall normal exists")
	assert_true(ResourceLoader.exists("res://assets/art3d/materials/leather.png"), "leather exists")


func test_m6_scripts_compile() -> void:
	assert_true(load("res://presentation/views/room_3d.gd") != null, "room_3d compiles")
	assert_true(load("res://presentation/views/unit_3d.gd") != null, "unit_3d compiles")
	assert_true(load("res://presentation/run_mode/run_mode_3d.gd") != null, "run_mode_3d compiles")
	assert_true(load("res://presentation/run_mode/run_mode_3d.tscn") != null, "run_mode_3d scene loads")
