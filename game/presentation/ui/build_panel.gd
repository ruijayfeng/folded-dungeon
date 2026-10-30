class_name BuildPanel
extends VBoxContainer
## Minimal build UI: phase toggle, blueprint placement, rotate/confirm/cancel.
## All game rules live in BuildController/DungeonSession; this only forwards input.

signal ui_action

var session: DungeonSession = null
var controller: BuildController = null
var blueprint_def: RoomDef = null

var phase_label: Label = null
var status_label: Label = null
var toggle_button: Button = null
var begin_button: Button = null
var rotate_button: Button = null
var confirm_button: Button = null
var cancel_button: Button = null


func setup(p_session: DungeonSession, p_controller: BuildController, p_blueprint: RoomDef) -> void:
	session = p_session
	controller = p_controller
	blueprint_def = p_blueprint
	_build_ui()
	refresh()


func _build_ui() -> void:
	custom_minimum_size = Vector2(300, 0)
	add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = "构筑面板（M1）"
	add_child(title)
	phase_label = Label.new()
	add_child(phase_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(300, 48)
	add_child(status_label)
	toggle_button = Button.new()
	toggle_button.text = "进入构筑节点 (Tab)"
	toggle_button.pressed.connect(_on_toggle_build)
	add_child(toggle_button)
	begin_button = Button.new()
	begin_button.text = "开始放置：战斗房"
	begin_button.pressed.connect(_on_begin_build)
	add_child(begin_button)
	rotate_button = Button.new()
	rotate_button.text = "旋转 (R)"
	rotate_button.pressed.connect(_on_rotate)
	add_child(rotate_button)
	confirm_button = Button.new()
	confirm_button.text = "确认放置 (Enter)"
	confirm_button.pressed.connect(_on_confirm)
	add_child(confirm_button)
	cancel_button = Button.new()
	cancel_button.text = "取消 (Esc)"
	cancel_button.pressed.connect(_on_cancel)
	add_child(cancel_button)


func refresh() -> void:
	if session == null:
		return
	phase_label.text = "阶段：%s    BP：%d    回合：%d" % [
		_phase_name(session.phase), session.grid.build_points, session.turn
	]
	var preview_text := "无预览"
	if controller != null and controller.active:
		preview_text = "预览：%s → %s（%s）" % [
			String(controller.room_def.id) if controller.room_def != null else "?",
			str(controller.target_cell),
			"可放置" if controller.preview_valid() else "不可放置",
		]
	status_label.text = preview_text
	toggle_button.text = "离开构筑节点 (Tab)" if session.phase == DungeonSession.Phase.BUILD else "进入构筑节点 (Tab)"
	toggle_button.disabled = session.phase != DungeonSession.Phase.EXPLORE and session.phase != DungeonSession.Phase.BUILD
	begin_button.disabled = session.phase != DungeonSession.Phase.BUILD
	rotate_button.disabled = controller == null or not controller.active
	confirm_button.disabled = controller == null or not controller.active
	cancel_button.disabled = controller == null or not controller.active


func _phase_name(phase: int) -> String:
	match phase:
		DungeonSession.Phase.EXPLORE:
			return "探索"
		DungeonSession.Phase.BUILD:
			return "构筑"
		DungeonSession.Phase.COMBAT:
			return "战斗"
		DungeonSession.Phase.REST:
			return "休整"
	return "未知"


func _on_toggle_build() -> void:
	if session.phase == DungeonSession.Phase.EXPLORE:
		session.enter_build_node()
	elif session.phase == DungeonSession.Phase.BUILD:
		session.leave_build_node()
	ui_action.emit()
	refresh()


func _on_begin_build() -> void:
	controller.begin(blueprint_def)
	ui_action.emit()
	refresh()


func _on_rotate() -> void:
	controller.rotate()
	ui_action.emit()
	refresh()


func _on_confirm() -> void:
	controller.confirm()
	ui_action.emit()
	refresh()


func _on_cancel() -> void:
	controller.cancel()
	ui_action.emit()
	refresh()
