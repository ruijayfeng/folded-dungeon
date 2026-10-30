class_name Unit
extends RefCounted
## Unit for exploration + M3 combat. Position is split into macro room cell and
## 9x9 micro cell. Stats are plain ints (no RNG); statuses are name -> turns.

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1
const DEFAULT_MOVE_POINTS: int = 4

var unit_id: StringName = &"player"
var display_name: String = ""
var team: int = TEAM_PLAYER
var room_cell: Vector2i = Vector2i(-1, -1)
var local_cell: Vector2i = Vector2i(4, 4)
var move_points: int = DEFAULT_MOVE_POINTS
var max_hp: int = 10
var hp: int = 10
var attack_damage: int = 2
var attack_range: int = 1
var has_acted: bool = false
var alive: bool = true
var statuses: Dictionary = {}   # StringName -> remaining turns


func _init(p_unit_id: StringName = &"player", p_team: int = TEAM_PLAYER) -> void:
	unit_id = p_unit_id
	team = p_team
	display_name = String(p_unit_id)


func reset_move_points(points: int = DEFAULT_MOVE_POINTS) -> void:
	move_points = points


func reset_turn(points: int = DEFAULT_MOVE_POINTS) -> void:
	move_points = maxi(1, points - (1 if has_status(&"chilled") else 0))
	has_acted = false


func can_move() -> bool:
	return alive and move_points > 0


func is_alive() -> bool:
	return alive


func take_damage(amount: int, source: StringName = &"") -> int:
	if not alive or amount <= 0:
		return 0
	var applied := mini(amount, hp)
	hp -= applied
	if hp <= 0:
		hp = 0
		alive = false
	return applied


func heal(amount: int) -> int:
	if not alive or amount <= 0:
		return 0
	var before := hp
	hp = mini(max_hp, hp + amount)
	return hp - before


func add_status(status_name: StringName, turns: int = 1) -> void:
	if status_name == &"":
		return
	statuses[status_name] = maxi(1, turns)


func has_status(status_name: StringName) -> bool:
	return statuses.has(status_name)


func status_turns(status_name: StringName) -> int:
	return int(statuses.get(status_name, 0))


func remove_status(status_name: StringName) -> void:
	statuses.erase(status_name)


func advance_statuses() -> Array[StringName]:
	var expired: Array[StringName] = []
	for status_name in statuses.keys():
		var remaining: int = int(statuses[status_name]) - 1
		if remaining <= 0:
			statuses.erase(status_name)
			expired.append(status_name)
		else:
			statuses[status_name] = remaining
	return expired


func clone() -> Unit:
	var copy := Unit.new(unit_id, team)
	copy.display_name = display_name
	copy.room_cell = room_cell
	copy.local_cell = local_cell
	copy.move_points = move_points
	copy.max_hp = max_hp
	copy.hp = hp
	copy.attack_damage = attack_damage
	copy.attack_range = attack_range
	copy.has_acted = has_acted
	copy.alive = alive
	copy.statuses = statuses.duplicate()
	return copy


func snapshot() -> Dictionary:
	return {
		"id": unit_id,
		"team": team,
		"room": room_cell,
		"cell": local_cell,
		"hp": hp,
		"alive": alive,
		"statuses": statuses.duplicate(),
	}
