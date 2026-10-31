class_name Unit3D
extends Node3D
## Billboard unit view (2.5D): AI-painted sprite + contact shadow + HP bar.
## Reads Unit state; never mutates it.

const UNIT_DIR := "res://assets/art3d/units/"
const MAT_DIR := "res://assets/art3d/materials/"

var unit: Unit = null
var is_player := false
var body_height := 1.6

var _sprite: Sprite3D = null
var _idle_texture: Texture2D = null
var _attack_texture: Texture2D = null
var _shadow: MeshInstance3D = null
var _hp_bg: MeshInstance3D = null
var _hp_fill: MeshInstance3D = null
var _rune: MeshInstance3D = null
var _hit_tween: Tween = null
var _move_tween: Tween = null
var _last_hp := -1


func setup(unit_ref: Unit, player_unit: bool) -> void:
	unit = unit_ref
	is_player = player_unit
	var tex_path := _pick_texture()
	var tex := _load_tex(tex_path)
	if tex == null:
		return
	_idle_texture = tex
	_attack_texture = _load_tex(tex_path.replace(".png", "-attack.png"))
	body_height = _pick_height()
	# contact shadow (flat on the floor, NOT billboarded)
	_shadow = _ground_shadow(Vector2(1.15, 1.15))
	_shadow.position = Vector3(0, 0.035, 0)
	add_child(_shadow)
	# sprite
	_sprite = Sprite3D.new()
	_sprite.texture = tex
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.pixel_size = body_height / float(tex.get_height())
	_sprite.modulate = Color(0.97, 0.92, 0.85, 1.0)
	_sprite.position = Vector3(0, body_height * 0.5, 0)
	_sprite.render_priority = 2
	add_child(_sprite)
	# hp bar
	_hp_bg = _flat_quad("", Vector2(0.9, 0.10), Color(0.06, 0.05, 0.05, 0.9))
	_hp_bg.position = Vector3(0, body_height + 0.28, 0)
	add_child(_hp_bg)
	_hp_fill = _flat_quad("", Vector2(0.86, 0.07), Color(0.85, 0.22, 0.18, 1.0))
	_hp_fill.position = Vector3(-0.43, body_height + 0.28, 0.005)
	add_child(_hp_fill)
	if is_player:
		_rune = _rune_ring()
		_rune.position = Vector3(0, 0.03, 0)
		add_child(_rune)
	_update_hp()


func _pick_texture() -> String:
	if is_player:
		return UNIT_DIR + "player-knight.png"
	var label := unit.display_name if unit != null else ""
	if label.contains("Boss"):
		return UNIT_DIR + "monster-demon.png"
	var n := 0
	for ch in label:
		if ch.is_valid_int():
			n = n * 10 + int(ch)
	if n > 0:
		return UNIT_DIR + ("monster-demon.png" if n % 2 == 1 else "monster-skeleton.png")
	return UNIT_DIR + "monster-skeleton.png"


func _pick_height() -> float:
	if is_player:
		return 1.9
	var label := unit.display_name if unit != null else ""
	if label.contains("Boss"):
		return 2.5
	return 1.55 if label.contains("1") or label.contains("3") else 1.45


func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _ground_shadow(size: Vector2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	var tex := _load_tex(MAT_DIR + "shadow-blob.png")
	if tex != null:
		mat.albedo_texture = tex
	mat.albedo_color = Color(1, 1, 1, 0.8)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi


func _flat_quad(texture_path: String, size: Vector2, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	var mat := StandardMaterial3D.new()
	if texture_path != "":
		var tex := _load_tex(texture_path)
		if tex != null:
			mat.albedo_texture = tex
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi


func _rune_ring() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.48
	torus.rings = 32
	torus.ring_segments = 8
	mi.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.45, 0.75, 1.0, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.65, 1.0)
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	return mi


func cell_position(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)


func place_at(cell: Vector2i, animate: bool = false) -> void:
	var target := cell_position(cell)
	if animate and is_inside_tree():
		if _move_tween != null:
			_move_tween.kill()
		_move_tween = create_tween()
		_move_tween.tween_property(self, "position", target, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		position = target


func update_from_unit(unit_ref: Unit) -> void:
	unit = unit_ref
	if unit == null:
		return
	if _last_hp >= 0 and unit.hp < _last_hp:
		flash_hit()
	_last_hp = unit.hp
	_update_hp()
	if not unit.alive and _sprite != null:
		_die_visual()


func _update_hp() -> void:
	if unit == null or _hp_fill == null:
		return
	var ratio := clampf(float(unit.hp) / float(maxi(1, unit.max_hp)), 0.0, 1.0)
	_hp_fill.scale = Vector3(maxf(ratio, 0.001), 1.0, 1.0)
	_hp_fill.position.x = -0.43 + 0.43 * ratio
	if ratio > 0.5:
		(_hp_fill.material_override as StandardMaterial3D).albedo_color = Color(0.45, 0.78, 0.30, 1.0)
	elif ratio > 0.25:
		(_hp_fill.material_override as StandardMaterial3D).albedo_color = Color(0.85, 0.65, 0.18, 1.0)
	else:
		(_hp_fill.material_override as StandardMaterial3D).albedo_color = Color(0.85, 0.22, 0.18, 1.0)


func flash_hit() -> void:
	if _sprite == null:
		return
	if _hit_tween != null:
		_hit_tween.kill()
	_sprite.modulate = Color(1.6, 0.55, 0.45, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(_sprite, "modulate", Color(0.97, 0.92, 0.85, 1.0), 0.18)


func play_attack() -> void:
	if _sprite == null:
		return
	var had_attack := _attack_texture != null
	if had_attack:
		_sprite.texture = _attack_texture
		var base_tex := _idle_texture
		get_tree().create_timer(0.22).timeout.connect(func() -> void:
			if _sprite != null:
				_sprite.texture = base_tex)
	var base := _sprite.position
	var t := create_tween()
	t.tween_property(_sprite, "position", base + Vector3(0, 0.12, 0.35), 0.06)
	t.tween_property(_sprite, "position", base, 0.10)
	t.parallel().tween_property(_sprite, "scale", Vector3(1.04, 0.96, 1.0), 0.06)
	t.tween_property(_sprite, "scale", Vector3.ONE, 0.08)


func _die_visual() -> void:
	var t := create_tween()
	t.tween_property(_sprite, "modulate:a", 0.0, 0.35)
	if _hp_bg != null:
		t.parallel().tween_property(_hp_bg, "modulate:a", 0.0, 0.25)
	if _hp_fill != null:
		t.parallel().tween_property(_hp_fill, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: visible = false)
