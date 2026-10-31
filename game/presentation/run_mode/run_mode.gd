extends Node2D
## M5 playable GUI run layer: drives RunController through
## build -> walk -> encounter/event/rest/shop -> boss -> settlement.

const TOTAL_FLOORS := 1
const RUN_SEED := 20261030
const MAP_POSITION := Vector2(16, 44)
const ROOM_POSITION := Vector2(340, 44)
const STATUS_POSITION := Vector2(340, 300)
const PANEL_POSITION := Vector2(16, 350)

var run: RunController = null
var map_view: GridMapView = null
var room_view: RoomView = null
var debug_panel: DebugPanel = null
var hud_label: Label = null
var status_label: Label = null
var button_panel: VBoxContainer = null
var selected_offer: int = -1
var preview_orientation: int = 0
var preview_cell: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	_build_ui()
	_start_new_run(RUN_SEED)


func _build_ui() -> void:
	var title := Label.new()
	title.text = "Folded Dungeon — M5 运行层（1/2/3 选择 / R 旋转 / 点击地图选格 / Enter 建造或结束回合）"
	title.position = Vector2(16, 8)
	add_child(title)
	map_view = GridMapView.new()
	map_view.position = MAP_POSITION
	add_child(map_view)
	room_view = RoomView.new()
	room_view.position = ROOM_POSITION
	add_child(room_view)
	hud_label = Label.new()
	hud_label.position = Vector2(340, 230)
	hud_label.custom_minimum_size = Vector2(620, 60)
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hud_label)
	status_label = Label.new()
	status_label.position = STATUS_POSITION
	status_label.custom_minimum_size = Vector2(620, 80)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)
	button_panel = VBoxContainer.new()
	button_panel.position = PANEL_POSITION
	button_panel.custom_minimum_size = Vector2(300, 0)
	add_child(button_panel)
	debug_panel = DebugPanel.new()
	debug_panel.position = Vector2(340, 520)
	add_child(debug_panel)


func _start_new_run(seed_value: int) -> void:
	run = RunController.new()
	run.start(seed_value, TOTAL_FLOORS)
	selected_offer = -1
	preview_orientation = 0
	preview_cell = Vector2i(-1, -1)
	if run.phase == RunController.Phase.BUILD and not run.current_offer.is_empty():
		selected_offer = 0
	_refresh()


func _refresh() -> void:
	if run == null:
		return
	if run.session == null:
		status_label.text = "无法开始单局"
		return
	map_view.setup(run.session.grid)
	map_view.set_current(run.session.current_room_cell())
	map_view.set_preview(preview_cell, _preview_valid())
	room_view.setup(run.session.current_room(), run.session.player.local_cell)
	room_view.set_rule_engine(run.engine)
	if run.phase == RunController.Phase.ENCOUNTER and run.combat != null and run.combat.state != null:
		room_view.set_combat_units(run.combat.state.units)
	else:
		room_view.set_combat_units([])
	debug_panel.setup(run.engine, run.session)
	_update_hud()
	_rebuild_buttons()


func _update_hud() -> void:
	var lines: Array[String] = []
	lines.append("楼层 %d/%d   金币 %d   构筑点 %d   阶段 %s" % [
		run.state.floor, run.state.total_floors, run.state.gold, run.state.build_points, _phase_name(),
	])
	if run.phase == RunController.Phase.BUILD and not run.current_offer.is_empty():
		var offer_parts: Array[String] = []
		for index in run.current_offer.size():
			var def := run.current_offer[index]
			offer_parts.append("%d=%s(%dBP)" % [index + 1, def.display_name, def.build_cost])
		lines.append("蓝图：" + "  ".join(offer_parts) + "   | 预览：%s" % str(preview_cell))
	elif run.phase == RunController.Phase.ENCOUNTER and run.combat != null and run.combat.state != null:
		var player := run.combat.state.player_unit()
		lines.append("战斗 round=%d  HP=%d/%d  怪物=%d" % [
			run.combat.state.round, player.hp if player != null else 0,
			player.max_hp if player != null else 0, run.combat.state.living_enemies().size(),
		])
	hud_label.text = "\n".join(lines)


func _phase_name() -> String:
	match run.phase:
		RunController.Phase.BUILD:
			return "构筑"
		RunController.Phase.EXPLORE:
			return "探索"
		RunController.Phase.ENCOUNTER:
			return "战斗"
		RunController.Phase.EVENT:
			return "事件"
		RunController.Phase.REST:
			return "休整"
		RunController.Phase.SHOP:
			return "商店"
		RunController.Phase.SETTLED:
			return "结算"
	return "未知"


func _preview_valid() -> bool:
	if run.phase != RunController.Phase.BUILD or selected_offer < 0 or selected_offer >= run.current_offer.size():
		return false
	if run.session.grid.get_room(preview_cell) != null:
		return false
	var def := run.current_offer[selected_offer]
	return run.session.grid.validate_placement(def, preview_cell, preview_orientation).is_valid()


func _rebuild_buttons() -> void:
	for child in button_panel.get_children():
		child.queue_free()
	match run.phase:
		RunController.Phase.BUILD:
			for index in run.current_offer.size():
				var def := run.current_offer[index]
				var button := Button.new()
				button.text = "%d. %s（%d BP）" % [index + 1, def.display_name, def.build_cost]
				button.pressed.connect(_on_offer_pressed.bind(index))
				button_panel.add_child(button)
			var hint := Label.new()
			hint.text = "选择蓝图后用鼠标点地图格，R 旋转，Enter 建造"
			button_panel.add_child(hint)
		RunController.Phase.EVENT:
			_add_choice_button("1. 治疗 +5", 0)
			_add_choice_button("2. 金币 +25", 1)
			_add_choice_button("3. 构筑点 +2", 2)
		RunController.Phase.REST:
			_add_choice_button("1. 休息（治疗 +6）", 0)
		RunController.Phase.SHOP:
			_add_choice_button("1. 免费治疗 +10", 0)
			_add_choice_button("2. 花 20 金币买 3 BP", 1)
			_add_choice_button("3. 离开商店", 2)
		RunController.Phase.SETTLED:
			var button := Button.new()
			button.text = "R. 重新开始"
			button.pressed.connect(_on_restart_pressed)
			button_panel.add_child(button)


func _add_choice_button(label_text: String, choice: int) -> void:
	var button := Button.new()
	button.text = label_text
	button.pressed.connect(_on_choice_pressed.bind(choice))
	button_panel.add_child(button)


func _on_offer_pressed(index: int) -> void:
	if run.phase != RunController.Phase.BUILD:
		return
	selected_offer = index
	preview_orientation = 0
	_preview_default_cell()
	_refresh()


func _on_choice_pressed(choice: int) -> void:
	if run.resolve_choice(choice):
		_refresh()


func _on_restart_pressed() -> void:
	_start_new_run(RUN_SEED)


func _preview_default_cell() -> void:
	preview_cell = Vector2i(-1, -1)
	for y in DungeonGrid.SIZE_Y:
		for x in DungeonGrid.SIZE_X:
			var cell := Vector2i(x, y)
			if run.session.grid.get_room(cell) == null:
				preview_cell = cell
				return


func _try_build() -> void:
	if run.phase != RunController.Phase.BUILD or selected_offer < 0:
		return
	var report := run.build_and_place(selected_offer, preview_cell, preview_orientation)
	if report.is_valid():
		status_label.text = "建造成功：走进新房间继续"
		selected_offer = -1
		preview_cell = Vector2i(-1, -1)
		if not run.current_offer.is_empty():
			selected_offer = 0
		_refresh()
	else:
		status_label.text = "建造失败：%s" % report.summary()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if run.phase == RunController.Phase.BUILD and selected_offer >= 0:
			var local_position := map_view.to_local(event.position)
			var cell := map_view.cell_at(local_position)
			if run.session.grid.in_bounds(cell):
				preview_cell = cell
				_refresh()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var keycode: int = event.keycode
	if run.phase == RunController.Phase.SETTLED:
		if keycode == KEY_R:
			_start_new_run(RUN_SEED)
		return
	if run.phase == RunController.Phase.BUILD:
		match keycode:
			KEY_1, KEY_2, KEY_3:
				var index: int = keycode - KEY_1
				if index < run.current_offer.size():
					selected_offer = index
					preview_orientation = 0
					_refresh()
			KEY_R:
				preview_orientation = (preview_orientation + 1) % 4
				_refresh()
			KEY_ENTER, KEY_KP_ENTER:
				_try_build()
		return
	if run.phase == RunController.Phase.EXPLORE:
		var dir: int = _key_dir(keycode)
		if dir != 0:
			_explore_move(dir)
		return
	if run.phase == RunController.Phase.ENCOUNTER:
		match keycode:
			KEY_W, KEY_UP:
				_combat_move(DoorSpec.Dir.N)
			KEY_D, KEY_RIGHT:
				_combat_move(DoorSpec.Dir.E)
			KEY_S, KEY_DOWN:
				_combat_move(DoorSpec.Dir.S)
			KEY_A, KEY_LEFT:
				_combat_move(DoorSpec.Dir.W)
			KEY_SPACE:
				_combat_attack_nearest()
			KEY_ENTER, KEY_KP_ENTER:
				run.combat.end_player_turn()
				run.sync_combat_result()
				_refresh()
		return
	if run.phase == RunController.Phase.EVENT or run.phase == RunController.Phase.REST or run.phase == RunController.Phase.SHOP:
		match keycode:
			KEY_1:
				_on_choice_pressed(0)
			KEY_2:
				_on_choice_pressed(1)
			KEY_3:
				_on_choice_pressed(2)


func _key_dir(keycode: int) -> int:
	match keycode:
		KEY_W, KEY_UP:
			return DoorSpec.Dir.N
		KEY_D, KEY_RIGHT:
			return DoorSpec.Dir.E
		KEY_S, KEY_DOWN:
			return DoorSpec.Dir.S
		KEY_A, KEY_LEFT:
			return DoorSpec.Dir.W
	return 0


func _explore_move(dir: int) -> void:
	var from_room := run.session.current_room_cell()
	var result := run.session.try_move(dir)
	if not result["ok"]:
		status_label.text = "移动失败：%s" % str(result["reason"])
		return
	run.engine.tick()
	if run.session.current_room_cell() != from_room:
		run.on_room_entered(run.session.current_room_cell())
	_refresh()


func _combat_move(dir: int) -> void:
	run.combat.player_move(dir)
	_refresh()


func _combat_attack_nearest() -> void:
	var player := run.combat.state.player_unit()
	if player == null:
		return
	for enemy in run.combat.state.living_enemies():
		if run.combat.state.distance(player, enemy) <= player.attack_range:
			run.combat.player_attack(enemy.unit_id)
			run.sync_combat_result()
			_refresh()
			return
	status_label.text = "没有相邻怪物可攻击"
