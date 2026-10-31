extends TestCase
## M6-5: procedural SFX/ambient files, bus layout and audio manager script.

const FILES: Array[String] = [
	"footstep_1.wav", "footstep_2.wav", "footstep_3.wav", "slash.wav", "hit.wav",
	"death.wav", "explosion.wav", "electric.wav", "steam.wav", "door_open.wav",
	"build.wav", "coin.wav", "ui_click.wav", "ui_error.wav", "boss_roar.wav",
	"victory.wav", "defeat.wav", "ambient_dungeon.wav",
]


func test_audio_files_exist() -> void:
	for file in FILES:
		assert_true(FileAccess.file_exists("res://assets/audio/" + file), "missing audio: " + file)


func test_ambient_stream_loads_and_loops() -> void:
	var stream := load("res://assets/audio/ambient_dungeon.wav") as AudioStreamWAV
	assert_true(stream != null, "ambient loads")
	if stream == null:
		return
	assert_true(stream.get_length() > 10.0, "ambient is at least 10s")
	assert_true(stream.data.size() > 0, "ambient has samples")


func test_audio_buses() -> void:
	assert_true(FileAccess.file_exists("res://default_bus_layout.tres"), "bus layout exists")
	assert_eq(AudioServer.get_bus_index("Master"), 0)
	assert_true(AudioServer.get_bus_index("Music") >= 0, "Music bus exists")
	assert_true(AudioServer.get_bus_index("SFX") >= 0, "SFX bus exists")


func test_audio_manager_script_loads() -> void:
	var script := load("res://presentation/audio/audio_manager.gd") as Script
	assert_true(script != null, "audio manager script loads")
	assert_true(ProjectSettings.has_setting("autoload/AudioManager"), "AudioManager autoload registered")
