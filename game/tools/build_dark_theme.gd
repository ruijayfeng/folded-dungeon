extends SceneTree
## M6-4: generates res://presentation/ui/dark_theme.tres from DarkUI helpers.
## Run headless: godot --headless --path game --script res://tools/build_dark_theme.gd

func _initialize() -> void:
	var theme := Theme.new()
	var font: Font = DarkUI.font()
	theme.default_font = font
	theme.default_font_size = 16

	theme.set_stylebox("panel", "Panel", DarkUI.panel_style(0.55))
	theme.set_stylebox("panel", "PanelContainer", DarkUI.panel_style(0.55))
	theme.set_font("font", "Label", font)
	theme.set_font_size("font_size", "Label", 16)
	theme.set_color("font_color", "Label", DarkUI.TEXT)

	theme.set_font("font", "Button", font)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_color("font_color", "Button", DarkUI.TEXT)
	theme.set_color("font_hover_color", "Button", DarkUI.GOLD)
	theme.set_color("font_pressed_color", "Button", DarkUI.GOLD)
	theme.set_stylebox("normal", "Button", DarkUI.button_style(false))
	theme.set_stylebox("hover", "Button", DarkUI.button_style(true))
	theme.set_stylebox("pressed", "Button", DarkUI.button_style(true))
	var focus := DarkUI.button_style(true)
	focus.border_color = DarkUI.GOLD
	theme.set_stylebox("focus", "Button", focus)

	theme.set_stylebox("normal", "LineEdit", DarkUI.flat(Color(0.08, 0.07, 0.06, 0.9), DarkUI.GOLD_DIM, 1))
	theme.set_stylebox("read_only", "LineEdit", DarkUI.flat(Color(0.04, 0.04, 0.05, 0.6), DarkUI.GOLD_DIM, 1))

	var err := ResourceSaver.save(theme, "res://presentation/ui/dark_theme.tres")
	print("SAVED theme err=", err)
	quit()
