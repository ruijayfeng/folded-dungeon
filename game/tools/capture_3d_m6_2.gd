extends SceneTree
## Dev-only: M6-2 quality screenshots (3D macro build view + themed rooms).

const OUT := "res://../docs/screenshots/"
const TARGETS: Array[String] = ["forge_room", "frost_room", "toxin_room", "vault_room"]

var mode: Node3D = null
var run: RunController = null

func _initialize() -> void:
	var safety := create_timer(180.0)
	safety.timeout.connect(func() -> void:
		print("SAFETY-QUIT")
		quit())
	var ps: PackedScene = load("res://presentation/run_mode/run_mode_3d.tscn")
	mode = ps.instantiate()
	root.add_child(mode)
	_drive.call_deferred()

func _shot(name: String) -> void:
	for i in 12:
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("SAVED ", name)

func _resolve_until_build() -> bool:
	var guard := 0
	while guard < 60:
		guard += 1
		match run.phase:
			RunController.Phase.BUILD:
				return true
			RunController.Phase.ENCOUNTER:
				run.combat.auto_resolve(60)
				run.sync_combat_result()
				mode._sync()
				await process_frame
			RunController.Phase.EVENT, RunController.Phase.REST, RunController.Phase.SHOP:
				run.resolve_choice(0)
				mode._sync()
				await process_frame
			RunController.Phase.SETTLED:
				return false
			_:
				mode._sync()
				await process_frame
	return false

func _force_build(def_id: String) -> bool:
	var def: RoomDef = load("res://data/rooms/%s.tres" % def_id) as RoomDef
	if def == null:
		return false
	run.current_offer = [def]
	var cell: Vector2i = run.auto_build_adjacent()
	if cell == Vector2i(-1, -1):
		return false
	run.auto_walk_into(cell)
	mode._room_key = ""
	mode._sync()
	return true

func _room_shot(name: String) -> void:
	var saved_phase: int = run.phase
	var saved_session: int = run.session.phase
	var saved_combat: CombatController = run.combat
	run.phase = RunController.Phase.EXPLORE
	run.session.phase = DungeonSession.Phase.EXPLORE
	run.combat = null
	mode._room_key = ""
	mode._sync()
	await _shot(name)
	run.phase = saved_phase
	run.session.phase = saved_session
	run.combat = saved_combat
	mode._sync()

func _drive() -> void:
	await process_frame
	await process_frame
	run = mode.run
	mode._default_preview()
	mode._sync()
	await _shot("m6-2-build")
	mode.preview_orientation = 1
	mode._sync()
	await _shot("m6-2-rotate")
	mode.preview_orientation = 0
	var index := 0
	for def_id in TARGETS:
		if not await _resolve_until_build():
			break
		if not _force_build(def_id):
			print("SKIP ", def_id)
			continue
		await _room_shot("m6-2-room-%d-%s" % [index, def_id])
		index += 1
	await _resolve_until_build()
	if run.phase == RunController.Phase.BUILD:
		mode._default_preview()
		mode._sync()
		await _shot("m6-2-build-full")
	quit()
