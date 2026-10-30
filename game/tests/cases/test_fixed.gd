extends TestCase


func test_fixed_point_basics() -> void:
	assert_eq(Fixed.clamp_value(-1), 0, "clamp low")
	assert_eq(Fixed.clamp_value(1001), 1000, "clamp high")
	assert_eq(Fixed.add(999, 5), 1000, "add clamps")
	assert_eq(Fixed.add(599, 1), 600, "exact threshold add")
	assert_eq(Fixed.sub(0, 1), 0, "sub clamps")
	assert_eq(Fixed.percent_of(1000, 60), 600, "percent")


func test_threshold_boundary() -> void:
	assert_false(Fixed.meets(599, Channels.HEAT_THRESHOLD), "599 below heat threshold")
	assert_true(Fixed.meets(600, Channels.HEAT_THRESHOLD), "600 meets heat threshold")
	assert_false(Fixed.meets(299, Channels.TOXIN_THRESHOLD), "299 below toxin threshold")
	assert_true(Fixed.meets(300, Channels.TOXIN_THRESHOLD), "300 meets toxin threshold")


func test_ratio_conversion() -> void:
	assert_eq(Fixed.from_ratio(0.6), 600, "0.6 -> 600")
	assert_eq(Fixed.from_ratio(0.3004), 300, "0.3004 -> 300")
	assert_almost_eq(Fixed.to_float(600), 0.6, 0.000001, "600 -> 0.6")


func test_runner_captures_failure() -> void:
	var failing := AlwaysFails.new()
	failing.test_always_fails()
	assert_eq(failing.failures.size(), 1, "framework records failures")
	assert_eq(failing.assertion_count, 1, "framework counts assertions")


class AlwaysFails extends TestCase:
	func test_always_fails() -> void:
		assert_true(false, "intentional failure for framework self-test")
