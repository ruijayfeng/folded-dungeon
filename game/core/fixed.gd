class_name Fixed
extends RefCounted
## Fixed-point helpers for deterministic channel values.
## Gameplay channel values are integers in [0, MAX]; thresholds are integers too,
## so comparisons never depend on floating point rounding (review I9).

const SCALE: int = 1000
const MAX: int = 1000


static func clamp_value(value: int) -> int:
	return clampi(value, 0, MAX)


static func add(a: int, b: int) -> int:
	return clamp_value(a + b)


static func sub(a: int, b: int) -> int:
	return clamp_value(a - b)


static func from_ratio(ratio: float) -> int:
	return clamp_value(roundi(ratio * float(SCALE)))


static func to_float(value: int) -> float:
	return float(value) / float(SCALE)


static func meets(value: int, threshold: int) -> bool:
	return value >= threshold


static func percent_of(value: int, percent: int) -> int:
	return clamp_value((value * percent) / 100)
