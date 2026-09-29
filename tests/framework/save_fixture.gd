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
## AND THE SETTINGS FILE, T6.11, the seventh root. `Settings.PATH` was a `const` too, and the
## suite's `reset_to_defaults()` saved it: a green run left the developer's `settings.cfg` at ZERO
## BYTES. Unlike the store it is not per case. The runner points `Settings.file_path` here once,
## before the first case, because a settings write is not something a case opts into: five
## cases do it, most on their first line, and a per-case switch is the one a new case forgets
## (T6.9's recorded gap). Never emptied: nothing reads it back, so nothing in it can go stale.
##
## PER RUN, T6.13. Both paths are inside `RunScratch.root()`, which is named for this process, so
## the emptying above can only ever empty this run's own files. They were fixed names under a
## `user://` every worktree shares, and a second suite's `activate()` deleted the first's slots
## mid-case. `RunScratch`'s header has the measurement.
##
## OWNS: the scratch save directory and pointing `SaveSystem` at it and back, and the name of the
## scratch settings file.
## MUST NOT: write save FILES (a case builds the file it wants to assert about), or assert
## anything.

static var _active: bool = false


## The scratch save directory, inside this run's own.
static func root() -> String:
	return RunScratch.path("saves")


## Where every settings write of a suite run goes. Set by `test_runner.gd`, read by nothing.
static func settings_path() -> String:
	return RunScratch.path("settings.cfg")


static func is_active() -> bool:
	return _active


## Point `SaveSystem` at the scratch directory, emptied first. Idempotent.
static func activate() -> void:
	_empty(root())
	SaveSystem.save_dir = root()
	_active = true


## Back to whatever the game itself ships. Called by the runner after EVERY case, not only by the
## cases that switched, for `fixtures.gd`'s reason: a case that crashed part way through would
## otherwise hand the next one a redirected store, and a later case writing a "slot" would put it
## somewhere no one is looking.
static func deactivate() -> void:
	if not _active:
		return
	_active = false
	_empty(root())
	SaveSystem.save_dir = SaveSystem.DEFAULT_SAVE_DIR


## Remove every file in `path`, leaving the directory. Absent is already empty.
static func _empty(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		dir.remove(file_name)
