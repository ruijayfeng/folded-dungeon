class_name MacroMap3D
extends Node3D
## M6-2: 3D overview of the 5x5 dungeon macro grid used during the build phase.
## Pure presentation: reads DungeonGrid + offer/preview state; never mutates it.

const GRID := 5
const SPACING := 3.0
const SLAB := 2.3
const SLAB_H := 0.18

var _root: Node3D = null


func _ready() -> void:
	_root = Node3D.new()
	_root.name = "Rooms"
	add_child(_root)
	_build_base()


static func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * SPACING, 0.0, cell.y * SPACING)


static func world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(
		clampi(roundi(pos.x / SPACING), 0, GRID - 1),
		clampi(roundi(pos.z / SPACING), 0, GRID - 1)
	)


func center_world() -> Vector3:
	return Vector3(SPACING * (GRID - 1) * 0.5, 0.0, SPACING * (GRID - 1) * 0.5)


func _build_base() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mat.albedo_color = Color(0.035, 0.032, 0.04)
	var pm := PlaneMesh.new()
	pm.size = Vector2(GRID * SPACING + 2.0, GRID * SPACING + 2.0)
	var floor_mi := MeshInstance3D.new()
	floor_mi.mesh = pm
	floor_mi.material_override = floor_mat
	floor_mi.position = Vector3(center_world().x, -0.02, center_world().z)
	add_child(floor_mi)
	# grid lines
	var im := ImmediateMesh.new()
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.30, 0.24, 0.14, 0.9)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	im.surface_begin(Mesh.PRIMITIVE_LINES, lm)
	for i in GRID + 1:
		var x := (i - 0.5) * SPACING
		var z0 := -0.5 * SPACING
		var z1 := (GRID - 0.5) * SPACING
		im.surface_add_vertex(Vector3(x, 0.01, z0))
		im.surface_add_vertex(Vector3(x, 0.01, z1))
		im.surface_add_vertex(Vector3(z0, 0.01, x))
		im.surface_add_vertex(Vector3(z1, 0.01, x))
	im.surface_end()
	var grid_mi := MeshInstance3D.new()
	grid_mi.mesh = im
	add_child(grid_mi)
	# overview fill light
	var l := OmniLight3D.new()
	l.position = center_world() + Vector3(0, 6.0, 0)
	l.light_color = Color(0.75, 0.80, 1.0)
	l.light_energy = 2.2
	l.omni_range = 22.0
	add_child(l)


func setup(grid: DungeonGrid, current: Vector2i, preview_cell: Vector2i, preview_def: RoomDef,
		preview_orientation: int, preview_valid: bool) -> void:
	if _root == null:
		_root = Node3D.new()
		add_child(_root)
	for child in _root.get_children():
		child.queue_free()
	if grid == null:
		return
	for y in GRID:
		for x in GRID:
			var cell := Vector2i(x, y)
			var room := grid.get_room(cell)
			if room == null:
				continue
			_build_room_slab(cell, room, cell == current)
	if preview_cell.x >= 0:
		_build_preview(preview_cell, preview_def, preview_orientation, preview_valid)


func _build_room_slab(cell: Vector2i, room: RoomInstance, is_current: bool) -> void:
	var theme := RoomTheme.for_id(room.definition.id)
	var tint: Color = theme.get("tint", Color.WHITE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(tint.r * 0.32, tint.g * 0.32, tint.b * 0.32)
	mat.emission_enabled = true
	mat.emission = Color(tint.r * 0.18, tint.g * 0.18, tint.b * 0.18)
	mat.emission_energy_multiplier = 1.0
	mat.roughness = 0.9
	var mi := _slab(cell, Vector3(SLAB, SLAB_H, SLAB), mat, 0.0)
	mi.position += Vector3(0, 0.0, 0)
	# door markers
	for dir in room.door_dirs():
		_marker(cell, dir, Color(1.0, 0.78, 0.35), 0.09)
	if is_current:
		for edge in 4:
			var pos := cell_to_world(cell)
			var s := Vector3(SLAB + 0.12, 0.05, 0.06) if edge < 2 else Vector3(0.06, 0.05, SLAB + 0.12)
			var p := pos + (Vector3(0, 0.12, -SLAB * 0.5) if edge == 0 else (Vector3(0, 0.12, SLAB * 0.5) if edge == 1 else (Vector3(-SLAB * 0.5, 0.12, 0) if edge == 2 else Vector3(SLAB * 0.5, 0.12, 0))))
			var gold := StandardMaterial3D.new()
			gold.albedo_color = Color(1.0, 0.82, 0.35)
			gold.emission_enabled = true
			gold.emission = Color(1.0, 0.72, 0.25)
			gold.emission_energy_multiplier = 2.4
			_mesh_box(p, s, gold)
	var label := Label3D.new()
	label.text = theme.get("label", str(room.definition.id))
	label.font_size = 48
	label.pixel_size = 0.006
	label.modulate = Color(0.92, 0.86, 0.72, 0.9) if not is_current else Color(1.0, 0.86, 0.42, 1.0)
	label.outline_size = 8
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = cell_to_world(cell) + Vector3(0, 0.55, 0)
	_root.add_child(label)


func _build_preview(cell: Vector2i, def: RoomDef, orientation: int, valid: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.35, 0.95, 0.55, 0.13) if valid else Color(1.0, 0.28, 0.25, 0.15)
	var mi := _slab(cell, Vector3(SLAB, SLAB_H * 3.0, SLAB), mat, SLAB_H * 1.6)
	mi.name = "PreviewSlab"
	_preview_outline(cell, Color(0.45, 1.0, 0.62, 0.9) if valid else Color(1.0, 0.40, 0.35, 0.9))
	if def == null:
		return
	var mask := DoorSpec.rotate_mask(def.door_mask, orientation)
	for dir in DoorSpec.all_dirs():
		if mask & dir:
			_marker(cell, dir, Color(0.45, 1.0, 0.65), 0.14)
	var label := Label3D.new()
	label.text = "%s%s" % [def.display_name, "" if valid else "（无效）"]
	label.font_size = 56
	label.pixel_size = 0.006
	label.modulate = Color(0.62, 1.0, 0.72) if valid else Color(1.0, 0.48, 0.42)
	label.outline_size = 10
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = cell_to_world(cell) + Vector3(0, 1.15, 0)
	_root.add_child(label)


func _preview_outline(cell: Vector2i, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var base := cell_to_world(cell) + Vector3(0, SLAB_H * 3.0 + SLAB_H * 1.6, 0)
	for edge in 4:
		var size := Vector3(SLAB + 0.08, 0.05, 0.06) if edge < 2 else Vector3(0.06, 0.05, SLAB + 0.08)
		var off := Vector3(0, 0, -SLAB * 0.5) if edge == 0 else (Vector3(0, 0, SLAB * 0.5) if edge == 1 else (Vector3(-SLAB * 0.5, 0, 0) if edge == 2 else Vector3(SLAB * 0.5, 0, 0)))
		_mesh_box(base + off, size, mat)


func _slab(cell: Vector2i, size: Vector3, mat: Material, lift: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = cell_to_world(cell) + Vector3(0, size.y * 0.5 + lift, 0)
	_root.add_child(mi)
	return mi


func _mesh_box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	_root.add_child(mi)


func _marker(cell: Vector2i, dir: int, color: Color, height: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	var base := cell_to_world(cell)
	var off := Vector3.ZERO
	match dir:
		DoorSpec.Dir.N: off = Vector3(0, 0.16, -SLAB * 0.5)
		DoorSpec.Dir.S: off = Vector3(0, 0.16, SLAB * 0.5)
		DoorSpec.Dir.W: off = Vector3(-SLAB * 0.5, 0.16, 0)
		DoorSpec.Dir.E: off = Vector3(SLAB * 0.5, 0.16, 0)
	var size := Vector3(0.36, height, 0.10) if dir == DoorSpec.Dir.N or dir == DoorSpec.Dir.S else Vector3(0.10, height, 0.36)
	_mesh_box(base + off, size, mat)
