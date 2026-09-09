class_name SaveFixture
extends RefCounted
## Where the suite's save files go, and how a case switches the store onto them.
##
## THE PROBLEM THIS CLOSES. `tests/framework/fixtures.gd` repoints five content roots so that a
## run reads fixture content instead of the game's. The save store was the SIXTH root and the
## only one left out, because `SaveSystem.SAVE_DIR` was a `const` — so every case that wrote a
## slot wrote it into the developer's real save directory. Those cases deleted what they wrote,
## which is not the same as never having written it: a case that crashes between the write and
## the delete leaves a slot behind, and the slot numbers the suite picks are slot numbers a
## player may have filled.
##
## WHY user:// AND NOT A FOLDER UNDER res://, and it is `fixtures.gd`'s reason unchanged: a
## directory inside the repository would be one a crashed run leaves dirty for `check_content.gd`
## to fail on. `user://` is outside the tree, so the worst a crash leaves is a stale scratch
## directory that the next `activate()` empties.
##
## EMPTIED ON THE WAY IN AS WELL AS OUT. `activate()` clears the directory rather than trusting
## `deactivate()` to have run, on exactly `fixtures.gd`'s reasoning: the run that failed to clean
## up is the run that crashed, and it is the next case that pays for it.
##
## OWNS: the scratch save directory, and pointing `SaveSystem` at it and back.
## MUST NOT: write save FILES (a case builds the file it wants to assert about), or assert
## anything.

const ROOT: String = "user://test_saves"

static var _active: bool = false


static func is_active() -> bool:
	return _active


## Point `SaveSystem` at the scratch directory, emptied first. Idempotent.
static func activate() -> void:
	_empty(ROOT)
	SaveSystem.save_dir = ROOT
	_active = true


## Back to whatever the game itself ships. Called by the runner after EVERY case, not only by the
## cases that switched, for `fixtures.gd`'s reason: a case that crashed part way through would
## otherwise hand the next one a redirected store, and a later case writing a "slot" would put it
## somewhere no one is looking.
static func deactivate() -> void:
	if not _active:
		return
	_active = false
	_empty(ROOT)
	SaveSystem.save_dir = SaveSystem.DEFAULT_SAVE_DIR


## Remove every file in `path`, leaving the directory. Absent is already empty.
static func _empty(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		dir.remove(file_name)
