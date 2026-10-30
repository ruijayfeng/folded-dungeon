extends TestCase

# Gold vectors for SplitMix64 seed 0 (checked against an independent Python model).
const VECTOR_0 := -2152535657050944081
const VECTOR_1 := 7960286522194355700
const VECTOR_2 := 487617019471545679


func test_known_vectors() -> void:
	var rng := DeterministicRng.new(0)
	assert_eq(rng.next_u64(), VECTOR_0, "splitmix64 seed 0 vector 0")
	assert_eq(rng.next_u64(), VECTOR_1, "splitmix64 seed 0 vector 1")
	assert_eq(rng.next_u64(), VECTOR_2, "splitmix64 seed 0 vector 2")


func test_same_seed_same_sequence() -> void:
	var a := DeterministicRng.new(12345)
	var b := DeterministicRng.new(12345)
	for i in 16:
		assert_eq(a.next_u64(), b.next_u64(), "draw %d matches for same seed" % i)


func test_different_seeds_differ() -> void:
	var a := DeterministicRng.new(1)
	var b := DeterministicRng.new(2)
	var difference_seen := false
	for i in 8:
		if a.next_u64() != b.next_u64():
			difference_seen = true
	assert_true(difference_seen, "different seeds diverge")


func test_bounded_int_and_float() -> void:
	var rng := DeterministicRng.new(7)
	for i in 200:
		var value := rng.next_int(10)
		assert_true(value >= 0 and value < 10, "next_int within [0,10): %d" % value)
	for i in 100:
		var value := rng.next_float()
		assert_true(value >= 0.0 and value < 1.0, "next_float within [0,1): %f" % value)


func test_state_snapshot_restores_sequence() -> void:
	var rng := DeterministicRng.new(42)
	for i in 5:
		rng.next_u64()
	var saved := rng.state()
	var expected: Array[int] = []
	for i in 3:
		expected.append(rng.next_u64())
	rng.set_state(saved)
	for value in expected:
		assert_eq(rng.next_u64(), value, "restored state continues sequence")


func test_named_streams_are_independent() -> void:
	var a := RngStreams.new(7)
	var b := RngStreams.new(7)
	a.stream(RngStreams.STREAM_COMBAT).next_u64()
	a.stream(RngStreams.STREAM_COMBAT).next_u64()
	assert_eq(
		a.stream(RngStreams.STREAM_RUN).next_u64(),
		b.stream(RngStreams.STREAM_RUN).next_u64(),
		"combat consumption does not shift run stream"
	)
	assert_eq(
		a.stream(RngStreams.STREAM_LOOT).next_u64(),
		b.stream(RngStreams.STREAM_LOOT).next_u64(),
		"loot stream unaffected"
	)


func test_streams_snapshot_restore() -> void:
	var streams := RngStreams.new(11)
	streams.stream(RngStreams.STREAM_LOOT).next_u64()
	var snapshot := streams.snapshot()
	var expected := streams.stream(RngStreams.STREAM_LOOT).next_u64()
	streams.restore(snapshot)
	assert_eq(streams.stream(RngStreams.STREAM_LOOT).next_u64(), expected, "stream snapshot restores")
