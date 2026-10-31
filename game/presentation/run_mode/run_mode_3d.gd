extends Node3D
## M6-1 playable 2.5D run layer: 3D dungeon room + AI billboard units + leather HUD.
## Drives the existing RunController unchanged; this script only presents and forwards input.

const TOTAL_FLOORS := 1
const RUN_SEED := 20261030
const ROOM_UNITS := 9

const COL_GOLD := Color(0.85, 0.70, 0.42)
const COL_TEXT := Color(0.90, 0.86, 0.76)
const COL_MUTED := Color(0.62, 0.57, 0.47)
const COL_DANGER := Color(0.85, 0.42, 0.35)
const COL_SAFE := Color(0.55, 0.82, 0.45)

var run: RunController = null
var room_3d: Room3D = null
var camera: Camera3D = null
var units_root: Node3D = null
var fx_root: Node3D = null
var hud: CanvasLayer = null
var hud_root: Control = null

var selected_offer := -1
var preview_orientation := 0
var preview_cell := Vector2i(-1, -1)

var _unit_views: Dictionary = {}
var _room_key := ""
var _base_camera := Vector3.ZERO
var _cam_focus := Vector3(ROOM_UNITS * 0.5, 1.15, ROOM_UNITS * 0.5)
var _shake := 0.0
var _time := 0.0
var _hp_snapshot: Dictionary = {}

var _font_title: SystemFont
var _font_body: SystemFont
var _title_panel: Panel
var _stats_panel: Panel
var _right_panel: Panel
var _bottom_panel: Panel
var _build_panel: Panel
var _choice_panel: Panel
var _channels_panel: Panel
var _settle_panel: Panel
var _map_panel: Panel

var _lbl_title: Label
var _lbl_floor: Label
var _lbl_phase: Label
var _lbl_stats: Label
var _lbl_hp: Label
var _lbl_status: Label
var _lbl_units: Label
var _lbl_intent: Label

var _offer_buttons: Array[Button] = []
var _choice_buttons: Array[Button] = []
var _channel_bars: Array[ColorRect] = []
var _channel_labels: Array[Label] = []
var _map_cells: Array[Button] = []
var _settle_label: Label
var _restart_button: Button

var _map_visible := false


func _ready() -> void:
	_build_environment()
	_build_camera()
	room_3d = Room3D.new()
	room_3d.name = "Room3D"
	add_child(room_3d)
	units_root = Node3D.new()
	units_root.name = "Units"
	add_child(units_root)
	fx_root = Node3D.new()
	fx_root.name = "Fx"
	add_child(fx_root)
	_build_hud()
	_start_run(RUN_SEED)


func _process(delta: float) -> void:
	_time += delta
	if camera == null:
		return
	var desired := _cam_focus + Vector3(9.8, 7.6, 9.8)
	_base_camera = _base_camera.lerp(desired, 1.0 - exp(-delta * 7.0))
	var off := Vector3.ZERO
	if _shake > 0.001:
		_shake = maxf(0.0, _shake - delta * 7.0)
		off = Vector3(
			sin(_time * 71.0) * _shake * 0.035,
			sin(_time * 53.0) * _shake * 0.025,
			sin(_time * 89.0) * _shake * 0.035
		)
	camera.position = _base_camera + off
	camera.look_at(_cam_focus, Vector3.UP)


# ---------------------------------------------------------------- world

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.028, 0.026, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.25, 0.34)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.22
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	env.glow_intensity = 1.35
	env.glow_strength = 1.0
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.72
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.055, 0.05)
	env.fog_light_energy = 1.0
	env.fog_density = 0.006
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.45, 0.45, 0.5)
	env.volumetric_fog_anisotropy = 0.4
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var fill := OmniLight3D.new()
	fill.position = Vector3(ROOM_UNITS * 0.5, 4.2, ROOM_UNITS * 0.5)
	fill.light_color = Color(0.45, 0.55, 0.75)
	fill.light_energy = 1.6
	fill.omni_range = 10.0
	add_child(fill)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52, -35, 0)
	moon.light_color = Color(0.55, 0.62, 0.78)
	moon.light_energy = 0.26
	moon.shadow_enabled = true
	add_child(moon)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.2
	camera.near = 0.1
	camera.far = 100.0
	var center := Vector3(ROOM_UNITS * 0.5, 1.15, ROOM_UNITS * 0.5)
	_base_camera = center + Vector3(9.8, 7.6, 9.8)
	camera.look_at_from_position(_base_camera, center, Vector3.UP)
	camera.current = true
	add_child(camera)


# ---------------------------------------------------------------- run flow

func _start_run(seed_value: int) -> void:
	run = RunController.new()
	run.start(seed_value, TOTAL_FLOORS)
	selected_offer = 0 if run.phase == RunController.Phase.BUILD and not run.current_offer.is_empty() else -1
	preview_orientation = 0
	preview_cell = Vector2i(-1, -1)
	_room_key = ""
	_hp_snapshot.clear()
	_clear_unit_views()
	_default_preview()
	_sync()


func _default_preview() -> void:
	preview_cell = Vector2i(-1, -1)
	if run == null or run.phase != RunController.Phase.BUILD:
		return
	if selected_offer < 0 or selected_offer >= run.current_offer.size():
		return
	var def := run.current_offer[selected_offer]
	if def == null:
		return
	for y in DungeonGrid.SIZE_Y:
		for x in DungeonGrid.SIZE_X:
			var cell := Vector2i(x, y)
			if run.session.grid.get_room(cell) != null:
				continue
			if run.session.grid.validate_placement(def, cell, preview_orientation).is_valid():
				preview_cell = cell
				return


func _preview_valid() -> bool:
	if run == null or run.phase != RunController.Phase.BUILD or preview_cell.x < 0:
		return false
	if selected_offer < 0 or selected_offer >= run.current_offer.size():
		return false
	var def := run.current_offer[selected_offer]
	return run.session.grid.validate_placement(def, preview_cell, preview_orientation).is_valid()


func _sync() -> void:
	if run == null:
		return
	_update_camera_focus()
	var previous_hp := _hp_snapshot.duplicate()
	_hp_snapshot.clear()
	var room := run.session.current_room()
	if room != null:
		var key := "%s|%d|%s" % [str(room.cell), room.orientation, str(room.definition.id)]
		if key != _room_key:
			_room_key = key
			room_3d.setup(room)
		var state := run.engine.room_state(room.cell)
		room_3d.update_channels(state)
	room_3d.highlight_cell(preview_cell if run.phase == RunController.Phase.BUILD else Vector2i(-1, -1),
		Color(0.35, 0.95, 0.55, 0.25) if _preview_valid() else Color(1.0, 0.35, 0.30, 0.25))
	_sync_units(previous_hp)
	_sync_hud()


func _sync_units(previous_hp: Dictionary) -> void:
	var wanted: Dictionary = {}
	if run == null or run.session == null:
		return
	if run.phase == RunController.Phase.ENCOUNTER and run.combat != null and run.combat.state != null:
		for unit in run.combat.state.units:
			wanted[unit.unit_id] = unit
	elif run.session.player != null:
		wanted[run.session.player.unit_id] = run.session.player
	# create / update
	for unit_id in wanted:
		var unit: Unit = wanted[unit_id]
		_hp_snapshot[unit_id] = unit.hp
		var is_player: bool = unit.team == Unit.TEAM_PLAYER
		var view: Unit3D = _unit_views.get(unit_id)
		if view == null:
			view = Unit3D.new()
			units_root.add_child(view)
			view.setup(unit, is_player)
			_unit_views[unit_id] = view
			view.place_at(unit.local_cell, false)
		else:
			var old_cell: Vector2i = Vector2i(roundi(view.position.x - 0.5), roundi(view.position.z - 0.5))
			view.update_from_unit(unit)
			if old_cell != unit.local_cell:
				view.place_at(unit.local_cell, true)
		var was: int = int(previous_hp.get(unit_id, unit.hp))
		if was > unit.hp:
			_damage_number(unit.local_cell, was - unit.hp, is_player)
			_attack_feedback(unit_id, is_player)
	# remove stale
	for unit_id in _unit_views.keys():
		if not wanted.has(unit_id):
			var view: Unit3D = _unit_views[unit_id]
			view.queue_free()
			_unit_views.erase(unit_id)


func _attack_feedback(unit_id: StringName, is_player: bool) -> void:
	if is_player:
		return
	var t := create_tween()
	_shake = maxf(_shake, 1.2)
	var view: Unit3D = _unit_views.get(unit_id)
	if view != null:
		view.play_attack()


func _damage_number(cell: Vector2i, amount: int, is_player: bool) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.font_size = 64
	label.pixel_size = 0.006
	label.modulate = Color(1.0, 0.85, 0.45) if is_player else Color(1.0, 0.42, 0.32)
	label.outline_size = 12
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(cell.x + 0.5, 1.8, cell.y + 0.5)
	label.no_depth_test = true
	fx_root.add_child(label)
	var t := create_tween()
	t.tween_property(label, "position:y", label.position.y + 0.5, 0.5)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	t.tween_callback(func() -> void: label.queue_free())


func _clear_unit_views() -> void:
	for unit_id in _unit_views.keys():
		var view: Unit3D = _unit_views[unit_id]
		if view != null:
			view.queue_free()
	_unit_views.clear()


func _shake_camera(amount: float) -> void:
	_shake = maxf(_shake, amount)


# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	var vp := get_viewport().get_visible_rect().size
	var vw := vp.x
	var vh := vp.y
	_font_title = SystemFont.new()
	_font_title.font_names = PackedStringArray(["Songti SC", "Noto Serif SC", "STSong", "PingFang SC"])
	_font_body = SystemFont.new()
	_font_body.font_names = PackedStringArray(["Songti SC", "Noto Serif SC", "PingFang SC"])
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	hud_root = Control.new()
	hud_root.size = Vector2(vw, vh)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_root)

	_title_panel = _panel(Vector2(24, 20), Vector2(330, 92))
	_lbl_title = _label(_title_panel, "折叠地牢", Vector2(16, 8), 30, COL_TEXT, _font_title)
	var rule := ColorRect.new()
	rule.color = Color(0.72, 0.56, 0.28, 0.75)
	rule.position = Vector2(18, 42)
	rule.size = Vector2(52, 2)
	_title_panel.add_child(rule)
	_lbl_floor = _label(_title_panel, "", Vector2(18, 46), 14, COL_MUTED, _font_body)
	_lbl_phase = _label(_title_panel, "", Vector2(18, 66), 15, COL_GOLD, _font_body)

	_stats_panel = _panel(Vector2(vw - 24 - 380, 20), Vector2(380, 64))
	_lbl_stats = _label(_stats_panel, "", Vector2(16, 8), 16, COL_TEXT, _font_body)
	_lbl_hp = _label(_stats_panel, "", Vector2(16, 34), 16, COL_GOLD, _font_body)

	_right_panel = _panel(Vector2(vw - 24 - 260, 100), Vector2(260, 240))
	_label(_right_panel, "单位", Vector2(16, 10), 19, COL_GOLD, _font_title)
	_lbl_units = _label(_right_panel, "", Vector2(16, 46), 14, COL_TEXT, _font_body)
	_lbl_units.size = Vector2(228, 100)
	var div := ColorRect.new()
	div.color = Color(0.5, 0.4, 0.24, 0.55)
	div.position = Vector2(16, 148)
	div.size = Vector2(228, 1)
	_right_panel.add_child(div)
	_lbl_intent = _label(_right_panel, "", Vector2(16, 158), 13, COL_TEXT, _font_body)
	_lbl_intent.size = Vector2(228, 70)

	_channels_panel = _panel(Vector2(24, vh - 24 - 54 - 12 - 178), Vector2(320, 178))
	_label(_channels_panel, "环境通道", Vector2(14, 8), 18, COL_GOLD, _font_title)
	for i in Channels.COUNT:
		var row_y := 40 + i * 26
		var name_label := _label(_channels_panel, "", Vector2(14, row_y), 13, Room3D.CHANNEL_COLORS.get(i, COL_MUTED), _font_body)
		_channel_labels.append(name_label)
		var bg := ColorRect.new()
		bg.color = Color(0.10, 0.10, 0.12, 0.9)
		bg.position = Vector2(110, row_y + 4)
		bg.size = Vector2(140, 9)
		_channels_panel.add_child(bg)
		var fill := ColorRect.new()
		fill.color = Color.WHITE
		fill.position = Vector2(111, row_y + 5)
		fill.size = Vector2(0, 7)
		_channels_panel.add_child(fill)
		_channel_bars.append(fill)

	_bottom_panel = _panel(Vector2(24, vh - 24 - 54), Vector2(vw - 48, 54))
	_label(_bottom_panel, "WASD 移动   ·   SPACE 攻击   ·   ENTER 结束回合/建造   ·   R 旋转   ·   TAB 地图   ·   1/2/3 选择", Vector2(14, 10), 15, COL_TEXT, _font_body)
	_lbl_status = _label(_bottom_panel, "", Vector2(14, 32), 12, COL_MUTED, _font_body)

	_build_panel = _panel(Vector2(24, vh - 24 - 54 - 12 - 200), Vector2(340, 200))
	_label(_build_panel, "蓝图", Vector2(14, 8), 19, COL_GOLD, _font_title)
	for i in 3:
		var b := Button.new()
		b.position = Vector2(14, 40 + i * 44)
		b.size = Vector2(310, 38)
		_style_button(b)
		b.pressed.connect(_on_offer_pressed.bind(i))
		_build_panel.add_child(b)
		_offer_buttons.append(b)
	_label(_build_panel, "1/2/3 选择 · 鼠标点地图格 · R 旋转 · Enter 建造", Vector2(14, 172), 12, COL_MUTED, _font_body)

	_choice_panel = _panel(Vector2(24, vh - 24 - 54 - 12 - 180), Vector2(340, 180))
	for i in 3:
		var b := Button.new()
		b.position = Vector2(14, 14 + i * 48)
		b.size = Vector2(310, 42)
		_style_button(b)
		b.pressed.connect(_on_choice_pressed.bind(i))
		_choice_panel.add_child(b)
		_choice_buttons.append(b)

	_settle_panel = _panel(Vector2(vw * 0.5 - 220, vh * 0.5 - 130), Vector2(440, 260))
	_settle_label = _label(_settle_panel, "", Vector2(20, 24), 30, COL_GOLD, _font_title)
	_settle_label.size = Vector2(400, 120)
	_settle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_restart_button = Button.new()
	_restart_button.text = "R · 重新开始"
	_restart_button.position = Vector2(20, 180)
	_restart_button.size = Vector2(400, 44)
	_style_button(_restart_button)
	_restart_button.pressed.connect(_restart)
	_settle_panel.add_child(_restart_button)

	_map_panel = _panel(Vector2(24, 100), Vector2(260, 292))
	_label(_map_panel, "地牢地图 (TAB)", Vector2(14, 8), 16, COL_GOLD, _font_title)
	for y in DungeonGrid.SIZE_Y:
		for x in DungeonGrid.SIZE_X:
			var b := Button.new()
			b.position = Vector2(14 + x * 45, 40 + y * 45)
			b.size = Vector2(42, 42)
			b.flat = true
			b.pressed.connect(_on_map_cell_pressed.bind(Vector2i(x, y)))
			_map_panel.add_child(b)
			_map_cells.append(b)
	_map_panel.visible = false

	_apply_phase_visibility()


func _panel(pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.019, 0.024, 0.42)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.55, 0.45, 0.25, 0.9)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 8
	p.add_theme_stylebox_override("panel", sb)
	hud_root.add_child(p)
	var leather := _tex("res://assets/art3d/materials/leather.png")
	if leather != null:
		var inner := Panel.new()
		inner.position = Vector2(2, 2)
		inner.size = size - Vector2(4, 4)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st := StyleBoxTexture.new()
		st.texture = leather
		st.modulate_color = Color(0.30, 0.25, 0.21, 0.58)
		inner.add_theme_stylebox_override("panel", st)
		p.add_child(inner)
	_ornament(p, size)
	return p


func _ornament(p: Panel, size: Vector2) -> void:
	var gold := Color(0.72, 0.56, 0.28, 0.85)
	for corner in 4:
		var cx := 4.0 if corner in [0, 2] else size.x - 18.0
		var cy := 4.0 if corner in [0, 1] else size.y - 4.0
		var h := ColorRect.new()
		h.color = gold
		h.position = Vector2(cx, cy)
		h.size = Vector2(14, 2)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(h)
		var v := ColorRect.new()
		v.color = gold
		v.position = Vector2(cx, cy)
		v.size = Vector2(2, 14)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(v)


func _label(parent: Control, text: String, pos: Vector2, font_size: int, color: Color, font: Font) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _style_button(b: Button) -> void:
	b.add_theme_font_override("font", _font_body)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", COL_TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.08, 0.92)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.50, 0.40, 0.22, 0.9)
	b.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.15, 0.11, 0.95)
	hover.border_color = Color(0.85, 0.70, 0.42, 1.0)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)


func _tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _update_camera_focus() -> void:
	var center := Vector3(ROOM_UNITS * 0.5, 1.15, ROOM_UNITS * 0.5)
	var focus := center
	if run != null and run.session != null and run.session.player != null:
		var p := run.session.player.local_cell
		var pv := Vector3(p.x + 0.5, 1.15, p.y + 0.5)
		var d := pv - center
		d.x = clampf(d.x, -3.6, 3.6)
		d.z = clampf(d.z, -3.6, 3.6)
		focus = center + d * 0.7
	_cam_focus = focus


func _sync_hud() -> void:
	if run == null:
		return
	var vp := get_viewport().get_visible_rect().size
	_lbl_floor.text = "楼层 %d/%d" % [run.state.floor, run.state.total_floors]
	if run.phase == RunController.Phase.ENCOUNTER and run.combat != null and run.combat.state != null:
		_lbl_floor.text += " · 回合 %d" % run.combat.state.round
	_lbl_phase.text = _phase_name()
	_lbl_stats.text = "金币 %d      构筑点 %d" % [run.state.gold, run.state.build_points]
	var hp := 0
	var max_hp := 0
	if run.session != null and run.session.player != null:
		hp = run.session.player.hp
		max_hp = run.session.player.max_hp
	_lbl_hp.text = "生命 %d/%d" % [hp, max_hp]
	# units
	var lines: Array[String] = []
	var p := run.session.player
	if p != null:
		lines.append("● 玩家      %d / %d" % [p.hp, p.max_hp])
	if run.combat != null and run.combat.state != null:
		for e in run.combat.state.living_enemies():
			lines.append("● %s   %d / %d" % [e.display_name, e.hp, e.max_hp])
	_lbl_units.text = "\n".join(lines)
	# channels
	var state: RoomState = null
	if run.session != null and run.session.current_room() != null:
		state = run.engine.room_state(run.session.current_room().cell)
	for i in Channels.COUNT:
		var value := 0
		if state != null:
			value = state.get_channel(i)
		var col: Color = Room3D.CHANNEL_COLORS.get(i, Color.WHITE)
		_colorset(_channel_bars, i, col, float(value) / float(Channels.MAX_VALUE))
		(_channel_labels[i] as Label).text = "%s %d" % [Channels.name_of(i), value]
	# intent
	if run.phase == RunController.Phase.ENCOUNTER and run.combat != null and run.combat.state != null:
		_lbl_intent.text = "玩家回合 · 剩余移动 %d\n敌人意图：靠近 / 攻击" % run.session.player.move_points
	elif run.phase == RunController.Phase.BUILD:
		_lbl_intent.text = "选择蓝图并放置房间\n门位需与相邻房间对齐"
	else:
		_lbl_intent.text = "目标：清空本层 7 个槽位"
	_apply_phase_visibility()
	_sync_map()


func _colorset(bars: Array[ColorRect], index: int, color: Color, ratio: float) -> void:
	if index < 0 or index >= bars.size():
		return
	var bar := bars[index]
	bar.color = color
	bar.size.x = clampf(ratio, 0.0, 1.0) * 138.0


func _sync_map() -> void:
	if run == null:
		return
	var current := Vector2i(-1, -1)
	if run.session != null:
		current = run.session.current_room_cell()
	for y in DungeonGrid.SIZE_Y:
		for x in DungeonGrid.SIZE_X:
			var idx := y * DungeonGrid.SIZE_X + x
			if idx >= _map_cells.size():
				continue
			var b := _map_cells[idx]
			var cell := Vector2i(x, y)
			var has_room: bool = run.session.grid.get_room(cell) != null
			var col := Color(0.10, 0.10, 0.13, 0.85)
			if has_room:
				col = Color(0.24, 0.22, 0.18, 0.95)
			if cell == current:
				col = Color(0.35, 0.50, 0.70, 0.95)
			if cell == preview_cell and run.phase == RunController.Phase.BUILD:
				col = Color(0.30, 0.60, 0.35, 0.95) if _preview_valid() else Color(0.65, 0.28, 0.25, 0.95)
			var sb := StyleBoxFlat.new()
			sb.bg_color = col
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.45, 0.38, 0.24, 0.8)
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", sb)
			b.add_theme_stylebox_override("pressed", sb)


func _apply_phase_visibility() -> void:
	if run == null:
		return
	_build_panel.visible = run.phase == RunController.Phase.BUILD
	_choice_panel.visible = run.phase in [RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP]
	_settle_panel.visible = run.phase == RunController.Phase.SETTLED
	if _channels_panel != null:
		_channels_panel.visible = run.phase == RunController.Phase.ENCOUNTER
	if run.phase == RunController.Phase.BUILD:
		for i in _offer_buttons.size():
			var b := _offer_buttons[i]
			if i < run.current_offer.size():
				var def := run.current_offer[i]
				b.visible = true
				b.text = "%d. %s  (%d BP)" % [i + 1, def.display_name, def.build_cost]
			else:
				b.visible = false
	elif run.phase == RunController.Phase.EVENT:
		_choice_buttons[0].text = "1. 治疗 +5"
		_choice_buttons[1].text = "2. 金币 +25"
		_choice_buttons[2].text = "3. 构筑点 +2"
		for b in _choice_buttons:
			b.visible = true
	elif run.phase == RunController.Phase.REST:
		_choice_buttons[0].text = "1. 休息（治疗 +6）"
		_choice_buttons[1].visible = false
		_choice_buttons[2].visible = false
	elif run.phase == RunController.Phase.SHOP:
		_choice_buttons[0].text = "1. 免费治疗 +10"
		_choice_buttons[1].text = "2. 花 20 金币买 3 BP"
		_choice_buttons[2].text = "3. 离开商店"
		for b in _choice_buttons:
			b.visible = true
	elif run.phase == RunController.Phase.SETTLED:
		_settle_label.text = "单局结束\n楼层 %d · 金币 %d" % [run.state.floor, run.state.gold]
	_map_panel.visible = _map_visible


func _phase_name() -> String:
	match run.phase:
		RunController.Phase.BUILD: return "构筑"
		RunController.Phase.EXPLORE: return "探索"
		RunController.Phase.ENCOUNTER: return "战斗"
		RunController.Phase.EVENT: return "事件"
		RunController.Phase.REST: return "休整"
		RunController.Phase.SHOP: return "商店"
		RunController.Phase.SETTLED: return "结算"
	return "未知"


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if run != null and run.phase == RunController.Phase.BUILD:
			var cell := _cell_from_screen(event.position)
			if cell.x >= 0:
				preview_cell = cell
				_sync()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var keycode: int = event.keycode
	if keycode == KEY_TAB:
		_map_visible = not _map_visible
		apply_map_visibility()
		return
	if run.phase == RunController.Phase.SETTLED:
		if keycode == KEY_R:
			_restart()
		return
	if run.phase == RunController.Phase.BUILD:
		match keycode:
			KEY_1, KEY_2, KEY_3:
				_on_offer_pressed(keycode - KEY_1)
			KEY_R:
				preview_orientation = (preview_orientation + 1) % 4
				_sync()
			KEY_ENTER, KEY_KP_ENTER:
				_try_build()
		return
	if run.phase == RunController.Phase.EXPLORE:
		var dir := _key_dir(keycode)
		if dir != 0:
			_explore_move(dir)
		return
	if run.phase == RunController.Phase.ENCOUNTER:
		match keycode:
			KEY_W, KEY_UP: _combat_move(DoorSpec.Dir.N)
			KEY_D, KEY_RIGHT: _combat_move(DoorSpec.Dir.E)
			KEY_S, KEY_DOWN: _combat_move(DoorSpec.Dir.S)
			KEY_A, KEY_LEFT: _combat_move(DoorSpec.Dir.W)
			KEY_SPACE: _combat_attack()
			KEY_ENTER, KEY_KP_ENTER:
				run.combat.end_player_turn()
				run.sync_combat_result()
				_sync()
		return
	if run.phase in [RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP]:
		match keycode:
			KEY_1: _on_choice_pressed(0)
			KEY_2: _on_choice_pressed(1)
			KEY_3: _on_choice_pressed(2)


func apply_map_visibility() -> void:
	if _map_panel != null:
		_map_panel.visible = _map_visible


func _cell_from_screen(screen: Vector2) -> Vector2i:
	if camera == null:
		return Vector2i(-1, -1)
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return Vector2i(-1, -1)
	var t := -from.y / dir.y
	if t < 0:
		return Vector2i(-1, -1)
	var hit := from + dir * t
	var cell := Vector2i(floori(hit.x), floori(hit.z))
	if cell.x < 0 or cell.y < 0 or cell.x >= ROOM_UNITS or cell.y >= ROOM_UNITS:
		return Vector2i(-1, -1)
	return cell


func _key_dir(keycode: int) -> int:
	match keycode:
		KEY_W, KEY_UP: return DoorSpec.Dir.N
		KEY_D, KEY_RIGHT: return DoorSpec.Dir.E
		KEY_S, KEY_DOWN: return DoorSpec.Dir.S
		KEY_A, KEY_LEFT: return DoorSpec.Dir.W
	return 0


func _on_offer_pressed(index: int) -> void:
	if run == null or run.phase != RunController.Phase.BUILD:
		return
	if index < 0 or index >= run.current_offer.size():
		return
	selected_offer = index
	preview_orientation = 0
	_default_preview()
	_sync()


func _on_choice_pressed(choice: int) -> void:
	if run == null:
		return
	if run.resolve_choice(choice):
		_sync()


func _on_map_cell_pressed(cell: Vector2i) -> void:
	if run == null or run.phase != RunController.Phase.BUILD:
		return
	preview_cell = cell
	_sync()


func _try_build() -> void:
	if run == null or run.phase != RunController.Phase.BUILD or selected_offer < 0:
		return
	if preview_cell.x < 0:
		_lbl_status.text = "请先在 3D 房间或地图上选择放置格"
		return
	var report := run.build_and_place(selected_offer, preview_cell, preview_orientation)
	if report.is_valid():
		_lbl_status.text = "建造成功：穿过门进入新房间"
		selected_offer = 0 if not run.current_offer.is_empty() else -1
		preview_orientation = 0
		_default_preview()
		_sync()
	else:
		_lbl_status.text = "建造失败：%s" % report.summary()
		_sync()


func _explore_move(dir: int) -> void:
	var from_room := run.session.current_room_cell()
	var result := run.session.try_move(dir)
	if not result["ok"]:
		_lbl_status.text = "移动失败：%s" % str(result["reason"])
		return
	run.engine.tick()
	if run.session.current_room_cell() != from_room:
		run.on_room_entered(run.session.current_room_cell())
		_room_key = ""
	_sync()


func _combat_move(dir: int) -> void:
	run.combat.player_move(dir)
	_sync()


func _combat_attack() -> void:
	var player := run.combat.state.player_unit()
	if player == null:
		return
	for enemy in run.combat.state.living_enemies():
		if run.combat.state.distance(player, enemy) <= player.attack_range:
			run.combat.player_attack(enemy.unit_id)
			run.sync_combat_result()
			_sync()
			return
	_lbl_status.text = "没有相邻怪物可攻击"


func _restart() -> void:
	_start_run(RUN_SEED)
