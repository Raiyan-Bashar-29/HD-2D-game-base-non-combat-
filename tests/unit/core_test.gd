extends TestCase
## Core layer: untyped data reads, the flag store, and the save round-trip.
##
## OWNS: assertions about core/, including the GameConfig seam that keeps the demo's ids out of
## src/. MUST NOT: know about gameplay or content — and specifically, must never assert a demo
## id, which is why the GameConfig cases compare against ProjectSettings instead.

var _probe_value: int = 0


func run() -> void:
	plan(50)
	_dict_read()
	_flags()
	_flags_hands_out_copies()
	_save_round_trip()
	_game_config()
	_game_naming()


func _dict_read() -> void:
	var data: Dictionary = {"i": 5, "f": 2.5, "b": true, "s": "hi", "one": 1, "v": [1.0, 2.0, 3.0]}
	equal("dict_read int", DictRead.get_int(data, "i"), 6)
	# JSON has one number type, so an int may arrive as a float and must survive.
	equal("dict_read int from float", DictRead.get_int(data, "f"), 3)
	equal("dict_read float from int", DictRead.get_float(data, "i"), 5.0)
	equal("dict_read bool", DictRead.get_bool(data, "b"), true)
	equal("dict_read bool from 1", DictRead.get_bool(data, "one"), true)
	equal("dict_read string", DictRead.get_string(data, "s"), "hi")
	equal("dict_read vector3", DictRead.get_vector3(data, "v"), Vector3(1.0, 2.0, 3.0))
	# Wrong type and missing key must both fall back, never crash.
	equal("dict_read wrong type falls back", DictRead.get_int(data, "s", -1), -1)
	equal("dict_read missing key falls back", DictRead.get_int(data, "nope", -2), -2)
	equal("dict_read bad vector3 falls back", DictRead.get_vector3(data, "s"), Vector3.ZERO)


func _flags() -> void:
	Flags.clear_all()
	equal("flags start empty", Flags.count(), 0)

	var heard: Array[StringName] = []
	var listener: Callable = func(flag: StringName, _value: Variant) -> void: heard.append(flag)
	Events.flag_changed.connect(listener)

	Flags.set_flag(&"test/bool", true)
	Flags.set_flag(&"test/int", 3)
	equal("flags bool", Flags.get_bool(&"test/bool"), true)
	equal("flags int", Flags.get_int(&"test/int"), 3)
	equal("flags signal fired twice", heard.size(), 2)

	# Setting the same value again must be silent, so listeners are never woken for a non-change.
	Flags.set_flag(&"test/int", 3)
	equal("flags no signal on no-op set", heard.size(), 2)

	equal("flags advance", Flags.advance(&"test/count", 2), 2)
	equal("flags advance again", Flags.advance(&"test/count", 3), 5)
	equal("flags typed getter rejects wrong type", Flags.get_bool(&"test/int", false), false)
	equal("flags prefix query", Flags.with_prefix("test/").size(), 3)

	Events.flag_changed.disconnect(listener)
	Flags.clear_all()
	equal("flags cleared", Flags.count(), 0)


## Godot passes Dictionaries and Arrays by reference. If the store handed out the real object,
## a caller could mutate world state without set_flag, so flag_changed would never fire and
## nothing listening would learn. Container contents are the first system that would be bitten.
func _flags_hands_out_copies() -> void:
	Flags.clear_all()
	Flags.set_flag(&"test/bag", {"apple": 2})

	var borrowed: Dictionary = Flags.get_dict(&"test/bag")
	borrowed["apple"] = 99
	borrowed["pear"] = 1
	var fresh: Dictionary = Flags.get_dict(&"test/bag")
	equal("mutating a fetched dict does not touch the store", DictRead.get_int(fresh, "apple"), 2)
	equal("nor can it add keys to the store", fresh.has("pear"), false)

	Flags.set_flag(&"test/list", [1, 2])
	var list: Array = Flags.get_array(&"test/list")
	list.append(3)
	equal("mutating a fetched array does not touch the store", Flags.get_array(&"test/list").size(), 2)

	equal("missing dict falls back to empty", Flags.get_dict(&"test/absent").is_empty(), true)
	equal("get_float accepts an int", Flags.get_float(&"test/whole", 0.0), 0.0)
	Flags.clear_all()


## The criterion docs/ROADMAP.md once claimed as met while it had never executed.
func _save_round_trip() -> void:
	# Director's section asks for an area change on restore, which needs a world root a test
	# has no business building. The transition path is covered by the boot run instead.
	SaveSystem.unregister(&"world")
	SaveSystem.register(&"test_probe", _probe_collect, _probe_apply, 3)

	var slot: int = SaveSystem.MAX_SLOTS - 1
	_probe_value = 42
	Flags.set_flag(&"save/marker", "kept")
	Clock.set_time(3, 14, 30)
	Weather.force(GameEnums.WeatherKind.FOG)

	equal("save returns OK", SaveSystem.save_to_slot(slot), OK)
	equal("slot now exists", SaveSystem.has_slot(slot), true)
	var header: Dictionary = SaveSystem.slot_info(slot)
	equal("header carries the version", DictRead.get_int(header, "version"), SaveSystem.SCHEMA_VERSION)
	equal("header excludes the payload", header.has("sections"), false)

	# Scramble everything, so a restore that does nothing cannot pass by accident.
	_probe_value = 7
	Flags.set_flag(&"save/marker", "lost")
	Clock.set_time(9, 1, 1)
	Weather.force(GameEnums.WeatherKind.STORM)

	equal("load returns OK", SaveSystem.load_from_slot(slot), OK)
	equal("participant value restored", _probe_value, 42)
	equal("participant saw its own section version", _seen_version, 3)
	equal("flag restored", Flags.get_string(&"save/marker"), "kept")
	equal("clock day restored", Clock.day, 3)
	equal("clock hour restored", Clock.hour, 14)
	equal("weather restored", Weather.current(), GameEnums.WeatherKind.FOG)
	equal("loading an empty slot is refused", SaveSystem.load_from_slot(slot - 1), ERR_FILE_NOT_FOUND)
	equal("delete returns OK", SaveSystem.delete_slot(slot), OK)
	equal("slot is gone", SaveSystem.has_slot(slot), false)

	SaveSystem.unregister(&"test_probe")
	Flags.clear_all()


var _seen_version: int = 0


func _probe_collect() -> Dictionary:
	return {"v": _probe_value}


func _probe_apply(data: Dictionary, from_version: int) -> void:
	_probe_value = DictRead.get_int(data, "v", -1)
	_seen_version = from_version


## GameConfig is the seam T1.2 added so `src/` stops naming demo content. Every assertion here
## compares against ProjectSettings rather than against a literal, on purpose: a test that
## asserted `first_area() == "courtyard"` would rebuild the leak it exists to prove is gone.
func _game_config() -> void:
	var configured: String = str(ProjectSettings.get_setting(GameConfig.FIRST_AREA_SETTING, ""))
	equal("first area comes from project.godot", GameConfig.first_area(), StringName(configured))
	equal("a template with a game in it names one", configured != "", true)
	equal("first spawn comes from project.godot", GameConfig.first_spawn(), StringName(
		str(ProjectSettings.get_setting(GameConfig.FIRST_SPAWN_SETTING, ""))))

	# An UNSET first area is a real state — a template nobody has put a game in yet — and it must
	# read as empty rather than as the string "<null>", which is what str(null) would give.
	ProjectSettings.set_setting(GameConfig.FIRST_AREA_SETTING, null)
	equal("an unset first area is empty", GameConfig.first_area(), &"")
	ProjectSettings.set_setting(GameConfig.FIRST_SPAWN_SETTING, null)
	equal("an unset first spawn falls back", GameConfig.first_spawn(), GameConfig.DEFAULT_FIRST_SPAWN)
	ProjectSettings.set_setting(GameConfig.FIRST_AREA_SETTING, configured)
	ProjectSettings.set_setting(GameConfig.FIRST_SPAWN_SETTING, "default")
	equal("restored", GameConfig.first_area(), StringName(configured))


## The banner and the log file name read these, which is why `Gulistan` is no longer written
## anywhere in src/core/log/log.gd.
func _game_naming() -> void:
	var name_setting: String = str(ProjectSettings.get_setting("application/config/name", ""))
	equal("name comes from project.godot", GameConfig.game_name(), name_setting)
	var slug: String = GameConfig.game_slug()
	equal("slug is not empty", slug != "", true)
	equal("slug is lower case", slug, slug.to_lower())
	var safe: bool = true
	for character: String in slug:
		if not GameConfig.SLUG_ALPHABET.contains(character) and character != "_":
			safe = false
	equal("slug is safe in a file name", safe, true)
	equal("slug has no leading or trailing underscore", slug.trim_prefix("_").trim_suffix("_"), slug)
