class_name EffectDef
extends Resource
## One effect of a ReactionRecipe.

enum Kind { ADD_CHANNEL, ADD_CHANNEL_TO_NEIGHBORS, SET_STATE, CLEAR_STATE, EMIT_WAVE, EMIT_EVENT }

@export var kind: int = Kind.ADD_CHANNEL
@export var channel: int = Channels.Channel.HEAT
@export var amount: int = 0
@export var state_name: StringName = &""
@export var duration_turns: int = 0
@export var wave_tag: StringName = &"fire"
@export var direction: int = 0
@export var max_steps: int = 4
@export var event_id: StringName = &""


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if kind < Kind.ADD_CHANNEL or kind > Kind.EMIT_EVENT:
		errors.append("EFFECT_KIND_INVALID: %d" % kind)
	if kind == Kind.ADD_CHANNEL or kind == Kind.ADD_CHANNEL_TO_NEIGHBORS:
		if not Channels.is_valid(channel):
			errors.append("EFFECT_CHANNEL_INVALID: %d" % channel)
		if amount == 0:
			errors.append("EFFECT_AMOUNT_ZERO")
	if kind == Kind.SET_STATE and state_name == &"":
		errors.append("EFFECT_STATE_EMPTY")
	if kind == Kind.EMIT_WAVE and wave_tag == &"":
		errors.append("EFFECT_WAVE_TAG_EMPTY")
	if kind == Kind.EMIT_WAVE and max_steps <= 0:
		errors.append("EFFECT_WAVE_STEPS_INVALID: %d" % max_steps)
	if kind == Kind.EMIT_EVENT and event_id == &"":
		errors.append("EFFECT_EVENT_ID_EMPTY")
	return errors
