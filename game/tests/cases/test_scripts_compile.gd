extends TestCase
## Guard against parse errors in core/presentation scripts (Godot compiles scripts lazily).

func test_core_and_presentation_scripts_compile() -> void:
	var failures: Array[String] = []
	for root_path in ["res://core", "res://presentation"]:
		_collect_compile_failures(root_path, failures)
	assert_true(failures.is_empty(), "script compile failures: %s" % ", ".join(failures))


func _collect_compile_failures(dir_path: String, failures: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := dir_path + "/" + file_name
		if dir.current_is_dir():
			_collect_compile_failures(full_path, failures)
		elif file_name.ends_with(".gd"):
			var script := load(full_path) as Script
			if script == null or not script.can_instantiate():
				failures.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
