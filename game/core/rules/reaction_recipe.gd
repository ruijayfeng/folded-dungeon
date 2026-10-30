class_name ReactionRecipe
extends Resource
## Data-driven room reaction: conditions (AND) + effects, no hardcoded room IDs.

@export var id: StringName = &""
@export var display_name: String = ""
@export var priority: int = 0
@export var cooldown_turns: int = 0
@export var max_triggers_per_turn: int = 1
@export var event_id: StringName = &""
@export var conditions: Array[ConditionDef] = []
@export var effects: Array[EffectDef] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty():
		errors.append("RECIPE_ID_EMPTY")
	if conditions.is_empty():
		errors.append("RECIPE_CONDITIONS_EMPTY")
	if effects.is_empty():
		errors.append("RECIPE_EFFECTS_EMPTY")
	if cooldown_turns < 0:
		errors.append("RECIPE_COOLDOWN_NEGATIVE")
	if max_triggers_per_turn <= 0:
		errors.append("RECIPE_TRIGGERS_INVALID")
	for condition in conditions:
		if condition == null:
			errors.append("RECIPE_CONDITION_NULL")
			continue
		for condition_error in condition.validate():
			errors.append("RECIPE_CONDITION_INVALID: %s" % condition_error)
	for effect in effects:
		if effect == null:
			errors.append("RECIPE_EFFECT_NULL")
			continue
		for effect_error in effect.validate():
			errors.append("RECIPE_EFFECT_INVALID: %s" % effect_error)
	return errors
