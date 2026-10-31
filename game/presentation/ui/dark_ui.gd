class_name DarkUI
extends RefCounted
## M6-4: shared dark-leather UI helpers (fonts, styleboxes, palette).

const FONT_PATH := "res://assets/art3d/fonts/NotoSerifSC-Subset.ttf"
const LEATHER_PATH := "res://assets/art3d/materials/leather.png"
const TITLE_ART := "res://assets/art3d/ui/title-keyart.jpg"
const THEME_PATH := "res://presentation/ui/dark_theme.tres"

const GOLD := Color(0.82, 0.67, 0.38)
const GOLD_DIM := Color(0.55, 0.45, 0.25)
const TEXT := Color(0.90, 0.86, 0.76)
const MUTED := Color(0.62, 0.57, 0.47)
const DANGER := Color(0.85, 0.42, 0.35)
const SAFE := Color(0.55, 0.82, 0.45)


static func font() -> Font:
	var f: Font = load(FONT_PATH) if ResourceLoader.exists(FONT_PATH) else null
	if f == null:
		var fallback := SystemFont.new()
		fallback.font_names = PackedStringArray(["Songti SC", "Noto Serif SC", "PingFang SC"])
		return fallback
	return f


static func theme() -> Theme:
	if ResourceLoader.exists(THEME_PATH):
		return load(THEME_PATH) as Theme
	return null


static func leather_texture() -> Texture2D:
	if ResourceLoader.exists(LEATHER_PATH):
		return load(LEATHER_PATH) as Texture2D
	return null


static func flat(color: Color, border: Color = GOLD_DIM, width: int = 1, radius: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_width_left = width
	sb.border_width_top = width
	sb.border_width_right = width
	sb.border_width_bottom = width
	sb.border_color = border
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	return sb


static func panel_style(alpha: float = 0.55) -> StyleBoxFlat:
	var sb := flat(Color(0.02, 0.019, 0.024, alpha), GOLD_DIM, 2)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 8
	return sb


static func leather_style(alpha: float = 0.60) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = leather_texture()
	sb.modulate_color = Color(0.30, 0.25, 0.21, alpha)
	sb.texture_margin_left = 4
	sb.texture_margin_top = 4
	sb.texture_margin_right = 4
	sb.texture_margin_bottom = 4
	return sb


static func button_style(hover: bool = false) -> StyleBoxFlat:
	var sb := flat(
		Color(0.18, 0.15, 0.11, 0.95) if hover else Color(0.10, 0.09, 0.08, 0.92),
		GOLD if hover else GOLD_DIM, 1)
	return sb


static func key_hint(text: String) -> String:
	return text
