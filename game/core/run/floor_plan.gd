class_name FloorPlan
extends RefCounted
## Deterministic node structure for one floor: content slots consumed by rooms
## the player builds. The room definition chosen by the player decides the
## spatial rules; the slot decides the encounter/reward content.

enum SlotType { BATTLE, EVENT, BATTLE_ALT, REST, ELITE, SHOP, BOSS }

const SEQUENCE: Array[int] = [
	SlotType.BATTLE,
	SlotType.EVENT,
	SlotType.BATTLE_ALT,
	SlotType.REST,
	SlotType.ELITE,
	SlotType.SHOP,
	SlotType.BOSS,
]

var floor: int = 1
var seed_value: int = 0
var slots: Array[Dictionary] = []


static func generate(seed_value: int, floor_value: int) -> FloorPlan:
	var plan := FloorPlan.new()
	plan.floor = floor_value
	plan.seed_value = seed_value
	for slot_type in SEQUENCE:
		plan.slots.append({"index": plan.slots.size(), "type": slot_type})
	return plan


static func type_name(slot_type: int) -> StringName:
	match slot_type:
		SlotType.BATTLE, SlotType.BATTLE_ALT:
			return &"battle"
		SlotType.EVENT:
			return &"event"
		SlotType.REST:
			return &"rest"
		SlotType.ELITE:
			return &"elite"
		SlotType.SHOP:
			return &"shop"
		SlotType.BOSS:
			return &"boss"
	return &"unknown"


func snapshot() -> Dictionary:
	return {"floor": floor, "slots": slots.duplicate(true)}
