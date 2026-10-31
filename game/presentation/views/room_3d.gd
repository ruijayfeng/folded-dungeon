class_name Room3D
extends Node3D
## 2.5D dungeon room built from pure RoomLayout data (M6-1).
## Presentation only: reads RoomInstance/RoomDef; never mutates simulation.

const ROOM := 9
const WALL_H := 2.2
const MAT_DIR := "res://assets/art3d/materials/"

const CHANNEL_COLORS := {
	Channels.Channel.HEAT: Color(1.0, 0.46, 0.20),
	Channels.Channel.TOXIN: Color(0.48, 0.92, 0.35),
	Channels.Channel.COLD: Color(0.45, 0.76, 1.0),
	Channels.Channel.CHARGE: Color(1.0, 0.86, 0.35),
	Channels.Channel.AIRFLOW: Color(0.82, 0.84, 0.95),
}

var current_room: RoomInstance = null
var room_def: RoomDef = null

var _floor: MeshInstance3D = null
var _grid: MeshInstance3D = null
var _props_root: Node3D = null
var _hazard_root: Node3D = null
var _door_root: Node3D = null
var _lights: Array[OmniLight3D] = []
var _flames: Array[Sprite3D] = []
var _hazard_planes: Array[Dictionary] = []
var _emitter_lights: Array[Dictionary] = []
var _hazard_particles: Array[Dictionary] = []
var _theme: Dictionary = {}
var _mat_floor_room: StandardMaterial3D
var _mat_wall_room: StandardMaterial3D
var _brazier_light: OmniLight3D = null
var _time := 0.0

var _mat_floor: StandardMaterial3D
var _mat_wall: StandardMaterial3D
var _mat_wood: StandardMaterial3D
var _mat_stone_dark: StandardMaterial3D
var _mat_iron: StandardMaterial3D
var _mat_gold: StandardMaterial3D
var _mat_bone: StandardMaterial3D
var _mat_cloth: StandardMaterial3D


func _ready() -> void:
	_load_materials()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	if _brazier_light != null:
		var flick := 0.92 + 0.08 * sin(_time * 13.0) + 0.04 * sin(_time * 37.0)
		_brazier_light.light_energy = 5.6 * flick
	for i in _lights.size():
		_lights[i].light_energy = 2.4 + 0.3 * sin(_time * 9.0 + float(i))
	for f in _flames:
		var s := 0.94 + 0.08 * sin(_time * 15.0 + float(f.get_index()))
		f.scale = Vector3(s, s, s)


func _tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _load_materials() -> void:
	_mat_floor = _mat_tex("floor-stone.png", "floor-stone-n.png", Vector2(2.4, 2.4), Color(0.9, 0.84, 0.76), 0.9, 0.0)
	_mat_wall = _mat_tex("wall-stone.png", "wall-stone-n.png", Vector2(1.2, 1.2), Color(0.9, 0.84, 0.76), 0.92, 0.0)
	_mat_wood = _mat_tex("wood-door.png", "", Vector2(0.9, 0.9), Color(0.68, 0.52, 0.38), 0.85, 0.0)
	_mat_stone_dark = _mat_plain(Color(0.20, 0.18, 0.16), 0.9)
	_mat_iron = _mat_plain(Color(0.16, 0.16, 0.18), 0.5, 0.85)
	_mat_gold = _mat_plain(Color(0.72, 0.54, 0.18), 0.3, 0.9)
	_mat_bone = _mat_plain(Color(0.64, 0.60, 0.50), 0.9)
	_mat_cloth = _mat_plain(Color(0.40, 0.08, 0.09), 0.95)


func _mat_plain(color: Color, rough: float = 0.9, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m


func _mat_tex(file: String, normal: String, uv: Vector2, tint: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var t := _tex(MAT_DIR + file)
	if t != null:
		m.albedo_texture = t
		m.texture_repeat = true
	var n := _tex(MAT_DIR + normal) if normal != "" else null
	if n != null:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = 1.1
	m.uv1_scale = Vector3(uv.x, uv.y, 1.0)
	m.albedo_color = tint
	m.roughness = rough
	m.metallic = metal
	return m


func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, pos: Vector3, top: float, bottom: float, height: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _plane(parent: Node3D, pos: Vector3, size: Vector2, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _flame(parent: Node3D, pos: Vector3, height: float = 0.6) -> void:
	var tex := _tex(MAT_DIR + "flame.png")
	if tex == null:
		return
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.position = pos
	spr.pixel_size = height / 192.0
	spr.modulate = Color(1.0, 0.88, 0.65, 0.95)
	parent.add_child(spr)
	_flames.append(spr)


func _shadow(parent: Node3D, pos: Vector3, size_units: float = 1.0) -> void:
	var tex := _tex(MAT_DIR + "shadow-blob.png")
	if tex == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.75)
	_plane(parent, pos, Vector2(size_units, size_units), mat)


func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)


func setup(room: RoomInstance) -> void:
	current_room = room
	room_def = room.definition if room != null else null
	for child in get_children():
		child.queue_free()
	_lights.clear()
	_flames.clear()
	_hazard_planes.clear()
	_emitter_lights.clear()
	_hazard_particles.clear()
	_theme = RoomTheme.for_id(room.definition.id)
	_mat_floor_room = _tinted(_mat_floor, _theme.get("tint", Color.WHITE))
	_mat_wall_room = _tinted(_mat_wall, _theme.get("tint", Color.WHITE))
	_brazier_light = null
	if room == null or room_def == null or room_def.layout == null:
		return
	var layout := room_def.layout
	_build_floor()
	_build_walls(layout)
	_door_root = Node3D.new()
	_door_root.name = "Doors"
	add_child(_door_root)
	_build_doors(room)
	_build_props()
	_build_theme_decor()
	_build_grid()
	_build_hazard_slots(layout)
	_build_hazard_particles(layout)
	# warm brazier in a safe interior corner
	_build_brazier(Vector3(7.35, 0.0, 1.45))
	# room accent light (theme)
	var accent: Color = _theme.get("accent", Color(1.0, 0.62, 0.28))
	var al := OmniLight3D.new()
	al.position = Vector3(ROOM * 0.5, 1.0, ROOM * 0.5)
	al.light_color = accent
	al.light_energy = 1.1
	al.omni_range = 6.0
	add_child(al)


func _build_floor() -> void:
	_floor = _plane(self, Vector3(ROOM * 0.5, 0.0, ROOM * 0.5), Vector2(ROOM + 0.4, ROOM + 0.4), _mat_floor_room)


func _build_walls(layout: RoomLayout) -> void:
	var door_cells := {}
	if current_room != null:
		for dir in current_room.door_dirs():
			door_cells[DoorSpec.local_door_cell(dir, current_room.orientation)] = true
	var walls := Node3D.new()
	walls.name = "Walls"
	add_child(walls)
	for r in ROOM:
		for c in ROOM:
			var border := r == 0 or r == ROOM - 1 or c == 0 or c == ROOM - 1
			if not border:
				continue
			var cell := Vector2i(c, r)
			if door_cells.has(cell):
				continue
			var near_camera: bool = r >= ROOM - 2 or c >= ROOM - 2
			if near_camera:
				_box(walls, Vector3(c + 0.5, 0.12, r + 0.5), Vector3(1.0, 0.24, 1.0), _mat_stone_dark)
				continue
			_box(walls, Vector3(c + 0.5, WALL_H * 0.5, r + 0.5), Vector3(1.0, WALL_H, 1.0), _mat_wall_room)
			_box(walls, Vector3(c + 0.5, WALL_H + 0.08, r + 0.5), Vector3(1.06, 0.16, 1.06), _mat_stone_dark)
	# wall trim strip at floor line (interior side)
	_box(walls, Vector3(ROOM * 0.5, 0.05, 0.98), Vector3(ROOM - 1.0, 0.1, 0.06), _mat_stone_dark)
	_box(walls, Vector3(0.98, 0.05, ROOM * 0.5), Vector3(0.06, 0.1, ROOM - 1.0), _mat_stone_dark)


func _build_doors(room: RoomInstance) -> void:
	for dir in room.door_dirs():
		var cell := DoorSpec.local_door_cell(dir, room.orientation)
		var pos := cell_center(cell)
		var group := Node3D.new()
		group.position = pos
		_door_root.add_child(group)
		var horizontal: bool = dir == DoorSpec.Dir.N or dir == DoorSpec.Dir.S
		if horizontal:
			_box(group, Vector3(-0.45, WALL_H * 0.5, 0), Vector3(0.10, WALL_H, 0.36), _mat_wall)
			_box(group, Vector3(0.45, WALL_H * 0.5, 0), Vector3(0.10, WALL_H, 0.36), _mat_wall)
			_box(group, Vector3(0, WALL_H - 0.07, 0), Vector3(1.0, 0.14, 0.36), _mat_wall)
			_box(group, Vector3(0, WALL_H - 0.16, 0), Vector3(0.9, 0.05, 0.4), _mat_gold)
		else:
			_box(group, Vector3(0, WALL_H * 0.5, -0.45), Vector3(0.36, WALL_H, 0.10), _mat_wall)
			_box(group, Vector3(0, WALL_H * 0.5, 0.45), Vector3(0.36, WALL_H, 0.10), _mat_wall)
			_box(group, Vector3(0, WALL_H - 0.07, 0), Vector3(0.36, 0.14, 1.0), _mat_wall)
			_box(group, Vector3(0, WALL_H - 0.16, 0), Vector3(0.4, 0.05, 0.9), _mat_gold)
		# cold mist inside the doorway (additive, does not block the player)
		var mist_tex := _tex(MAT_DIR + "door-mist.png")
		if mist_tex != null:
			var out_dir := DoorSpec.delta(dir)
			var face := Vector3(-out_dir.x, 0.0, -out_dir.y)
			var mist := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.92, 2.0)
			mist.mesh = qm
			var mm := StandardMaterial3D.new()
			mm.albedo_texture = mist_tex
			mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mm.albedo_color = Color(0.55, 0.65, 0.85, 0.22)
			mist.material_override = mm
			mist.position = Vector3(out_dir.x * 0.04, 0.95, out_dir.y * 0.04)
			mist.rotation_degrees.y = rad_to_deg(atan2(face.x, face.z))
			group.add_child(mist)
		# dim cold corridor light outside the opening
		var out_light := OmniLight3D.new()
		var od := DoorSpec.delta(dir)
		out_light.position = Vector3(od.x * 0.95, 1.0, od.y * 0.95)
		out_light.light_color = Color(0.42, 0.55, 0.85)
		out_light.light_energy = 0.5
		out_light.omni_range = 2.2
		group.add_child(out_light)
		# floor threshold glow
		var thresh := StandardMaterial3D.new()
		thresh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		thresh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		thresh.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		thresh.albedo_color = Color(0.85, 0.62, 0.28, 0.14)
		_plane(group, Vector3(0, 0.02, 0), Vector2(0.82, 0.82), thresh)
		var dl := OmniLight3D.new()
		dl.position = Vector3(0, 1.2, 0)
		dl.light_color = Color(1.0, 0.62, 0.28)
		dl.light_energy = 1.5
		dl.omni_range = 2.8
		group.add_child(dl)


func _build_props() -> void:
	_props_root = Node3D.new()
	_props_root.name = "Props"
	add_child(_props_root)
	# north-wall torches
	for tp in [Vector3(3.2, 1.55, 1.12), Vector3(7.3, 1.55, 1.12)]:
		_box(_props_root, tp, Vector3(0.08, 0.28, 0.08), _mat_iron, Vector3(30, 0, 0))
		_flame(_props_root, tp + Vector3(0, 0.25, 0.06), 0.5)
		var l := OmniLight3D.new()
		l.position = tp + Vector3(0, 0.2, 0.3)
		l.light_color = Color(1.0, 0.60, 0.26)
		l.light_energy = 2.8
		l.omni_range = 5.2
		l.shadow_enabled = true
		add_child(l)
		_lights.append(l)
	# west-wall torches
	for tp in [Vector3(1.12, 1.55, 2.4), Vector3(1.12, 1.55, 6.4)]:
		_box(_props_root, tp, Vector3(0.08, 0.28, 0.08), _mat_iron, Vector3(0, 0, -30))
		_flame(_props_root, tp + Vector3(0.06, 0.25, 0), 0.5)
		var l := OmniLight3D.new()
		l.position = tp + Vector3(0.3, 0.2, 0)
		l.light_color = Color(1.0, 0.60, 0.26)
		l.light_energy = 2.2
		l.omni_range = 4.6
		add_child(l)
		_lights.append(l)
	# crates / barrels / bones
	_shadow(_props_root, Vector3(7.3, 0.04, 6.6), 1.0)
	_box(_props_root, Vector3(7.3, 0.35, 6.6), Vector3(0.7, 0.7, 0.7), _mat_wood, Vector3(0, 18, 0))
	_shadow(_props_root, Vector3(1.9, 0.04, 7.1), 0.9)
	_cyl(_props_root, Vector3(1.9, 0.42, 7.1), 0.34, 0.30, 0.85, _mat_wood)
	_cyl(_props_root, Vector3(2.65, 0.30, 7.4), 0.28, 0.24, 0.6, _mat_wood)
	_shadow(_props_root, Vector3(7.0, 0.04, 6.0), 0.7)
	_box(_props_root, Vector3(7.0, 0.04, 6.0), Vector3(0.5, 0.05, 0.08), _mat_bone, Vector3(0, 35, 0))
	for i in 5:
		_box(_props_root, Vector3(3.6 + i * 0.32, 0.04, 4.1 + (i % 3) * 0.2), Vector3(0.22, 0.04, 0.06), _mat_bone, Vector3(0, 20 + i * 17, 0))
	# hanging chains on back wall
	for ci in 3:
		var base_x := 1.7 + ci * 0.28
		for li in 5:
			_box(_props_root, Vector3(base_x + (0.03 if li % 2 == 0 else -0.03), 1.85 - li * 0.16, 1.14), Vector3(0.055, 0.10, 0.04), _mat_iron, Vector3(0, 20 + li * 30, 15))
	# wall shield
	_cyl(_props_root, Vector3(7.15, 1.42, 1.16), 0.26, 0.26, 0.06, _mat_wood).rotation_degrees = Vector3(90, 0, 0)
	_sphere(_props_root, Vector3(7.15, 1.42, 1.22), 0.07, _mat_gold)
	# candles
	for cp in [Vector3(2.55, 0.0, 1.55), Vector3(3.05, 0.0, 1.55), Vector3(6.9, 0.0, 7.1)]:
		_cyl(_props_root, cp + Vector3(0, 0.12, 0), 0.045, 0.055, 0.24, _mat_bone)
		_flame(_props_root, cp + Vector3(0, 0.36, 0), 0.22)
		var cl := OmniLight3D.new()
		cl.position = cp + Vector3(0, 0.42, 0)
		cl.light_color = Color(1.0, 0.65, 0.32)
		cl.light_energy = 0.5
		cl.omni_range = 1.6
		add_child(cl)
	# skulls
	for sp in [Vector3(3.3, 0.13, 6.7), Vector3(6.6, 0.13, 6.7), Vector3(2.55, 0.13, 4.3)]:
		_sphere(_props_root, sp, 0.13, _mat_bone)
		_sphere(_props_root, sp + Vector3(-0.05, 0.02, 0.10), 0.035, _mat_stone_dark)
		_sphere(_props_root, sp + Vector3(0.05, 0.02, 0.10), 0.035, _mat_stone_dark)
	# rubble
	for ri in 7:
		_sphere(_props_root, Vector3(1.4 + (ri % 4) * 0.24, 0.06, 3.1 + (ri / 4) * 0.3), 0.08, _mat_stone_dark)
	# small crate / barrel
	_box(_props_root, Vector3(2.55, 0.26, 6.85), Vector3(0.6, 0.52, 0.5), _mat_wood, Vector3(0, 24, 0))
	# banner on back wall
	_box(_props_root, Vector3(6.2, 1.45, 1.12), Vector3(0.7, 1.0, 0.04), _mat_cloth)
	_box(_props_root, Vector3(6.2, 1.99, 1.12), Vector3(0.8, 0.06, 0.06), _mat_gold)


func _build_brazier(pos: Vector3) -> void:
	_shadow(_props_root, Vector3(pos.x, 0.04, pos.z), 1.5)
	_box(_props_root, Vector3(pos.x, 0.12, pos.z), Vector3(0.5, 0.24, 0.5), _mat_stone_dark)
	_cyl(_props_root, Vector3(pos.x, 0.34, pos.z), 0.34, 0.18, 0.2, _mat_iron)
	_cyl(_props_root, Vector3(pos.x, 0.48, pos.z), 0.02, 0.34, 0.1, _mat_wood)
	_flame(_props_root, Vector3(pos.x, 0.9, pos.z), 1.0)
	_brazier_light = OmniLight3D.new()
	_brazier_light.position = Vector3(pos.x, 1.1, pos.z)
	_brazier_light.light_color = Color(1.0, 0.56, 0.22)
	_brazier_light.light_energy = 5.6
	_brazier_light.omni_range = 7.5
	_brazier_light.shadow_enabled = true
	_brazier_light.shadow_blur = 1.4
	add_child(_brazier_light)


func _build_grid() -> void:
	var im := ImmediateMesh.new()
	var line_mat := StandardMaterial3D.new()
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.albedo_color = Color(0.72, 0.76, 0.82, 0.08)
	im.surface_begin(Mesh.PRIMITIVE_LINES, line_mat)
	for i in ROOM + 1:
		im.surface_add_vertex(Vector3(i, 0.012, 0.0))
		im.surface_add_vertex(Vector3(i, 0.012, ROOM))
		im.surface_add_vertex(Vector3(0.0, 0.012, i))
		im.surface_add_vertex(Vector3(ROOM, 0.012, i))
	im.surface_end()
	_grid = MeshInstance3D.new()
	_grid.mesh = im
	add_child(_grid)
	# subtle gold edge line
	var edge_mat := StandardMaterial3D.new()
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge_mat.albedo_color = Color(0.78, 0.62, 0.30, 0.22)
	for i in 4:
		var along_x: bool = i < 2
		var pos := Vector3(ROOM * 0.5, 0.03, 0.02) if i == 0 else (Vector3(ROOM * 0.5, 0.03, ROOM - 0.02) if i == 1 else (Vector3(0.02, 0.03, ROOM * 0.5) if i == 2 else Vector3(ROOM - 0.02, 0.03, ROOM * 0.5)))
		var size := Vector3(ROOM - 0.1, 0.03, 0.035) if along_x else Vector3(0.035, 0.03, ROOM - 0.1)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = edge_mat
		mi.position = pos
		add_child(mi)


func _build_hazard_slots(layout: RoomLayout) -> void:
	_hazard_root = Node3D.new()
	_hazard_root.name = "Hazard"
	add_child(_hazard_root)
	var seen := {}
	var blob_tex := _tex(MAT_DIR + "hazard-mask.png")
	for channel in layout.hazard_cells:
		seen[int(channel)] = true
		var cells: Array = layout.hazard_cells[channel]
		for cell in cells:
			var decal := Decal.new()
			if blob_tex != null:
				decal.texture_albedo = blob_tex
			decal.size = Vector3(1.6, 1.2, 1.6)
			decal.position = Vector3(cell.x + 0.5, 0.65, cell.y + 0.5)
			decal.albedo_mix = 1.0
			decal.cull_mask = 1
			_hazard_root.add_child(decal)
			_hazard_planes.append({"channel": int(channel), "decal": decal})
	for emitter in room_def.emitters:
		if emitter == null:
			continue
		seen[int(emitter.channel)] = true
	for channel in seen:
		var col: Color = CHANNEL_COLORS.get(int(channel), Color.WHITE)
		var l := OmniLight3D.new()
		l.position = Vector3(ROOM * 0.5, 0.75, ROOM * 0.5)
		l.light_color = col
		l.light_energy = 0.0
		l.omni_range = 4.5
		add_child(l)
		_emitter_lights.append({"channel": int(channel), "light": l})


func update_channels(state: RoomState) -> void:
	if state == null:
		return
	for entry in _hazard_planes:
		var ch: int = entry["channel"]
		var decal: Decal = entry["decal"]
		var value := state.get_channel(ch)
		var col: Color = CHANNEL_COLORS.get(ch, Color.WHITE)
		col.a = clampf(float(value) / float(Channels.MAX_VALUE) * 0.55, 0.0, 0.55)
		decal.modulate = col
	for entry in _emitter_lights:
		var ch: int = entry["channel"]
		var light: OmniLight3D = entry["light"]
		var value := state.get_channel(ch)
		light.light_energy = clampf(float(value) / float(Channels.MAX_VALUE), 0.0, 1.0) * 1.6
	for entry in _hazard_particles:
		var ch: int = entry["channel"]
		var node: CPUParticles3D = entry["node"]
		var value := state.get_channel(ch)
		node.amount = maxi(1, int(clampf(float(value) / float(Channels.MAX_VALUE), 0.0, 1.0) * 24.0))
		node.emitting = value > 0


func _tinted(base: StandardMaterial3D, tint: Color) -> StandardMaterial3D:
	var m := base.duplicate() as StandardMaterial3D
	var c := m.albedo_color
	m.albedo_color = Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a)
	return m


func _emissive(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func _build_theme_decor() -> void:
	var accent: Color = _theme.get("accent", Color(1.0, 0.62, 0.28))
	var decor: StringName = _theme.get("decor", &"camp")
	match decor:
		&"forge":
			_box(_props_root, Vector3(2.35, 0.25, 2.55), Vector3(1.1, 0.5, 0.6), _mat_iron)
			_box(_props_root, Vector3(2.35, 0.55, 2.35), Vector3(0.5, 0.18, 0.4), _mat_iron)
			for i in 7:
				_sphere(_props_root, Vector3(5.9 + (i % 3) * 0.22, 0.08, 2.1 + (i / 3) * 0.2), 0.10, _emissive(Color(1.0, 0.35, 0.10), 2.2))
			_sphere(_props_root, Vector3(2.4, 0.7, 2.5), 0.06, _emissive(Color(1.0, 0.55, 0.2), 3.0))
		&"frost":
			var ice_mat := StandardMaterial3D.new()
			ice_mat.albedo_color = Color(0.62, 0.82, 0.98, 0.85)
			ice_mat.emission_enabled = true
			ice_mat.emission = Color(0.35, 0.62, 0.95)
			ice_mat.emission_energy_multiplier = 0.55
			ice_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ice_mat.roughness = 0.25
			for i in 6:
				var h := 0.35 + (i % 3) * 0.14
				var c := _cyl(_props_root, Vector3(2.15 + (i % 3) * 0.32, h * 0.5, 2.3 + (i / 3) * 0.4), 0.0, 0.075 + (i % 2) * 0.03, h, ice_mat)
				c.rotation_degrees = Vector3(0, i * 41, (i % 2) * 6)
			var frost_pool := _plane(_props_root, Vector3(6.55, 0.02, 2.05), Vector2(1.7, 1.3), _emissive(Color(0.30, 0.52, 0.80), 0.35))
			var pool_mat := frost_pool.material_override as StandardMaterial3D
			if pool_mat != null:
				pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				pool_mat.albedo_color.a = 0.35
		&"toxin":
			for i in 6:
				_cyl(_props_root, Vector3(2.0 + (i % 3) * 0.4, 0.10, 4.9 + (i / 3) * 0.4), 0.03, 0.08, 0.2, _emissive(Color(0.5, 0.9, 0.3), 1.0))
		&"storm":
			_cyl(_props_root, Vector3(2.3, 0.6, 2.3), 0.10, 0.16, 1.2, _mat_iron)
			for i in 3:
				_sphere(_props_root, Vector3(2.3, 1.25 + i * 0.18, 2.3), 0.10 - i * 0.02, _emissive(Color(1.0, 0.86, 0.35), 3.0))
			for i in 4:
				_box(_props_root, Vector3(6.4 + (i % 2) * 0.4, 0.15, 2.0 + (i / 2) * 0.4), Vector3(0.16, 0.3, 0.16), _mat_iron)
		&"accumulator":
			for i in 2:
				_cyl(_props_root, Vector3(2.3 + i * 0.8, 0.55, 2.4), 0.22, 0.28, 1.1, _mat_stone_dark)
				_cyl(_props_root, Vector3(2.3 + i * 0.8, 0.9, 2.4), 0.24, 0.24, 0.16, _emissive(Color(1.0, 0.74, 0.28), 2.0))
		&"conduit":
			_box(_props_root, Vector3(4.5, 0.22, 2.1), Vector3(4.4, 0.12, 0.12), _mat_iron)
			_box(_props_root, Vector3(4.5, 0.22, 2.1), Vector3(4.2, 0.05, 0.06), _emissive(Color(0.4, 0.82, 1.0), 1.6))
		&"mirror":
			_box(_props_root, Vector3(2.3, 0.9, 2.3), Vector3(0.1, 1.5, 0.8), _emissive(Color(0.72, 0.85, 0.95), 0.8))
			_box(_props_root, Vector3(6.6, 0.9, 6.4), Vector3(0.8, 1.5, 0.1), _emissive(Color(0.72, 0.85, 0.95), 0.8))
		&"echo":
			for i in 4:
				_cyl(_props_root, Vector3(2.4 + i * 0.5, 0.5 + (i % 2) * 0.18, 6.4 - i * 0.3), 0.02, 0.14, 0.9 + (i % 2) * 0.3, _emissive(Color(0.72, 0.45, 1.0), 1.5)).rotation_degrees = Vector3(0, i * 31, 0)
		&"gravity":
			for i in 4:
				_sphere(_props_root, Vector3(2.3 + (i % 2) * 0.7, 0.7 + (i / 2) * 0.35, 2.3 + (i / 2) * 0.6), 0.16, _mat_stone_dark)
		&"fold":
			var torus := TorusMesh.new()
			torus.inner_radius = 0.8
			torus.outer_radius = 0.9
			var ring := MeshInstance3D.new()
			ring.mesh = torus
			ring.material_override = _emissive(Color(0.35, 0.65, 1.0), 2.0)
			ring.position = Vector3(4.5, 0.04, 4.5)
			_props_root.add_child(ring)
		&"vault":
			for i in 5:
				_sphere(_props_root, Vector3(2.2 + (i % 3) * 0.3, 0.10, 6.3 + (i / 3) * 0.3), 0.13, _emissive(Color(1.0, 0.78, 0.30), 0.9))
			_box(_props_root, Vector3(6.4, 0.25, 2.2), Vector3(0.8, 0.5, 0.55), _mat_wood)
			_box(_props_root, Vector3(6.4, 0.55, 2.2), Vector3(0.84, 0.06, 0.58), _mat_gold)
		&"ballista":
			_box(_props_root, Vector3(4.5, 0.3, 2.1), Vector3(1.4, 0.35, 0.7), _mat_wood)
			_cyl(_props_root, Vector3(4.5, 0.55, 2.1), 0.06, 0.06, 1.2, _mat_iron).rotation_degrees = Vector3(0, 0, 90)
			for i in 5:
				_box(_props_root, Vector3(2.2 + i * 0.12, 0.2, 6.6), Vector3(0.05, 0.05, 0.9), _mat_wood)
		&"boss":
			_box(_props_root, Vector3(4.5, 0.25, 2.2), Vector3(1.2, 0.5, 0.9), _mat_stone_dark)
			_sphere(_props_root, Vector3(4.5, 0.62, 2.2), 0.24, _mat_bone)
			_box(_props_root, Vector3(4.5, 0.42, 2.2), Vector3(0.5, 0.1, 0.1), _mat_cloth)
		&"camp":
			_box(_props_root, Vector3(2.4, 0.22, 6.9), Vector3(0.9, 0.4, 0.6), _mat_wood)
			_sphere(_props_root, Vector3(2.6, 0.5, 6.9), 0.10, _emissive(Color(1.0, 0.6, 0.25), 2.0))
		&"battle":
			for i in 4:
				_box(_props_root, Vector3(6.3 + (i % 2) * 0.25, 0.22, 2.1 + (i / 2) * 0.25), Vector3(0.12, 0.4, 0.12), _mat_iron)
		&"corridor":
			_cyl(_props_root, Vector3(2.2, 0.35, 6.8), 0.28, 0.24, 0.7, _mat_wood)
	for light in _props_root.get_children():
		if light is OmniLight3D:
			continue


func _build_hazard_particles(layout: RoomLayout) -> void:
	var channels := {}
	for channel in layout.hazard_cells:
		channels[int(channel)] = layout.hazard_cells[channel]
	for emitter in room_def.emitters:
		if emitter != null:
			channels[int(emitter.channel)] = []
	for channel in channels:
		var cells: Array = channels[channel]
		var center := Vector3(ROOM * 0.5, 0.0, ROOM * 0.5)
		if not cells.is_empty():
			center = Vector3.ZERO
			for cell in cells:
				center += Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)
			center /= float(cells.size())
		var p := CPUParticles3D.new()
		p.amount = 24
		p.lifetime = 2.4
		p.gravity = Vector3(0, 0.35, 0)
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(2.6, 0.2, 2.6) if cells.is_empty() else Vector3(0.6, 0.2, 0.6) * float(maxi(1, cells.size()))
		p.direction = Vector3(0, 1, 0)
		p.spread = 28.0
		p.initial_velocity_min = 0.05
		p.initial_velocity_max = 0.22
		p.scale_amount_min = 0.06
		p.scale_amount_max = 0.16
		p.color = CHANNEL_COLORS.get(int(channel), Color.WHITE)
		p.position = center + Vector3(0, 0.15, 0)
		p.emitting = true
		add_child(p)
		_hazard_particles.append({"channel": int(channel), "node": p})


func highlight_cell(cell: Vector2i, color: Color) -> void:
	if _hazard_root == null:
		return
	var old := _hazard_root.get_node_or_null("CellHighlight")
	if old != null:
		old.queue_free()
	if cell.x < 0:
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = color
	var p := _plane(_hazard_root, Vector3(cell.x + 0.5, 0.045, cell.y + 0.5), Vector2(0.92, 0.92), mat)
	p.name = "CellHighlight"
