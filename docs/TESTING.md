# Adding assertions to a template you did not write

Rung 4 of the ladder is a headless test suite with the real autoloads live. It is not a
conventional Godot test setup, and five of its rules will cost you an hour each if you meet them
by discovering them. They are all here.

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless res://tests/test_runner.tscn --quit-after 400
```

Exit 0 if every assertion passes, 1 otherwise. The last line reads
`=== 1517 passed, 0 failed, 0 skipped ===`.

---

## The five things that are not obvious

### 1. The suite is a SCENE, entered positionally. Never `--script`.

`res://tests/test_runner.tscn`, given as a positional argument. Under
`--headless --script foo.gd` the autoload *nodes* are created but the autoload *identifiers*
(`Log`, `Flags`, `Events`) fail to compile — `Compile Error: Identifier not found: Log`. So no
test that touches a system can be a `--script` tool, and the same is true of
`--headless --check-only --script` on any file mentioning an autoload: that error is expected
there and means nothing.

### 2. `TestCase.run()` is SYNCHRONOUS. No assertion can await a frame or press a key.

The runner calls `run()`; it does not await it. So nothing in a test can wait for a physics step,
a threaded load, a tween, or an input event — an `InputEvent` pushed inside `run()` never reaches
the frame that would deliver it.

What the suite does instead:

- **Drive the seam directly.** Interactions go through `attempt()`, a climb through
  `climb_step(delta)` in a bounded loop. If a system only works via `_physics_process`, the thing
  to assert is the pure function underneath it.
- **Extract the pure part.** The wetness dry-out is a plain `RefCounted` with no node in it
  precisely so its behaviour over time is assertable rather than photographable.
- **For a real frame, a temporary probe.** Add one to `src/systems/debug/` — `dev_capture.gd` is
  where they go — run it windowed with real `InputEventAction`s, read the log, quote it in
  `DEVLOG.md`, and then **remove it**. This is the approved substitute and it has a worked example
  in `DEVLOG.md` for every package that needed one. `git diff src/systems/debug/` must be empty
  when you are done.

Multi-frame scenarios that recur — twenty area round trips, a whole NPC day — live as *runs* in
`dev_probes.gd`, not as assertions.

### 3. Every case declares a `plan(n)`, maintained by hand.

The first statement of `run()`:

```gdscript
func run() -> void:
    plan(14)
    _the_first_block()
    _the_second_block()
```

Add an assertion, bump the number. A stale plan fails loudly with both numbers and the case name,
so it is self-correcting friction rather than a trap.

**Why bookkeeping nobody likes, and why nothing cheaper works.** A GDScript runtime error aborts
**only the innermost frame** — probed: a null dereference three frames deep printed its
`SCRIPT ERROR`, and both the calling function and `_ready()` above it ran to completion. So the
runner sees a case that returned normally, and a completion sentinel at the end of `run()` cannot
work either, because it is reached. Nothing the runner can inspect afterwards differs, **except
that the assertions after the crash never ran.** A count is the only thing that sees that, and the
same line catches three more silent passes: an early `return`, a block commented out, and a case
that asserts nothing at all. This is TAP's `1..N`, for TAP's reason.

A crashing case exited 0 for the life of this project before the plan existed. That invalidated
every green result it had.

**A plan may be computed, and should be when the count depends on content.** `transitions_test.gd`
declares `plan(FIXED + PER_AREA * areas.size())`, so authoring an area does not mean editing a
number. Compute it from something you gathered *before* the assertions run.

**A skip counts as the outcomes it stands in for**, so the plan is the same number with or without
demo content in the checkout.

### 4. The plan is not enough on its own — and the second mechanism is why.

A crash in a *leaf helper with nothing asserted after it* meets its plan exactly and reports a
clean pass. Measured, with the plan already in place: a planted `nothing.get_child_count()`
produced `2/2` and exit 0.

`tests/framework/error_watch.gd` is the only thing in the engine that sees it — an `OS.add_logger`
`Logger` counting `ERROR_TYPE_SCRIPT`, read per case so the failure names the case that crashed.
You do not have to do anything to get this; you have to know it exists, because **it fails a case
that raises an engine script error even if every assertion passed.** Only `ERROR_TYPE_SCRIPT`
fails; `push_error` arrives as `ERROR_TYPE_ERROR` and is counted and reported but not fatal, since
several cases assert refusals and bad input on purpose.

### 5. A case must be listed in the runner, or it never runs.

Add your file's path to `CASES` in `tests/test_runner.gd`. `_manifest_is_complete()` scans
`tests/unit/` and fails on a file that exists and is not listed — a suite file nobody listed is
never run and every rung stays green, which is the same failure shape as a file that does not
parse, one layer up.

---

## Writing a case

```gdscript
extends TestCase
## What this file covers, and what it deliberately does not.
##
## OWNS: ...
## MUST NOT: ...

func run() -> void:
    plan(3)
    _a_named_block()


## One behaviour per function, named as the sentence it proves.
func _a_named_block() -> void:
    equal("an empty inventory holds nothing", inventory.count(), 0)
```

- **`equal(label, actual, expected)` is the only assertion**, deliberately: a suite with eight
  helpers spends its time debating which to use. Floats go through
  `equal(label, is_equal_approx(a, b), true)`.
- **`skip(label, why, stands_for)`** where a block genuinely asserts something about *authored
  content* that a stripped template does not have. A skip is printed and counted; silence would
  let a stripped run look identical to a full one while covering a third less.
- **`build(scene_path)` then set exported properties then `attach(node)`**, in that order.
  `Interactable` forwards `object_id` to its `PersistentState` child in `_enter_tree`, which runs
  on `add_child` — anything set afterwards is too late and the object silently stops persisting. A
  one-step `spawn()` helper hid exactly that bug the first time the framework was written.
- **Free what you build.** Anything alive at exit prints a wall of leaked-RID errors, and that
  noise is how a real error gets lost.
- The case's own file is subject to `check_budgets` — 250 code lines, 40 per function. Split the
  file rather than raising a budget.

## A test builds its own content

**A test that names demo content is testing the demo.** `tools/check_boundary.gd` scans
`tests/unit/` and `tests/framework/` as well as `src/`, and it derives the forbidden names from
`scenes/areas/` and the ids in `data/`, so this is a gate, not a habit.

`tests/framework/fixtures.gd` is the seam, and its rule is one line: **in memory when a system is
HANDED content, on disk when a system LOOKS IT UP BY ID.**

| Your system | Fixture |
|---|---|
| receives an `ItemDefinition` / `PathAction` (a `Pickup`, a `PathActionPoint`) | build it in memory with `FixtureContent` and set it on the node. No files, no global state |
| looks content up by id (`Inventory.add(id)`, `DialogueRunner.begin(id)`, an `NpcBrain` reading a schedule, `QuestTracker` reading a quest, `WorldMap` reading an area def) | `Fixtures.activate()` — it writes `.tres` files to `user://test_fixtures/` and points all five registries' `content_dir` there |

The five registries scan a directory (ADR-0006) and cache statically, so an in-memory
`ItemDefinition` is **invisible** to `Inventory.add(id)`. A test-only injection method on each
registry was rejected: a backdoor in engine code that exists for the suite and nothing else is
worse than a temp folder, and going out through `ResourceSaver` and back through the real scan
proves the `.tres` authoring round trip as a side effect.

`user://` and not a folder under `res://`, because writing into `res://data/` would mutate the
content root `NEW_GAME.md` tells a game to delete, and a crashed run would leave stray files that
`check_content` then fails on.

The runner calls `Fixtures.deactivate()` after **every** case, including ones that never
activated — a case that crashed half way through its fixtures would otherwise hand the next one a
redirected content root and never say so.

Everything in `FixtureContent` is abstract on purpose: `fixture/unique`, `fixture_post_a`. If a
name in there ever describes a place, that is the demo growing back.

### Asserting something about content that may not exist

`Fixtures.has_demo_content()` answers whether this checkout still has a game in it, and
`Fixtures.area_ids()` **discovers** the areas rather than listing them — so a contract holds for
area three the day it appears, and for none at all in a stripped template. That is the shape to
copy: scan, then either assert per item found or `skip` with the count.

---

## Proving a gate

**A gate that never fails has never been tested.** Every checker and every regression assertion
added since T1.2 is proved by planting the violation it exists to catch, watching it exit 1,
removing it, watching it exit 0 — with both outputs quoted in `DEVLOG.md`. It costs two minutes
and it is the only thing separating a gate from a reassuring printout.

Plant the *real* failure, not a convenient one: the assertion that fails when you break the
assertion is not evidence.

## What the suite cannot see

Stated so nobody reads a green run as more than it is:

- **Anything visual.** `--headless` uses a dummy rasteriser and shades nothing. Lighting, sprite
  cells, legibility — windowed capture, and look at the PNG.
- **Anything needing a frame.** See rule 2.
- **An exported build.** A test running under `res://` cannot test a build it is not running in;
  `export_test.gd` asserts `is_exported() == false` rather than leaving that blindness implied.
  The export proof is a run of the executable with both sides' numbers quoted.
- **`0 warnings, 0 errors` from the boot rung is not a compile check.** It counts the game's own
  `Log` calls. Grep `--headless --import` for `SCRIPT ERROR` and `Parse Error` instead.

## Read next

[`AUTHORING.md`](AUTHORING.md) · [`ARCHITECTURE.md`](ARCHITECTURE.md#the-extension-surface) ·
[`CONTEXT.md`](CONTEXT.md) — the forty gotchas, several of which are the long form of the rules
above · `tests/framework/test_case.gd` and `tests/test_runner.gd`, whose headers carry the
reasoning in full.
