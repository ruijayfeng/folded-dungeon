extends Node
## M6-5: procedural SFX + ambience, bus volumes and persisted audio settings.
## Autoloaded as `AudioManager`. Presentation only; never touches game state.

const SFX_DIR := "res://assets/audio/"
const SFX_FILES := {
	&"footstep_1": "footstep_1.ogg",
	&"footstep_2": "footstep_2.ogg",
	&"footstep_3": "footstep_3.ogg",
	&"slash": "slash.ogg",
	&"hit": "hit.ogg",
	&"death": "death.wav",
	&"explosion": "explosion.wav",
	&"electric": "electric.wav",
	&"steam": "steam.wav",
	&"door_open": "door_open.ogg",
	&"build": "build.ogg",
	&"coin": "coin.ogg",
	&"ui_click": "ui_click.wav",
	&"ui_error": "ui_error.wav",
	&"boss_roar": "boss_roar.wav",
	&"victory": "victory.wav",
	&"defeat": "defeat.wav",
	&"ambient_dungeon": "ambient_dungeon.wav",
	&"music_title": "music_title.wav",
	&"music_combat": "music_combat.wav",
}
const SFX_ALIASES := {
	&"footstep": &"footstep_1",
	&"reaction_combustion": &"explosion",
	&"reaction_thermal": &"steam",
	&"reaction_charge": &"electric",
	&"wave": &"slash",
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _ambient: AudioStreamPlayer = null
var _music: AudioStreamPlayer = null
var _next_player := 0
var _settings := {"master": 0.85, "music": 0.70, "sfx": 0.95, "muted": false}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	_ambient = AudioStreamPlayer.new()
	_ambient.bus = &"Music"
	add_child(_ambient)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = -8.0
	add_child(_music)
	_load_settings()
	_apply_settings()


func play_sfx(id: StringName, pitch_jitter: float = 0.0) -> void:
	var stream := _get_stream(id)
	if stream == null or _players.is_empty():
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 1.0
	p.play()


func play_footstep() -> void:
	play_sfx(StringName("footstep_%d" % randi_range(1, 3)), 0.06)


func play_ambient(id: StringName = &"ambient_dungeon") -> void:
	var stream := _get_stream(id)
	if stream == null or _ambient == null:
		return
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.data.size() / 2)
		_ambient.stream = wav
	else:
		_ambient.stream = stream
	if not _ambient.playing:
		_ambient.play()


func stop_ambient() -> void:
	if _ambient != null:
		_ambient.stop()


func play_music(id: StringName) -> void:
	var stream := _get_stream(id)
	if stream == null or _music == null:
		return
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.data.size() / 2)
		_music.stream = wav
	else:
		_music.stream = stream
	if not _music.playing:
		_music.play()


func stop_music() -> void:
	if _music != null:
		_music.stop()


func set_bus_volume(bus_name: String, linear: float) -> void:
	var key := bus_name.to_lower()
	_settings[key] = clampf(linear, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	_save_settings()


func get_bus_volume(bus_name: String) -> float:
	return float(_settings.get(bus_name.to_lower(), 1.0))


func set_muted(muted: bool) -> void:
	_settings["muted"] = muted
	_apply_settings()
	_save_settings()


func is_muted() -> bool:
	return bool(_settings.get("muted", false))


func _apply_settings() -> void:
	for bus_name in ["Master", "Music", "SFX"]:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		AudioServer.set_bus_mute(idx, bool(_settings.get("muted", false)))
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(float(_settings.get(bus_name.to_lower(), 1.0)), 0.0001)))


func _get_stream(id: StringName) -> AudioStream:
	var key: StringName = SFX_ALIASES.get(id, id) as StringName
	if _streams.has(key):
		return _streams[key]
	var file: String = SFX_FILES.get(key, "")
	if file.is_empty():
		return null
	var path := SFX_DIR + file
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	_streams[key] = stream
	return stream


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://audio_settings.cfg") == OK:
		for key in _settings.keys():
			_settings[key] = cfg.get_value("audio", key, _settings[key])


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in _settings.keys():
		cfg.set_value("audio", key, _settings[key])
	cfg.save("user://audio_settings.cfg")
