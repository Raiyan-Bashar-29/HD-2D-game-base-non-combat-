extends Node
## Save and load orchestration. Autoload `SaveSystem`.
##
## WHY IT WORKS THIS WAY
## The obvious design is one big save function that reaches into every system and reads its
## variables. That function becomes the god object: it has to know every system, so every new
## feature edits it, and it is the first file to hit a thousand lines. Instead this file knows
## NOTHING about game content. Systems register a pair of callables and own their own format.
##
## A system registers itself, usually in its _ready():
##     SaveSystem.register(&"clock", _collect_save, _apply_save)
##     func _collect_save() -> Dictionary: return {"day": day, "minute": minute}
##     func _apply_save(data: Dictionary, _from: int) -> void: day = DictRead.get_int(data, "day", 1)
##
## OWNS: slot files on disk, the file format, the schema version, atomic writes, migration.
## MUST NOT: know what any section contains. Adding a saveable system never edits this file.

const SAVE_DIR: String = "user://saves"
const MAX_SLOTS: int = 6
## Bump when the envelope changes shape. Section contents are each system's own business.
const SCHEMA_VERSION: int = 1

## Section version per participant, so a system can change its own format without forcing an
## envelope bump and without _migrate having to understand every other section. See ADR-0004.
var _versions: Dictionary[StringName, int] = {}
var _collectors: Dictionary[StringName, Callable] = {}
var _appliers: Dictionary[StringName, Callable] = {}
var _playtime: float = 0.0
var _busy: bool = false


func _ready() -> void:
	if DirAccess.make_dir_recursive_absolute(SAVE_DIR) != OK:
		Log.error("save", "Could not create %s" % SAVE_DIR)


func _process(delta: float) -> void:
	_playtime += delta


## Register a save participant. `collect` returns a Dictionary; `apply` takes one.
## Re-registering the same id replaces the previous pair, which makes hot-reload safe.
func register(id: StringName, collect: Callable, apply: Callable, version: int = 1) -> void:
	if not collect.is_valid() or not apply.is_valid():
		Log.error("save", "Participant '%s' passed an invalid callable" % id)
		return
	_collectors[id] = collect
	_appliers[id] = apply
	_versions[id] = maxi(1, version)
	Log.debug("save", "Participant registered: %s" % id)


## Drop a participant. Call this if the owning node is freed before the game ends.
func unregister(id: StringName) -> void:
	_collectors.erase(id)
	_appliers.erase(id)
	_versions.erase(id)


func slot_path(slot: int) -> String:
	return "%s/slot_%02d.json" % [SAVE_DIR, slot]


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Read only the header of a slot, for the load menu. Never applies anything.
func slot_info(slot: int) -> Dictionary:
	if not has_slot(slot):
		return {}
	var parsed: Dictionary = _read_json(slot_path(slot))
	if parsed.is_empty():
		return {}
	parsed.erase("sections")
	return parsed


## The most recently written slot, or -1 if none has ever been written. This is what Continue
## means, and it is why the main menu can omit the row entirely on a first run.
##
## Compared on the stored `saved_utc` string, which sorts correctly because it is ISO-8601 and
## zero-padded. The FILE's modification time would be wrong the moment a save is copied between
## machines or restored from a backup, and it is not in the file the player can read.
func latest_slot() -> int:
	var best: int = -1
	var newest: String = ""
	for slot: int in MAX_SLOTS:
		var info: Dictionary = slot_info(slot)
		if info.is_empty():
			continue
		var when: String = DictRead.get_string(info, "saved_utc", "")
		if best < 0 or when > newest:
			best = slot
			newest = when
	return best


func save_to_slot(slot: int) -> Error:
	if _busy:
		Log.warn("save", "Save to slot %d ignored: another save is in flight" % slot)
		return ERR_BUSY
	if slot < 0 or slot >= MAX_SLOTS:
		Log.error("save", "Slot %d out of range" % slot)
		return ERR_INVALID_PARAMETER
	_busy = true

	var sections: Dictionary = {}
	for id: StringName in _collectors:
		var collect: Callable = _collectors[id]
		var section: Variant = collect.call()
		if section is Dictionary:
			# Wrapped, not flat: the version travels with the data it describes.
			sections[String(id)] = {"v": _versions[id], "data": section}
		else:
			Log.error("save", "Participant '%s' returned %s, not a Dictionary" % [id, type_string(typeof(section))])

	var envelope: Dictionary = {
		"version": SCHEMA_VERSION,
		"saved_utc": Time.get_datetime_string_from_system(true, true),
		"playtime_seconds": snappedf(_playtime, 0.1),
		"sections": sections,
	}

	var err: Error = _write_atomic(slot_path(slot), JSON.stringify(envelope, "  "))
	_busy = false
	if err != OK:
		Log.error("save", "Slot %d write failed: %s" % [slot, error_string(err)])
		return err
	Log.info("save", "Slot %d written (%d sections)" % [slot, sections.size()])
	Events.game_saved.emit(slot)
	return OK


func load_from_slot(slot: int) -> Error:
	if not has_slot(slot):
		Log.warn("save", "Slot %d is empty" % slot)
		return ERR_FILE_NOT_FOUND

	var envelope: Dictionary = _read_json(slot_path(slot))
	if envelope.is_empty():
		return ERR_FILE_CORRUPT

	var version: int = DictRead.get_int(envelope, "version", 0)
	if version != SCHEMA_VERSION:
		envelope = _migrate(envelope, version)
		if envelope.is_empty():
			return ERR_FILE_CORRUPT

	_playtime = DictRead.get_float(envelope, "playtime_seconds", 0.0)
	var sections: Dictionary = DictRead.get_dict(envelope, "sections")

	# Apply in registration order, so a system that depends on an earlier one sees it ready.
	for id: StringName in _appliers:
		var key: String = String(id)
		if not sections.has(key):
			Log.debug("save", "Slot %d has no section for '%s' — leaving it at defaults" % [slot, key])
			continue
		var section: Variant = sections[key]
		if not (section is Dictionary):
			Log.error("save", "Section '%s' in slot %d is not a Dictionary" % [key, slot])
			continue
		var wrapped: Dictionary = section
		if not wrapped.has("v"):
			# Written before per-section versioning existed. Loud, then defaults, rather than
			# handing a differently-shaped payload to an applier that cannot recognise it.
			Log.warn("save", "Section '%s' predates section versioning - loading defaults" % key)
			continue
		var apply: Callable = _appliers[id]
		apply.call(DictRead.get_dict(wrapped, "data"), DictRead.get_int(wrapped, "v", 1))

	Log.info("save", "Slot %d loaded (v%d, %.0fs played)" % [slot, version, _playtime])
	Events.game_loaded.emit(slot)
	return OK


func delete_slot(slot: int) -> Error:
	if not has_slot(slot):
		return ERR_FILE_NOT_FOUND
	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		return ERR_CANT_OPEN
	return dir.remove(slot_path(slot).get_file())


## Total seconds of play in the current run, for the save header and the pause screen.
func playtime() -> float:
	return _playtime


func reset_playtime() -> void:
	_playtime = 0.0


## Write to a temporary file, then swap it into place. A crash mid-write therefore destroys
## the temporary file and leaves the previous save intact, instead of truncating it to zero.
func _write_atomic(path: String, text: String) -> Error:
	var temp: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	file.close()

	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		return ERR_CANT_OPEN
	if dir.file_exists(path.get_file()):
		var removed: Error = dir.remove(path.get_file())
		if removed != OK:
			return removed
	return dir.rename(temp.get_file(), path.get_file())


func _read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Log.error("save", "Cannot open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	Log.error("save", "%s is not valid save JSON" % path)
	return {}


## Upgrade an older save to the current schema. Returns {} if it cannot be rescued.
## Each version gets its own explicit step so migrations stay readable and testable.
func _migrate(envelope: Dictionary, from_version: int) -> Dictionary:
	if from_version <= 0:
		Log.error("save", "Save has no usable version field")
		return {}
	if from_version > SCHEMA_VERSION:
		Log.error("save", "Save is from a newer build (v%d > v%d)" % [from_version, SCHEMA_VERSION])
		return {}
	# No migrations needed yet: v1 is the first shipped schema. When v2 arrives, add
	# `if from_version == 1: ...` here, transform in place, and fall through.
	Log.info("save", "Migrated save from v%d to v%d" % [from_version, SCHEMA_VERSION])
	return envelope
