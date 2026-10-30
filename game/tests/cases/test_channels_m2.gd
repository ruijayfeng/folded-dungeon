extends TestCase


func test_room_state_channels_and_clamp() -> void:
	var state := RoomState.new(&"room#1", Vector2i(1, 2))
	assert_eq(state.get_channel(Channels.Channel.HEAT), 0)
	assert_eq(state.add_channel(Channels.Channel.HEAT, 250), 250)
	assert_eq(state.add_channel(Channels.Channel.HEAT, 900), 750, "clamped at 1000")
	assert_eq(state.get_channel(Channels.Channel.HEAT), 1000)
	assert_eq(state.add_channel(Channels.Channel.HEAT, -1200), -1000, "clamped at 0")
	state.set_channel(Channels.Channel.TOXIN, 1234)
	assert_eq(state.get_channel(Channels.Channel.TOXIN), Channels.MAX_VALUE, "set clamps")


func test_room_state_timed_states_and_clone() -> void:
	var state := RoomState.new(&"room#1", Vector2i(1, 2))
	state.set_state(&"burning", 2)
	state.set_state(&"permanent", 0)
	assert_true(state.has_state(&"burning"), "timed state set")
	var expired := state.advance_states()
	assert_true(expired.is_empty(), "state still has one turn")
	expired = state.advance_states()
	assert_true(expired.has(&"burning"), "state expires")
	assert_false(state.has_state(&"burning"))
	assert_true(state.has_state(&"permanent"), "permanent state stays")

	var copy := state.clone()
	copy.add_channel(Channels.Channel.COLD, 500)
	assert_eq(state.get_channel(Channels.Channel.COLD), 0, "clone is independent")
	assert_eq(copy.get_channel(Channels.Channel.COLD), 500)
