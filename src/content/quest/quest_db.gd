class_name QuestDb
extends RefCounted
## Every Quest in the project, found by scanning data/quests and cached by id.
##
## THE FOURTH REGISTRY, AND THE NOTE IN schedule_db.gd's HEADER CAME DUE HERE. It said: "three
## is a pattern, four is a problem - if a fourth registry appears, that is the moment to
## reconsider." It was reconsidered, and the verdict is to keep the fourth copy for now, with
## a board row rather than a silent shrug:
##
##   - GDScript has no generics. A shared base could only cache `Resource` and hand it back
##     untyped, so every one of `definition()`, `conversation()`, `schedule()` and `quest()`
##     becomes a cast at the call site - and static typing is this project's non-negotiable #2,
##     not a preference. Four readable files that each return their own type beat one clever
##     file plus four casts.
##   - What is genuinely duplicated is about thirty lines of scan-and-validate. The path scan is
##     ALREADY shared: `ItemDb.resource_paths()` is called here rather than copied, so the
##     exported-pack `.remap` handling has exactly one implementation. The rest is the part that
##     differs by type.
##   - The refactor that WOULD pay is a base holding the cache plus a thin typed facade per
##     registry. That touches four registries and the four areas of the suite that cover them,
##     which is a package, not a paragraph. `docs/WORK_PACKAGES.md` has the row.
##
## Everything else is ADR-0006 verbatim, which was never about items: a scan is the only option
## where dropping a .tres in a folder is the entire act, a hand-maintained list rots, and a
## generated manifest fails SILENTLY when someone forgets to regenerate it.
##
## OWNS: finding quests on disk, caching them by id, and reporting what is wrong.
## MUST NOT: track progress, read a flag, or touch an autoload. Problems are RETURNED, never
## logged, so tools/check_content.gd can use this class under `--script`.

const QUEST_DIR: String = "res://data/quests"

## The directory actually scanned. A CONTENT ROOT rather than a constant: a game may keep its
## quests somewhere else, and the test fixtures point it at a temp directory so this registry
## can be proved with no authored content on disk at all. Restore it to QUEST_DIR and rescan().
static var content_dir: String = QUEST_DIR
const ID_PREFIX: String = "quest/"

static var _by_id: Dictionary[StringName, Quest] = {}
static var _problems: PackedStringArray = PackedStringArray()
static var _loaded: bool = false


## The quest for an id, or null. A typo yields null rather than a crash; the caller decides
## whether that is a quest nobody can start or an error.
static func quest(quest_id: StringName) -> Quest:
	_ensure_loaded()
	if not _by_id.has(quest_id):
		return null
	return _by_id[quest_id]


static func has(quest_id: StringName) -> bool:
	_ensure_loaded()
	return _by_id.has(quest_id)


static func all() -> Dictionary[StringName, Quest]:
	_ensure_loaded()
	return _by_id


static func count() -> int:
	_ensure_loaded()
	return _by_id.size()


static func problems() -> PackedStringArray:
	_ensure_loaded()
	return _problems


## Static state survives a scene reload and a new game, which is right for immutable content and
## wrong while authoring or testing. Tests and the validator call this.
##
## rescan() AND NOT reload(). `Script` declares `reload()`, and a GDScript identifier IS the
## script object, so `QuestDb.reload()` would dispatch to the native method and silently reset
## every static variable in this file - including `content_dir`. That is not hypothetical: it is
## exactly what `ItemDb.reload()` did for four packages. See gotcha 17.
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
	# NO QUESTS IS NOT A PROBLEM, and the folder need not exist. Same reasoning as ItemDb and
	# the same T1.2 finding: an empty content root is the legal starting state of a base
	# template, and reporting it made a stripped checkout fail its own gate on step one of
	# docs/NEW_GAME.md. A file that is present and does not load is the real error.


static func _register(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)
	var found: Quest = resource as Quest
	if found == null:
		_problems.append("%s is not a Quest" % path)
		return
	var required: StringName = StringName(ID_PREFIX + path.get_file().get_basename())
	if found.id != required:
		_problems.append("%s declares id '%s' but its file name requires '%s'" % [
			path, found.id, required,
		])
		return
	if _by_id.has(found.id):
		_problems.append("duplicate quest id '%s' at %s" % [found.id, path])
		return
	_problems.append_array(found.problems())
	_by_id[found.id] = found
