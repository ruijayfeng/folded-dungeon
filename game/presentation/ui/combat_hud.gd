class_name CombatHUD
extends Label
## Minimal M3 combat HUD: round, player HP, enemy count and controls.

var controller: CombatController = null
var session: DungeonSession = null


func setup(p_controller: CombatController, p_session: DungeonSession) -> void:
	controller = p_controller
	session = p_session
	custom_minimum_size = Vector2(380, 60)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	refresh()


func refresh() -> void:
	if controller == null or controller.state == null or session == null or session.phase != DungeonSession.Phase.COMBAT:
		text = "战斗：未开始（按 C 在当前房间开始测试战斗）"
		return
	var state := controller.state
	var player := state.player_unit()
	var enemy_count := state.living_enemies().size()
	text = "战斗 round=%d  HP=%d/%d  怪物=%d\nWASD 移动 / SPACE 攻击 / ENTER 结束回合" % [
		state.round,
		player.hp if player != null else 0,
		player.max_hp if player != null else 0,
		enemy_count,
	]
