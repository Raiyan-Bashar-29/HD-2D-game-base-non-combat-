class_name Fixtures
extends RefCounted
## Where fixture content lives, and how a case switches the registries onto it.
##
## THE DECISION: IN MEMORY WHERE POSSIBLE, ON DISK WHERE THE REGISTRY LOOKS.
## Both were on the table and the answer is split, deliberately, along one line: does the system
## under test receive the content, or LOOK IT UP BY ID?
##
## - RECEIVED. A `Pickup` is handed an `ItemDefinition`, a `PathActionPoint` a `PathAction`.
##   Nothing scans anything, so the fixture is built in memory by `FixtureContent` and set on
##   the node. No file, no temp directory, no global state to restore.
## - LOOKED UP. `Inventory.add(id)` asks `ItemDb`, `DialogueRunner.begin(id)` asks `DialogueDb`,
##   `NpcBrain` asks `ScheduleDb`, `QuestTracker` asks `QuestDb`. Those four registries find
##   content BY DIRECTORY SCAN
##   (ADR-0006) and cache it statically, so an in-memory resource is invisible to them. The
##   options were a test-only injection method on each registry - engine code carrying a
##   backdoor that exists for the suite and for nothing else - or a real directory the real
##   scan really reads. This picks the second.
##
## WHAT THE SECOND OPTION BUYS BEYOND UNWELDING THE SUITE: the fixtures go out through
## `ResourceSaver` and come back through the registry's own scan, so the suite now proves the
## .tres authoring round trip that a consuming game depends on and that nothing tested before.
##
## WHY user:// AND NOT A FOLDER UNDER res://
## Writing into `res://data/` would mean the suite mutates the very content root
## `docs/NEW_GAME.md` tells a game to delete, and a crashed run would leave stray .tres files
## that `tools/check_content.gd` would then fail on. `user://` is outside the repo, so the
## worst a crashed run leaves behind is a stale temp directory that the next `activate()`
## overwrites.
##
## OWNS: the temp content root, redirecting the four registries onto it and back, and telling
## a case whether demo content exists at all.
## MUST NOT: build content (that is `FixtureContent`), or assert anything.

const ROOT: String = "user://test_fixtures"
const ITEM_DIR: String = "user://test_fixtures/items"
const DIALOGUE_DIR: String = "user://test_fixtures/dialogue"
const SCHEDULE_DIR: String = "user://test_fixtures/schedules"
const QUEST_DIR: String = "user://test_fixtures/quests"

const AREA_ROOT: String = "res://scenes/areas"

static var _active: bool = false


static func is_active() -> bool:
	return _active


## Point all four registries at fixture content. Idempotent, and it REWRITES the files every
## time: a case that edited a cached resource in place must not leave that edit for the next.
static func activate() -> bool:
	var written: bool = _write_all()
	ItemDb.content_dir = ITEM_DIR
	DialogueDb.content_dir = DIALOGUE_DIR
	ScheduleDb.content_dir = SCHEDULE_DIR
	QuestDb.content_dir = QUEST_DIR
	_reload_all()
	_active = true
	return written


## Back to whatever the game itself ships. Called by the runner after EVERY case, not only by
## the cases that switched, because a case that crashes half way through would otherwise leave
## every later case reading fixture content and never say so.
static func deactivate() -> void:
	if not _active:
		return
	_active = false
	ItemDb.content_dir = ItemDb.ITEM_DIR
	DialogueDb.content_dir = DialogueDb.DIALOGUE_DIR
	ScheduleDb.content_dir = ScheduleDb.SCHEDULE_DIR
	QuestDb.content_dir = QuestDb.QUEST_DIR
	_reload_all()


## Whether this checkout still has the demo in it. A stripped template - `data/` and
## `scenes/areas/` deleted, which is step one of docs/NEW_GAME.md - answers false, and the cases
## that genuinely assert things ABOUT the demo skip themselves and say so.
static func has_demo_content() -> bool:
	return not (area_ids().is_empty()
		and ItemDb.resource_paths(ItemDb.ITEM_DIR).is_empty()
		and ItemDb.resource_paths(DialogueDb.DIALOGUE_DIR).is_empty()
		and ItemDb.resource_paths(ScheduleDb.SCHEDULE_DIR).is_empty()
		and ItemDb.resource_paths(QuestDb.QUEST_DIR).is_empty())


## Every area a game has authored, DISCOVERED rather than listed. The structural contract in
## `area_root.gd`'s header applies to whatever areas exist, so listing two demo ids would both
## weld the suite to the demo and stop covering area three.
static func area_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for folder: String in DirAccess.get_directories_at(AREA_ROOT):
		var packed: String = "%s/%s/%s.tscn" % [AREA_ROOT, folder, folder]
		if ResourceLoader.exists(packed):
			out.append(StringName(folder))
	out.sort()
	return out


static func _reload_all() -> void:
	ItemDb.rescan()
	DialogueDb.rescan()
	ScheduleDb.rescan()
	QuestDb.rescan()


static func _write_all() -> bool:
	var ok: bool = true
	for directory: String in [ITEM_DIR, DIALOGUE_DIR, SCHEDULE_DIR, QUEST_DIR]:
		if DirAccess.make_dir_recursive_absolute(directory) != OK:
			ok = false
	for definition: ItemDefinition in FixtureContent.items():
		ok = _save(definition, ITEM_DIR, definition.id) and ok
	var talk: Conversation = FixtureContent.conversation()
	ok = _save(talk, DIALOGUE_DIR, talk.id) and ok
	var timetable: NpcSchedule = FixtureContent.schedule()
	ok = _save(timetable, SCHEDULE_DIR, timetable.id) and ok
	var errand: Quest = FixtureContent.quest()
	ok = _save(errand, QUEST_DIR, errand.id) and ok
	return ok


## The file NAME carries the id, because every registry requires the two to agree - which is
## itself a rule the fixtures now exercise rather than assume.
static func _save(resource: Resource, directory: String, id: StringName) -> bool:
	var path: String = "%s/%s.tres" % [directory, String(id).get_file()]
	return ResourceSaver.save(resource, path) == OK
