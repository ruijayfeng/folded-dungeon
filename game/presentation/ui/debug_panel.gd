class_name DebugPanel
extends Label
## M2 rule debug panel: channel values of the current room + recent rule events.

const MAX_LINES := 10

var rule_engine: RuleEngine = null
var session: DungeonSession = null


func setup(engine: RuleEngine, game_session: DungeonSession) -> void:
	rule_engine = engine
	session = game_session
	custom_minimum_size = Vector2(620, 120)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	refresh()


func refresh() -> void:
	if rule_engine == null or session == null:
		text = "RuleEngine: <none>"
		return
	var lines: Array[String] = []
	lines.append("RuleEngine turn=%d  events=%d" % [rule_engine.turn, rule_engine.events.size()])
	var state := rule_engine.room_state(session.current_room_cell())
	if state != null:
		var channel_parts: Array[String] = []
		for channel in Channels.COUNT:
			channel_parts.append("%s=%d" % [Channels.name_of(channel), state.get_channel(channel)])
		lines.append("channels: " + ", ".join(channel_parts))
	lines.append("recent: " + _recent_events())
	text = "\n".join(lines)


func _recent_events() -> String:
	if rule_engine.events.is_empty():
		return "<none>"
	var start := maxi(0, rule_engine.events.size() - MAX_LINES)
	var parts: Array[String] = []
	for index in range(start, rule_engine.events.size()):
		var event: Dictionary = rule_engine.events[index]
		parts.append("t%d:%s" % [int(event.get("turn", 0)), String(event["type"])])
	return " | ".join(parts)
