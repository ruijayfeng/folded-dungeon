extends TestCase


func test_mask_rotation_cycle() -> void:
	assert_eq(DoorSpec.rotate_mask(DoorSpec.Dir.N, 0), DoorSpec.Dir.N, "N step 0")
	assert_eq(DoorSpec.rotate_mask(DoorSpec.Dir.N, 1), DoorSpec.Dir.E, "N step 1")
	assert_eq(DoorSpec.rotate_mask(DoorSpec.Dir.N, 2), DoorSpec.Dir.S, "N step 2")
	assert_eq(DoorSpec.rotate_mask(DoorSpec.Dir.N, 3), DoorSpec.Dir.W, "N step 3")
	assert_eq(DoorSpec.rotate_mask(DoorSpec.Dir.N, 4), DoorSpec.Dir.N, "N step 4 wraps")
	assert_eq(
		DoorSpec.rotate_mask(DoorSpec.Dir.N | DoorSpec.Dir.E, 1),
		DoorSpec.Dir.E | DoorSpec.Dir.S,
		"NE -> ES"
	)
	for mask in [1, 2, 4, 8, 3, 5, 6, 10, 12, 15]:
		for steps in 4:
			var rotated := DoorSpec.rotate_mask(mask, steps)
			assert_eq(DoorSpec.rotate_mask(rotated, -steps), mask, "mask rotation inverse for %d/%d" % [mask, steps])


func test_cell_rotation_stays_in_room() -> void:
	assert_eq(DoorSpec.rotate_cell(Vector2i(4, 0), 1), Vector2i(8, 4), "N cell -> E cell")
	assert_eq(DoorSpec.rotate_cell(Vector2i(8, 4), 1), Vector2i(4, 8), "E cell -> S cell")
	assert_eq(DoorSpec.rotate_cell(Vector2i(4, 0), 4), Vector2i(4, 0), "4 rotations are identity")
	for dir in DoorSpec.all_dirs():
		for orientation in 4:
			var cell := DoorSpec.local_door_cell(dir, orientation)
			assert_true(
				cell.x >= 0 and cell.x < DoorSpec.ROOM_SIZE and cell.y >= 0 and cell.y < DoorSpec.ROOM_SIZE,
				"door cell in bounds: dir=%d orientation=%d cell=%s" % [dir, orientation, str(cell)]
			)


func test_anchor_rotation() -> void:
	assert_true(
		DoorSpec.rotate_anchor(Vector2(4.5, 0.0), 1).is_equal_approx(Vector2(9.0, 4.5)),
		"N anchor -> E anchor"
	)
	assert_true(
		DoorSpec.rotate_anchor(Vector2(9.0, 4.5), 1).is_equal_approx(Vector2(4.5, 9.0)),
		"E anchor -> S anchor"
	)
	var anchor := Vector2(4.5, 0.0)
	assert_true(DoorSpec.rotate_anchor(anchor, 4).is_equal_approx(anchor), "4 rotations are identity")


func test_adjacent_door_anchors_coincide() -> void:
	var a_cell := Vector2i(2, 2)
	for orientation in 4:
		var door_dir := DoorSpec.rotate_dir(DoorSpec.Dir.E, orientation)
		var b_cell := a_cell + DoorSpec.delta(door_dir)
		var back_dir := DoorSpec.opposite(door_dir)
		var b_orientation := (DoorSpec.dir_index(back_dir) - DoorSpec.dir_index(DoorSpec.Dir.W) + 4) % 4
		var a_room := RoomInstance.new(&"a", _def_with_doors(DoorSpec.Dir.E), a_cell, orientation)
		var b_room := RoomInstance.new(&"b", _def_with_doors(DoorSpec.Dir.W), b_cell, b_orientation)
		var a_anchor := a_room.world_door_anchor(door_dir)
		var b_anchor := b_room.world_door_anchor(back_dir)
		assert_true(
			a_anchor.is_equal_approx(b_anchor),
			"anchors coincide for orientation %d: %s vs %s" % [orientation, str(a_anchor), str(b_anchor)]
		)


func test_instance_door_mask_rotates() -> void:
	var instance := RoomInstance.new(&"x", _def_with_doors(DoorSpec.Dir.N | DoorSpec.Dir.E), Vector2i(0, 0), 1)
	assert_eq(instance.door_mask(), DoorSpec.Dir.E | DoorSpec.Dir.S, "instance mask rotates")
	assert_true(instance.has_door(DoorSpec.Dir.E), "rotated mask has E")
	assert_false(instance.has_door(DoorSpec.Dir.N), "rotated mask lost N")


func _def_with_doors(mask: int) -> RoomDef:
	var def := RoomDef.new()
	def.id = &"test_room"
	def.display_name = "test"
	def.door_mask = mask
	return def
