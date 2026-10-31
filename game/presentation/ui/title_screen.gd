extends Control
## M6-4: main title screen with the D key art, dark-leather menu and fade-in.

const RUN_SCENE := "res://presentation/run_mode/run_mode_3d.tscn"

var _menu: VBoxContainer
var _help_panel: PanelContainer
var _settings_panel: PanelContainer
var _settings_sliders: Array[HSlider] = []
var _font: Font


func _ready() -> void:
	AudioManager.stop_ambient()
	AudioManager.play_music(&"music_title")
	theme = DarkUI.theme()
	_font = DarkUI.font()
	_build()
	_fade_in()


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load(DarkUI.TITLE_ART)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.014, 0.018, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var bottom := TextureRect.new()
	bottom.texture = _bottom_gradient()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 84)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 64)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	margin.add_child(row)

	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.custom_minimum_size = Vector2(560, 0)
	left.add_theme_constant_override("separation", 6)
	row.add_child(left)

	var kicker := _label("ROGUELIKE · TACTICAL · SPATIAL BUILDING", 14, DarkUI.GOLD)
	kicker.uppercase = true
	left.add_child(kicker)

	var title := _label("折叠地牢", 82, DarkUI.TEXT)
	left.add_child(title)

	var rule := ColorRect.new()
	rule.color = DarkUI.GOLD
	rule.custom_minimum_size = Vector2(88, 3)
	left.add_child(rule)

	var sub := _label("FOLDED DUNGEON", 20, DarkUI.MUTED)
	left.add_child(sub)

	var tagline := _label("折起房间，让规则互相点燃。", 19, DarkUI.TEXT)
	left.add_child(tagline)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	left.add_child(spacer)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 12)
	left.add_child(_menu)
	var primary := true
	for item in [
		["开始新的一局", _on_start],
		["操作说明", _toggle_help],
		["音频设置", _toggle_settings],
		["退出", _on_quit],
	]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(340, 56)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(item[1])
		b.pressed.connect(func() -> void: AudioManager.play_sfx(&"ui_click"))
		if primary:
			var n := DarkUI.button_style(false)
			n.bg_color = Color(0.24, 0.18, 0.10, 0.98)
			n.border_color = DarkUI.GOLD
			var h := DarkUI.button_style(true)
			h.bg_color = Color(0.32, 0.24, 0.13, 1.0)
			h.border_color = DarkUI.GOLD
			b.add_theme_stylebox_override("normal", n)
			b.add_theme_stylebox_override("hover", h)
			b.add_theme_stylebox_override("pressed", h)
			b.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
			primary = false
		_menu.add_child(b)
	if _menu.get_child_count() > 0:
		(_menu.get_child(0) as Button).grab_focus()

	var credits := _label("v0.6 · M6 2.5D 视觉升级中", 14, DarkUI.MUTED)
	credits.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	credits.position = Vector2(size.x - 330, size.y - 40)
	add_child(credits)

	_help_panel = PanelContainer.new()
	_help_panel.visible = false
	_help_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_help_panel.custom_minimum_size = Vector2(560, 320)
	_help_panel.position = Vector2(size.x * 0.5 - 280, size.y * 0.5 - 160)
	add_child(_help_panel)
	var help := VBoxContainer.new()
	help.add_theme_constant_override("separation", 10)
	_help_panel.add_child(help)
	help.add_child(_label("操作说明", 26, DarkUI.GOLD))
	help.add_child(_label("构筑：1/2/3 选蓝图 · 鼠标点 3D 地牢格 · R 旋转 · Enter 建造", 16, DarkUI.TEXT))
	help.add_child(_label("探索：WASD / 方向键移动，穿过门进入相邻房间", 16, DarkUI.TEXT))
	help.add_child(_label("战斗：WASD 移动 · Space 攻击 · Enter 结束回合", 16, DarkUI.TEXT))
	help.add_child(_label("通用：Tab 地牢地图 · F3 调试面板 · Esc 返回标题", 16, DarkUI.TEXT))
	var close := Button.new()
	close.text = "返回"
	close.custom_minimum_size = Vector2(160, 44)
	close.pressed.connect(_toggle_help)
	close.pressed.connect(func() -> void: AudioManager.play_sfx(&"ui_click"))
	help.add_child(close)

	_settings_panel = PanelContainer.new()
	_settings_panel.visible = false
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_settings_panel.custom_minimum_size = Vector2(520, 360)
	_settings_panel.position = Vector2(size.x * 0.5 - 260, size.y * 0.5 - 180)
	add_child(_settings_panel)
	var settings := VBoxContainer.new()
	settings.add_theme_constant_override("separation", 12)
	_settings_panel.add_child(settings)
	settings.add_child(_label("音频设置", 26, DarkUI.GOLD))
	_settings_sliders.clear()
	for bus_name in ["Master", "Music", "SFX"]:
		var srow := HBoxContainer.new()
		srow.add_theme_constant_override("separation", 12)
		settings.add_child(srow)
		var name_label := _label({"Master": "总音量", "Music": "音乐/环境", "SFX": "音效"}.get(bus_name, bus_name), 16, DarkUI.TEXT)
		name_label.custom_minimum_size = Vector2(150, 0)
		srow.add_child(name_label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = AudioManager.get_bus_volume(bus_name)
		slider.custom_minimum_size = Vector2(240, 28)
		srow.add_child(slider)
		var value_label := _label("%d%%" % int(slider.value * 100.0), 15, DarkUI.MUTED)
		value_label.custom_minimum_size = Vector2(60, 0)
		srow.add_child(value_label)
		slider.value_changed.connect(_on_volume_changed.bind(bus_name, value_label))
		_settings_sliders.append(slider)
	var mute := CheckBox.new()
	mute.text = "静音"
	mute.button_pressed = AudioManager.is_muted()
	mute.add_theme_font_override("font", _font)
	mute.add_theme_font_size_override("font_size", 16)
	mute.toggled.connect(_on_mute_toggled)
	settings.add_child(mute)
	var sclose := Button.new()
	sclose.text = "返回"
	sclose.custom_minimum_size = Vector2(160, 44)
	sclose.pressed.connect(_toggle_settings)
	sclose.pressed.connect(func() -> void: AudioManager.play_sfx(&"ui_click"))
	settings.add_child(sclose)


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _bottom_gradient() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0.01, 0.01, 0.015, 0.0))
	g.set_color(1, Color(0.01, 0.01, 0.015, 0.92))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 8
	gt.height = 256
	return gt


func _fade_in() -> void:
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.45)


func _toggle_help() -> void:
	_help_panel.visible = not _help_panel.visible
	if _help_panel.visible:
		_settings_panel.visible = false


func _toggle_settings() -> void:
	_settings_panel.visible = not _settings_panel.visible
	if _settings_panel.visible:
		_help_panel.visible = false


func _on_volume_changed(value: float, bus_name: String, value_label: Label) -> void:
	AudioManager.set_bus_volume(bus_name, value)
	value_label.text = "%d%%" % int(value * 100.0)


func _on_mute_toggled(pressed: bool) -> void:
	AudioManager.set_muted(pressed)


func _on_start() -> void:
	AudioManager.stop_music()
	get_tree().change_scene_to_file(RUN_SCENE)


func _on_quit() -> void:
	get_tree().quit()


func menu_buttons() -> Array[Button]:
	var out: Array[Button] = []
	if _menu != null:
		for child in _menu.get_children():
			if child is Button:
				out.append(child as Button)
	return out


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_on_start()
		KEY_ESCAPE:
			if _settings_panel.visible:
				_toggle_settings()
			elif _help_panel.visible:
				_toggle_help()
			else:
				_on_quit()
		KEY_I:
			_toggle_help()
		KEY_O:
			_toggle_settings()
