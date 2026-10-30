extends TestCase

const RULE_ROOMS: Array[StringName] = [
	&"forge_room", &"toxin_room", &"frost_room", &"storm_room",
	&"mirror_room", &"gravity_room", &"accumulator_room", &"echo_room",
	&"conduit_room", &"ballista_room", &"vault_room", &"fold_room",
]
const STRUCTURAL_ROOMS: Array[StringName] = [&"start_room", &"combat_room", &"boss_room", &"corridor_room"]


func test_twelve_rule_rooms_load_and_validate() -> void:
	assert_eq(RULE_ROOMS.size(), 12, "12 rule rooms")
	for room_id in RULE_ROOMS:
		var def := load("res://data/rooms/%s.tres" % room_id) as RoomDef
		assert_true(def != null, "load %s" % room_id)
		if def == null:
			continue
		assert_eq(String(def.id), String(room_id), "id matches for %s" % room_id)
		assert_true(def.validate().is_empty(), "validates: %s (%s)" % [room_id, "; ".join(def.validate())])
	for room_id in STRUCTURAL_ROOMS:
		var def := load("res://data/rooms/%s.tres" % room_id) as RoomDef
		assert_true(def != null and def.validate().is_empty(), "structural room valid: %s" % room_id)


func test_room_rule_fields() -> void:
	var storm := load("res://data/rooms/storm_room.tres") as RoomDef
	assert_true(storm.tags.has(&"wind_source"), "storm is air source")
	assert_eq(storm.emitters.size(), 1, "storm emitter")
	assert_eq(storm.emitters[0].channel, Channels.Channel.AIRFLOW, "storm emits airflow")
	var gravity := load("res://data/rooms/gravity_room.tres") as RoomDef
	assert_true(gravity.tags.has(&"gravity"), "gravity tag")
	assert_eq(gravity.gravity_dir, DoorSpec.Dir.S, "gravity pulls south")
	var echo := load("res://data/rooms/echo_room.tres") as RoomDef
	assert_eq(echo.periodic_turns, 2, "echo period")
	assert_eq(echo.periodic_event, &"echo_pulse", "echo event")
	var conduit := load("res://data/rooms/conduit_room.tres") as RoomDef
	assert_eq(conduit.transfer_percent, 150, "conduit transfer bonus")
	var vault := load("res://data/rooms/vault_room.tres") as RoomDef
	assert_true(vault.tags.has(&"vault"), "vault tag")
	var fold := load("res://data/rooms/fold_room.tres") as RoomDef
	assert_true(fold.tags.has(&"fold_chamber"), "fold chamber tag")
