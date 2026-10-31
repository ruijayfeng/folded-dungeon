class_name RoomTheme
extends RefCounted
## M6-2: presentation-side visual theme per RoomDef.id.
## Colors/decor only; never read or written by the simulation.

const THEMES := {
	&"start_room": {"tint": Color(0.90, 0.84, 0.74), "accent": Color(1.0, 0.62, 0.28), "decor": &"camp", "label": "起始房间"},
	&"combat_room": {"tint": Color(0.86, 0.80, 0.72), "accent": Color(0.85, 0.32, 0.22), "decor": &"battle", "label": "战斗房间"},
	&"corridor_room": {"tint": Color(0.72, 0.70, 0.68), "accent": Color(0.65, 0.60, 0.50), "decor": &"corridor", "label": "走廊房"},
	&"toxin_room": {"tint": Color(0.68, 0.78, 0.62), "accent": Color(0.45, 0.95, 0.35), "decor": &"toxin", "label": "毒雾房"},
	&"forge_room": {"tint": Color(0.94, 0.72, 0.55), "accent": Color(1.0, 0.42, 0.16), "decor": &"forge", "label": "熔炉房"},
	&"frost_room": {"tint": Color(0.70, 0.80, 0.92), "accent": Color(0.45, 0.78, 1.0), "decor": &"frost", "label": "冰霜房"},
	&"storm_room": {"tint": Color(0.80, 0.78, 0.88), "accent": Color(1.0, 0.86, 0.35), "decor": &"storm", "label": "风暴房"},
	&"accumulator_room": {"tint": Color(0.92, 0.80, 0.62), "accent": Color(1.0, 0.74, 0.28), "decor": &"accumulator", "label": "蓄能房"},
	&"conduit_room": {"tint": Color(0.72, 0.80, 0.86), "accent": Color(0.40, 0.82, 1.0), "decor": &"conduit", "label": "导管房"},
	&"mirror_room": {"tint": Color(0.78, 0.82, 0.90), "accent": Color(0.80, 0.92, 1.0), "decor": &"mirror", "label": "镜面房"},
	&"echo_room": {"tint": Color(0.74, 0.70, 0.86), "accent": Color(0.72, 0.45, 1.0), "decor": &"echo", "label": "回声房"},
	&"gravity_room": {"tint": Color(0.72, 0.72, 0.80), "accent": Color(0.60, 0.52, 1.0), "decor": &"gravity", "label": "重力房"},
	&"fold_room": {"tint": Color(0.70, 0.78, 0.86), "accent": Color(0.35, 0.65, 1.0), "decor": &"fold", "label": "折叠房"},
	&"vault_room": {"tint": Color(0.94, 0.84, 0.58), "accent": Color(1.0, 0.80, 0.32), "decor": &"vault", "label": "宝库房"},
	&"ballista_room": {"tint": Color(0.78, 0.74, 0.68), "accent": Color(0.85, 0.62, 0.32), "decor": &"ballista", "label": "箭塔房"},
	&"boss_room": {"tint": Color(0.86, 0.66, 0.60), "accent": Color(0.95, 0.22, 0.18), "decor": &"boss", "label": "Boss 房间"},
}


static func for_id(room_id: StringName) -> Dictionary:
	if THEMES.has(room_id):
		return THEMES[room_id]
	return {"tint": Color(0.90, 0.84, 0.74), "accent": Color(1.0, 0.62, 0.28), "decor": &"camp", "label": String(room_id)}


static func tint_for(room_id: StringName) -> Color:
	return for_id(room_id).get("tint", Color.WHITE)


static func accent_for(room_id: StringName) -> Color:
	return for_id(room_id).get("accent", Color(1.0, 0.62, 0.28))
