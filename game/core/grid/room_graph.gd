class_name RoomGraph
extends RefCounted
## Adjacency graph over placed rooms. Physical edges come from matched door pairs;
## virtual edges are reserved for the fold mechanic (M2-8).

const KIND_PHYSICAL := &"physical"
const KIND_VIRTUAL := &"virtual"

var _edges: Array[Dictionary] = []


func clear() -> void:
	_edges.clear()


func add_edge(a: StringName, b: StringName, kind: StringName = KIND_PHYSICAL, dir: int = 0, anchor: Vector2 = Vector2.ZERO) -> void:
	if a == b:
		return
	_edges.append({"a": a, "b": b, "kind": kind, "dir": dir, "anchor": anchor})


func remove_edge(a: StringName, b: StringName) -> bool:
	for index in range(_edges.size() - 1, -1, -1):
		var edge: Dictionary = _edges[index]
		if (edge["a"] == a and edge["b"] == b) or (edge["a"] == b and edge["b"] == a):
			_edges.remove_at(index)
			return true
	return false


func connect_virtual(a: StringName, b: StringName, label: StringName = &"fold") -> bool:
	if a == b or has_edge(a, b):
		return false
	_edges.append({"a": a, "b": b, "kind": KIND_VIRTUAL, "dir": 0, "anchor": Vector2.ZERO, "label": label})
	return true


func disconnect_virtual(a: StringName, b: StringName) -> bool:
	for index in range(_edges.size() - 1, -1, -1):
		var edge: Dictionary = _edges[index]
		if edge["kind"] != KIND_VIRTUAL:
			continue
		if (edge["a"] == a and edge["b"] == b) or (edge["a"] == b and edge["b"] == a):
			_edges.remove_at(index)
			return true
	return false


func edges() -> Array[Dictionary]:
	return _edges.duplicate(true)


func physical_edges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for edge in _edges:
		if edge["kind"] == KIND_PHYSICAL:
			result.append(edge.duplicate(true))
	return result


func virtual_edges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for edge in _edges:
		if edge["kind"] == KIND_VIRTUAL:
			result.append(edge.duplicate(true))
	return result


func has_edge(a: StringName, b: StringName) -> bool:
	for edge in _edges:
		if (edge["a"] == a and edge["b"] == b) or (edge["a"] == b and edge["b"] == a):
			return true
	return false


func node_ids() -> Array[StringName]:
	var seen := {}
	var result: Array[StringName] = []
	for edge in _edges:
		for node_id in [edge["a"], edge["b"]]:
			if not seen.has(node_id):
				seen[node_id] = true
				result.append(node_id)
	result.sort_custom(_compare_ids)
	return result


func neighbors(node_id: StringName) -> Array[StringName]:
	var seen := {}
	var result: Array[StringName] = []
	for edge in _edges:
		var other: StringName = &""
		if edge["a"] == node_id:
			other = edge["b"]
		elif edge["b"] == node_id:
			other = edge["a"]
		if other != &"" and not seen.has(other):
			seen[other] = true
			result.append(other)
	result.sort_custom(_compare_ids)
	return result


func find_path(from_id: StringName, to_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if from_id == to_id:
		if _has_node(from_id):
			result.append(from_id)
		return result
	var visited := {from_id: true}
	var queue: Array[StringName] = [from_id]
	var previous := {}
	var found := false
	while not queue.is_empty():
		var current: StringName = queue.pop_front()
		for next_id in neighbors(current):
			if visited.has(next_id):
				continue
			visited[next_id] = true
			previous[next_id] = current
			if next_id == to_id:
				found = true
				queue.clear()
				break
			queue.append(next_id)
	if not found:
		return result
	var cursor := to_id
	while cursor != from_id:
		result.push_front(cursor)
		cursor = previous[cursor]
	result.push_front(from_id)
	return result


func is_fully_connected(required: Array[StringName] = []) -> bool:
	var nodes := node_ids()
	if nodes.is_empty():
		return required.is_empty()
	var reachable := _reachable_from(nodes[0])
	for node_id in nodes:
		if not reachable.has(node_id):
			return false
	for node_id in required:
		if not reachable.has(node_id):
			return false
	return true


func _reachable_from(start_id: StringName) -> Dictionary:
	var reachable := {start_id: true}
	var queue: Array[StringName] = [start_id]
	while not queue.is_empty():
		var current: StringName = queue.pop_front()
		for next_id in neighbors(current):
			if reachable.has(next_id):
				continue
			reachable[next_id] = true
			queue.append(next_id)
	return reachable


func _has_node(node_id: StringName) -> bool:
	for edge in _edges:
		if edge["a"] == node_id or edge["b"] == node_id:
			return true
	return false


static func _compare_ids(a: StringName, b: StringName) -> bool:
	return String(a) < String(b)


## Builds a physical-edge graph from a DungeonGrid (used by connectivity checks).
static func from_grid(grid) -> RoomGraph:
	var graph := RoomGraph.new()
	for edge in grid.edges():
		graph.add_edge(edge["a"], edge["b"], KIND_PHYSICAL, int(edge["dir"]), edge["anchor"])
	return graph
