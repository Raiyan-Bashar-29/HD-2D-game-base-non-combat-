extends TestCase
## Every scratch directory the suite writes is this run's alone, and a dead run's is swept.
##
## THE DEFECT, AS IT STOOD (T6.13). `user://` is shared by every worktree on a machine, and the
## scratch directories were fixed names under it, so two suites at once emptied each other's
## save slots mid-case. The claim that closes it has two halves, asserted separately because
## each can break alone: every scratch root is under `TestScratch.ROOT`, which carries this
## process's id; and `sweep_stale` removes a root whose process has exited and leaves every
## other one, above all this run's own.
##
## THE CONCURRENCY ITSELF IS NOT ASSERTED HERE. A case cannot launch a second suite and wait on
## it inside one frame loop, and a sleep-and-hope case would be the flaky test this row exists
## to remove. It was proved by launching two runs at once; the command is in the DEVLOG entry.
##
## OWNS: assertions about `TestScratch`, and that the fixtures build their roots on it.
## MUST NOT: assert what a fixture writes (save_dir_test, content_scan_test), or call
## `TestScratch.remove_own()`, which would delete the directories the store is parked in.

## A folder name that begins with the prefix but carries no pid, so the sweep must leave it.
const NOT_A_RUN: String = "test_run_not_a_pid"
const PLANTED_FILE: String = "planted.txt"


func run() -> void:
	plan(12)
	_the_root_names_this_process()
	_every_fixture_root_is_under_it()
	_a_dead_run_is_swept_and_nothing_else()


func _the_root_names_this_process() -> void:
	equal("the root is under user://", TestScratch.ROOT.begins_with("user://"), true)
	equal("and names this process",
			TestScratch.ROOT.get_file(), "%s%d" % [TestScratch.PREFIX, OS.get_process_id()])
	equal("a path is built under it", TestScratch.path("a/b"), TestScratch.ROOT + "/a/b")


## One assertion per root, because the defect was a single fixed name, and one left behind would
## reopen it for exactly the cases that use that root.
func _every_fixture_root_is_under_it() -> void:
	var under: String = TestScratch.ROOT + "/"
	equal("the save scratch is this run's", SaveFixture.ROOT.begins_with(under), true)
	equal("so is the parking directory", SaveFixture.UNCLAIMED.begins_with(under), true)
	equal("so is the fixture content root", Fixtures.ROOT.begins_with(under), true)
	equal("and every registry directory is inside it",
			Fixtures.AREA_DEF_DIR.begins_with(Fixtures.ROOT + "/"), true)


## IN A SANDBOX INSIDE THIS RUN'S OWN ROOT, NOT IN user:// ITSELF. The first version planted its
## dead run in `user://`, and two suites launched at once each swept the other's plant before it
## was asserted: the very race this row closes, reproduced by its own test. The sandbox holds a
## dead run, a live one (this process), and a folder that names no pid, so exactly one is swept.
##
## THE PID IS SEARCHED FOR, NOT ASSUMED DEAD. A literal pid could belong to a live process on
## some machine, and the sweep would then correctly leave it and fail this case for no reason.
func _a_dead_run_is_swept_and_nothing_else() -> void:
	var sandbox: String = TestScratch.path("sweep")
	var dead: int = 2147480000
	while OS.is_process_running(dead):
		dead -= 4
	var dead_root: String = sandbox.path_join("%s%d" % [TestScratch.PREFIX, dead])
	var live_root: String = sandbox.path_join("%s%d" % [TestScratch.PREFIX, OS.get_process_id()])
	var decoy: String = sandbox.path_join(NOT_A_RUN)
	DirAccess.make_dir_recursive_absolute(dead_root.path_join("saves"))
	_plant(dead_root.path_join("saves"))
	DirAccess.make_dir_recursive_absolute(live_root)
	DirAccess.make_dir_recursive_absolute(decoy)
	equal("the dead run's root was planted", DirAccess.dir_exists_absolute(dead_root), true)

	equal("the sweep removes exactly the dead run", TestScratch.sweep_stale(sandbox), 1)
	equal("the dead run's root is gone, files and all",
			DirAccess.dir_exists_absolute(dead_root), false)
	equal("a live run's root is left alone", DirAccess.dir_exists_absolute(live_root), true)
	equal("and a folder that names no pid is not a run",
			DirAccess.dir_exists_absolute(decoy), true)
	for leftover: String in [live_root, decoy, sandbox]:
		DirAccess.remove_absolute(leftover)


func _plant(directory: String) -> void:
	var file: FileAccess = FileAccess.open(directory.path_join(PLANTED_FILE), FileAccess.WRITE)
	if file != null:
		file.store_string("left by a run that crashed")
		file.close()
