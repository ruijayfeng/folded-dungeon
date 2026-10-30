extends SceneTree
## Generates data-driven content through ResourceSaver (never hand-edit .tres).
## Run with: game/tools/godot gen-data
##
## M0: start_room / combat_room
## M2: 6 rule rooms + 3 reaction recipes

const ROOM_PATHS := {
	"start_room": "res://data/rooms/start_room.tres",
	"combat_room": "res://data/rooms/combat_room.tres",
	"forge_room": "res://data/rooms/forge_room.tres",
	"toxin_room": "res://data/rooms/toxin_room.tres",
	"frost_room": "res://data/rooms/frost_room.tres",
	"mirror_room": "res://data/rooms/mirror_room.tres",
	"accumulator_room": "res://data/rooms/accumulator_room.tres",
	"ballista_room": "res://data/rooms/ballista_room.tres",
	"boss_room": "res://data/rooms/boss_room.tres",
	"corridor_room": "res://data/rooms/corridor_room.tres",
	"storm_room": "res://data/rooms/storm_room.tres",
	"gravity_room": "res://data/rooms/gravity_room.tres",
	"echo_room": "res://data/rooms/echo_room.tres",
	"conduit_room": "res://data/rooms/conduit_room.tres",
	"vault_room": "res://data/rooms/vault_room.tres",
	"fold_room": "res://data/rooms/fold_room.tres",

}
const RECIPE_PATHS := {
	"combustion": "res://data/recipes/combustion.tres",
	"thermal_neutralize": "res://data/recipes/thermal_neutralize.tres",
	"charge_release": "res://data/recipes/charge_release.tres",
}


func _initialize() -> void:
	var errors := 0
	errors += _save_room(_make_start_room(), ROOM_PATHS["start_room"])
	errors += _save_room(_make_combat_room(), ROOM_PATHS["combat_room"])
	errors += _save_room(_make_forge_room(), ROOM_PATHS["forge_room"])
	errors += _save_room(_make_toxin_room(), ROOM_PATHS["toxin_room"])
	errors += _save_room(_make_frost_room(), ROOM_PATHS["frost_room"])
	errors += _save_room(_make_mirror_room(), ROOM_PATHS["mirror_room"])
	errors += _save_room(_make_accumulator_room(), ROOM_PATHS["accumulator_room"])
	errors += _save_room(_make_ballista_room(), ROOM_PATHS["ballista_room"])
	errors += _save_room(_make_boss_room(), ROOM_PATHS["boss_room"])
	errors += _save_room(_make_corridor_room(), ROOM_PATHS["corridor_room"])
	errors += _save_room(_make_storm_room(), ROOM_PATHS["storm_room"])
	errors += _save_room(_make_gravity_room(), ROOM_PATHS["gravity_room"])
	errors += _save_room(_make_echo_room(), ROOM_PATHS["echo_room"])
	errors += _save_room(_make_conduit_room(), ROOM_PATHS["conduit_room"])
	errors += _save_room(_make_vault_room(), ROOM_PATHS["vault_room"])
	errors += _save_room(_make_fold_room(), ROOM_PATHS["fold_room"])
	errors += _save_resource(_make_combustion_recipe(), RECIPE_PATHS["combustion"])
	errors += _save_resource(_make_thermal_neutralize_recipe(), RECIPE_PATHS["thermal_neutralize"])
	errors += _save_resource(_make_charge_release_recipe(), RECIPE_PATHS["charge_release"])
	if errors > 0:
		push_error("content generation failed: %d error(s)" % errors)
		quit(1)
		return
	print("[M2] content generated: %d rooms, %d recipes" % [ROOM_PATHS.size(), RECIPE_PATHS.size()])
	quit(0)


# --- rooms -----------------------------------------------------------------

func _make_base_layout() -> RoomLayout:
	var layout := RoomLayout.new()
	layout.size = Vector2i(DoorSpec.ROOM_SIZE, DoorSpec.ROOM_SIZE)
	layout.terrain = RoomLayout.make_border_terrain()
	var spawns: Array[Vector2i] = [Vector2i(4, 4)]
	layout.spawn_cells = spawns
	layout.fill_derived_door_data()
	return layout


func _basic_room(room_id: StringName, display_name: String, category: int, door_mask: int, build_cost: int) -> RoomDef:
	var def := RoomDef.new()
	def.id = room_id
	def.display_name = display_name
	def.category = category
	def.door_mask = door_mask
	def.build_cost = build_cost
	def.layout = _make_base_layout()
	return def


func _make_start_room() -> RoomDef:
	var def := _basic_room(&"start_room", "起始房间", RoomDef.Category.SPECIAL, DoorSpec.Dir.N | DoorSpec.Dir.E, 0)
	def.tags = _tags([&"start"])
	def.description = "玩家进入本层的位置；带北门与东门。"
	return def


func _make_combat_room() -> RoomDef:
	var def := _basic_room(&"combat_room", "战斗房间", RoomDef.Category.COMBAT, 15, 1)
	def.tags = _tags([&"combat"])
	def.description = "普通战斗房间；四面均有门，便于构筑连接。"
	return def


func _make_forge_room() -> RoomDef:
	var def := _basic_room(&"forge_room", "熔炉房", RoomDef.Category.ELEMENT, DoorSpec.Dir.E, 1)
	def.tags = _tags([&"heat_source"])
	def.emitters = _emitters([_emitter(Channels.Channel.HEAT, 250)])
	def.description = "每回合积累热量（+250）；热量沿门向较冷的相邻房间传导。"
	return def


func _make_toxin_room() -> RoomDef:
	var def := _basic_room(&"toxin_room", "毒雾房", RoomDef.Category.ELEMENT, DoorSpec.Dir.W | DoorSpec.Dir.E, 1)
	def.tags = _tags([&"gas_source", &"flammable"])
	def.emitters = _emitters([_emitter(Channels.Channel.TOXIN, 200)])
	def.description = "每回合产生毒雾（+200）；与高温叠加会触发爆燃。"
	return def


func _make_frost_room() -> RoomDef:
	var def := _basic_room(&"frost_room", "冰霜房", RoomDef.Category.ELEMENT, 15, 1)
	def.tags = _tags([&"cold_source"])
	def.emitters = _emitters([_emitter(Channels.Channel.COLD, 200)])
	def.description = "每回合积累寒冷（+200）；与热量相消（热/冷各 -200）。"
	return def


func _make_mirror_room() -> RoomDef:
	var def := _basic_room(&"mirror_room", "镜面房", RoomDef.Category.CONVERSION, DoorSpec.Dir.W | DoorSpec.Dir.S, 1)
	def.tags = _tags([&"mirror"])
	def.wave_redirect_steps = 1
	def.description = "进入本房间的波/射束顺时针转向 90° 后继续传播。"
	return def


func _make_accumulator_room() -> RoomDef:
	var def := _basic_room(&"accumulator_room", "蓄能房", RoomDef.Category.TRANSFER, 15, 1)
	def.tags = _tags([&"charge_storage"])
	def.absorb_channel = Channels.Channel.CHARGE
	def.absorb_percent = 50
	def.description = "每回合吸收相邻房间 50% 的能量；能量达到 600 时释放（各相邻 +100）。"
	return def


func _make_storm_room() -> RoomDef:
	var def := _basic_room(&"storm_room", "风暴房", RoomDef.Category.ELEMENT, 15, 1)
	def.tags = _tags([&"wind_source"])
	def.emitters = _emitters([_emitter(Channels.Channel.AIRFLOW, 200)])
	def.description = "每回合产生气流（+200）；气流会把毒雾/火焰/投射物吹向相邻房间。"
	return def


func _make_gravity_room() -> RoomDef:
	var def := _basic_room(&"gravity_room", "重力房", RoomDef.Category.CONVERSION, 15, 1)
	def.tags = _tags([&"gravity"])
	def.gravity_dir = DoorSpec.Dir.S
	def.description = "房间内重力朝南：击退方向改为正南（战斗中生效）。"
	return def


func _make_echo_room() -> RoomDef:
	var def := _basic_room(&"echo_room", "回声房", RoomDef.Category.SPECIAL, 15, 1)
	def.tags = _tags([&"echo"])
	def.periodic_turns = 2
	def.periodic_event = &"echo_pulse"
	def.description = "每 2 回合产生一次回声脉冲事件（重复房间行动的效果待后续扩展）。"
	return def


func _make_conduit_room() -> RoomDef:
	var def := _basic_room(&"conduit_room", "导管房", RoomDef.Category.TRANSFER, DoorSpec.Dir.W | DoorSpec.Dir.E, 1)
	def.tags = _tags([&"conduit"])
	def.transfer_percent = 150
	def.description = "沿东西方向定向传导，传导效率 150%。"
	return def


func _make_vault_room() -> RoomDef:
	var def := _basic_room(&"vault_room", "宝库房", RoomDef.Category.RESOURCE, 15, 1)
	def.tags = _tags([&"vault"])
	def.description = "建成时立即获得 25 金币（单局经济来源）。"
	return def


func _make_fold_room() -> RoomDef:
	var def := _basic_room(&"fold_room", "折叠房", RoomDef.Category.SPECIAL, 15, 2)
	def.tags = _tags([&"fold_chamber"])
	def.description = "建成后获得 1 次折叠充能（M2 虚拟传导边；折叠移动待扩展）。"
	return def


func _make_corridor_room() -> RoomDef:
	var def := _basic_room(&"corridor_room", "走廊房", RoomDef.Category.TRANSFER, DoorSpec.Dir.N, 1)
	def.description = "只有一扇门的紧凑房间；用于在不规则布局中灵活连接。"
	return def


func _make_boss_room() -> RoomDef:
	var def := _basic_room(&"boss_room", "Boss 房间", RoomDef.Category.SPECIAL, 15, 2)
	def.tags = _tags([&"boss"])
	def.description = "本层最终挑战房间；Boss 会持续向房间注入热量。"
	return def


func _make_ballista_room() -> RoomDef:
	var def := _basic_room(&"ballista_room", "箭塔房", RoomDef.Category.COMBAT, DoorSpec.Dir.N | DoorSpec.Dir.E, 1)
	def.tags = _tags([&"turret"])
	def.periodic_turns = 2
	def.periodic_event = &"turret_fire"
	def.description = "每 2 回合向朝向方向发射一次投射物（M3 接入弹道）。"
	return def


# --- recipes ---------------------------------------------------------------

func _make_combustion_recipe() -> ReactionRecipe:
	var recipe := ReactionRecipe.new()
	recipe.id = &"combustion"
	recipe.display_name = "爆燃"
	recipe.priority = 20
	recipe.cooldown_turns = 1
	recipe.max_triggers_per_turn = 1
	recipe.event_id = &"combustion"
	var conditions: Array[ConditionDef] = [
		_tag_condition(&"gas_source"),
		_condition(ConditionDef.Kind.CHANNEL_AT_LEAST, Channels.Channel.HEAT, Channels.HEAT_THRESHOLD),
		_condition(ConditionDef.Kind.CHANNEL_AT_LEAST, Channels.Channel.TOXIN, Channels.TOXIN_THRESHOLD),
	]
	recipe.conditions = conditions
	var effects: Array[EffectDef] = [
		_channel_effect(Channels.Channel.HEAT, 300),
		_channel_effect(Channels.Channel.TOXIN, -500),
		_state_effect(&"burning", 2),
		_wave_effect(&"fire", 0, 4),
	]
	recipe.effects = effects
	return recipe


func _make_thermal_neutralize_recipe() -> ReactionRecipe:
	var recipe := ReactionRecipe.new()
	recipe.id = &"thermal_neutralize"
	recipe.display_name = "冷热相消"
	recipe.priority = 10
	recipe.cooldown_turns = 0
	recipe.max_triggers_per_turn = 1
	recipe.event_id = &"thermal_shock"
	var conditions: Array[ConditionDef] = [
		_condition(ConditionDef.Kind.CHANNEL_AT_LEAST, Channels.Channel.HEAT, 200),
		_condition(ConditionDef.Kind.CHANNEL_AT_LEAST, Channels.Channel.COLD, 200),
	]
	recipe.conditions = conditions
	var effects: Array[EffectDef] = [
		_channel_effect(Channels.Channel.HEAT, -200),
		_channel_effect(Channels.Channel.COLD, -200),
	]
	recipe.effects = effects
	return recipe


func _make_charge_release_recipe() -> ReactionRecipe:
	var recipe := ReactionRecipe.new()
	recipe.id = &"charge_release"
	recipe.display_name = "充能释放"
	recipe.priority = 30
	recipe.cooldown_turns = 0
	recipe.max_triggers_per_turn = 1
	recipe.event_id = &"charge_burst"
	var conditions: Array[ConditionDef] = [
		_condition(ConditionDef.Kind.CHANNEL_AT_LEAST, Channels.Channel.CHARGE, 600),
	]
	recipe.conditions = conditions
	var effects: Array[EffectDef] = [
		_channel_effect(Channels.Channel.CHARGE, -600),
		_neighbor_channel_effect(Channels.Channel.CHARGE, 100),
		_event_effect(&"charge_burst"),
	]
	recipe.effects = effects
	return recipe


# --- builders --------------------------------------------------------------

func _tags(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(value)
	return result


func _emitters(values: Array) -> Array[ChannelEmitter]:
	var result: Array[ChannelEmitter] = []
	for value in values:
		result.append(value)
	return result


func _emitter(channel: int, rate: int) -> ChannelEmitter:
	var emitter := ChannelEmitter.new()
	emitter.channel = channel
	emitter.rate_per_turn = rate
	emitter.max_value = Channels.MAX_VALUE
	return emitter


func _tag_condition(tag: StringName) -> ConditionDef:
	var condition := ConditionDef.new()
	condition.kind = ConditionDef.Kind.HAS_TAG
	condition.tag = tag
	return condition


func _condition(kind: int, channel: int, threshold: int) -> ConditionDef:
	var condition := ConditionDef.new()
	condition.kind = kind
	condition.channel = channel
	condition.threshold = threshold
	return condition


func _channel_effect(channel: int, amount: int) -> EffectDef:
	var effect := EffectDef.new()
	effect.kind = EffectDef.Kind.ADD_CHANNEL
	effect.channel = channel
	effect.amount = amount
	return effect


func _neighbor_channel_effect(channel: int, amount: int) -> EffectDef:
	var effect := EffectDef.new()
	effect.kind = EffectDef.Kind.ADD_CHANNEL_TO_NEIGHBORS
	effect.channel = channel
	effect.amount = amount
	return effect


func _state_effect(state_name: StringName, duration: int) -> EffectDef:
	var effect := EffectDef.new()
	effect.kind = EffectDef.Kind.SET_STATE
	effect.state_name = state_name
	effect.duration_turns = duration
	return effect


func _wave_effect(wave_tag: StringName, direction: int, max_steps: int) -> EffectDef:
	var effect := EffectDef.new()
	effect.kind = EffectDef.Kind.EMIT_WAVE
	effect.wave_tag = wave_tag
	effect.direction = direction
	effect.max_steps = max_steps
	return effect


func _event_effect(event_id: StringName) -> EffectDef:
	var effect := EffectDef.new()
	effect.kind = EffectDef.Kind.EMIT_EVENT
	effect.event_id = event_id
	return effect


# --- saving ----------------------------------------------------------------

func _save_room(def: RoomDef, path: String) -> int:
	var def_errors := def.validate()
	if not def_errors.is_empty():
		push_error("invalid room '%s': %s" % [path, "; ".join(def_errors)])
		return 1
	return _save_resource(def, path)


func _save_resource(resource: Resource, path: String) -> int:
	if resource is ReactionRecipe:
		var recipe_errors := (resource as ReactionRecipe).validate()
		if not recipe_errors.is_empty():
			push_error("invalid recipe '%s': %s" % [path, "; ".join(recipe_errors)])
			return 1
	var result := ResourceSaver.save(resource, path)
	if result != OK:
		push_error("ResourceSaver.save failed for %s: %d" % [path, result])
		return 1
	return 0
