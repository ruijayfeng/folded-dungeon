class_name RuleEngine
extends RefCounted
## Deterministic environment rule pipeline (M2).
##
## turn:
##   1. decrement cooldowns / advance timed states / reset trigger counters
##   2. emitters
##   3. one-hop propagation between door-connected rooms (higher -> lower)
##   4. absorption (e.g. accumulator rooms)
##   5. reaction recipes (priority order, per room in row-major order)
##   6. channel decay
##   7. periodic room events (e.g. ballista every N turns)
##
## All channel values are fixed-point ints in [0, 1000]; comparisons are integer.
## The pipeline is deterministic: sorted room order, fixed channel order, sorted
## recipe order, and a seeded RNG only where content explicitly needs randomness.

const DEFAULT_TRANSFER_PERCENT := {
	Channels.Channel.HEAT: 40,
	Channels.Channel.TOXIN: 50,
	Channels.Channel.COLD: 40,
	Channels.Channel.CHARGE: 50,
	Channels.Channel.AIRFLOW: 25,
}
const DEFAULT_DECAY_PER_TURN := {
	Channels.Channel.HEAT: 0,
	Channels.Channel.TOXIN: 0,
	Channels.Channel.COLD: 0,
	Channels.Channel.CHARGE: 0,
	Channels.Channel.AIRFLOW: 0,
}
## True = transfer conserves the channel (source loses what destination gains).
## Charge is stored energy; heat/toxin/cold/airflow are environmental fields.
const DEFAULT_CONSERVATIVE := {
	Channels.Channel.HEAT: false,
	Channels.Channel.TOXIN: false,
	Channels.Channel.COLD: false,
	Channels.Channel.CHARGE: true,
	Channels.Channel.AIRFLOW: false,
}

var grid: DungeonGrid = null
var recipes: Array[ReactionRecipe] = []
var states: Dictionary = {}        # Vector2i -> RoomState
var events: Array[Dictionary] = []
var turn: int = 0
var channel_params: Dictionary = {}  # channel -> {"transfer_percent": int, "decay_per_turn": int}
var virtual_edges: Array[Dictionary] = []  # [{"a": Vector2i, "b": Vector2i}]
var rng_streams: RngStreams = null

var _edges: Array[Dictionary] = []  # [{"a": Vector2i, "b": Vector2i}]


func setup(p_grid: DungeonGrid, p_recipes: Array[ReactionRecipe], p_virtual_edges: Array = [], seed_value: int = 0) -> void:
	grid = p_grid
	recipes = p_recipes.duplicate()
	recipes.sort_custom(_compare_recipes)
	virtual_edges = _copy_edge_list(p_virtual_edges)
	rng_streams = RngStreams.new(seed_value)
	states.clear()
	events.clear()
	turn = 0
	channel_params.clear()
	for channel in Channels.COUNT:
		channel_params[channel] = {
			"transfer_percent": DEFAULT_TRANSFER_PERCENT[channel],
			"decay_per_turn": DEFAULT_DECAY_PER_TURN[channel],
			"conservative": DEFAULT_CONSERVATIVE[channel],
		}
	_ensure_states()
	_edges = _build_edges()


## Must be called after rooms are placed/removed (M2 build loop).
func sync_rooms() -> void:
	_ensure_states()
	for cell in states.keys():
		if grid.get_room(cell) == null:
			states.erase(cell)
	_edges = _build_edges()


func set_channel_params(channel: int, transfer_percent: int, decay_per_turn: int, conservative: bool = false) -> void:
	if not Channels.is_valid(channel):
		return
	channel_params[channel] = {
		"transfer_percent": clampi(transfer_percent, 0, 300),
		"decay_per_turn": clampi(decay_per_turn, 0, Channels.MAX_VALUE),
		"conservative": conservative,
	}


func room_state(cell: Vector2i) -> RoomState:
	return states.get(cell, null)


func get_channel(cell: Vector2i, channel: int) -> int:
	var state := room_state(cell)
	if state == null:
		return 0
	return state.get_channel(channel)


func set_channel(cell: Vector2i, channel: int, value: int) -> void:
	var state := room_state(cell)
	if state != null:
		state.set_channel(channel, value)


func add_channel(cell: Vector2i, channel: int, delta: int) -> int:
	var state := room_state(cell)
	if state == null:
		return 0
	return state.add_channel(channel, delta)


func tick() -> Array[Dictionary]:
	var turn_events: Array[Dictionary] = []
	if grid == null:
		return turn_events
	turn += 1
	_begin_turn(turn_events)
	_apply_emitters(turn_events)
	_propagate(turn_events)
	_absorb(turn_events)
	_resolve_reactions(turn_events)
	_apply_decay(turn_events)
	_apply_periodic(turn_events)
	events.append_array(turn_events)
	return turn_events


func preview_turns(turns: int) -> Dictionary:
	var copy := clone_for_preview()
	var preview_events: Array[Dictionary] = []
	for i in turns:
		preview_events.append_array(copy.tick())
	return {"turns": turns, "events": preview_events, "state": copy.snapshot()}


func clone_for_preview() -> RuleEngine:
	var copy := RuleEngine.new()
	copy.grid = grid
	copy.recipes = recipes
	copy.channel_params = channel_params.duplicate(true)
	copy.virtual_edges = _copy_edge_list(virtual_edges)
	copy._edges = _copy_edge_list(_edges)
	copy.turn = turn
	copy.events = events.duplicate(true)
	if rng_streams != null:
		var rng_snapshot := rng_streams.snapshot()
		copy.rng_streams = RngStreams.new(0)
		copy.rng_streams.restore(rng_snapshot)
	for cell in states:
		copy.states[cell] = states[cell].clone()
	return copy


func snapshot() -> Dictionary:
	var rooms: Array[Dictionary] = []
	for cell in _sorted_state_cells():
		var state: RoomState = states[cell]
		rooms.append({
			"cell": [cell.x, cell.y],
			"channels": state.channel_snapshot(),
			"states": state.states.duplicate(),
		})
	return {"turn": turn, "rooms": rooms, "event_count": events.size()}


func restore_snapshot(data: Dictionary) -> void:
	turn = int(data.get("turn", 0))
	var room_entries: Array = data.get("rooms", [])
	for entry in room_entries:
		if not (entry is Dictionary):
			continue
		var cell_array: Array = entry.get("cell", [])
		if cell_array.size() != 2:
			continue
		var cell := Vector2i(int(cell_array[0]), int(cell_array[1]))
		var state: RoomState = states.get(cell, null)
		if state == null:
			continue
		var channels: Array = entry.get("channels", [])
		for index in mini(channels.size(), Channels.COUNT):
			state.set_channel(index, int(channels[index]))
		state.states.clear()
		var saved_states: Dictionary = entry.get("states", {})
		for state_name in saved_states:
			state.states[state_name] = int(saved_states[state_name])


static func load_recipe_library(path: String = "res://data/recipes/") -> Array[ReactionRecipe]:
	var result: Array[ReactionRecipe] = []
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("RuleEngine.load_recipe_library: cannot open %s" % path)
		return result
	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for recipe_file in files:
		var loaded := load(path + recipe_file)
		if loaded is ReactionRecipe:
			result.append(loaded)
		else:
			push_warning("RuleEngine.load_recipe_library: %s is not a ReactionRecipe" % recipe_file)
	return result


# --- pipeline phases -------------------------------------------------------

func _begin_turn(turn_events: Array[Dictionary]) -> void:
	for cell in _sorted_state_cells():
		var state: RoomState = states[cell]
		state.triggers_this_turn = 0
		state.recipe_triggers.clear()
		for recipe_id in state.cooldowns.keys():
			var remaining: int = state.cooldowns[recipe_id]
			if remaining > 0:
				state.cooldowns[recipe_id] = remaining - 1
		var expired := state.advance_states()
		for state_name in expired:
			_emit(turn_events, &"state_expired", {"room": state.instance_id, "state": state_name, "cell": cell})


func _apply_emitters(turn_events: Array[Dictionary]) -> void:
	for cell in _sorted_state_cells():
		var state: RoomState = states[cell]
		var room := grid.get_room(cell)
		if room == null or room.definition == null:
			continue
		for emitter in room.definition.emitters:
			if emitter == null:
				continue
			var applied := state.add_channel(emitter.channel, emitter.rate_per_turn, emitter.max_value)
			if applied != 0:
				_emit(turn_events, &"channel_emitted", {
					"room": state.instance_id,
					"cell": cell,
					"channel": emitter.channel,
					"delta": applied,
				})


## One hop per turn. Direction: hotter -> colder. Amount = source * percent.
func _propagate(turn_events: Array[Dictionary]) -> void:
	for channel in Channels.COUNT:
		var transfers: Array[Dictionary] = []
		for edge in _edges:
			var a: Vector2i = edge["a"]
			var b: Vector2i = edge["b"]
			if not states.has(a) or not states.has(b):
				continue
			var a_value: int = states[a].get_channel(channel)
			var b_value: int = states[b].get_channel(channel)
			if a_value == b_value:
				continue
			var source_cell := a if a_value > b_value else b
			var dest_cell := b if a_value > b_value else a
			var source_value := maxi(a_value, b_value)
			var percent := _effective_transfer_percent(source_cell, channel)
			var amount := int(floor(float(source_value) * float(percent) / 100.0))
			if amount <= 0:
				continue
			transfers.append({"from": source_cell, "to": dest_cell, "channel": channel, "amount": amount})
		for transfer in transfers:
			var dest_state: RoomState = states[transfer["to"]]
			var applied: int = dest_state.add_channel(transfer["channel"], transfer["amount"])
			if applied == 0:
				continue
			if bool(channel_params[transfer["channel"]].get("conservative", false)):
				var source_state: RoomState = states[transfer["from"]]
				source_state.add_channel(transfer["channel"], -applied)
			_emit(turn_events, &"channel_transferred", {
				"from": states[transfer["from"]].instance_id,
				"to": dest_state.instance_id,
				"from_cell": transfer["from"],
				"to_cell": transfer["to"],
				"channel": transfer["channel"],
				"amount": applied,
			})


func _absorb(turn_events: Array[Dictionary]) -> void:
	for cell in _sorted_state_cells():
		var room := grid.get_room(cell)
		if room == null or room.definition == null:
			continue
		var channel := room.definition.absorb_channel
		if channel < 0 or room.definition.absorb_percent <= 0:
			continue
		var state: RoomState = states[cell]
		for neighbor_cell in _neighbor_cells(cell):
			var neighbor: RoomState = states.get(neighbor_cell, null)
			if neighbor == null:
				continue
			var offered := int(floor(float(neighbor.get_channel(channel)) * float(room.definition.absorb_percent) / 100.0))
			if offered <= 0:
				continue
			var taken: int = neighbor.add_channel(channel, -offered)
			var stored: int = state.add_channel(channel, -taken)
			if stored != 0:
				_emit(turn_events, &"channel_absorbed", {
					"room": state.instance_id,
					"from": neighbor.instance_id,
					"channel": channel,
					"amount": stored,
				})


func _resolve_reactions(turn_events: Array[Dictionary]) -> void:
	for cell in _sorted_state_cells():
		var state: RoomState = states[cell]
		for recipe in recipes:
			if recipe == null:
				continue
			if int(state.recipe_triggers.get(recipe.id, 0)) >= recipe.max_triggers_per_turn:
				continue
			if int(state.cooldowns.get(recipe.id, 0)) > 0:
				continue
			if not _conditions_met(cell, recipe):
				continue
			_emit(turn_events, &"reaction_triggered", {
				"recipe": recipe.id,
				"event_id": recipe.event_id,
				"room": state.instance_id,
				"cell": cell,
				"channels_before": state.channel_snapshot(),
				"states_before": state.states.duplicate(),
			})
			for effect in recipe.effects:
				_execute_effect(cell, recipe, effect, turn_events)
			state.triggers_this_turn += 1
			state.recipe_triggers[recipe.id] = int(state.recipe_triggers.get(recipe.id, 0)) + 1
			if recipe.cooldown_turns > 0:
				state.cooldowns[recipe.id] = recipe.cooldown_turns + 1


func _execute_effect(cell: Vector2i, recipe: ReactionRecipe, effect: EffectDef, turn_events: Array[Dictionary]) -> void:
	if effect == null:
		return
	var state: RoomState = states[cell]
	match effect.kind:
		EffectDef.Kind.ADD_CHANNEL:
			var applied := state.add_channel(effect.channel, effect.amount)
			_emit(turn_events, &"channel_changed", {
				"room": state.instance_id,
				"cell": cell,
				"channel": effect.channel,
				"delta": applied,
				"source": recipe.id,
			})
		EffectDef.Kind.ADD_CHANNEL_TO_NEIGHBORS:
			for neighbor_cell in _neighbor_cells(cell):
				var neighbor: RoomState = states.get(neighbor_cell, null)
				if neighbor == null:
					continue
				var applied: int = neighbor.add_channel(effect.channel, effect.amount)
				if applied != 0:
					_emit(turn_events, &"channel_changed", {
						"room": neighbor.instance_id,
						"cell": neighbor_cell,
						"channel": effect.channel,
						"delta": applied,
						"source": recipe.id,
					})
		EffectDef.Kind.SET_STATE:
			state.set_state(effect.state_name, effect.duration_turns)
			_emit(turn_events, &"state_set", {"room": state.instance_id, "state": effect.state_name, "duration": effect.duration_turns})
		EffectDef.Kind.CLEAR_STATE:
			state.clear_state(effect.state_name)
			_emit(turn_events, &"state_cleared", {"room": state.instance_id, "state": effect.state_name})
		EffectDef.Kind.EMIT_WAVE:
			_resolve_wave(cell, effect, turn_events)
		EffectDef.Kind.EMIT_EVENT:
			_emit(turn_events, effect.event_id, {"room": state.instance_id, "cell": cell, "source": recipe.id})


func _apply_decay(turn_events: Array[Dictionary]) -> void:
	for cell in _sorted_state_cells():
		var state: RoomState = states[cell]
		for channel in Channels.COUNT:
			var decay: int = int(channel_params[channel]["decay_per_turn"])
			if decay <= 0:
				continue
			var applied := state.add_channel(channel, -decay)
			if applied != 0:
				_emit(turn_events, &"channel_decayed", {"room": state.instance_id, "channel": channel, "delta": applied})


func _apply_periodic(turn_events: Array[Dictionary]) -> void:
	for cell in _sorted_state_cells():
		var room := grid.get_room(cell)
		if room == null or room.definition == null:
			continue
		var period := room.definition.periodic_turns
		if period <= 0 or turn % period != 0:
			continue
		_emit(turn_events, &"room_periodic", {
			"room": room.instance_id,
			"cell": cell,
			"event_id": room.definition.periodic_event,
			"turn": turn,
		})


# --- waves ------------------------------------------------------------------

func _resolve_wave(origin_cell: Vector2i, effect: EffectDef, turn_events: Array[Dictionary]) -> void:
	var room := grid.get_room(origin_cell)
	if room == null:
		return
	var dir := effect.direction
	if not DoorSpec.is_door_dir(dir) or not room.has_door(dir):
		dir = _first_door_dir(room)
	if dir == 0:
		return
	_emit(turn_events, &"wave_emitted", {
		"wave": effect.wave_tag,
		"room": room.instance_id,
		"cell": origin_cell,
		"dir": dir,
	})
	var current := room
	for _step in effect.max_steps:
		if not current.has_door(dir):
			break
		var next_cell := current.cell + DoorSpec.delta(dir)
		var next_room := grid.get_room(next_cell)
		if next_room == null:
			break
		current = next_room
		_emit(turn_events, &"wave_entered", {
			"wave": effect.wave_tag,
			"room": current.instance_id,
			"cell": next_cell,
			"dir": dir,
		})
		_emit(turn_events, &"wave_hit", {
			"wave": effect.wave_tag,
			"room": current.instance_id,
			"cell": next_cell,
		})
		var redirect := current.definition.wave_redirect_steps
		if redirect != 0:
			dir = DoorSpec.rotate_dir(dir, redirect)
			_emit(turn_events, &"wave_redirected", {
				"wave": effect.wave_tag,
				"room": current.instance_id,
				"new_dir": dir,
			})


# --- helpers ----------------------------------------------------------------

func _conditions_met(cell: Vector2i, recipe: ReactionRecipe) -> bool:
	for condition in recipe.conditions:
		if condition == null:
			return false
		if condition.scope == ConditionDef.Scope.SELF:
			if not _condition_matches(cell, condition):
				return false
		else:
			var any_neighbor := false
			for neighbor_cell in _neighbor_cells(cell):
				if _condition_matches(neighbor_cell, condition):
					any_neighbor = true
					break
			if not any_neighbor:
				return false
	return true


func _condition_matches(cell: Vector2i, condition: ConditionDef) -> bool:
	var state: RoomState = states.get(cell, null)
	var room := grid.get_room(cell)
	if state == null or room == null:
		return false
	match condition.kind:
		ConditionDef.Kind.CHANNEL_AT_LEAST:
			return state.get_channel(condition.channel) >= condition.threshold
		ConditionDef.Kind.CHANNEL_AT_MOST:
			return state.get_channel(condition.channel) <= condition.threshold
		ConditionDef.Kind.HAS_TAG:
			return room.definition.tags.has(condition.tag)
		ConditionDef.Kind.HAS_STATE:
			return state.has_state(condition.state_name)
	return false


func _effective_transfer_percent(source_cell: Vector2i, channel: int) -> int:
	var base: int = int(channel_params[channel]["transfer_percent"])
	var room := grid.get_room(source_cell)
	if room != null and room.definition != null:
		base = (base * room.definition.transfer_percent) / 100
	return clampi(base, 0, 300)


func _first_door_dir(room: RoomInstance) -> int:
	for dir in DoorSpec.all_dirs():
		if room.has_door(dir):
			return dir
	return 0


func _neighbor_cells(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for edge in _edges:
		if edge["a"] == cell:
			result.append(edge["b"])
		elif edge["b"] == cell:
			result.append(edge["a"])
	result.sort_custom(_compare_cells)
	return result


func _ensure_states() -> void:
	for cell in grid.sorted_cells():
		if states.has(cell):
			continue
		var room := grid.get_room(cell)
		if room != null:
			states[cell] = RoomState.new(room.instance_id, cell)


static func _copy_edge_list(source: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for edge in source:
		if edge is Dictionary:
			result.append(edge.duplicate(true))
	return result


func _build_edges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	for edge in grid.edges():
		var cells: Array = edge["cells"]
		_append_edge(result, seen, cells[0], cells[1])
	for edge in virtual_edges:
		var a: Vector2i = edge.get("a", Vector2i(-1, -1))
		var b: Vector2i = edge.get("b", Vector2i(-1, -1))
		if grid.get_room(a) != null and grid.get_room(b) != null:
			_append_edge(result, seen, a, b)
	return result


func _append_edge(result: Array[Dictionary], seen: Dictionary, a: Vector2i, b: Vector2i) -> void:
	if a == b:
		return
	var first := a
	var second := b
	if _compare_cells(b, a):
		first = b
		second = a
	var key := "%s|%s" % [str(first), str(second)]
	if seen.has(key):
		return
	seen[key] = true
	result.append({"a": first, "b": second})


func _sorted_state_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in states:
		cells.append(cell)
	cells.sort_custom(_compare_cells)
	return cells


func _emit(turn_events: Array[Dictionary], event_type: StringName, data: Dictionary) -> void:
	var event := {"type": event_type, "turn": turn}
	for key in data:
		event[key] = data[key]
	turn_events.append(event)


static func _compare_cells(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	return a.x < b.x


static func _compare_recipes(a: ReactionRecipe, b: ReactionRecipe) -> bool:
	if a.priority != b.priority:
		return a.priority < b.priority
	return String(a.id) < String(b.id)
