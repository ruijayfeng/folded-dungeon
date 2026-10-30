extends Node2D
## M1 playable sandbox: explore the starting room, enter a build node,
## place a rotated room, then walk through the new door.
## Presentation only; all rules live in core/.

const START_ROOM_PATH := "res://data/rooms/start_room.tres"
const COMBAT_ROOM_PATH := "res://data/rooms/combat_room.tres"
const MAP_POSITION := Vector2(16, 40)
const ROOM_POSITION := Vector2(340, 40)
const PANEL_POSITION := Vector2(16, 340)
const STATUS_POSITION := Vector2(340, 250)

var session: DungeonSession = null
var build_controller: BuildController = null
var map_view: GridMapView = null
var room_view: RoomView = null
var build_panel: BuildPanel = null
var status_label: Label = null
var blueprint_def: RoomDef = null


func _ready() -> void:
	_setup()


func _setup() -> void:
	var start_def := load(START_ROOM_PATH) as RoomDef
	blueprint_def = load(COMBAT_ROOM_PATH) as RoomDef
	session = DungeonSession.new()
	var report := session.start_run(start_def, Vector2i(2, 2), 0, 20261030, 10)
	if not report.is_valid():
		push_error("failed to start M1 sandbox: %s" % report.summary())
		return
	session.acquire_blueprint(blueprint_def)
	build_controller = BuildController.new(session)

	var title := Label.new()
	title.text = "Folded Dungeon — M1 sandbox（WASD 移动 / Tab 构筑节点 / 地图点击选格）"
	title.position = Vector2(16, 8)
	add_child(title)

	map_view = GridMapView.new()
	map_view.position = MAP_POSITION
	add_child(map_view)
	map_view.setup(session.grid)
	map_view.set_build_controller(build_controller)

	room_view = RoomView.new()
	room_view.position = ROOM_POSITION
	add_child(room_view)

	build_panel = BuildPanel.new()
	build_panel.position = PANEL_POSITION
	add_child(build_panel)
	build_panel.setup(session, build_controller, blueprint_def)
	build_panel.ui_action.connect(_refresh_views)

	status_label = Label.new()
	status_label.position = STATUS_POSITION
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(380, 0)
	add_child(status_label)

	_refresh_views()


func _refresh_views() -> void:
	room_view.setup(session.current_room(), session.player.local_cell)
	map_view.set_current(session.current_room_cell())
	build_panel.refresh()
	status_label.text = "阶段：%s    BP：%d    回合：%d\n位置：房间 %s / 格 %s（行动点 %d）" % [
		_build_phase_name(session.phase),
		session.grid.build_points,
		session.turn,
		str(session.player.room_cell),
		str(session.player.local_cell),
		session.player.move_points,
	]


func _build_phase_name(phase: int) -> String:
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_W, KEY_UP:
				_try_move(DoorSpec.Dir.N)
			KEY_D, KEY_RIGHT:
				_try_move(DoorSpec.Dir.E)
			KEY_S, KEY_DOWN:
				_try_move(DoorSpec.Dir.S)
			KEY_A, KEY_LEFT:
				_try_move(DoorSpec.Dir.W)
			KEY_TAB:
				_toggle_build_node()
			KEY_R:
				if build_controller.active:
					build_controller.rotate()
					_refresh_views()
			KEY_ENTER, KEY_KP_ENTER:
				if build_controller.active:
					build_controller.confirm()
					_refresh_views()
			KEY_ESCAPE:
				if build_controller.active:
					build_controller.cancel()
					_refresh_views()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if build_controller.active:
			var local_position := map_view.to_local(event.position)
			build_controller.set_cell(map_view.cell_at(local_position))
			_refresh_views()


func _try_move(dir: int) -> void:
	var result := session.try_move(dir)
	if result["ok"]:
		_refresh_views()
	else:
		status_label.text = "移动失败：%s" % str(result["reason"])


func _toggle_build_node() -> void:
	if build_controller.active:
		build_controller.cancel()
	if session.phase == DungeonSession.Phase.EXPLORE:
		session.enter_build_node()
	elif session.phase == DungeonSession.Phase.BUILD:
		session.leave_build_node()
	_refresh_views()
