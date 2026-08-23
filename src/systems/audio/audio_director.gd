extends Node
## Music and ambience playback, and the mixer layout. Autoload `Audio`.
##
## WHY THE BUSES ARE BUILT IN CODE
## A bus layout is normally a binary .tres that nobody can read in a diff and everybody is
## afraid to touch. Four buses declared here are readable, and the volume settings wire
## straight onto them by name.
##
## OWNS: the bus layout, the music player pair, the ambience player, and applying volume
## settings to buses.
## MUST NOT: own positional sound. A creaking door owns its own AudioStreamPlayer3D, because
## the sound belongs to the door and should die with it. Routing a world sound through a
## global singleton is how you end up with a footstep playing after the character is gone.
##
## NOTE ON ASSETS: there is no audio in the project yet. Every method here accepts null and
## does nothing gracefully, so the system is complete and testable before a single .ogg
## exists. That is deliberate, not unfinished.

const BUSES: Array[String] = ["Music", "Ambience", "SFX", "UI"]
const DEFAULT_FADE: float = 1.5
## Below this, a bus is muted outright rather than left at an inaudible level.
const SILENCE_THRESHOLD: float = 0.001

var _music_a: AudioStreamPlayer = null
var _music_b: AudioStreamPlayer = null
var _music_active_is_a: bool = true
var _ambience: AudioStreamPlayer = null
var _current_music_path: String = ""


func _ready() -> void:
	_ensure_buses()
	_music_a = _make_player("Music", "MusicA")
	_music_b = _make_player("Music", "MusicB")
	_ambience = _make_player("Ambience", "Ambience")
	Events.setting_changed.connect(_on_setting_changed)
	_apply_all_volumes()
	Log.info("audio", "Buses ready: Master + %s" % ", ".join(BUSES))


## Cross-fade to a new music track. Passing null fades out to silence.
## Requesting the track that is already playing does nothing, so an area re-entry does not
## restart the music from the top.
func play_music(stream: AudioStream, fade: float = DEFAULT_FADE) -> void:
	var path: String = stream.resource_path if stream != null else ""
	if path == _current_music_path and path != "":
		return
	_current_music_path = path

	var incoming: AudioStreamPlayer = _music_b if _music_active_is_a else _music_a
	var outgoing: AudioStreamPlayer = _music_a if _music_active_is_a else _music_b
	_music_active_is_a = not _music_active_is_a

	if stream != null:
		incoming.stream = stream
		incoming.volume_db = -60.0
		incoming.play()
		_fade_to(incoming, 0.0, fade)
	if outgoing.playing:
		_fade_to(outgoing, -60.0, fade, true)
	Log.debug("audio", "Music -> %s" % (path if path != "" else "(silence)"))


func stop_music(fade: float = DEFAULT_FADE) -> void:
	play_music(null, fade)


## Ambience is the environmental bed: wind, birds, rain. It layers under music.
func play_ambience(stream: AudioStream, fade: float = DEFAULT_FADE) -> void:
	if _ambience.stream == stream:
		return
	if stream == null:
		_fade_to(_ambience, -60.0, fade, true)
		return
	_ambience.stream = stream
	_ambience.volume_db = -60.0
	_ambience.play()
	_fade_to(_ambience, 0.0, fade)


## Duck music and ambience, for dialogue and for cutscene emphasis.
func duck(amount_db: float = -8.0, seconds: float = 0.4) -> void:
	for bus_name: String in ["Music", "Ambience"]:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index < 0:
			continue
		var tween: Tween = create_tween()
		tween.tween_method(_set_bus_db.bind(index), AudioServer.get_bus_volume_db(index), amount_db, seconds)


## Undo duck() by re-reading the settings, so it cannot drift out of sync with the mixer.
func unduck(seconds: float = 0.6) -> void:
	for bus_name: String in ["Music", "Ambience"]:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index < 0:
			continue
		var target: float = _db_for_bus(bus_name)
		var tween: Tween = create_tween()
		tween.tween_method(_set_bus_db.bind(index), AudioServer.get_bus_volume_db(index), target, seconds)


## Create the buses if they are not already present, each routed to Master.
func _ensure_buses() -> void:
	for bus_name: String in BUSES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		var index: int = AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


func _make_player(bus_name: String, node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus_name
	# Music and ambience must keep playing while the game is paused in a menu.
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func _fade_to(player: AudioStreamPlayer, target_db: float, seconds: float, stop_after: bool = false) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", target_db, maxf(0.01, seconds))
	if stop_after:
		tween.tween_callback(player.stop)


func _apply_all_volumes() -> void:
	_set_named_bus("Master", _db_for_bus("Master"))
	for bus_name: String in BUSES:
		_set_named_bus(bus_name, _db_for_bus(bus_name))


## Map a bus to its setting. Master is special-cased because its setting is "audio/master".
func _db_for_bus(bus_name: String) -> float:
	var linear: float = Settings.get_float("audio/%s" % bus_name.to_lower())
	if linear <= SILENCE_THRESHOLD:
		return -80.0
	return linear_to_db(linear)


func _set_named_bus(bus_name: String, db: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, db)
	AudioServer.set_bus_mute(index, db <= -80.0)


func _set_bus_db(db: float, index: int) -> void:
	AudioServer.set_bus_volume_db(index, db)


func _on_setting_changed(section: String, _key: String, _value: Variant) -> void:
	if section == "audio":
		_apply_all_volumes()
