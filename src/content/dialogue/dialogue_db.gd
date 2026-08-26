class_name DialogueDb
extends RefCounted
## Every Conversation in the project, found by scanning data/dialogue and cached by id.
##
## THE SAME REGISTRY AS ItemDb, AND DELIBERATELY SO. ADR-0006 settled the argument for items:
## a scan is the only option where dropping a .tres in a folder is the entire act, a
## hand-maintained list rots, and a generated manifest fails SILENTLY when someone forgets to
## regenerate it. None of that reasoning is about items. Conversations are the second content
## type and they get the identical treatment, including the id-equals-filename rule and the
## `ResourceLoader.list_directory()` / `DirAccess` fallback, which ItemDb.resource_paths()
## already implements and this class reuses rather than copies.
##
## WHY IT REUSES ItemDb.resource_paths(): that function absorbs every difference between
## running from source and from an exported .pck - bare name or full path, .tres or a
## converted .res, the .remap and .import indirection. A second implementation would be a
## second thing to get wrong in an exported build, which is the one place neither can be
## tested yet. See the honest limit at the foot of ADR-0006.
##
## OWNS: finding conversations on disk, caching them by id, and reporting what is wrong.
## MUST NOT: run a conversation, hold conversational state, or touch an autoload. Problems are
## RETURNED, never logged, so tools/check_content.gd can use this class under `--script`.

const DIALOGUE_DIR: String = "res://data/dialogue"

## The directory actually scanned. A CONTENT ROOT rather than a constant: a game may keep its
## conversations somewhere else, and the test fixtures point it at a temp directory so this registry
## can be proved with no authored content on disk at all. Restore it to DIALOGUE_DIR and reload().
static var content_dir: String = DIALOGUE_DIR
const ID_PREFIX: String = "talk/"

static var _by_id: Dictionary[StringName, Conversation] = {}
static var _problems: PackedStringArray = PackedStringArray()
static var _loaded: bool = false


## The conversation for an id, or null. A typo yields null rather than a crash; the caller
## decides whether that is a refusal or an error.
static func conversation(talk_id: StringName) -> Conversation:
	_ensure_loaded()
	if not _by_id.has(talk_id):
		return null
	return _by_id[talk_id]


static func has(talk_id: StringName) -> bool:
	_ensure_loaded()
	return _by_id.has(talk_id)


static func all() -> Dictionary[StringName, Conversation]:
	_ensure_loaded()
	return _by_id


static func count() -> int:
	_ensure_loaded()
	return _by_id.size()


## Every content error found while scanning. Empty means the catalogue is sound.
static func problems() -> PackedStringArray:
	_ensure_loaded()
	return _problems


## Static state survives a scene reload and a new game, which is right for immutable content
## and wrong while authoring or testing. Tests and the validator call this.
static func rescan() -> void:
	_by_id.clear()
	_problems = PackedStringArray()
	_loaded = false
	_ensure_loaded()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	for path: String in ItemDb.resource_paths(content_dir):
		_register(path)
	# No conversations is not a problem. Same reasoning as ItemDb, and the same T1.2 finding.


static func _register(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)
	var talk: Conversation = resource as Conversation
	if talk == null:
		_problems.append("%s is not a Conversation" % path)
		return
	var required: StringName = StringName(ID_PREFIX + path.get_file().get_basename())
	if talk.id != required:
		_problems.append("%s declares id '%s' but its file name requires '%s'" % [
			path, talk.id, required,
		])
		return
	if _by_id.has(talk.id):
		_problems.append("duplicate conversation id '%s' at %s" % [talk.id, path])
		return
	_problems.append_array(talk.problems())
	_by_id[talk.id] = talk
