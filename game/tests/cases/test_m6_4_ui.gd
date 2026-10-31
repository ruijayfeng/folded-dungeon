extends TestCase
## M6-4: title screen, bundled font and dark theme load headlessly.


func test_font_and_theme_exist() -> void:
	assert_true(FileAccess.file_exists("res://assets/art3d/fonts/NotoSerifSC-Subset.ttf"), "subset font exists")
	assert_true(FileAccess.file_exists("res://assets/art3d/fonts/OFL.txt"), "OFL license exists")
	assert_true(FileAccess.file_exists("res://presentation/ui/dark_theme.tres"), "dark theme exists")


func test_theme_loads_and_has_font() -> void:
	var theme: Theme = DarkUI.theme()
	assert_true(theme != null, "theme loads")
	if theme == null:
		return
	assert_true(theme.default_font != null, "theme has default font")
	var font := DarkUI.font()
	assert_true(font != null, "ui font loads")
	if font != null:
		assert_true(font.get_string_size("折叠地牢").x > 0.0, "font has CJK glyphs")


func test_title_scene_instantiates() -> void:
	var packed := load("res://presentation/ui/title_screen.tscn") as PackedScene
	assert_true(packed != null, "title scene loads")
	if packed == null:
		return
	var instance: Control = packed.instantiate()
	assert_true(instance != null, "title scene instantiates")
	instance.call("_ready")
	var buttons := instance.call("menu_buttons") as Array
	assert_true(buttons.size() >= 3, "title has at least 3 menu buttons")
	for b in buttons:
		var btn := b as Button
		assert_true(btn.custom_minimum_size.x > 0.0 and btn.custom_minimum_size.y > 0.0, "menu button has min size")
	instance.free()


func test_title_art_exists() -> void:
	assert_true(FileAccess.file_exists("res://assets/art3d/ui/title-keyart.jpg"), "title key art exists")
