class_name RoomInstance
extends RefCounted
## A placed room: definition + orientation + macro-grid cell.
## Runtime mutable state (channels, timers) will live in separate state objects (M2).

var instance_id: StringName = &""
var definition: RoomDef = null
var orientation: int = 0
var cell: Vector2i = Vector2i.ZERO


func _init(p_instance_id: StringName = &"", p_definition: RoomDef = null, p_cell: Vector2i = Vector2i.ZERO, p_orientation: int = 0) -> void:
	instance_id = p_instance_id
	definition = p_definition
	cell = p_cell
	orientation = p_orientation


func door_mask() -> int:
	if definition == null:
		return 0
	return DoorSpec.rotate_mask(definition.door_mask, orientation)


func has_door(dir: int) -> bool:
	return (door_mask() & dir) != 0


func door_dirs() -> Array[int]:
	var result: Array[int] = []
	for dir in DoorSpec.all_dirs():
		if has_door(dir):
			result.append(dir)
	return result


func world_door_cell(dir: int) -> Vector2i:
	return DoorSpec.world_door_cell(cell, dir, orientation)


func world_door_anchor(dir: int) -> Vector2:
	return DoorSpec.world_door_anchor(cell, dir, orientation)


func layout() -> RoomLayout:
	if definition == null:
		return null
	return definition.layout


func clone() -> RoomInstance:
	return RoomInstance.new(instance_id, definition, cell, orientation)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(instance_id).is_empty():
		errors.append("INSTANCE_ID_EMPTY")
	if definition == null:
		errors.append("INSTANCE_DEF_MISSING")
	else:
		for def_error in definition.validate():
			errors.append("INSTANCE_DEF_INVALID: %s" % def_error)
	if orientation < 0 or orientation > 3:
		errors.append("INSTANCE_ORIENTATION_INVALID: %d" % orientation)
	return errors


func describe() -> String:
	var def_id := &"<null>"
	if definition != null:
		def_id = definition.id
	return "%s[%s] cell=%s orientation=%d" % [instance_id, def_id, str(cell), orientation]
