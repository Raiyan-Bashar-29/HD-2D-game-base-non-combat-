class_name TestScratch
extends RefCounted
## The one directory a suite run may write to, and it belongs to this process alone.
##
## THE PROBLEM THIS CLOSES (T6.13). `user://` is named after the project, not the checkout, so
## every worktree on a machine shares one. The scratch directories were fixed names under it —
## `user://test_saves`, `user://test_fixtures` and four more — so two suites running at once
## shared them, and each `SaveFixture.activate()` empties its directory. One run deleted the other
## run's slot files mid-case: T6.12's clean run failed eleven assertions in `menus_test` and
## `smoke_test` ("the session loads — expected 0, got 16") while another worktree's suite ran, and
## the re-run passed. `Fixtures` had the same race more quietly: every `activate()` rewrites the
## `.tres` files, so a registry could scan a file the other run was half way through writing.
##
## ONE ROOT PER PROCESS, NAMED FOR ITS PID. Every scratch path in the suite is built under `ROOT`,
## so two concurrent runs never name the same file. A per-process id and not a random one because
## it is what lets a later run tell a crashed run's leftovers from a live run's directory.
##
## REMOVED ON THE WAY OUT, SWEPT ON THE WAY IN. The runner removes `ROOT` when it finishes. A run
## that crashed never reaches that line, so the runner's first act is `sweep_stale()`, which
## removes every other run's root whose process is no longer running. A LIVE process's root is
## never touched, which is the entire point. A reused pid can only make the sweep leave a dead
## run's directory for one more run, never delete a live one.
##
## NOT IN src/, AND NOTHING IN src/ KNOWS IT EXISTS. The seams it feeds were already there:
## `SaveSystem.save_dir` and each registry's `content_dir`. This only changes the values.
##
## OWNS: the per-process scratch root, and removing it and dead runs' roots.
## MUST NOT: know which case writes what under it (the fixtures own their own subdirectories), or
## assert anything.

## Every run's root starts with this, and the pid follows it. `sweep_stale` reads it back.
const PREFIX: String = "test_run_"

## Not a `const` because a pid is not a constant expression. Assigned once, when the class loads,
## and never again: `static var` in an upper-case name so call sites still read like the path it is.
static var ROOT: String = "user://%s%d" % [PREFIX, OS.get_process_id()]


## A path under this run's root. `name` may contain slashes.
static func path(name: String) -> String:
	return "%s/%s" % [ROOT, name]


## Remove this run's root and everything in it. The runner calls it last.
static func remove_own() -> void:
	_remove_tree(ROOT)


## Remove every other run's root in `parent` whose process has exited, and return how many. The
## runner calls it first on `user://`, so a crashed run costs the disk one directory until the next
## run. `parent` is a parameter so `scratch_test` can sweep a sandbox inside its own root: planting
## a "dead run" in `user://` itself would be swept by any concurrent suite before it asserted.
static func sweep_stale(parent: String = "user://") -> int:
	var removed: int = 0
	var own: int = OS.get_process_id()
	for folder: String in DirAccess.get_directories_at(parent):
		if not folder.begins_with(PREFIX):
			continue
		var digits: String = folder.trim_prefix(PREFIX)
		if not digits.is_valid_int():
			continue
		var pid: int = digits.to_int()
		if pid == own or OS.is_process_running(pid):
			continue
		_remove_tree(parent.path_join(folder))
		removed += 1
	return removed


## Files first, then subdirectories, then the directory itself. Absent is already removed.
static func _remove_tree(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute("%s/%s" % [dir_path, file_name])
	for folder: String in DirAccess.get_directories_at(dir_path):
		_remove_tree("%s/%s" % [dir_path, folder])
	DirAccess.remove_absolute(dir_path)
