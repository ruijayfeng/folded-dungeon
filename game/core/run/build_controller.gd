class_name BuildController
extends RefCounted
## Owns the build preview state (def, orientation, target cell) and validates it
## through DungeonGrid. UI and tests share the same logic; preview never mutates
## the real layout until confirm().

var session: DungeonSession = null
var active: bool = false
var room_def: RoomDef = null
var orientation: int = 0
var target_cell: Vector2i = Vector2i(-1, -1)
var preview: ValidationReport = null


func _init(session_ref: DungeonSession = null) -> void:
	session = session_ref


func begin(def: RoomDef) -> bool:
	if session == null or def == null:
		return false
	active = true
	room_def = def
	orientation = 0
	target_cell = _default_target_cell()
	refresh_preview()
	return true


func set_cell(cell: Vector2i) -> void:
	target_cell = cell
	refresh_preview()


func rotate() -> void:
	orientation = (orientation + 1) % 4
	refresh_preview()


func refresh_preview() -> void:
	if session == null or session.grid == null or room_def == null or not active:
		preview = null
		return
	preview = session.grid.validate_placement(room_def, target_cell, orientation)


func preview_valid() -> bool:
	return preview != null and preview.is_valid()


func confirm() -> ValidationReport:
	if session == null:
		var report := ValidationReport.new()
		report.add_error(&"NO_SESSION", "BuildController has no session")
		return report
	if not active or room_def == null:
		var report := ValidationReport.new()
		report.add_error(&"NOT_ACTIVE", "no active build preview")
		return report
	var report := session.build_room(room_def, target_cell, orientation)
	if report.is_valid():
		active = false
	return report


func cancel() -> void:
	active = false
	room_def = null
	orientation = 0
	target_cell = Vector2i(-1, -1)
	preview = null


func _default_target_cell() -> Vector2i:
	if session == null or session.player == null:
		return Vector2i(-1, -1)
	var room_cell := session.player.room_cell
	for dir in DoorSpec.all_dirs():
		var candidate := room_cell + DoorSpec.delta(dir)
		if session.grid != null and session.grid.in_bounds(candidate) and session.grid.get_room(candidate) == null:
			return candidate
	return room_cell + Vector2i(1, 0)
