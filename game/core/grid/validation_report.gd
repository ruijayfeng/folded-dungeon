class_name ValidationReport
extends RefCounted
## Structured result for grid mutations (docs/03 §5.1).
## Errors carry stable reason codes for UI/tests.

var errors: Array[Dictionary] = []
var warnings: Array[Dictionary] = []


func add_error(code: StringName, detail: String = "") -> void:
	errors.append({"code": code, "detail": detail})


func add_warning(code: StringName, detail: String = "") -> void:
	warnings.append({"code": code, "detail": detail})


func is_valid() -> bool:
	return errors.is_empty()


func has_code(code: StringName) -> bool:
	for entry in errors:
		if entry["code"] == code:
			return true
	return false


func first_code() -> StringName:
	if errors.is_empty():
		return &"OK"
	return errors[0]["code"]


func codes() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry in errors:
		result.append(entry["code"])
	return result


func merge(other: ValidationReport) -> void:
	errors.append_array(other.errors)
	warnings.append_array(other.warnings)


func summary() -> String:
	if is_valid():
		return "OK"
	var parts := PackedStringArray()
	for entry in errors:
		parts.append("%s(%s)" % [entry["code"], entry["detail"]])
	return "; ".join(parts)
