extends TestCase
## M6-1: pure mapping rules used by the 3D room builder.


func test_rotated_door_cells_stay_on_border() -> void:
	for dir in DoorSpec.all_dirs():
		for orientation in 4:
			var cell := DoorSpec.local_door_cell(dir, orientation)
			var on_border: bool = cell.x == 0 or cell.x == DoorSpec.ROOM_SIZE - 1 or cell.y == 0 or cell.y == DoorSpec.ROOM_SIZE - 1
			assert_true(on_border, "door cell on border: dir=%d ori=%d -> %s" % [dir, orientation, str(cell)])


func test_door_rotation_preserves_count() -> void:
	var mask := DoorSpec.Dir.N | DoorSpec.Dir.E | DoorSpec.Dir.S
	for orientation in 4:
		var rotated := DoorSpec.rotate_mask(mask, orientation)
		var count := 0
		for dir in DoorSpec.all_dirs():
			if rotated & dir:
				count += 1
		assert_eq(count, 3, "rotation keeps door count (ori=%d)" % orientation)


func test_ground_pick_plane() -> void:
	var from := Vector3(4.5, 10.0, 4.5)
	var dir := Vector3(0.0, -1.0, 0.0)
	var t := -from.y / dir.y
	var hit := from + dir * t
	assert_almost_eq(hit.x, 4.5)
	assert_almost_eq(hit.z, 4.5)
	assert_almost_eq(hit.y, 0.0)
