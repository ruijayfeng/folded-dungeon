class_name RngStreams
extends RefCounted
## Named deterministic RNG streams derived from one run seed.
## Domains are separated (run/floor/combat/loot) so consuming one stream
## cannot shift the sequence of another.

const STREAM_RUN := &"run"
const STREAM_FLOOR := &"floor"
const STREAM_COMBAT := &"combat"
const STREAM_LOOT := &"loot"
const STREAM_NAMES: Array[StringName] = [STREAM_RUN, STREAM_FLOOR, STREAM_COMBAT, STREAM_LOOT]

var _master: DeterministicRng = null
var _streams: Dictionary = {}


func _init(run_seed: int = 0) -> void:
	_master = DeterministicRng.new(run_seed)
	for stream_name in STREAM_NAMES:
		_streams[stream_name] = DeterministicRng.new(_master.next_u64())


func stream(stream_name: StringName) -> DeterministicRng:
	if not _streams.has(stream_name):
		push_error("RngStreams.stream: unknown stream '%s'" % stream_name)
		return null
	return _streams[stream_name]


func master_state() -> int:
	return _master.state()


## Snapshot/restore keeps determinism across save/load and golden replays.
func snapshot() -> Dictionary:
	var result := {"master": _master.state(), "streams": {}}
	for stream_name in STREAM_NAMES:
		result["streams"][String(stream_name)] = _streams[stream_name].state()
	return result


func restore(data: Dictionary) -> void:
	_master.set_state(int(data.get("master", 0)))
	var stored: Dictionary = data.get("streams", {})
	for stream_name in STREAM_NAMES:
		_streams[stream_name].set_state(int(stored.get(String(stream_name), 0)))
