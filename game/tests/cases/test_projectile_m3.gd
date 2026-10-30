extends TestCase


func test_mirror_redirects_projectile_into_south_room() -> void:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	var shooter := _def(&"shooter", DoorSpec.Dir.E)
	var mirror := load("res://data/rooms/mirror_room.tres") as RoomDef
	var target_room := _def(&"target", DoorSpec.Dir.N)
	assert_valid(grid.place_start(shooter, Vector2i(1, 2)), "shooter")
	assert_valid(grid.place_room(mirror, Vector2i(2, 2)), "mirror")
	assert_valid(grid.place_room(target_room, Vector2i(2, 3)), "target room")
	var enemy := Unit.new(&"enemy_1", Unit.TEAM_ENEMY)
	enemy.max_hp = 5
	enemy.hp = 5
	enemy.room_cell = Vector2i(2, 3)
	enemy.local_cell = Vector2i(4, 4)
	var projectiles := ProjectileSystem.new(grid)
	var shot := projectiles.fire(Vector2i(1, 2), DoorSpec.Dir.E, 3, [enemy], 4)
	assert_eq(enemy.hp, 2, "projectile redirected into the south room hits enemy")
	assert_true(_has_event(shot, &"projectile_redirected"), "mirror redirect event")
	var redirected := _find_event(shot, &"projectile_redirected")
	assert_eq(redirected["new_dir"], DoorSpec.Dir.S, "mirror redirects east to south")
	var hit := _find_event(shot, &"projectile_hit")
	assert_eq(hit["cell"], Vector2i(2, 3), "hit happens in the redirected room")


func test_plain_room_does_not_redirect() -> void:
	var grid := DungeonGrid.new()
	grid.set_budget(10, 25)
	var shooter := _def(&"shooter", DoorSpec.Dir.E)
	var plain := _def(&"plain", DoorSpec.Dir.W | DoorSpec.Dir.E)
	assert_valid(grid.place_start(shooter, Vector2i(1, 2)), "shooter")
	assert_valid(grid.place_room(plain, Vector2i(2, 2)), "plain room")
	var enemy := Unit.new(&"enemy_1", Unit.TEAM_ENEMY)
	enemy.max_hp = 5
	enemy.hp = 5
	enemy.room_cell = Vector2i(2, 2)
	enemy.local_cell = Vector2i(4, 4)
	var projectiles := ProjectileSystem.new(grid)
	var shot := projectiles.fire(Vector2i(1, 2), DoorSpec.Dir.E, 3, [enemy], 4)
	assert_eq(enemy.hp, 2, "plain room hits the enemy directly")
	assert_false(_has_event(shot, &"projectile_redirected"), "no redirect without mirror")


func _has_event(events_list: Array, event_type: StringName) -> bool:
	for event in events_list:
		if event["type"] == event_type:
			return true
	return false


func _find_event(events_list: Array, event_type: StringName) -> Dictionary:
	for event in events_list:
		if event["type"] == event_type:
			return event
	return {}


func _def(room_id: StringName, mask: int) -> RoomDef:
	var def := RoomDef.new()
	def.id = room_id
	def.display_name = String(room_id)
	def.door_mask = mask
	def.build_cost = 0
	var layout := RoomLayout.new()
	layout.size = Vector2i(9, 9)
	layout.terrain = RoomLayout.make_border_terrain()
	var spawns: Array[Vector2i] = [Vector2i(4, 4)]
	layout.spawn_cells = spawns
	layout.fill_derived_door_data()
	def.layout = layout
	return def
