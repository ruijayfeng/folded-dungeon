class_name CombatFx
extends RefCounted
## M6-3: pure mapping from core event logs to presentation FX descriptors.
## No nodes, no state: unit-testable and safe for the presentation layer.

const REACTION_COLORS := {
	&"combustion": Color(1.0, 0.42, 0.12),
	&"thermal_neutralize": Color(0.82, 0.90, 1.0),
	&"charge_release": Color(1.0, 0.86, 0.32),
}

const WAVE_COLORS := {
	&"heat_wave": Color(1.0, 0.40, 0.12),
	&"frost_wave": Color(0.45, 0.78, 1.0),
	&"toxin_wave": Color(0.45, 0.95, 0.35),
	&"charge_wave": Color(1.0, 0.86, 0.32),
	&"airflow_wave": Color(0.82, 0.86, 1.0),
}


static func reaction_color(recipe_id: StringName) -> Color:
	return REACTION_COLORS.get(recipe_id, Color(1.0, 0.70, 0.30))


static func wave_color(wave: StringName) -> Color:
	return WAVE_COLORS.get(wave, Color(1.0, 0.55, 0.20))


static func map_engine_event(event: Dictionary) -> Dictionary:
	var kind := String(event.get("type", ""))
	match kind:
		"wave_emitted":
			return {"kind": "wave", "dir": int(event.get("dir", 0)), "wave": event.get("wave", &""), "cell": event.get("cell", Vector2i.ZERO)}
		"wave_entered":
			return {"kind": "wave_enter", "dir": int(event.get("dir", 0)), "wave": event.get("wave", &""), "cell": event.get("cell", Vector2i.ZERO)}
		"wave_hit":
			return {"kind": "wave_hit", "wave": event.get("wave", &""), "cell": event.get("cell", Vector2i.ZERO)}
		"wave_redirected":
			return {"kind": "wave_redirect", "dir": int(event.get("new_dir", 0)), "wave": event.get("wave", &"")}
		"reaction_triggered":
			var recipe: StringName = event.get("recipe", &"")
			return {"kind": "reaction", "recipe": recipe, "color": reaction_color(recipe), "cell": event.get("cell", Vector2i.ZERO)}
		"room_periodic":
			if String(event.get("event_id", "")) == "turret_fire":
				return {"kind": "turret", "cell": event.get("cell", Vector2i.ZERO)}
			if String(event.get("event_id", "")) == "boss_heat":
				return {"kind": "boss", "cell": event.get("cell", Vector2i.ZERO)}
			return {}
		"channel_changed":
			return {"kind": "channel", "channel": int(event.get("channel", 0)), "cell": event.get("cell", Vector2i.ZERO)}
		_:
			return {}


static func map_combat_event(event: Dictionary) -> Dictionary:
	var kind := String(event.get("type", ""))
	match kind:
		"unit_attacked":
			return {"kind": "hit", "attacker": event.get("attacker", &""), "defender": event.get("defender", &""), "damage": int(event.get("damage", 0))}
		"unit_died":
			return {"kind": "death", "unit": event.get("unit", &""), "team": int(event.get("team", 0))}
		"unit_knockback", "knockback_collision":
			return {"kind": "knockback", "unit": event.get("unit", &"")}
		"turret_hit":
			return {"kind": "hit", "attacker": &"turret", "defender": event.get("unit", &""), "damage": int(event.get("damage", 0))}
		"hazard_damage":
			return {"kind": "hazard", "unit": event.get("unit", &""), "damage": int(event.get("damage", 0))}
		"boss_ability":
			return {"kind": "boss_ability", "unit": event.get("unit", &""), "ability": event.get("ability", &"")}
		"enemy_stunned":
			return {"kind": "stun", "unit": event.get("unit", &"")}
		_:
			return {}
