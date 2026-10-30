class_name ChannelEmitter
extends Resource
## A per-turn channel emission attached to a RoomDef (full pipeline lands in M2).

@export var channel: int = 0
@export var rate_per_turn: int = 0
@export var max_value: int = Channels.MAX_VALUE


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if not Channels.is_valid(channel):
		errors.append("EMITTER_CHANNEL_INVALID: %d" % channel)
	if rate_per_turn < 0:
		errors.append("EMITTER_RATE_NEGATIVE: %d" % rate_per_turn)
	if max_value <= 0 or max_value > Channels.MAX_VALUE:
		errors.append("EMITTER_MAX_INVALID: %d" % max_value)
	return errors
