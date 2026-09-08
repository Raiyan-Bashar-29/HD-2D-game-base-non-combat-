extends TestCase
## What the save loader does with a file it cannot trust, and the one path it CANNOT REACH.
##
## WHY THIS IS SEPARATE FROM `core_test.gd`. That case owns the save ROUND TRIP — write, read
## back, restore. This one owns the refusals, and they are a different question: not "does a good
## save survive" but "what happens to a bad one". `core_test.gd` asserted exactly one of them (an
## empty slot) and nothing in the suite had ever written a MALFORMED save file, so every OTHER
## refusal in `load_from_slot`, and both of `_migrate`'s, were carried by review alone.
## Split by QUESTION, on T5.7's precedent.
##
## ONE BAD SECTION MUST NOT COST THE WHOLE FILE, and three blocks below are about that line. A
## corrupt envelope is refused outright; a corrupt SECTION is logged and skipped while the rest of
## the save loads, because the difference between those two is the difference between a player
## losing a setting and a player losing forty hours.
##
## THE ONE THAT IS NOT A TEST OF BEHAVIOUR. `_migrate`'s success path is UNREACHABLE at
## `SCHEMA_VERSION == 1`, and that is arithmetic rather than an opinion: it is called only when
## `version != 1`, and it then refuses `<= 0` and `> 1` — and no integer is all three of not-one,
## above-zero and at-most-one. So its "Migrated save from v%d to v%d" line cannot print for any
## input a file can contain. `_the_migration_path_has_no_reachable_success_case()` asserts the
## boundary exhaustively AND pins `SCHEMA_VERSION`, so the day someone ships v2 this case fails
## and says what to write. An unreachable path is not a bug — but `SYSTEMS_INVENTORY.md` calling
## migration DONE was describing a mechanism nothing can enter.
##
## THE SAVE DIRECTORY IS REAL, because `SaveSystem.SAVE_DIR` is a `const` with no redirect, the
## way `Fixtures` redirects the five content roots. So this case writes a real slot and deletes it
## on every path, exactly as `core_test.gd` does, and uses a slot of its own so the two cannot
## collide.
##
## OWNS: assertions about a save file the loader must refuse, or must partially skip.
## MUST NOT: assert the round trip (that is `core_test.gd`), or name authored content.

const FIXED: int = 17
const PROBE: StringName = &"recovery_probe"
## Two below `MAX_SLOTS`, so it cannot collide with `core_test.gd`'s `MAX_SLOTS - 1`.
const SLOT: int = SaveSystem.MAX_SLOTS - 2

## Counts applier calls. The skip blocks assert this stays at zero, because "the load returned OK"
## and "the section was applied" are different claims — and when the question is whether a
## malformed section was skipped, only the second one answers it.
var _applied: int = 0


func run() -> void:
	plan(FIXED)
	_a_file_that_is_not_json_is_refused()
	_a_save_with_no_version_field_is_refused()
	_a_save_from_a_newer_build_is_refused()
	_a_section_that_is_not_a_dictionary_is_skipped_and_the_rest_loads()
	_a_section_predating_versioning_is_skipped_and_the_rest_loads()
	_a_section_that_is_absent_leaves_its_system_at_defaults()
	_the_migration_path_has_no_reachable_success_case()


## The shape a half-written file, a truncated copy or a disk error leaves behind.
func _a_file_that_is_not_json_is_refused() -> void:
	_arm("this is not json {{{")
	equal("a file that is not JSON is refused as corrupt",
			SaveSystem.load_from_slot(SLOT), ERR_FILE_CORRUPT)
	equal("and nothing was applied from it", _applied, 0)
	_disarm()


## A missing `version` reads as 0 through `DictRead`, which is not `SCHEMA_VERSION`, so it reaches
## `_migrate` and is refused there rather than being quietly assumed to be current.
func _a_save_with_no_version_field_is_refused() -> void:
	_arm('{"sections":{}}')
	equal("a save with no version field is refused",
			SaveSystem.load_from_slot(SLOT), ERR_FILE_CORRUPT)
	equal("and nothing was applied from it", _applied, 0)
	_disarm()


## What a player hits by copying a save back from a machine running a newer build. Refused rather
## than attempted, because a forward migration cannot be written in advance.
func _a_save_from_a_newer_build_is_refused() -> void:
	_arm('{"version":99,"sections":{}}')
	equal("a save from a newer build is refused",
			SaveSystem.load_from_slot(SLOT), ERR_FILE_CORRUPT)
	equal("and nothing was applied from it", _applied, 0)
	_disarm()


func _a_section_that_is_not_a_dictionary_is_skipped_and_the_rest_loads() -> void:
	_arm('{"version":1,"sections":{"recovery_probe":"not a dictionary"}}')
	equal("a section that is not a Dictionary does not fail the load",
			SaveSystem.load_from_slot(SLOT), OK)
	equal("and that section's applier was never called", _applied, 0)
	_disarm()


## A section written before per-section versioning existed. Skipped LOUDLY rather than handed to an
## applier that cannot recognise its shape — the loader's own comment says why.
func _a_section_predating_versioning_is_skipped_and_the_rest_loads() -> void:
	_arm('{"version":1,"sections":{"recovery_probe":{"data":{"kept":true}}}}')
	equal("a section with no per-section version does not fail the load",
			SaveSystem.load_from_slot(SLOT), OK)
	equal("and its applier was never called, so it keeps its defaults", _applied, 0)
	_disarm()


## The ordinary forward-compatibility case: a save written before this system existed at all. For
## that one system it must be indistinguishable from a new game.
func _a_section_that_is_absent_leaves_its_system_at_defaults() -> void:
	_arm('{"version":1,"sections":{}}')
	equal("a save with no section for a registered system still loads",
			SaveSystem.load_from_slot(SLOT), OK)
	equal("and that system's applier was never called", _applied, 0)
	_disarm()


## THE BOUNDARY, EXHAUSTIVELY, AND THE PIN THAT MAKES IT EXPIRE. Every integer a `version` field
## can hold falls into exactly one of three buckets and only the middle one loads, which is what
## makes `_migrate`'s success path unreachable rather than merely untested.
func _the_migration_path_has_no_reachable_success_case() -> void:
	_arm('{"version":-1,"sections":{}}')
	equal("a negative version is refused", SaveSystem.load_from_slot(SLOT), ERR_FILE_CORRUPT)
	_disarm()
	_arm('{"version":0,"sections":{}}')
	equal("version zero is refused", SaveSystem.load_from_slot(SLOT), ERR_FILE_CORRUPT)
	_disarm()
	_arm('{"version":2,"sections":{}}')
	equal("one past the schema is refused", SaveSystem.load_from_slot(SLOT), ERR_FILE_CORRUPT)
	_disarm()
	_arm('{"version":1,"sections":{}}')
	equal("only the current schema loads, and it never enters _migrate at all",
			SaveSystem.load_from_slot(SLOT), OK)
	_disarm()
	## WHEN THIS FAILS, WRITE THE MIGRATION TEST. A v2 schema gives `_migrate` its first reachable
	## success case, and the block above stops being exhaustive the moment one exists.
	equal("SCHEMA_VERSION is still 1, so _migrate has no reachable success path",
			SaveSystem.SCHEMA_VERSION, 1)


## Register the probe and plant `text` as the slot's raw contents. Registered fresh each time so
## `_applied` counts one block's calls rather than the whole case's.
func _arm(text: String) -> void:
	_applied = 0
	SaveSystem.register(PROBE, _probe_collect, _probe_apply, 1)
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(SLOT), FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Unregistered and DELETED on every path including the failing ones: a slot left behind would be
## read by the next block, and a participant left registered would answer it too.
func _disarm() -> void:
	SaveSystem.unregister(PROBE)
	if SaveSystem.has_slot(SLOT):
		SaveSystem.delete_slot(SLOT)


func _probe_collect() -> Dictionary:
	return {"kept": true}


func _probe_apply(_data: Dictionary, _from: int) -> void:
	_applied += 1
