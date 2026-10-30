class_name RoomDef
extends Resource
## Static definition of a room type (docs/03 §4.1). Points at pure-data RoomLayout;
## never at scenes/nodes — presentation maps layout data separately (B3).

enum Category { ELEMENT = 0, CONVERSION = 1, TRANSFER = 2, COMBAT = 3, RESOURCE = 4, SPECIAL = 5 }

@export var id: StringName = &""
@export var display_name: String = ""
@export var category: int = Category.ELEMENT
@export var door_mask: int = 0
@export var layout: RoomLayout = null
@export var emitters: Array[ChannelEmitter] = []
@export var transfer_percent: int = 100
@export var absorb_channel: int = -1
@export var absorb_percent: int = 0
@export var wave_redirect_steps: int = 0
@export var periodic_turns: int = 0
@export var periodic_event: StringName = &""
@export var build_cost: int = 1
@export var tags: Array[StringName] = []
@export var description: String = ""


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty():
		errors.append("ROOM_ID_EMPTY")
	if display_name.is_empty():
		errors.append("ROOM_NAME_EMPTY")
	if category < 0 or category > Category.SPECIAL:
		errors.append("ROOM_CATEGORY_INVALID: %d" % category)
	if door_mask <= 0 or (door_mask & ~15) != 0:
		errors.append("ROOM_DOOR_MASK_INVALID: %d" % door_mask)
	if layout == null:
		errors.append("ROOM_LAYOUT_MISSING")
	else:
		for layout_error in layout.validate():
			errors.append("ROOM_LAYOUT_INVALID: %s" % layout_error)
	for emitter in emitters:
		if emitter == null:
			errors.append("ROOM_EMITTER_NULL")
			continue
		for emitter_error in emitter.validate():
			errors.append("ROOM_EMITTER_INVALID: %s" % emitter_error)
	if build_cost < 0:
		errors.append("ROOM_BUILD_COST_NEGATIVE: %d" % build_cost)
	if transfer_percent < 0 or transfer_percent > 300:
		errors.append("ROOM_TRANSFER_PERCENT_INVALID: %d" % transfer_percent)
	if absorb_channel != -1 and not Channels.is_valid(absorb_channel):
		errors.append("ROOM_ABSORB_CHANNEL_INVALID: %d" % absorb_channel)
	if absorb_percent < 0 or absorb_percent > 100:
		errors.append("ROOM_ABSORB_PERCENT_INVALID: %d" % absorb_percent)
	if wave_redirect_steps < -3 or wave_redirect_steps > 3:
		errors.append("ROOM_REDIRECT_STEPS_INVALID: %d" % wave_redirect_steps)
	if periodic_turns < 0:
		errors.append("ROOM_PERIODIC_TURNS_INVALID: %d" % periodic_turns)
	if periodic_turns > 0 and periodic_event == &"":
		errors.append("ROOM_PERIODIC_EVENT_EMPTY")
	return errors


func door_dirs() -> Array[int]:
	var result: Array[int] = []
	for dir in DoorSpec.all_dirs():
		if door_mask & dir:
			result.append(dir)
	return result


func has_door(dir: int) -> bool:
	return (door_mask & dir) != 0


static func category_name(value: int) -> StringName:
	match value:
		Category.ELEMENT:
			return &"element"
		Category.CONVERSION:
			return &"conversion"
		Category.TRANSFER:
			return &"transfer"
		Category.COMBAT:
			return &"combat"
		Category.RESOURCE:
			return &"resource"
		Category.SPECIAL:
			return &"special"
	return &"unknown"
