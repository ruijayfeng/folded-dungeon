class_name RunState
extends RefCounted
## Persisted-by-snapshot state for one run. No scene references.

var seed_value: int = 0
var floor: int = 1
var total_floors: int = 2
var gold: int = 0
var build_points: int = 10
var phase: StringName = &"build"
var slot_index: int = 0
var cleared_slots: Array[int] = []
var blueprints: Array[StringName] = []
var events: Array[Dictionary] = []
var victory: bool = false
var run_over: bool = false


func snapshot() -> Dictionary:
	return {
		"seed": seed_value,
		"floor": floor,
		"total_floors": total_floors,
		"gold": gold,
		"build_points": build_points,
		"phase": phase,
		"slot_index": slot_index,
		"cleared_slots": cleared_slots.duplicate(),
		"blueprints": blueprints.duplicate(),
		"victory": victory,
		"run_over": run_over,
		"events": events.size(),
	}
