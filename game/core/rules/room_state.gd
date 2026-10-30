class_name RoomState
extends RefCounted
## Runtime channel/state values for one placed room. Never stored in .tres data.

var instance_id: StringName = &""
var cell: Vector2i = Vector2i(-1, -1)
var channels: PackedInt32Array = PackedInt32Array()
var states: Dictionary = {}       # StringName -> remaining turns (0 = permanent)
var cooldowns: Dictionary = {}    # recipe id -> turns remaining
var triggers_this_turn: int = 0
var recipe_triggers: Dictionary = {}   # recipe id -> triggers this turn


func _init(p_instance_id: StringName = &"", p_cell: Vector2i = Vector2i(-1, -1)) -> void:
	instance_id = p_instance_id
	cell = p_cell
	channels.resize(Channels.COUNT)
	channels.fill(0)


func get_channel(channel: int) -> int:
	if not Channels.is_valid(channel):
		return 0
	return channels[channel]


func set_channel(channel: int, value: int) -> void:
	if not Channels.is_valid(channel):
		return
	channels[channel] = clampi(value, 0, Channels.MAX_VALUE)


func add_channel(channel: int, delta: int, cap: int = Channels.MAX_VALUE) -> int:
	if not Channels.is_valid(channel):
		return 0
	var before := channels[channel]
	channels[channel] = clampi(before + delta, 0, clampi(cap, 0, Channels.MAX_VALUE))
	return channels[channel] - before


func has_state(state_name: StringName) -> bool:
	return states.has(state_name)


func set_state(state_name: StringName, duration_turns: int = 0) -> void:
	if state_name == &"":
		return
	states[state_name] = duration_turns


func clear_state(state_name: StringName) -> void:
	states.erase(state_name)


## Decrements timed states; returns names of states that expired this turn.
func advance_states() -> Array[StringName]:
	var expired: Array[StringName] = []
	for state_name in states.keys():
		var remaining: int = states[state_name]
		if remaining > 0:
			remaining -= 1
			if remaining <= 0:
				states.erase(state_name)
				expired.append(state_name)
			else:
				states[state_name] = remaining
	return expired


func clone() -> RoomState:
	var copy := RoomState.new(instance_id, cell)
	copy.channels = channels.duplicate()
	copy.states = states.duplicate()
	copy.cooldowns = cooldowns.duplicate()
	copy.triggers_this_turn = triggers_this_turn
	copy.recipe_triggers = recipe_triggers.duplicate()
	return copy


func channel_snapshot() -> Array[int]:
	var result: Array[int] = []
	for channel in Channels.COUNT:
		result.append(channels[channel])
	return result


func snapshot() -> Dictionary:
	return {
		"cell": cell,
		"channels": channel_snapshot(),
		"states": states.duplicate(),
	}
