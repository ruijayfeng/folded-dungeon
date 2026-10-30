class_name TestCase
extends RefCounted
## Minimal headless assertion framework (no third-party addons).
## The runner instantiates one TestCase per test method and inspects failures.

var failures: Array[String] = []
var assertion_count: int = 0


func assert_true(condition: bool, message: String = "") -> void:
	assertion_count += 1
	if not condition:
		failures.append("assert_true: %s" % message)


func assert_false(condition: bool, message: String = "") -> void:
	assertion_count += 1
	if condition:
		failures.append("assert_false: %s" % message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertion_count += 1
	if actual != expected:
		failures.append("assert_eq: %s (actual=%s expected=%s)" % [message, str(actual), str(expected)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	assertion_count += 1
	if actual == unexpected:
		failures.append("assert_ne: %s (both=%s)" % [message, str(actual)])


func assert_almost_eq(actual: float, expected: float, epsilon: float = 0.0001, message: String = "") -> void:
	assertion_count += 1
	if absf(actual - expected) > epsilon:
		failures.append("assert_almost_eq: %s (actual=%f expected=%f)" % [message, actual, expected])


func assert_has_code(report: ValidationReport, code: StringName, message: String = "") -> void:
	assertion_count += 1
	if report == null:
		failures.append("assert_has_code: %s (report is null)" % message)
		return
	if not report.has_code(code):
		failures.append("assert_has_code: %s (missing %s in %s)" % [message, code, report.summary()])


func assert_valid(report: ValidationReport, message: String = "") -> void:
	assertion_count += 1
	if report == null:
		failures.append("assert_valid: %s (report is null)" % message)
		return
	if not report.is_valid():
		failures.append("assert_valid: %s (%s)" % [message, report.summary()])


func fail(message: String) -> void:
	assertion_count += 1
	failures.append("fail: %s" % message)
