class_name ScheduleDb
extends RefCounted
## Every NpcSchedule in the project, found by scanning data/schedules and cached by id.
##
## THE THIRD REGISTRY, AND DELIBERATELY IDENTICAL TO THE FIRST TWO. ADR-0006 settled the
## argument once: a scan is the only option where dropping a .tres in a folder is the entire
## act, a hand-maintained list rots, and a generated manifest fails SILENTLY when someone
## forgets to regenerate it. That reasoning was never about items. Schedules get the same
## treatment, including the id-equals-filename rule and `ItemDb.resource_paths()`, which is
## reused rather than copied so the exported-pack `.remap` handling has one implementation.
##
## THAT THIS IS THE THIRD COPY OF THE SAME NINETY LINES IS NOTED AND NOT YET ACTED ON. A shared
## generic registry is the obvious refactor and it is deliberately deferred: GDScript has no
## generics, so it would be a base class handing back untyped Resources plus a cast at every
## call site, which trades three readable files for one clever one and a lost static type. If a
## fourth registry appears, that is the moment to reconsider - three is a pattern, four is a
## problem.
##
## OWNS: finding schedules on disk, caching them by id, and reporting what is wrong.
## MUST NOT: run a schedule, move an NPC, or touch an autoload. Problems are RETURNED, never
## logged, so tools/check_content.gd can use this class under `--script`.

const SCHEDULE_DIR: String = "res://data/schedules"
const ID_PREFIX: String = "schedule/"

static var _by_id: Dictionary[StringName, NpcSchedule] = {}
static var _problems: PackedStringArray = PackedStringArray()
static var _loaded: bool = false


## The schedule for an id, or null. A typo yields null rather than a crash; the caller decides
## whether that is an NPC that stands still or an error.
static func schedule(schedule_id: StringName) -> NpcSchedule:
	_ensure_loaded()
	if not _by_id.has(schedule_id):
		return null
	return _by_id[schedule_id]


static func has(schedule_id: StringName) -> bool:
	_ensure_loaded()
	return _by_id.has(schedule_id)


static func all() -> Dictionary[StringName, NpcSchedule]:
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
static func reload() -> void:
	_by_id.clear()
	_problems = PackedStringArray()
	_loaded = false
	_ensure_loaded()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	for path: String in ItemDb.resource_paths(SCHEDULE_DIR):
		_register(path)
	# No schedules is not a problem. Same reasoning as ItemDb, and the same T1.2 finding.


static func _register(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)
	var found: NpcSchedule = resource as NpcSchedule
	if found == null:
		_problems.append("%s is not an NpcSchedule" % path)
		return
	var required: StringName = StringName(ID_PREFIX + path.get_file().get_basename())
	if found.id != required:
		_problems.append("%s declares id '%s' but its file name requires '%s'" % [
			path, found.id, required,
		])
		return
	if _by_id.has(found.id):
		_problems.append("duplicate schedule id '%s' at %s" % [found.id, path])
		return
	_problems.append_array(found.problems())
	_by_id[found.id] = found
