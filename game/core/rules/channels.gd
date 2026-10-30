class_name Channels
extends RefCounted
## Environment channels for the spatial rule engine (docs/01 §5.2).
## Values are fixed-point integers (see Fixed); thresholds are integers too.

enum Channel { HEAT = 0, TOXIN = 1, COLD = 2, CHARGE = 3, AIRFLOW = 4 }

const COUNT: int = 5
const MAX_VALUE: int = 1000
const HEAT_THRESHOLD: int = 600
const TOXIN_THRESHOLD: int = 300
const NAMES: Array[StringName] = [&"heat", &"toxin", &"cold", &"charge", &"airflow"]


static func is_valid(channel: int) -> bool:
	return channel >= 0 and channel < COUNT


static func name_of(channel: int) -> StringName:
	if not is_valid(channel):
		return &"unknown"
	return NAMES[channel]
