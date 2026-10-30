extends SceneTree
## Headless test runner. Exits non-zero when any assertion fails.
## Usage: game/tools/godot test

const TEST_SCRIPTS: Array[String] = [
	"res://tests/cases/test_fixed.gd",
	"res://tests/cases/test_rng.gd",
	"res://tests/cases/test_room_def.gd",
	"res://tests/cases/test_doors.gd",
	"res://tests/cases/test_grid.gd",
	"res://tests/scenarios/m0_build_layout.gd",
	"res://tests/cases/test_movement.gd",
	"res://tests/cases/test_build_flow.gd",
	"res://tests/cases/test_room_scenes.gd",
	"res://tests/scenarios/m1_build_and_enter.gd",
	"res://tests/cases/test_channels_m2.gd",
	"res://tests/cases/test_m2_content.gd",
	"res://tests/cases/test_propagation_m2.gd",
	"res://tests/cases/test_recipes_m2.gd",
	"res://tests/cases/test_pipeline_m2.gd",
	"res://tests/scenarios/m2_combo_chain.gd",
	"res://tests/cases/test_fold_m2.gd",
	"res://tests/cases/test_m2_visual.gd",
	"res://tests/cases/test_unit_m3.gd",
	"res://tests/cases/test_projectile_m3.gd",
	"res://tests/cases/test_combat_m3.gd",
	"res://tests/scenarios/m3_battle_layouts.gd",
	"res://tests/cases/test_run_state_m4.gd",
	"res://tests/cases/test_run_controller_m4.gd",
	"res://tests/scenarios/m4_vertical_slice.gd",
	"res://tests/cases/test_scripts_compile.gd",
]


func _initialize() -> void:
	var total_tests := 0
	var total_assertions := 0
	var case_count := 0
	var failures: Array[String] = []

	for script_path in TEST_SCRIPTS:
		var script := load(script_path) as Script
		if script == null or not script.can_instantiate():
			failures.append("%s: script failed to compile" % script_path)
			continue
		var probe: Variant = script.new()
		if not (probe is TestCase):
			failures.append("%s: script is not a TestCase" % script_path)
			continue
		var method_names := _test_method_names(probe)
		if method_names.is_empty():
			failures.append("%s: no test_* methods found" % script_path)
			continue
		case_count += 1
		print("[case] %s" % script_path)
		for method_name in method_names:
			var test_case: Variant = script.new()
			test_case.call(StringName(method_name))
			total_tests += 1
			total_assertions += test_case.assertion_count
			if not test_case.failures.is_empty():
				for failure in test_case.failures:
					failures.append("%s::%s: %s" % [script_path, method_name, failure])

	var summary := {
		"ok": failures.is_empty(),
		"cases": case_count,
		"tests": total_tests,
		"assertions": total_assertions,
		"failed": failures.size(),
	}
	print(JSON.stringify(summary))
	for failure in failures:
		print("FAIL " + failure)
	quit(0 if failures.is_empty() else 1)


func _test_method_names(probe: Variant) -> Array[String]:
	var names: Array[String] = []
	for method in probe.get_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	names.sort()
	return names
