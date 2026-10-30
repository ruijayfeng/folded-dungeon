class_name DeterministicRng
extends RefCounted
## Deterministic SplitMix64 stream (algorithm/constants are a replay contract).
## GDScript ints are signed 64-bit and overflow wraps, so the unsigned constants
## are written as signed literals and unsigned right shifts use _lsr() masks.
## Reference: Steele/Lea/Flood SplitMix64; vector checked against a Python model.
## Ported in spirit from wooftactics/Tactics.Core/Randomness/DeterministicRandom.cs (Apache-2.0).

const ALGORITHM_ID := "splitmix64-v1"
const C1: int = -7046029254386353131  # 0x9E3779B97F4A7C15
const C2: int = -4658895280553007687  # 0xBF58476D1CE4E5B9
const C3: int = -7723592293110705685  # 0x94D049BB133111EB

var _state: int = 0


func _init(seed_value: int = 0) -> void:
	_state = seed_value


func state() -> int:
	return _state


func set_state(value: int) -> void:
	_state = value


static func _lsr(value: int, bits: int) -> int:
	match bits:
		30:
			return (value >> 30) & ((1 << 34) - 1)
		27:
			return (value >> 27) & ((1 << 37) - 1)
		31:
			return (value >> 31) & ((1 << 33) - 1)
	push_error("DeterministicRng._lsr: unsupported shift %d" % bits)
	return 0


func next_u64() -> int:
	_state = _state + C1
	var z := _state
	z = (z ^ _lsr(z, 30)) * C2
	z = (z ^ _lsr(z, 27)) * C3
	return z ^ _lsr(z, 31)


## Uniform-ish bounded integer. Uses modulo on the unsigned representation.
## Good enough for gameplay RNG; determinism is the hard requirement here.
func next_int(exclusive_upper_bound: int) -> int:
	if exclusive_upper_bound <= 0:
		push_error("DeterministicRng.next_int: upper bound must be positive")
		return 0
	var remainder := next_u64() % exclusive_upper_bound
	if remainder < 0:
		remainder += exclusive_upper_bound
	return remainder


## Returns a float in [0, 1) built from the top 53 bits.
func next_float() -> float:
	var top := (next_u64() >> 11) & ((1 << 53) - 1)
	return float(top) / 9007199254740992.0  # 2^53


func next_range(min_value: int, max_value: int) -> int:
	if max_value < min_value:
		var tmp := min_value
		min_value = max_value
		max_value = tmp
	if min_value == max_value:
		return min_value
	return min_value + next_int(max_value - min_value + 1)
