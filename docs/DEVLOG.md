# Development Log

Append-only. Newest entry at the top. One entry per working session.

**Entry template**

```
## YYYY-MM-DD — Title
**Did:**       what changed, concretely
**Why:**       the reason, so a future reader does not undo it
**Connects:**  how the new pieces wire into what already existed
**Verified:**  the exact command run, and its result. No claim without one
**Unblocks:**  what is now possible that was not before
**Known gaps:** what is deliberately still missing
```

---

## 2026-08-30 — T3.1 · One scan, five typed façades

**Did.** Collapsed five copies of the same scan-and-validate into one function, on
`claude/t3-1-registry` branched from `claude/wp-09b-attributes`. Two new engine files:
`src/content/content_entry.gd` (5 code lines) is the base every catalogued `.tres` now extends —
an `@export var id` and a `problems()`, and nothing else; `src/content/content_scan.gd` (39) holds
`into()`, which walks a content root, loads each `.tres`, checks it is the right class, checks its
`id` against its file name, refuses a duplicate, appends the resource's own `problems()` and puts
it in **the caller's dictionary**, plus `resource_paths()` and `_normalise()` moved verbatim from
`ItemDb`. The five registries lost `_register()` entirely and are now typed façades: content root,
typed cache, typed accessor, and a two-line `_ensure_loaded()`. `ItemDefinition`, `Conversation`,
`NpcSchedule`, `Quest` and `AreaDef` each changed one line — `extends Resource` to
`extends ContentEntry` — and dropped their own `@export var id`. `ItemDb.resource_paths()` became
`ContentScan.resource_paths()` at nine call sites with no alias left behind. New case
`tests/unit/content_scan_test.gd` (153 code lines, 47 assertions), listed in `CASES`.

**Why.** WP-08 reconsidered this refactor at the fourth copy and **kept** the copy, on reasoning
that has not been overturned: GDScript has no generics, so a base holding the CACHE could only
store `Resource` and hand it back untyped, and every accessor would become a cast at the call site
— against non-negotiable #2. WP-11 made it the fifth copy and changed only the arithmetic. Both
were right about the wrong half. **The duplication was never in the cache.** A scan needs exactly
two things from a resource — its `id` and its `problems()` — so the base belongs on the
**resource**, and the shared part is a **function** that fills a dictionary the caller owns and
types. `ItemDb._by_id` is still `Dictionary[StringName, ItemDefinition]`, `ItemDb.definition()`
still returns `ItemDefinition`, and grep finds no new cast anywhere. Measured, in code lines as
`check_budgets` counts them: five registries **290 → 187**, plus 44 shared, so **290 against 231**.
The −59 is the least interesting number; what matters is that `_register()` was 17 lines
duplicated five ways, and a bug in the id check, the duplicate check, the type check or the
`.remap` handling is now one fix.

`ContentEntry` is not tidiness. `project.godot` sets `unsafe_property_access` and
`unsafe_method_access` to **error**, so a shared scan reading `resource.id` or calling
`resource.problems()` through a `Resource` does not compile at all. The base is what makes the
shared scan legal, and its `MUST NOT` says a field belongs there only when the SCAN uses it.

**Connects.** Nothing above `src/content/` changed. `Inventory`, `DialogueRunner`, `NpcBrain`,
`QuestTracker`, `WorldMap`, `Speaker` and `check_content.gd` all call the same accessors on the
same class names and got the same answers. `tests/framework/fixtures.gd` — the seam every case
depends on — still redirects five separate `content_dir` variables and still calls five separate
`rescan()`s, because that is the only shape that works (see the gotcha below). The
`.tres` format is untouched: the demo's files declare `id` exactly as before, now satisfying the
base's export instead of the subclass's, and `check_content` loads all of them unchanged.

**Verified.**

```
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --import                        # zero SCRIPT ERROR / Parse Error
"$G" --headless --quit-after 120                # Session ended after 1.2s — 0 warnings, 0 errors
"$G" --headless res://tests/test_runner.tscn --quit-after 400
                                                # === 1402 passed, 0 failed, 0 skipped ===
"$G" --headless --script tools/check_budgets.gd # 125 files, 10506 code lines, 0 warnings, 0 violations — PASS
"$G" --headless --script tools/check_content.gd # PASS
"$G" --headless --script tools/check_boundary.gd# PASS, 119 engine scripts scanned
```

1355 → 1402, +47, none lost.

**The stripped template, run locally, because it is the load-bearing rung for this package.**
`data/` and `scenes/areas/` moved aside, `--import`, then the suite: **`1334 passed, 0 failed, 19
skipped`** against 1287/19 before — +47, the same 19 skips, so every new assertion runs with no
authored content on disk. `check_content` exit 0 and `check_boundary` exit 0 on the stripped
checkout, which is the thing that proves **an empty content root is still not an error**. Both
directories restored and the full run re-confirmed at 1402.

**The gates were proved failing (gotcha 23).** Two real violations planted in `data/items/` —
`planted_mismatch.tres`, a copy of a real definition carrying `id = &"item/mismatched"`, and
`planted_broken.tres`, one line of prose:

```
  !! res://data/items/planted_broken.tres is not an ItemDefinition
  !! res://data/items/planted_mismatch.tres declares id 'item/mismatched' but its file name requires 'item/planted_mismatch'
FAIL — 2 content violation(s)
check_content exit code = 1
```

Both removed:

```
PASS
check_content exit code = 0
```

The suite's own exit 1 needed no planting: the first run of the new case failed for real (below),
`=== 1401 passed, 1 failed, 0 skipped ===`, and the runner exited 1.

**NEW GOTCHA 37, and it decided the whole design.** The obvious refactor is
`ItemDb extends ContentDb` with `_by_id`, `_loaded` and `content_dir` as `static var`s on the base.
Probed under 4.7.2 with two throwaway subclasses bumping a base counter:

```
A.shared=3 B.shared=3 Base.shared=3
```

**A base-class `static var` is ONE storage shared by every subclass.** Five registries inheriting
it would have shared one cache and one `content_dir`, so `Fixtures.activate()` would have pointed
all five at a single folder and four catalogues would have come back empty — with every accessor
still typed and the class diagram still looking right. That is why the shared part is a function
and each façade keeps its own three statics. The same probe confirmed the three other facts the
design rests on: `is_instance_of(res, ItemDefinition)` discriminates correctly with a `class_name`
passed as a `Script`; `Script.get_global_name()` returns `ItemDefinition`; and a
`Dictionary[StringName, ItemDefinition]` passed through an untyped `Dictionary` parameter keeps
its value type (`is_typed_value() == true`) and is filled by reference — which is the mechanism
that keeps every accessor typed. The probe scripts were deleted; `git diff` shows no
`tools/_probe/`.

**The one thing the new test got wrong first, and it is a suite-wide lesson.** The case writes a
sound `AreaDef`, scans, then writes a *different* `AreaDef` over the same path and scans again to
prove a resource's own `problems()` reach the caller. It reported `expected 1, got 0`:
**`ResourceLoader` caches by path**, so the second scan was handed the first resource. One failing
assertion was the only trace. The fix is a second id rather than a second write, and anything in
the suite that expects a re-authored file to be re-read needs a new path.

**What the 47 assertions are for.** A refactor's real assertions are the existing ones staying
green, and those did. The new ones exist for the failure mode a *shared* scan has and five copies
did not: it can go on working for four catalogues and quietly stop reporting a bad file for the
fifth. So `content_scan_test.gd` drives `into()` directly for every branch it has — empty root,
absent root, sound file, id mismatch naming both values, a resource of the wrong type, a
`.tres`/`.res` duplicate, an empty prefix (`AreaDb`'s shape, which no other registry exercises),
and a resource whose own `problems()` must propagate — and then plants the same violation in all
five fixture roots at once and names **each registry by hand**. It also asserts one bad file costs
the catalogue exactly that file, and that every `content_dir` goes back to its own constant after
`Fixtures.deactivate()`.

**A windowed capture, although there should have been nothing to see.**
`--resolution 960x540 --quit-after 90 -- --new-game --shot-frame=70 --time=12:00`: the courtyard at
midday with the player, the keeper, the sign, the pickup, the HUD clock and the
`Read Weathered Notice` prompt — indistinguishable from WP-09b's, which is the point. The boot
readout still names every catalogue and its resolved paths — `items: 4`, `dialogue: 1`,
`schedules: 1`, `quests: 1`, `areas: 2` — and the session ended `0 warnings, 0 errors`. **If a
screen had changed, the refactor had leaked.** No temporary probe was needed: this package touches
no input path and no audio path, and `src/systems/debug/` carries exactly one deliberate line, the
`resource_paths` rename in `catalogue_report.gd`.

**The acceptance test was `docs/AUTHORING.md`, and not one word of it changed.** It names `ItemDb`
once, describes the scan, the folders and the id-equals-filename rule, and every sentence in it is
still true. `docs/TESTING.md` needed one number.

**Unblocks.** A sixth catalogue is now a 36-line façade rather than a sixth copy of the scan — and
that cuts both ways, which `content_scan.gd`'s header says: WP-09b deliberately did *not* add one
for attributes, and cheapness is not a reason to. Any improvement to the scan — recursion into
subdirectories, a better duplicate diagnostic, a different `.remap` case — is now one edit that
five catalogues and both content gates inherit at once.

**Known gaps.** No sixth catalogue, no hot-reload or file-watcher on the content roots, no content
editor, no async or threaded scanning, no cache outliving a session, and no change to what a
`.tres` may contain — all deferred deliberately, because a consuming game must not be able to tell
this package happened. `ContentScan` does not recurse into subdirectories; neither did any of the
five copies, and nobody has asked. `ContentEntry` holds `id` and `problems()` and nothing else, on
purpose: `name_key` is on four of the five content types but not on `NpcSchedule`, and a field the
scan does not read has no business on the base. The five façades are still five files — the two
`content_dir` lines and the three-line `has()`/`count()`/`problems()` are duplicated by shape, and
they are not worth removing, because each of them names a type.

**Files: 20**, which exceeds the board's "about 8". Two new files, five registries rewritten, five
resource classes changed by one `extends` line, one new test case, and eleven single-identifier
renames the compiler would have caught. New code is negative. The rule's reasoning — a package
that outgrows one chat gets half-finished — was never in danger, and the count is said out loud
rather than quietly exceeded.


**CI green, run 33267916883, job logs read rather than the tick** (gotcha 26 — the run listing
lags and the tick is not the evidence). Full checkout: **`1402 passed, 0 failed, 0 skipped`**,
`125 files, 10506 code lines, 0 warnings, 0 violations`. **Stripped template — the load-bearing
job for this package, because it is the only rung that proves an empty content root is still not
an error: `1334 passed, 0 failed, 19 skipped`**, against `1287 passed, 0 failed, 19 skipped`
before. Same nineteen skips, forty-seven more assertions, and `check_content` and
`check_boundary` PASS on a checkout with `data/` and `scenes/areas/` deleted. All rungs green in
both jobs, and the workflow was not touched.

**Commit `767fbe3` on `claude/t3-1-registry`, PR #20**, stacked onto
`claude/wp-09b-attributes` (#19) rather than `main`, matching the rest of the chain.

---

## 2026-08-29 — WP-09b · Attributes, and the ground under your feet

**Did.** The two thirds of WP-09 that were split out for having no consumer, on
`claude/wp-09b-attributes` branched from `claude/wp-11-worldmap`. `Attributes`
(`src/gameplay/character/attributes.gd`, 21 code lines) is a namespace over `Flags` —
`attr/<who>/<name>`, an integer number of steps clamped to ±4 — with no resource, no registry and
no save section. `GroundSurface` (`src/gameplay/world/ground_surface.gd`, 26) resolves a node to
the `metadata/surface` on it or on its nearest tagged ancestor. `Footsteps`
(`src/gameplay/character/footsteps.gd`, 115) is a component under a body that probes downward,
takes a step every 1.7 metres and generates the sound from the surface's NAME. `PlayerController`
gained `character_id`, the const `PACE`, and a public `current_speed()` that scales every gait by
the attribute. Content: three `metadata/surface` tags in `courtyard.tscn`, one in
`lantern_hall.tscn`, a `Footsteps` node in `player.tscn`. 56 new assertions in
`tests/unit/character_depth_test.gd` and a new `AUTHORING.md` section.

**Why.** The row's own instruction was "decide FIRST what reads one", and it was the right one:
17 of the 23 settings have no consumer, and WP-09 found `Gate.locked_key` and
`PathAction.refusal_key` declared, validated by a content gate and read by nothing for six
packages. So this ships with exactly ONE consumer and two structural defences against that number
growing quietly. There is no registry and no enum of attribute names — any StringName is an
attribute the moment something writes it, which meets ADR-0006's no-code-per-thing test without a
sixth directory scan (`area_db.gd`'s header warns against one). And **an attribute's name is a
const on its CONSUMER**, `PlayerController.PACE`, never on the container: an attribute nobody reads
therefore has nowhere to be written down, and `attributes.gd` cannot accumulate a table of good
intentions. That is the whole design — a rule about where a name lives, not a mechanism.

A value is a STEP rather than the number: a flag holding `4.7` would be a walk speed authored into
a save file and the tuned `walk_speed = 3.2` would stop being the truth. Clamped for `Standing`'s
reason — a repeatable action must not farm a number that later gates content.

A surface is metadata rather than a component (a node per floor tile), a group (one flat namespace
shared with `navmesh_source`, where a typo becomes a second surface silently) or an enum — **a
list of surface names in `src/` is engine code naming demo content, which `check_boundary` fails
the build over.** Inheriting from the nearest tagged ancestor is what makes it cheap: the courtyard
tags `Terrain` once and overrides the two floors that differ. The step's timbre is DERIVED from the
name for the same boundary reason: a table would be the same violation, and it would mean a game
authoring `sand` gets silence until someone edits `src/`. Art is deferred and audio is art, so the
burst is generated the way `AmbienceBed` generates its rain, and `stream_for()` is the one function
a game with real recordings replaces.

**Connects.** `attr/<who>/<name>` is the FIFTH use of namespace-over-`Flags` after
`PersistentState`'s `obj/<area>/<object>/<field>`, `Standing`'s `standing/<who>`, `Equipment`'s
`equip/<wearer>/<item>` and `WorldMap`'s `map/<area>` — WP-11 said the next thing needing saved
per-thing state should reach for it before reaching for a save section, and it did, first. The same
three consequences follow and all three are asserted: already saved with no register, version or
migration; already cleared by a new game; already announced on `flag_changed`, so a quest step or a
dialogue condition can test an attribute with no code at all. It needed no new staging flag either
— `--flag=attr/player/pace:4` already exists, already waits for the area (gotcha 32) and already
goes through `_settle_stable` (gotcha 35), so `dev_stage.gd` stayed at 247 of its 250 lines and did
not have to split. `Footsteps` is a component found under a body, the shape `Inventory` and
`Equipment` already have; it plays through its own `AudioStreamPlayer3D` rather than through
`Audio`, which is what `audio_director.gd`'s header asks for in the words "a footstep playing after
the character is gone". No new signal, no new autoload, no new registry, no new CSV row.

**Verified.**

```
"$G" --headless --import                     # grepped for SCRIPT ERROR / Parse Error: zero
"$G" --headless --quit-after 120             # Session ended after 1.3s — 0 warnings, 0 errors
"$G" --headless res://tests/test_runner.tscn --quit-after 400
                                             # === 1355 passed, 0 failed, 0 skipped ===
"$G" --headless --script tools/check_budgets.gd   # 122 files, 10416 code lines, 0 violations — PASS
"$G" --headless --script tools/check_content.gd   # PASS
"$G" --headless --script tools/check_boundary.gd  # PASS, 116 engine scripts scanned
```

**The windowed probe, which is the only thing that can see either criterion.** Neither claim is
visual, so no capture reads it, and `TestCase.run()` is synchronous, so no assertion reaches it.
Run windowed with a temporary `--footsteps` probe in `dev_probes.gd`, since removed —
`git diff src/systems/debug/` is empty:

```
PROBE audible=true driver=WASAPI
PROBE at (4.0, 0.2, 4.0)    grounded=true surface='grass' brightness=0.733 decay=2.13 playing=true steps=1
PROBE at (0.0, 0.6, -2.0)   grounded=true surface='wood'  brightness=0.841 decay=4.68 playing=true steps=2
PROBE at (-8.5, 3.4, -2.5)  grounded=true surface='stone' brightness=0.550 decay=3.02 playing=true steps=3
PROBE pace=0 speed=3.200 moved=2.861 m in 60 frames, steps=4
PROBE pace=4 speed=4.800 moved=4.687 m in 60 frames, steps=7
```

Three surfaces, correct: grass and wood from their own tags and **stone INHERITED from `Terrain`**,
which is the walk up the tree working in a real area rather than in a fixture. Then the attribute
criterion, driven by real `MOVE_UP` input over the same 60 physics frames: 2.861 m at `pace=0`
against 4.687 m at `pace=4`, and 4 steps against 7, because a faster walk fills a stride sooner.

**A DEFECT THE PROBE FOUND AND NOTHING ELSE COULD HAVE, AND IT IS GOTCHA 2 WITH A SPEAKER ON IT.**
The first run of that probe reported `playing=true` on all three surfaces with every rung green —
and grass came back at brightness 0.452 against stone's 0.446, which is *the same sound*. The cause
is that **`String.hash()` mixes its low bits weakly**: `"grass"` hashes to 260508453 and `"stone"`
to 274826446, wildly different numbers whose last three digits are 453 and 446, so `hash() % 1000`
clusters short names of similar length — `"wood"` and `"sand"` differ by 159027 in a number of
2.09 billion. A second axis was added first and did not save it (3.65 against 3.71, the same
coincidence twice); the real fix is an avalanche in `_spread`, one multiply and two shifts, which
moves the pair to 796 and 572. Both axes were kept: two independent dimensions make the remaining
odds small. **The regression assertion demands a MARGIN, not mere inequality**, because inequality
is exactly what the broken version passed. New gotcha 36.

**A windowed capture, LOOKED AT.** `build/shots/wp09b_courtyard.png`, the courtyard at 12:00 after
the metadata edits, confirming that the three tagged materials are the three the player actually
walks on and that nothing in the scene moved: grass underfoot, the wood dais with the keeper beside
it, stone pillars and back wall.

**Proved red, then green — three times, each with the real failure shape (gotcha 23).**

1. `const HOME_GROUND := &"courtyard"` planted in `footsteps.gd` — `check_boundary` exits 1 with
   `res://src/gameplay/character/footsteps.gd:54 names demo content 'courtyard' (from
   res://data/areas/courtyard.tres)`; reverted, exit 0.
2. The consumer broken the way it would really break — `current_speed()` made to return the gait
   speed and ignore the attribute, which is *precisely* the declared-and-unread failure this
   package exists to avoid. The suite exits 1: `1352 passed, 3 failed`, first failure
   `FAILED: a raised pace is measurably faster — expected true, got false`. Reverted,
   `1355 passed, 0 failed`, exit 0.
3. The inheritance walk stopped after one node — the break that silently loses the demo's third
   surface. Exits 1 with `FAILED: an untagged body inherits from the root — expected fixture_hard,
   got `; reverted, exit 0.

**Unblocks.** Anything that wants to react to what is underfoot: a dust puff, a splash, a slower
crossing, a track left in snow — `Footsteps.current_surface()` is the query, and it is a query
rather than a signal because nothing needs one yet. Anything that wants to change a character:
a conversation, a trigger volume, a rest point or a quest consequence can write
`attr/<who>/<name>` today with no code, and a quest step can test one. And a second attribute
costs nothing to name — only the line that reads it.

**Known gaps.**
- **No footstep particles**, which the inventory row asked for beside the audio. A puff is a
  listener on the surface a step was taken on and is a package for whoever wants one.
- **Exactly one attribute has a consumer, and that is the rule rather than an omission.**
  `attr/player/patience` is writable today and nothing will do anything with it. Naming an
  attribute is free; READING one is a line of engine code, and `AUTHORING.md` says so out loud.
- No character sheet screen, no attribute that gates an interaction, no equipment that modifies
  one, and no surface that costs anything to cross — a slow surface is a `PlayerController`
  change and belongs with whoever wants the mechanic.
- **`Footsteps` polls its parent's velocity rather than being told.** Cheap and correct for one
  body; a hundred characters each raycasting every frame is not measured, and the probe pattern
  (`--npc-storm`) is where that question belongs if it ever matters.
- A surface name is a public identifier the way an item id is: renaming `grass` to `lawn` changes
  the sound every step in that area makes. Stated rather than hidden, and the same price
  `Equipment` pays for an item id.

**CI green, run 33266184919, job logs read rather than the tick** (gotcha 26 — the run listing lags
and the tick is not the evidence). Full checkout: **1355 passed, 0 failed, 0 skipped**. Stripped
template: **1287 passed, 0 failed, 19 skipped** — the same 19 skips as before, because
`character_depth_test.gd` names no demo content and therefore runs in full against a stripped
checkout, which is the point of building both surfaces out of `fixture_` names. All three checkers
PASS in both jobs.

**Commit `da126d9` on `claude/wp-09b-attributes`, PR #19**, stacked onto `claude/wp-11-worldmap`
(#18) rather than `main`, matching the rest of the chain.


## 2026-08-29 — WP-11 · World map and fast travel

**Did.** A world map, discovery and fast travel, on `claude/wp-11-worldmap` branched from
`claude/wp-09-character`. Five new files: `src/content/world/area_def.gd`,
`src/content/world/area_db.gd`, `src/systems/world_map/world_map.gd`,
`src/ui/screens/map_screen.gd`, `tests/unit/world_map_test.gd`. Two authored `AreaDef`s in
`data/areas/`, six CSV rows, one new palette colour, and a `WorldMap` node under `GameRoot`.

**Why this package over the three alternatives.** T3.1 (the generic registry), T3.3 (an
item-count quest step) and WP-09b (attributes and surfaces) are all real and all narrower, and
each improves something that already works. The world map was the last system in the catalogue
with NO PROOF AT ALL, which is the reason WP-08 went first and the same reason this went now:
`TEMPLATE.md`'s replacement for the retracted "depth before breadth" is breadth of systems with
one shallow proof each. Two areas is what the demo has and two areas is what this was proved on.

**Why it is a flag and not a store.** WP-09's section said to copy `Equipment`'s shape for
discovery, and it copied cleanly. A known area is `map/<area id>` in `Flags` — the FOURTH use of
the namespace-over-`Flags` convention after `PersistentState`'s `obj/<area>/<object>/<field>`,
`Standing`'s `standing/<who>` and `Equipment`'s `equip/<wearer>/<item>`. Three independent
systems on one convention is now a pattern rather than a coincidence. The consequences are
`Equipment`'s three, verbatim: it is already saved (no `SaveSystem.register`, no version, no
migration, and a new game clears it for free), anything that writes the key reveals a place with
no code, and `flag_changed` already announces it. So "discovery persists across a save and a
reload, including from the far side of an area that is no longer loaded" needed no code at all:
the flag never lived in the area.

**Connects.** `WorldMap` listens to `Events.area_entered` (Director) and `Events.game_started`,
writes `Flags`, and emits `Events.area_discovered` and `Events.area_change_requested` — the same
signal `AreaDoor` emits, so `Director` still owns every transition and its guard, and nothing
else calls `change_area()`. `MapScreen` reads `AreaDb` and `WorldMap` and is bound to `M` in
`ScreenKeys`, which is where that file's own header predicted the map key would land. `AreaDb` is
the fifth directory-scan registry (ADR-0006) and is reported by `CatalogueReport` and redirected
by `Fixtures` like the other four. Nothing already in the tree was modified to make discovery
work: a `DialogueChoice` effect, a `TriggerVolume` or a `Lever` writing `map/<id>` reveals a
place, and a `Gate` with `requires_flag = &"map/<id>"` is a road that opens once you know where
it goes.

**Verified.**

```
"$G" --headless --import                            # zero SCRIPT ERROR / Parse Error lines
"$G" --headless --quit-after 120                    # 0 warnings, 0 errors
"$G" --headless res://tests/test_runner.tscn --quit-after 400
"$G" --headless --script tools/check_budgets.gd     # 118 files, 10,115 code lines, exit 0
"$G" --headless --script tools/check_content.gd     # exit 0, "mapped areas: 2"
"$G" --headless --script tools/check_boundary.gd    # exit 0, 16 demo names derived
```

Suite: `=== 1298 passed, 0 failed, 0 skipped ===`, exit 0 (1224 before; 59 in the new case, 2 in
`export_test` for the fifth catalogue line, 4 in `art_contract_test` for two screens added to
`STYLED_SCREENS`, and 9 that `docs_test.gd` computed for itself from the new worked example in
`AUTHORING.md` — expected, not a regression). Boot log carries
`[content] areas: 2 found in res://data/areas -> [...courtyard.tres, ...lantern_hall.tres]` and
`[map] World map ready over 2 mapped area(s)`.

A stripped template — `data/` and `scenes/areas/` deleted by hand, the way the CI job does it —
ran `=== 1230 passed, 0 failed, 19 skipped ===`, exit 0, with `check_budgets`, `check_content` and
`check_boundary` all exit 0 and `mapped areas: 0`. `world_map_test` reported `49/49` there and
named its one skip: *"the authored map agrees with the authored areas (no areas in scenes/areas)"*.

**Proved red, then green — three times, each with the real failure shape (gotcha 23).**

1. `data/areas/lantern_hall.tres` `name_key` misspelled by one letter:

```
  !! lantern_hall name_key 'area.lantern_hall.nam' is not in the CSV
FAIL — 1 content violation(s)
exit=1
```

   reverted: `reverted exit=0`.

2. The load-bearing invariant broken the way it would really break — `discover()` made to keep a
   `Dictionary` instead of writing the flag, which is the "second truth" a discovery store would
   have been:

```
FAIL and the whole of that is one flag — expected true, got false
FAIL somewhere else is not — expected false, got true
FAIL only the one place — expected 1, got 2
FAIL exactly one discovery was announced — expected 1, got 0
FAIL somewhere never found is refused — expected false, got true
FAIL no request escaped any of them — expected 0, got 1
FAIL discover it before saving — expected true, got false
FAIL scrambled — expected false, got true
=== 1288 passed, 10 failed, 0 skipped ===
FAILED: world_map_test raised 1 engine script error(s): ["Out of bounds get index '0'
  (on base: 'Array[StringName]') at res://tests/unit/world_map_test.gd:151"]
FAILED: world_map_test planned 59 outcomes and produced 57 — a crash, an early return or a
  stale plan
exit=1
```

   All three framework mechanisms fired on one break — the assertions, `ErrorWatch`, and the
   plan. Reverted: `=== 1298 passed, 0 failed, 0 skipped ===`, exit 0.

3. `const HOME := &"courtyard"` planted in `map_screen.gd`:

```
  !! res://src/ui/screens/map_screen.gd:33 names demo content 'courtyard'
     (from res://data/areas/courtyard.tres)
FAIL — 1 boundary violation(s)
exit=1
```

   reverted: `reverted exit=0`. Note the source it cites: the gate now derives area ids from
   `data/areas/` as well as from the `scenes/areas/` folder names.

**The input path, proved by a temporary probe and then removed** (gotcha 15). Added to
`dev_capture.gd` as `--probe-map`, run windowed with real `InputEventAction`s:

```
[test] PROBE after M: top=map depth=1
[test] PROBE focus='@Button@27' text='Lantern Hall'
[test] PROBE after M again: top=NOTHING depth=0
[map ] Travelling to 'lantern_hall' (spawn 'from_courtyard')
[test] PROBE after Enter: area=lantern_hall depth=0
```

So `M` opens the map, focus lands on the only travellable marker, `M` closes it again, and Enter
on that marker really travels — landing on the spawn the `.tres` authored, not the one the door
uses. `depth=0` afterwards is `ScreenKeys` unwinding the stack on `area_change_requested`, which
is why `MapScreen` deliberately does not close itself. `git diff src/systems/debug/dev_capture.gd`
is empty.

**Three windowed captures, LOOKED AT and READ** (gotcha 28 — a map with the wrong area marked
still looks like a map, so the shot has to be discriminating). All at 960x540, `--new-game`,
`--shot-frame=100`, `--time=12:00 --freeze-time`, `--quit-after 120` (220 for the third).

1. `--open-menu=map` — a large WHITE dot low on the plate reading *"Rose Courtyard · you are
   here"*, and a small GREY dot above it reading *"???"*. Two states, drawn differently, in one
   shot.
2. `--flag=map/lantern_hall:true --open-menu=map` — same camera, same hour, ONE FLAG different:
   the grey `???` is a GOLD dot reading *"Lantern Hall"* with the focus ring on it, and the
   courtyard marker is unchanged. The seam photographed.
3. `--goto=lantern_hall --open-menu=map` — the two states SWAPPED: Lantern Hall white and *"you
   are here"*, Rose Courtyard gold and selectable, over the hall's warm interior instead of the
   courtyard's daylight. That is the far-side claim and the proof of travel in one frame.

**A staging race the third capture found, and gotcha 21's shape fixed it.** `--goto` and
`--open-menu` both begin by awaiting the first area, so they leave that wait on the same frame: if
the menu opened first, the travel `--goto` was about to request unwound it, and the capture was of
nothing with every rung green. A fixed number of extra frames only moves the race.
`dev_stage._settle_stable(frames)` demands twenty CONSECUTIVE settled frames and resets its count
the moment a transition starts, so it cannot be satisfied early. Fourth staging flag to need a
wait after `--open-menu`, `--flag` and `--open-inventory`, and the first to need a persistent one.

**Two gaps in earlier packages, closed in passing, both one line.** `journal_screen.gd` was never
added to `art_contract_test.gd`'s `STYLED_SCREENS`, whose own comment says "a sixth screen belongs
on this list" — so the gate that stops a colour being written down again could not see the journal
at all. Both it and `map_screen.gd` are listed now, +4 assertions. And `docs/NEW_GAME.md` never
listed `data/quests/` among the content roots; it now lists that and `data/areas/`.

**One new palette entry, the first since T2.1 wrote the file.** An undiscovered marker has to be
visible and clearly lesser, and `dim` is a translucent black that would have drawn nothing against
the plate. `UiPalette/colors/muted` in `ui_theme.tres`, read by name. That is the T2.1 seam
working as advertised: one file, one line. The `Button` styleboxes were left unpopulated for the
fourth package running — the map's markers are legible against the shipped dark palette, so this
screen did not force the decision either.

**CI green**, run 33262997072, read from the job logs rather than the tick: full checkout
`=== 1298 passed, 0 failed, 0 skipped ===` with `mapped areas: 2`, stripped template
`=== 1230 passed, 0 failed, 19 skipped ===` with `mapped areas: 0`. Both match the local runs.

**Unblocks.** Objective markers on the map: `Events.quest_advanced` has had an emitter since
WP-08 and `MapScreen` already redraws on facts, so that is a listener and one more marker state
rather than new state. A `Gate` or a `QuestStep` gating on having FOUND somewhere works today with
no code. And a region map for a game with thirty areas needs thirty `.tres` files and no code,
which is ADR-0006's test applied to a fifth catalogue.

**Gaps.**
- **A departure-side travel point** — a kiosk you must stand at — was not built. It is a
  restriction on a mechanism rather than the mechanism, it needs content the demo does not have,
  and it would be one interactable emitting the request the map screen already emits. That is a
  game's policy, not the template's.
- **`AreaDb` is the fifth copy of the same thirty lines**, and T3.1's arithmetic is worse for it.
  Not re-argued here: WP-08 costed the refactor and the board carries the row. `area_db.gd`'s
  header states the changed number rather than repeating the reasoning.
- **The map draws nothing but dots.** No fog of war, no zoom or pan, no terrain, no objective
  markers, no travel cost and no travel time. Art is deferred indefinitely, so a `ColorRect` per
  place is what this template ships and a consuming game brings its own plate.
- **An area whose `.tres` is renamed loses its place in an existing save**, because the flag key
  contains the area id. Same price `Equipment` pays for an item id, stated rather than hidden.
- The `Button` styleboxes, still.

## 2026-08-27 — WP-09 · Character depth: equipment, and two @exports nothing had ever read

**Did:** the equipment third of WP-09, and split the other two thirds onto the board as `09b`.

The row asked for three systems in one package — an attribute container, surface-aware footsteps,
and equipment that changes traversal. That is three sets of content, three test files and three
captures, well past the board's own "8 files or 500 new code lines, over that split it and add a
row". So it was split, and the third with a CONSUMER was built: traversal already has a class that
gates on a flag, so equipment had somewhere to be proved the day it existed.

**`Equipment` owns no dictionary.** A slot is a flag:

```
equip/<wearer_id>/<item id>          equip/player/item/brass_lantern
```

`PersistentState`'s `obj/<area>/<object>/<field>` and `Standing`'s `standing/<who>`, applied a
third time. `ItemDefinition` gains one field, `equip_slot`, a `GameEnums.EquipSlot` ordinal with
NONE first so every `.tres` authored before it stays valid unedited. `Equipment.of(who)` resolves
the component off the interactor the interaction contract already hands over, exactly as
`Inventory.of(who)` does, so an NPC or a stash can have one.

**Why:** three things fall out of the flag shape, and together they are the whole argument against
a `Dictionary[EquipSlot, StringName]` plus a save section.

1. **It is already saved.** No `SaveSystem.register`, no save version, no migration — and a new
   game clears it for free, because `Director.start_new_game()` clears flags.
2. **A gate can require it with NO CODE.** A `Gate.requires_flag` pointing at one of those keys
   gates traversal on a held lantern, and `Gate` was not touched. Neither was `QuestStep`, nor
   `DialogueChoice`, nor `ClimbPoint`. This is the second system to ride WP-08's seam, which is
   the first evidence it generalises rather than fitting one case.
3. **It is announced already.** `flag_changed` fires, so `QuestTracker` re-derives and a dialogue
   condition re-evaluates without anything learning that equipment exists.

The cost, stated: the key contains an item id, so an item id is now a public identifier the way an
`object_id` is. Renaming an item's `.tres` brings it back stowed — the item survives, because
`Inventory` deliberately keeps counts whose definition has vanished.

**THE ITEM STAYS IN THE BAG WHILE IT IS HELD.** Moving it out would make equipment a second place
items live: `Inventory.count_of()` would begin lying and `Gate.requires_item` would refuse a key
that is in the player's hand. So equipping is purely a flag, and the price is that losing the item
has to stow it — `_revalidate`, bound to `inventory_changed` rather than to `item_lost`, because
that is the one signal every path emits, a restored save included.

**Two @exports that had been declared, validated and read by nothing.** Found while looking for
where an equip-gated gate tells the player it needs a light. `Gate.locked_key` (WP-01) and
`PathAction.refusal_key` (WP-07) were both set by authored content, both checked by
`check_content`, and both DEAD: `interact_prompt.gd` computed `refusal.<reason>` from the enum and
never asked the object. `PathAction.refusal_key`'s own comment claimed it was "shown for the
LOW_STANDING refusal". Gotcha 2's shape exactly — a message that is merely WRONG looks the same as
a message that is right, so eight rungs, both CI jobs and 1,149 assertions were green over it for
two packages. `interaction_refused` now carries a `message_key` alongside `args`, for the same
reason `args` travels there rather than being asked of the target, and
`Interactable.refusal_key(who, reason)` is the override. Empty means "compute it from the reason".

**Connects:** `Equipment` sits beside `Inventory` under the player and writes through `Flags`, so
it reaches `SaveSystem` and `flag_changed` with no wiring of its own. `InventoryScreen` binds the
component in `for_carrier(who)` and Enter on a row calls `Equipment.toggle` — the first time
pressing an inventory row has done anything; its comment said "use and tooltips are WP-09 and
beyond". `Gate` reads the flag through the `requires_flag` it already had. `--equip=` joins
`--give=` in `dev_stage.gd`. Nothing above `gameplay` learned a new name except the one signal.

**Verified:**

```
$ "$G" --headless --import 2>&1 | grep -cEi "SCRIPT ERROR|Parse Error"
0
$ "$G" --headless --quit-after 120
22:35:42 [INFO ] [boot     ] Session ended after 1.4s — 0 warnings, 0 errors
$ "$G" --headless res://tests/test_runner.tscn --quit-after 400
22:38:16 [DEBUG] [test     ] --- equipment_test: 70/70 ---
22:38:16 [DEBUG] [test     ] --- docs_test: 90/90 ---
22:38:16 [INFO ] [test     ] === 1224 passed, 0 failed, 0 skipped ===   (exit 0)
$ "$G" --headless --script tools/check_budgets.gd    -> exit 0
    ok   src/gameplay/character/equipment.gd      82 / 250
    ok   src/ui/screens/inventory_screen.gd      123 / 250
    ok   src/systems/debug/dev_stage.gd          235 / 250
    ok   tests/unit/equipment_test.gd            146 / 250
$ "$G" --headless --script tools/check_content.gd    -> exit 0
       item/brass_lantern     TOOL         max_stack=1
$ "$G" --headless --script tools/check_boundary.gd   -> exit 0
    demo names derived: 16 — [..., "item/brass_lantern", "brass_lantern", ...]
```

1149 → **1224**: 70 in the new case, and 5 that `docs_test.gd` computed from the new worked `.tres`
example in `AUTHORING.md`.

**BOTH GATES PROVED RED, THEN GREEN, with the real failure shape (gotcha 23).**

(1) The authored gate's `locked_key`, misspelled by one letter in `courtyard.tscn`:

```
$ "$G" --headless --script tools/check_content.gd
  !! res://scenes/areas/courtyard/courtyard.tscn:369 localization key 'object.gate.arch.lockd' is not in the CSV
FAIL — 1 content violation(s)
PLANTED content exit 1
REVERTED content exit 0
```

(2) The load-bearing invariant broken the way it would really break — `equip()` made to remove the
item from the bag, which is the shortcut a later reader would reach for:

```
PLANTED suite exit 1
22:31:19 [INFO ] [test] === 1201 passed, 18 failed, 0 skipped ===
22:31:19 [ERROR] [test] FAILED: it is still carried — expected true, got false
22:31:19 [ERROR] [test] FAILED: toggle holds it — expected true, got false
REVERTED suite exit 0
22:31:27 [INFO ] [test] === 1219 passed, 0 failed, 0 skipped ===
```

**THE INPUT PATH WAS PROVED BY A TEMPORARY PROBE, AND THE PROBE WAS REMOVED** (gotcha 15 —
`TestCase.run()` is synchronous, so no assertion can press a key, and "Enter on a satchel row
equips it" is an input path). Added to `dev_stage.gd`, run windowed, quoted here verbatim, deleted:

```
$ "$G" --resolution 960x540 --quit-after 140 -- --new-game --give=item/brass_lantern \
       --probe-equip-row --time=12:00 --freeze-time
22:34:40 [INFO ] [test     ] PROBE focus='@Button@26' held=[]
22:34:40 [INFO ] [equipment] player equipped 'item/brass_lantern'
22:34:40 [INFO ] [test     ] PROBE after press 1: held=[&"item/brass_lantern"]
22:34:40 [INFO ] [equipment] player stowed 'item/brass_lantern'
22:34:40 [INFO ] [test     ] PROBE after press 2: held=[]
```

`git diff src/systems/debug/` afterwards carries only `--equip` and the `--open-inventory` wait.

**THREE WINDOWED CAPTURES, LOOKED AT AND READ.** All at `--time=12:00 --freeze-time` with
`--new-game --shot-frame=70` (or 160 where an interaction had to land first), because no ordinary
run enters an area (gotcha 31) and a propless corner at 18:40 renders near-black.

1. `--give=item/brass_lantern,item/rose_petal:2 --equip=item/brass_lantern --open-inventory` —
   the satchel over a live courtyard reading `Brass Lantern  x1   [in hand]` under *Tools* and, two
   rows down, `Rose Petal  x2` with NO marker under *Materials*. **The unmarked row is the point**:
   a marker glued onto every row would photograph identically on one item, which is gotcha 28's
   lesson — a capture of something that merely looks fine is not evidence.
2. `--give=item/brass_lantern --stand-by=ShadowedArch --interact=1` — the arch refusing with
   *"It is pitch dark beyond the arch, and you have no light in hand."* That is `locked_key`, on
   screen for the first time since it was declared; the generic line would have read "It will not
   budge. Something holds it shut." The lantern is in the bag throughout, so carrying is visibly
   not the same as holding.
3. The same line plus `--equip=item/brass_lantern` — same camera, same hour, same position, one
   flag different: the blocker slab that stood beside the player in (2) is GONE, and
   *"Lantern raised, the dark under the arch gives way."* is up.

**TWO DEFECTS THE CAPTURE FOUND AND NO GATE COULD.**

1. **The satchel screen redrew only on `inventory_changed`.** Capture 1 came back reading
   `Brass Lantern x1` with no marker while the log said `player equipped 'item/brass_lantern'` —
   the screen was right about the bag and silently wrong about the hand. `_on_row_pressed` calling
   `refresh()` itself is not enough, because a press is not the only way equipment moves: staging
   equips from the command line and `_revalidate` stows an item the moment it leaves the bag. It
   now listens to `equipment_changed` as well, which is the signal's whole reason for existing.
2. **`--open-inventory` did not wait for the area**, so with `--new-game` it drew over the title
   screen and the arriving transition unwound it. Third flag to need that wait after `--open-menu`
   and `--flag` — gotcha 32's family, and `dev_stage.gd` now says any flag that puts something on
   screen needs it.

**ONE ENGINE SURPRISE, and it is going on the gotcha list.** `Array[StringName].sort()` DOES NOT
SORT ALPHABETICALLY — it orders by the StringName's internal handle. `equipped_ids()` returned the
two fixture ids reversed, and the only trace was one failing assertion:

```
FAILED: the ids come back sorted — expected item/fixture_held_two,item/fixture_worn,
                                        got item/fixture_worn,item/fixture_held_two
```

`Inventory.ids()` already sorted through `String` with a `sort_custom`, and its comment is why this
took a minute rather than an hour. `equipped_ids()` does the same now.

**Unblocks:** "hold a light to enter the dark" as a quest step, a dialogue condition or a climb
requirement, all with no code. `09b` (attributes, surfaces) has a worked example of the
namespace-over-`Flags` shape to copy. Any future per-carrier state that must be saved and
announced has a third precedent rather than a second.

**Gaps:**
- **A quest step still cannot read an ITEM COUNT, and equipment did not make it cheaper.** Being
  HELD is a fact about one item, which is exactly what a flag is. A COUNT is not, and both ways to
  expose one cost something real: an `Inventory` mirroring `count/<item>` into `Flags` writes every
  carried item into the flag section as well as its own, and a `QuestStep` reading the bag directly
  puts `gameplay/Inventory` inside a `systems` tracker against the layer rule. Now **T3.3** on the
  board with both options costed, rather than a sentence repeated in three documents.
- **Attributes and surface-aware footsteps are not done** — `09b`, with the reasons in its section.
  The one worth repeating: a footstep is the single claim this ladder cannot see at all. Not
  visual, so no capture reads it; not synchronous, so no assertion reaches it; and headless the
  audio driver is `Dummy` and every `play()` leaks.
- No equipment SCREEN, and no stat effect from equipment — nothing reads a stat yet.
- The `Button` styleboxes in `ui_theme.tres` are still unpopulated. The satchel did not force the
  decision: its rows are legible against the shipped dark palette. Third package to leave them,
  and each time for the same stated reason rather than by omission.
- `Gate.stays_open` defaults true, so an equip-gated gate that has opened once stays open even
  once the lantern is stowed. Correct for "you needed a light to get in"; a gate that re-checks
  every time is a different object, and nothing has asked for one.

**CI green, run 33095187525, and the JOB LOGS were read rather than the tick.** Full checkout
**1224 passed, 0 failed, 0 skipped** with `quests: 1` in `check_content`; stripped template
**1169 passed, 0 failed, 16 skipped** — the equipment case runs in BOTH jobs, because it is
fixtures all the way down and skips nothing, which is the point of `tests/framework`. All three
checkers PASS in both. The push run (33095176524) and the pull-request run (33095253385) are green
as well.

**Commit `1b3d799` on `claude/wp-09-character`, PR #17**, stacked onto `claude/wp-08-quests` (#16)
rather than `main`, matching the rest of the chain.


## 2026-08-26 — Resequencing: the export proof jumps the queue, and one contradiction is settled

**Did:** no code. Three planning corrections, all found by reading the docs against each other
rather than against the engine.

1. **New package T2.0 — the export proof**, at the FRONT of Phase T2, ahead of T2.1. It has its
   own section on the board with a manifest and exit criteria, so the row is a real fallback
   handoff and not a title.
2. **Settled a direct contradiction between two documents.** `SYSTEMS_INVENTORY.md` marked export
   presets `LATER`; `ROADMAP.md`'s Phase T3 called the export proof *"the one genuinely blocking
   item from WP-15"*. Both had been true in writing for as long as the T-phases have existed.
   Settled in favour of **blocking**, and the inventory row now says so and records that it was
   changed.
3. **WP-10 (crafting and gathering) marked OPTIONAL** on the board. `TEMPLATE.md` already said it
   should be — *"crafting is the clearest case: a genre choice, not a requirement of every game"* —
   and the row still said `TODO`. The note and the row now agree.

Also swept two smaller drifts in `CONTEXT.md`: it carried a stale `**Next package:**` line per
package, two of them stranded and contradicting each other (T1.4 and T1.2), and it described the
board as "fifteen packages" from before the T-phases were added.

**Why:** the asymmetry decides the order. The export proof is cheap to run — one preset, one
export, one count — and if it FAILS the fix is architectural, a revision to ADR-0006 touching how
all content is found. Every package built before it would then have been built on an assumption
known to be false. T2.1 by contrast fails locally, inside `CharacterVisual` and a `Theme`. Cheap
test, architectural blast radius, so it goes first.

The underlying risk is a familiar shape: the three registries find items, conversations and
schedules by DIRECTORY SCAN (ADR-0006), and nothing in any scene references those `.tres` files —
the registry discovers them at runtime. Godot's exporter walks *dependencies*. If it therefore
omits them, an exported build has an empty inventory, dialogue that will not start and NPCs that
stand still, **while every ladder rung, both CI jobs, `check_content` and 911 assertions stay
green** — because they all run from `res://` in the editor, where the files are plainly there.
That is "409 passing checks and never rendered a frame" reproduced at the last possible moment,
and T1.4's CI cannot see it either.

**Connects:** T1.4 made completion claims checkable by a third party. This is the first thing that
CI provably cannot check, which is why it needs a package rather than a gate.

**Verified:** docs only — no `.gd`, `.tscn` or `.tres` touched. Ladder re-run anyway, because a
docs-only claim is still a claim:
`--headless --import` exit 0 with zero `SCRIPT ERROR` / `Parse Error` lines · boot
`0 warnings, 0 errors` · `911 passed, 0 failed, 0 skipped`, exit 0 · `check_budgets`,
`check_content`, `check_boundary` all exit 0 · CI green.

One claim in the new T2.0 section was **wrong when first written and corrected before commit**: it
said `export_presets.cfg` is gitignored by the `*.cfg` conventions. It is not — `.gitignore` names
only `override.cfg`, checked with `git check-ignore -v`, which reports it as not ignored. The
section now says so. Worth recording because it is exactly the kind of plausible-sounding detail
that a later session would have trusted.

**Unblocks:** T2.0 as the next chat, with a written manifest. T2.1's chip was replaced rather than
left pending, so the board and the handoff agree.

**Known gaps:** the `## Plan — where this is going` section of `CONTEXT.md` is still stale — it
names WP-07 as next and cites 460 assertions when there are 911. Left alone deliberately: it is a
narrative section, rewriting it is not this pass's job, and a partial rewrite would be worse than
an obviously old one. Whoever closes T2.0 should replace it wholesale.

---
## 2026-08-26 — T1.4: the ladder stops being seven commands a human remembers

**Did:** `.github/workflows/ladder.yml` and `.github/actions/setup-godot/action.yml`. Six of the
seven rungs now run on every push, every pull request and on manual dispatch, in two jobs:

- **Ladder (full checkout)** — rung 2 import, rung 3 boot, rung 4 suite, then `check_budgets`,
  `check_content`, `check_boundary`, each its own step so a failure names itself.
- **Ladder (stripped template)** — `rm -rf data scenes/areas`, then the same rungs minus the boot.

The composite action downloads `Godot_v4.7.2-stable_linux.x86_64.zip`, verifies it against a
SHA512 **pinned as a literal in the workflow**, installs it, and asserts
`godot --version` is exactly `4.7.2.stable.official.ed1daf0bf` before any rung depends on it.
Standard build, never mono. Nothing in `src/` changed, and the one line touched in `tests/` was
reverted to its original value.

**Why:** the ladder was seven commands a human types in order, remembering to grep rung 2. That
held for eleven packages, and it is not a system. It could not have been automated before T1.3:
until then rung 4 reported success on a case that crashed, and a green badge over a suite that
cannot fail is worth *less* than no badge, because it is believed.

**Four decisions, and the reasoning is in the workflow file's own comments:**

1. **`.godot/` is NOT cached, the engine archive is.** The cache would be exactly the artefact
   whose absence causes the fresh-clone parse failures, which is the temptation. It is refused
   because a restored `.godot/` can resolve a `class_name` this commit deleted, or hand a `.tres`
   an importer for a file that changed shape — "CI is green and a fresh clone is broken" is the
   precise failure this package exists to prevent, and there is no correctness-preserving cache
   key short of the whole tree. The engine zip is immutable and keyed by version, so it cannot go
   stale. Cache the fixed thing, never the derived one. Cost of the decision: an import per run,
   measured at 8 seconds.
2. **Rung 1 (`--check-only`) is not automatable and is absent.** Autoload identifiers do not
   resolve under it and that error is EXPECTED (gotcha 1); a machine cannot tell it from a real
   one. Rung 2 is the compile check and is where zero tolerance lives.
3. **The boot rung asserts only its last `Session ended` line**, not the whole log. Gotcha 13:
   quitting mid-load prints spurious `Parse Error` lines *after* a clean report, so a whole-log
   grep here would be a flake generator. Frame count is 300, not the local 120 — `--quit-after`
   counts frames, a headless frame costs milliseconds, and a shared runner has no reason to be
   handed a tighter margin than it needs.
4. **The windowed capture rung is stated as impossible, not dropped.** `--headless` shades
   nothing (gotcha 2) and a runner has no GPU, so any capture it produced would be exactly the
   evidence that gotcha calls worthless. Anything with a visual consequence still needs a human.

**Connects:** nothing in `src/` or `tests/` was changed to accommodate CI — which was the stated
tripwire for this package, and it never fired. The workflow calls the same six commands
`docs/CONTEXT.md` already listed, so the local ladder and CI cannot diverge without one of them
going red. The stripped job turns T1.3's by-hand claim into a mechanism.

**Verified:**

*The gate goes RED.* One assertion in `tests/unit/core_test.gd:23` changed to expect `6` where
`DictRead.get_int` returns `5`, pushed as commit `ad6e225`. Run
[32989608134](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32989608134)
— `completed/failure`. **Failing step: `Rung 4 - test suite`, in BOTH jobs.** Its output:

```
=== 910 passed, 1 failed, 0 skipped ===
FAILED: dict_read int — expected 6, got 5
##[error]Process completed with exit code 1.
```

Rungs 2 and 3 passed, correctly: a wrong expected value is not a parse error. Rungs 5, 6 and 7
were skipped. The stripped job failed the same way at `860 passed, 1 failed, 12 skipped`.

*And GREEN again.* Assertion restored, commit `272053f`, run
[32989771404](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32989771404)
— `completed/success`, both jobs:

```
godot.zip: OK
No SCRIPT ERROR / Parse Error lines: every script compiled.
Session ended after 2.1s — 0 warnings, 0 errors
=== 911 passed, 0 failed, 0 skipped ===          (full checkout)
=== 861 passed, 0 failed, 12 skipped ===         (stripped) — named skips: 8
98 files, 8100 code lines, 0 warnings, 0 violations
```

The stripped numbers reproduce T1.3's hand-run result exactly.

*Local ladder, after all CI work, on the final tree:*

```
--headless --import                                  exit 0, 0 SCRIPT ERROR / Parse Error lines
--headless --quit-after 120                          Session ended after 1.3s — 0 warnings, 0 errors
--headless res://tests/test_runner.tscn --quit-after 400   exit 0, 911 passed, 0 failed, 0 skipped
--headless --script tools/check_budgets.gd           exit 0
--headless --script tools/check_content.gd           exit 0
--headless --script tools/check_boundary.gd          exit 0
```

*The stripped run was also measured locally before CI existed*, by moving `data/` and
`scenes/areas/` aside: `861 passed, 0 failed, 12 skipped`, true exit code 0, all three checkers
exit 0, then restored with `git status` clean. That is what the stripped job was written against.

**Three things this cost an hour each, and two are new gotchas:**

1. **GitHub runs every `run:` block as `bash -e {0}`, so `set -uo pipefail` inside a step does
   NOT turn errexit off.** The first red run reported nothing but `Process completed with exit
   code 1` — the step died on the failing `godot` line, before the line that prints which
   assertion failed. The artefact had the answer and the step did not, which is a step that fails
   without saying why. Every rung that needs to survive its own command's failure now captures
   the status with `|| status=$?`, which is exempt from errexit. Fixed in the same package that
   introduced it, and the fix is proved by the quoted red run above.
2. **Verifying a shell fragment interactively with `( ... )` inside an `&&` chain silently
   disables `set -e`.** While checking rung 4 before pushing, the fragment reported exit 0 on a
   deliberately failing suite, which looked exactly like the workflow being broken. It was not:
   run as a real script file — which is how Actions runs it — the same fragment exits 1.
   Measured both ways. A workflow fragment must be tested as a FILE, never inline.
3. **`gh`'s run listing lagged several minutes and led to a wrong diagnosis.** `actions/runs`
   reported `total_count: 0` for four minutes after a push whose run had already been created and
   completed. On that evidence CI looked disabled, and the repo was made public to rule out a
   private-minutes limit — which was unnecessary; the runs that had already passed were pushed
   while it was private. The repo was returned to private and pushes still trigger. Push-event
   delivery on this repo ran up to **25 minutes** behind at times, which is why
   `workflow_dispatch` is now a trigger: a gate with exactly one way to be invoked has a single
   point of failure. A manual run also gets its own `concurrency` group, keyed on its run id,
   because a dispatch mid-verification was cancelled by the very push it was verifying and a
   cancelled run reports neither pass nor fail.

**Unblocks:** every later package. A completion claim is now checkable by a third party instead
of trusted, which is the precondition for a consumer trusting this template at all. T2.1 can
refactor the art seams knowing that breaking a system will be visible without anyone remembering
to run anything.

**Known gaps:**
- **The windowed capture rung has no automation and cannot have one** on a GPU-less runner. Every
  visual claim still rests on a human looking at a PNG. This is stated in the workflow, not
  hidden.
- **No branch protection.** The gate reports; nothing stops a red branch being merged. That is a
  repository setting, not a file in this repo, and it is the natural follow-on.
- **No status badge in `README.md`,** deliberately: a badge on a private repo renders as "unknown"
  to anyone who can see the README, which is worse than no badge.
- **The stripped job does not prune the demo half of `localization/strings.csv`.** `NEW_GAME.md`
  says a game should; pruning it mechanically here would only be the job testing its own regex.
- Push-event delivery latency is outside this repo's control. `workflow_dispatch` is the
  mitigation, not a fix.

---

## 2026-08-26 — T1.3: the suite stops testing the demo, and stops passing when it crashes

**Did:**

Two jobs, and each turned out to rest on a fact nobody had checked.

**1. Fixtures.** A test asserting `item/rose_key` was testing the demo, not the item system.

- `tests/framework/fixture_content.gd` — new. Builds the content a case needs: three items (one
  unique key item, one that stacks to a limit, one spare so a sort order has something to be an
  order OF), a conversation whose graph exercises every rule the runner has, a two-block
  timetable, and a path action that can refuse, fail AND succeed. Every name is abstract —
  `fixture/unique`, not a key to a rose garden.
- `tests/framework/fixtures.gd` — new. Where that content lives, and the switch onto it.
  **The decision, and it is split deliberately along one line: does the system under test
  RECEIVE the content, or LOOK IT UP BY ID?** A `Pickup` is handed an `ItemDefinition` and a
  `PathActionPoint` a `PathAction`, so those fixtures are built in memory and set on the node —
  no file, no global state. But `Inventory.add(id)` asks `ItemDb`, `DialogueRunner.begin(id)`
  asks `DialogueDb` and `NpcBrain` asks `ScheduleDb`, and those three find content **by
  directory scan** (ADR-0006) and cache it statically, so an in-memory resource is invisible to
  them. The choice there was a test-only injection method on each registry — engine code
  carrying a backdoor that exists for the suite and nothing else — or a real directory the real
  scan really reads. It writes `.tres` files to `user://test_fixtures/` and points the registry
  there. **That buys something beyond unwelding the suite:** the fixtures go out through
  `ResourceSaver` and come back through the registry's own scan, so the suite now proves the
  authoring round trip a consuming game depends on and that nothing tested before.
- `ItemDb` / `DialogueDb` / `ScheduleDb` gained `static var content_dir`, defaulting to the
  `res://data/...` const it replaces in the scan. A content ROOT rather than a constant.
- Migrated: `items_test`, `pickups_test`, `screens_test`, `dialogue_test`, `npc_test`,
  `path_actions_test`, `transitions_test`, plus label keys in `traversal_test` and
  `interaction_test`. Two patterns replaced naming: **discovery** (`transitions_test` and
  `npc_test` now scan `scenes/areas/` instead of listing two ids, so area three is covered the
  day it appears) and **aggregation** (one assertion over every authored action instead of two
  named `.tres` files).
- Blocks that genuinely assert things about the demo — the authored catalogue matches the disk,
  every authored item name has a CSV row, every authored waypoint exists in some authored area —
  are gated on the demo existing and `skip()`ped when it does not. **A skip stands in for the
  assertions it replaces**, so the plan is the same number either way and a stripped run reports
  exactly what it gave up rather than looking identical to a full one.

**2. Framework hardening.** `ROADMAP.md` had carried this since T1.1: a deliberately crashing
case exited 0, which invalidated every green result the project had.

- `TestCase.plan(n)` — TAP's `1..N`, for TAP's reason. The runner fails a case whose outcomes do
  not equal its plan, a case that declares no plan, and a case that plans zero.
- `tests/framework/error_watch.gd` — new. An `OS.add_logger` `Logger` counting
  `ERROR_TYPE_SCRIPT`, read per case so a failure names the case that crashed.
- `test_runner.gd` — scans `tests/unit/` and fails on a `.gd` file that exists and is not in
  `CASES`; arms the exit code to 1 on its first line and only clears it at the end; calls
  `Fixtures.deactivate()` after every case, not only the ones that switched; and prints the
  skip total.
- `tools/check_boundary.gd` now scans `tests/framework/` and `tests/unit/` as well as `src/`.
  The suite was exempt because unwelding it was this package's own job; now that the fixtures
  exist, scanning it is what stops the welding growing back one convenient literal at a time.

**Why:**

Deleting `data/` and `scenes/areas/` is step one of `docs/NEW_GAME.md`. T1.2 proved every other
rung survives it. Rung 4 did not, so the ladder that makes this a template was one `rm -rf` away
from being three quarters of a ladder.

And a suite that cannot fail is not a gate. Gotcha 23 says a gate that never fails has never
been tested; this is the same sentence pointed at the test suite itself.

**Connects:**

`Fixtures` reads the same `content_dir` the game and `tools/check_content.gd` read, so there is
one scan path, not a production one and a test one. `Fixtures.area_ids()` is the discovery
`transitions_test` and `npc_test` now share. `ErrorWatch` sits beside the tally rather than
inside it — it counts, the runner decides.

**Verified:**

Two things this package learned by measuring, both of which changed the design:

*A GDScript runtime error aborts ONLY the innermost frame.* Probed with a null dereference three
frames deep:

```
PROBE about to crash
SCRIPT ERROR: Cannot call method 'get_child_count' on a null value.
PROBE reached end of _outer after crash
PROBE reached end of _ready after crash
EXIT=0
```

`_inner` aborted; `_outer` and `_ready` both ran to completion. That is why the runner cannot see
a crash, and why a completion sentinel at the end of `run()` would not have worked. It also means
`get_tree().quit(1)` then `quit(0)` exits 0 — last call wins — which is what makes arming the
exit code safe.

*The plan alone was not enough, and this was measured rather than assumed.* With the plan in
place, a crash planted in a leaf helper with no assertion after it:

```
--- zz_probe_test: 2/2 ---
=== 913 passed, 0 failed, 0 skipped ===
EXIT=0
```

Hence `ErrorWatch`. Same probe, after:

```
zz_probe_test raised 1 engine script error(s): ["Cannot call method 'get_child_count' on a null
value. at res://tests/unit/zz_probe_test.gd:13 in _crash()"]
--- zz_probe_test: 2/2 ---
=== 913 passed, 1 failed, 0 skipped ===
EXIT=1
```

Note the `2/2`: the two mechanisms are complementary, not redundant.

All four silent-pass modes planted, each exiting 1, each removed:

| Planted | Result |
|---|---|
| a crash in a leaf helper | `raised 1 engine script error(s)` — exit 1 |
| a failing assertion | `FAILED: this one fails on purpose — expected 2, got 1` — exit 1 |
| an early return | `planned 3 outcomes and produced 1` — exit 1 |
| no plan at all | `declared no plan, so a crash in it would be invisible` — exit 1 |
| a suite file not in CASES | `exists but is not listed in CASES, so it never runs` — exit 1 |

**THE STRIP.** `data/` and `scenes/areas/` moved aside, whole ladder re-run:

```
=== 861 passed, 0 failed, 12 skipped ===
EXIT=0
SKIPPED: items_test: the authored catalogue is sound (no content in data/items) — 3 assertion(s) not run
SKIPPED: items_test: authored item names are translated (no content in data/items) — 1 assertion(s) not run
SKIPPED: transitions_test: every area has the required shape (no areas in scenes/areas) — 1 assertion(s) not run
SKIPPED: transitions_test: sheltering and the clock agree (no areas in scenes/areas) — 1 assertion(s) not run
SKIPPED: transitions_test: flag prefixes do not collide (no areas in scenes/areas) — 1 assertion(s) not run
SKIPPED: dialogue_test: the authored conversations are sound (no content in data/dialogue) — 2 assertion(s) not run
SKIPPED: npc_test: authored waypoints exist in an authored area (no areas or no schedules) — 1 assertion(s) not run
SKIPPED: path_actions_test: the authored actions are sound (no content in res://data/actions) — 2 assertion(s) not run
12 assertion(s) were skipped: this run covers less than a full one
check_content exit=0 · check_boundary exit=0 · check_budgets exit=0
Session ended after 1.3s — 0 warnings, 0 errors
```

Twelve assertions of 911, not a third: the migration turned per-item and per-waypoint loops into
one assertion over the whole set, so what a stripped run loses is smaller than what the demo used
to be named in. Restored, and `git status` showed no change to any file under `data/` or
`scenes/areas/`.

The widened boundary gate proved the same way: `&"item/rose_key"` planted in `items_test.gd` gave
`res://tests/unit/items_test.gd:16 names demo content 'item/rose_key'`, `FAIL — 2 boundary
violation(s)`, exit 1; removed, exit 0.

Full ladder on the restored checkout:

```
--headless --import                          # no SCRIPT ERROR, no Parse Error
--headless --quit-after 120                  # Session ended after 1.2s — 0 warnings, 0 errors
res://tests/test_runner.tscn --quit-after 400 # === 911 passed, 0 failed, 0 skipped === exit 0
tools/check_budgets.gd   PASS  exit 0
tools/check_content.gd         exit 0
tools/check_boundary.gd  PASS  exit 0 — 93 scripts over src/ and tests/
```

**A BUG THIS FOUND, and it is the fourth native-name collision in this project.**
**`ItemDb.reload()` had never called our function.** `Script` declares `reload()`, and `ItemDb`
as an identifier IS the GDScript object, so `ItemDb.reload()` dispatched to `Script.reload()` —
which reloads the script and resets its static variables. Behaviour coincided exactly with what
our `reload()` was written to do (clear the cache, rescan on next access), so nothing ever broke
and no test could see it. It surfaced only when `content_dir` was added: assigning it stuck, and
then `reload()` silently reset it to the default. Proved by putting a print in `_ensure_loaded()`
and watching `ItemDb.reload()` not reach it. All three registries now expose `rescan()`; every
call site — `tools/check_content.gd` included, so the validator's reload was a script reload too
— was updated. After `Area3D.priority`, `class_name Container` and `DictRead.get_name`, this is
the fourth. Gotcha 17 says check every name against the API dump, *static functions included*,
and it was right again.

**Unblocks:**

T1.4 (CI) — the ladder is now worth automating, because every rung of it can fail. A consuming
game can delete the demo on day one and keep rung 4. And `tests/unit/` is now a place a new
system's assertions can go without acquiring a dependency on the courtyard.

**Known gaps:**

- **The plan is a number a human maintains.** Add an assertion and the run fails until the number
  is bumped. That is TAP's trade and it is self-correcting — a stale plan fails loudly, naming
  the case and both numbers — but it is friction, and the first thing to reconsider if it starts
  getting in the way.
- **`ErrorWatch` counts only `ERROR_TYPE_SCRIPT`.** `push_error` from a deliberate negative-path
  test arrives as `ERROR_TYPE_ERROR` and would make the gate unusable within a day, so those are
  counted separately and not failed on. A real engine error of that type therefore still passes.
- **A cached `.tres` survives an edit.** `ResourceLoader` caches by path, so a case that edits a
  loaded resource must edit it back; `rescan()` hands back the same instance. `dialogue_test` does
  restore everything it touches, and its comment now says so honestly rather than claiming the
  reload is the reset.
- **`user://test_fixtures/` is left on disk** after a run. Harmless — the next `activate()`
  overwrites it and the default content root is restored either way — but nothing cleans it up.
- Assertions moved 921 → 911. The drop is aggregation, not lost coverage: named per-item and
  per-waypoint assertions became set-level ones that also cover content added later.

---

## 2026-08-26 — T1.2: the engine/demo boundary becomes a gate, and four leaks close

**Did:**

The boundary rule existed only as prose in `TEMPLATE.md`. It is now mechanical.

- `tools/check_boundary.gd` — new gate, rung 6 of the ladder. **FAILS if any file under `src/`
  names demo content.** The forbidden names are **derived, never listed**: every folder under
  `scenes/areas/`, the `id` of every `.tres` under `data/`, and each id's last segment, so
  `schedule/keeper` also forbids the bare `keeper`. Twelve names today, and it cannot go stale
  when content is added.
- `src/core/util/game_config.gd` — new. `GameConfig`, a pure reader of the `[game]` section of
  `project.godot`: `first_area()`, `first_spawn()`, `game_name()`, `game_slug()`. Depends on
  nothing.
- `project.godot` — new `[game]` section: `world/first_area="courtyard"`,
  `world/first_spawn="default"`.
- `src/systems/scene_director/director.gd` — `const FIRST_AREA := &"courtyard"` **deleted**.
  `start_new_game()` reads `GameConfig.first_area()` and refuses, before clearing anything, when
  it is empty.
- `src/core/log/log.gd` — the literal `Gulistan` gone from both the boot banner and the log file
  name; both now come from `application/config/name` through `GameConfig`.
- `src/systems/debug/{dev_capture,dev_probes,dev_stage}.gd` — argument parsing is now behind
  `OS.is_debug_build()`. Only the F12 hotkey was gated before.
- `src/systems/debug/dev_capture.gd` — **restored a missing `_settled()`**; see the bug below.
- `src/content/{items/item_db,dialogue/dialogue_db,npc/schedule_db}.gd` — "no items / no
  conversations / no schedules found" is **no longer a problem**. See the second bug below.
- `docs/NEW_GAME.md` — new. The strip-and-start checklist.
- `tests/unit/core_test.gd` — 11 assertions on `GameConfig`, comparing against `ProjectSettings`
  rather than against a literal, because a test asserting `first_area() == "courtyard"` would
  rebuild the leak it exists to prove is gone.

**Why:**

`TEMPLATE.md` already recorded the failure mode: `game_root.gd` once carried
`const FIRST_AREA := &"courtyard"` and it passed eight verification rungs, a budget checker, a
content checker, 900 assertions and an adversarial review, **because no rule forbade it.** A rule
only a human enforces is the rule that let that through.

**Three decisions worth writing down:**

1. **Comments are exempt; code is not.** Mechanically: a line whose first non-whitespace character
   is `#` is not scanned — the same definition `check_budgets.gd` uses. A `##` line saying
   `data/items/rose_key.tres must declare id = &"item/rose_key"` is *teaching by example*: it
   changes no behaviour, it is how the file-name-is-the-id rule is explained, and forbidding it
   would push the documentation into abstraction nobody can follow. A `const` changes behaviour.
   That is the whole difference. A **trailing** comment on a code line IS scanned, which is
   stricter than the rule needs — stricter is the safe direction for a gate.

   **What it cannot see, stated so nobody mistakes green for proof:** a name assembled at runtime
   (`"item/" + kind`); a demo name that appears in neither `data/` nor `scenes/areas/` — a
   waypoint marker like `north_arch`, a node name inside an area scene, a flag namespace invented
   in code; and anything outside `src/**/*.gd`, so the prefabs in `scenes/objects/` are unscanned.
   The exempt-directory count is *printed*, not swallowed.

2. **`src/systems/debug/` is exempt, and the exemption has a precondition the tool checks.**
   Those three files exist to drive the demo: `--give=item/rose_key` stages a photograph, and a
   probe that travelled to an abstract area would verify nothing. They are the development
   harness, not the engine. But an exemption granted to code a *player* could drive would be
   worthless, so `_check_debug_gate()` fails if any debug script defining `_parse_arguments()`
   loses its `OS.is_debug_build()` guard. The exemption and the condition it rests on live in one
   file. Fourteen demo names sit inside it today, counted and printed.

3. **The first area is a project setting, not an `@export`.** An `@export` on
   `scenes/boot/game_root.tscn` was the alternative and was rejected: `TEMPLATE.md` classifies
   `scenes/boot/` as engine, so that would have moved the leak rather than closed it.
   `project.godot` is already the one file a new game must edit, and the gate deliberately does
   not scan it.

**Connects:**

`Log` now depends on `GameConfig` — the first dependency the logger has ever had, and its header
says so. It is safe because `GameConfig` reads `ProjectSettings` and nothing else, so the
"everything may depend on Log; Log depends on nothing" invariant degrades to one edge that cannot
cycle. `Director.start_new_game()` is still the one place that knows what a new game is; it just
no longer knows *which* game. `dev_stage.gd`'s `--new-game` reports `GameConfig.first_area()`
instead of `Director.FIRST_AREA`.

The gate became its own tool rather than living in `check_content.gd`, which is where the brief
put it: the combined file came out at **252 of the 250 allowed code lines** and `check_budgets.gd`
refused it. The seam was already in the reasoning — `check_content.gd` validates that the *demo*
is well formed, `check_boundary.gd` validates that the *engine* does not know the demo exists —
and the new tool loads nothing, so it keeps working when the content it scans for has been
deleted, which is exactly the state a new game starts in. Fourth time the budget checker has
exposed a split that was already there.

**Two bugs found, neither by a static gate:**

1. **`dev_capture.gd` had failed to parse since the WP-13 merge, and the ladder said nothing.**
   The merge added `await _settled()` in `_soak_and_dry` without the function, so the whole file
   was dead — F12, `--shot`, `--time`, `--freeze-time` and `--weather` had all been broken for a
   package. Found by `--headless --import`, which prints
   `Parse Error: Function "_settled()" not found in base self`. **The boot rung still printed
   `0 warnings, 0 errors`**, because `Log` counts `Log.error` calls and an engine parse error is
   neither. New gotcha in `CONTEXT.md`. Fixed by adding the five-line `_settled()`, the third
   copy, for the reason already written in `dev_stage.gd`.

2. **A stripped template failed its own content gate on the first command of `NEW_GAME.md`.**
   `ItemDb`, `DialogueDb` and `ScheduleDb` each reported "no X found in ..." as a problem, so
   deleting `data/**` — step one of starting a new game — turned `check_content.gd` red. An empty
   folder is the *legal starting state* of a base template; a file that is present and does not
   load is the real error, and `_register` already reports that per file. Whether a game needs
   items is that game's question, not this base's. Removed from all three. Found by actually
   performing the checklist rather than writing it.

**Verified:**

Baseline before starting: 910 assertions.

Full ladder, on the restored demo:

```
$ "$G" --headless --import                                  # 0 SCRIPT ERROR / Parse Error lines
$ "$G" --headless --quit-after 120
17:45:31 [INFO ] [boot] Session ended after 1.2s - 0 warnings, 0 errors
$ "$G" --headless res://tests/test_runner.tscn --quit-after 400
17:45:42 [INFO ] [test] === 921 passed, 0 failed ===          exit 0
$ "$G" --headless --script tools/check_budgets.gd
95 files, 7742 code lines, 0 warnings, 0 violations   PASS    exit 0
$ "$G" --headless --script tools/check_content.gd     PASS    exit 0
$ "$G" --headless --script tools/check_boundary.gd    PASS    exit 0
```

**The gate bites.** Planted `const PLANTED_VIOLATION: StringName = &"courtyard"` at the end of
`src/core/util/layers.gd`:

```
$ "$G" --headless --script tools/check_boundary.gd
  !! res://src/core/util/layers.gd:32 names demo content 'courtyard' (from res://scenes/areas/courtyard)
FAIL - 1 boundary violation(s)                              exit 1
```

Removed it, restored the file from a copy, `git diff --stat` empty:

```
$ "$G" --headless --script tools/check_boundary.gd
PASS                                                        exit 0
```

**The debug-gate precondition bites too.** Deleted the `OS.is_debug_build()` guard from
`dev_probes.gd`:

```
  !! res://src/systems/debug/dev_probes.gd parses command-line arguments with no OS.is_debug_build() guard
FAIL - 1 boundary violation(s)                              exit 1
```

Restored, `PASS`.

**A deliberately broken assertion still exits 1.** Flipped `slug is not empty` to expect `false`:

```
17:41:05 [ERROR] [test] FAILED: slug is not empty - expected false, got true
=== 920 passed, 1 failed ===                                exit 1
```

**`NEW_GAME.md` was performed, not imagined.** Deleted every `.tres` under `data/`, both area
folders, pruned the CSV from 189 rows to 147, and set `world/first_area=""`:

```
  localization keys: 146
  item definitions: 0 - conversations: 0 - schedules: 0 - path actions: 0 - scenes scanned: 14
PASS                                                     (check_content,  exit 0)
  demo names derived: 0 - []
  src scripts scanned: 74 (res://src/systems/debug/ is exempt)
PASS                                                     (check_boundary, exit 0)
PASS                                                     (check_budgets,  exit 0)
17:44:28 [INFO ] [boot] Session ended after 1.2s - 0 warnings, 0 errors
$ "$G" --headless --quit-after 60 -- --new-game
17:44:41 [ERROR] [world] No first area - set game/world/first_area in project.godot
```

Everything restored afterwards; `git status` shows `data/`, `scenes/areas/` and `strings.csv`
unmodified.

**Windowed capture**, which is also the proof that `dev_capture.gd` parses again — `--shot`,
`--time` and `--freeze-time` could not have taken effect otherwise:

```
$ "$G" --resolution 960x540 --quit-after 90 -- --new-game --shot=<path> --shot-frame=70 \
      --time=18:40 --freeze-time
17:41:21 [INFO ] [test] --new-game requested 'courtyard'
17:41:21 [INFO ] [area] Area 'courtyard' ready (2 spawns, 9 interactables, 3 waypoints)
```

Looked at the PNG: the setting-driven first area, at dusk, with the clock readout reading
`Day 1 | 18:40 | Dusk` and an interaction prompt up. The boot banner now reads
`Project Gulistan 0.0.1 | Godot 4.7.2-stable (official) | headless | debug=true`, and the log file
is `project_gulistan_2026-08-26T17-36-20.log` — both from `project.godot`, neither from a literal.

**Unblocks:**

T1.3 (test fixtures). The boundary is now a gate rather than a promise, so the one remaining weld
— a third of the assertions naming demo content — is the last thing standing between the template
and a demo that can actually be deleted. T2.2 (consumer documentation) has its spine in
`NEW_GAME.md`.

**Gaps:**

- **The suite still cannot survive the demo being deleted.** Everything else on the ladder can;
  T1.2 ran it. T1.3.
- The gate reads text. It cannot see a computed id, a waypoint name, or anything outside
  `src/**/*.gd`. Written into the tool header so a green run is not mistaken for a proof.
- **A deliberately CRASHING test case has still not been proved to exit 1** — only a failing
  assertion has. Different path, still unhardened, still T1.3.
- The debug surface's release gate is verified by a text scan for `OS.is_debug_build()`, not by
  running a release export. An actual export run belongs with T1.4 or WP-15.
- `ui.menu.title` holds the game's *name* in a `ui.*` key — an engine key with a game-specific
  value. Called out in `NEW_GAME.md` rather than restructured; a `[game]`-driven title would mean
  the menu reading a project setting for a player-facing string, which is a bigger decision.

---

## 2026-08-26 — WP-07: path actions, and the difference between a refusal and a failure

**Did:**

The signature mechanic. Non-combat verbs you perform on a person, with a standing that gates
them and that they move.

- `src/content/npc/path_action.gd` — `PathAction`. Verb, label, a standing floor to be offered
  at all, a standing line to succeed at, and what it writes and says either way.
- `src/gameplay/interactables/path_action_point.gd` — `PathActionPoint`, an `Interactable`.
  One node per action.
- `src/gameplay/character/standing.gd` — `Standing`. A namespace over `Flags`, and nothing more.
- `data/actions/keeper_scrutinise.tres`, `keeper_barter.tres`, `scenes/objects/path_action.tscn`.
- Five new `InteractVerb`s and `RefusalReason.LOW_STANDING`.
- `tools/check_content.gd` validates every `.tres` in `data/actions`.
- `tests/unit/path_actions_test.gd` — 51 new assertions. 555 -> 606.
- `dev_probes.gd` split again, into itself plus `dev_stage.gd`.

**Why:**

**A refusal and a failure are different things, and keeping them apart is the whole design.**
A refusal happens BEFORE anything: the player is told why and nothing changes. A failure happens
AFTER committing: the action ran, it did not work, and it cost standing. An action that could
only refuse would be a lock with extra steps. An action that could only fail would give the
player no way to read the situation before spending. The interesting middle is where Octopath's
Inquire lives, and it needs both — so barter has three bands: refused below 1, committed and
failing at 1, committed and succeeding at 2.

**No dice.** `success_standing` is a threshold, not a probability. A random path action makes
the player save-scum, and a save-scummed mechanic is experienced as a slot machine rather than
as a relationship. If randomness is ever wanted it goes behind that one field and every
authored `.tres` stays valid.

**One node per action, and no menu.** An NPC offering three actions is three overlapping
`Interactable`s, which the sensor already ranks and Tab-cycles between — the exact case its
header describes. A path-action menu would be a second selection mechanism competing with the
first, with its own focus handling and its own screen, to solve a problem already solved.

**`once` applies to SUCCESS only.** A single early failure must not lock the player out of an
action forever with no way back, which is what `once` on any outcome would do. Asserted.

**Standing is a namespace over `Flags`, not a store.** It is exactly the kind of fact `Flags`
exists to hold: already saved, already announced, already dumpable. A second store would be a
second truth for one integer per person. It is keyed `standing/<who>` and NOT through
`PersistentState`, because that namespaces per area — right for a chest, wrong for a person:
the keeper who dislikes you in the courtyard must still dislike you in the hall.

**No fourth registry.** Unlike items, conversations and schedules, nothing ever looks a path
action up by id — it is only reached through the NPC that offers it, exactly as a chest reaches
its `ItemDefinition`s. So the note in `schedule_db.gd` about three being a pattern and four
being a problem does not fire, and no registry was written.

**One defect found, in WP-06's code:**

**The unreachable guard believed a single frame.** The keeper reported "cannot reach 'dais'" in
windowed runs and never in headless ones. A `NavigationAgent3D` recomputes its path
asynchronously, so the frame after a target moves — which for a WANDER activity is every few
seconds — it legitimately has no path yet and answers "unreachable" to a question it has not
finished thinking about. The guard now requires the answer to hold for thirty consecutive
physics frames, and a new target clears the accumulated evidence. Three windowed runs clean
where one in two failed before. This is the second time this guard has been wrong in the same
direction, which is itself the lesson: a question asked of an asynchronous system needs both a
delay before asking and a persistence test on the answer.

**Connections:**

`PathActionPoint` -> `Standing` -> `Flags` -> the save. `Interactable.attempt()` gives it the
refusal path and the interactor for free, so `requires_item` asks whoever is interacting rather
than a global inventory. `Events.notify_requested` carries the outcome line. The keeper's two
actions sit beside its `Speaker` on the same NPC, so one person now offers a conversation and
two verbs, selected between with the cycle key.

**Verified:**

```
--headless --import                                   clean
--headless --quit-after 120                           0 warnings, 0 errors
--headless res://tests/test_runner.tscn                606 passed, 0 failed, exit 0
--headless --script tools/check_budgets.gd            78 files, 6012 lines, 0 violations
--headless --script tools/check_content.gd            PASS, incl. 2 path actions
--headless --quit-after 2400 -- --round-trips=20      nodes 142 -> 142 (+0), memory +2 KiB
--headless --quit-after 5000 -- --npc-day             dais at 12:00, bench at 20:00
```

The content gate was proved by pointing an action's `failure_key` at a row that does not exist
and watching it fail, then restoring it.

**Three captures, examined, one per band**, taken with `--standing=keeper:N --stand-by=Keeper
--cycle=1 --interact=1`:

- **0 — refused.** `They do not know you well enough. (0 of 1)`. Standing unchanged at 0.
- **1 — committed and failed.** `They look at the basket, then at you, and move it to their
  other arm.` Standing 1 -> 0. The prompt still reads Barter, because a failed action stays
  on offer.
- **2 — committed and succeeded.** `They part with a handful of petals, and almost smile.`
  Standing 2 -> 3, and **the prompt has changed to "Observe — The Keeper's Hands"**, because
  barter is now `once`-done and the sensor has fallen back to the other action. The design
  visible in a photograph.

The first attempt at these three captures produced three identical images: all three outcomes
show the same prompt until the button is pressed, and the shutter was 250 frames after the
refusal message had already expired. The `--interact` flag and a corrected `--shot-frame` are
what made them different.

**Unblocks:**

WP-08's quests, which need a mechanic whose outcome is worth tracking, and WP-09's character
depth, where a skill would gate an action exactly as standing does now.

**Known gaps:**

Five verbs are declared and two are authored; `INQUIRE`, `GUIDE` and `SOOTHE` have keys and no
content. There is no UI listing what a person offers — you discover their actions by standing
next to them and cycling, which is honest for a skeleton and thin for a game. Standing is a
single number per person with no factions or groups behind it. Nothing decays. And an action
cannot yet give an item, only set a flag: `Inventory.add` from a path action is one field away
but nothing needed it yet.

## 2026-08-26 — WP-06: NPCs that keep a timetable, and eight defects an audit found

**Did:**

A navmesh baked from the geometry that is actually present, an NPC that walks to a named place
because the clock says so, and a schedule authored as data.

- `src/content/npc/` — `ScheduleEntry`, `NpcSchedule`, `ScheduleDb`. The third registry, and
  deliberately identical to the first two.
- `src/gameplay/character/npc_brain.gd` — `NpcBrain`. Reads a schedule for a waypoint NAME,
  resolves it against the area's `Waypoints/` node, hands the position to a `NavigationAgent3D`.
- `AreaRoot` bakes its own navmesh at load, behind the curtain, and reports the polygon count.
- `scenes/characters/npc.tscn` — reuses `CharacterVisual` unchanged, and carries a `Speaker`
  child, so an NPC is a conversation partner with no new code at all.
- `data/schedules/keeper.tres`, two `Waypoints/` nodes, `GameEnums.NpcActivity`.
- `dev_capture.gd` split into itself plus `dev_probes.gd`; `--npc-day`, `--npc-storm`,
  `--npc-settle` added.
- `tests/unit/npc_test.gd` — 74 new assertions, plus 17 more covering the fixes below.
  460 -> 555.

**Why:**

**A schedule names a waypoint, not a position.** Coordinates would be authored against one
area's geometry, silently wrong the moment a bench moved, and unusable by a second NPC. A name
resolves at runtime, so moving the marker moves everyone who goes there.

**There is no `until_hour`.** An entry runs until the next one begins and the last wraps past
midnight, so a day is always completely covered and two entries cannot disagree about who owns
14:00. `entry_for_hour` falls back to the LAST entry when the hour precedes every block, which
is what makes a night shift work — asserted for all twenty-four hours.

**The navmesh is baked at load, not checked in.** A committed `NavigationMesh` goes stale the
moment someone moves a wall, and a stale navmesh fails silently. Baking from the geometry that
is present cannot disagree with it, and the cost is paid behind the same black curtain that
already hides the shader warm-up.

**Arrival is the agent's answer, not a distance check.** `is_navigation_finished()` accounts for
a target that is unreachable; a hand-rolled `distance < 0.5` reports "not there yet" forever when
a waypoint ends up inside a wall.

**Three defects found while building it, each by running the engine:**

1. **The navmesh baked EMPTY and said nothing.** `SOURCE_GEOMETRY_ROOT_NODE_CHILDREN` parses the
   children of the `NavigationRegion3D`, which has none — the terrain is a sibling. An empty
   navmesh means every NPC concludes it has already arrived, everywhere, and an empty bake takes
   0ms, so "baked in 0ms" is exactly what the failure looks like. Now group-sourced, and the
   log line reports the POLYGON COUNT and errors at zero.
2. **The navmesh bridged a step the body cannot climb.** `agent_max_climb` was 0.55 and the dais
   is 0.4 high, so the bake connected the ground to the dais top — but `move_and_slide()` has no
   step-up at all, so the NPC walked into the riser and stopped while the agent insisted it had
   not arrived, with no error anywhere. This game has no jumping and authored vertical movement,
   so the climb limit is now BELOW anything the body cannot manage and waypoints sit on the
   ground.
3. **My own reachability guard fired before the navigation map had synchronised**, and acted on
   the answer: an unsynchronised map reports everything unreachable, and the guard then parked
   the NPC at `get_final_position()`, which is the origin. It now waits for a decision and for a
   non-empty path before believing the answer.

**Eight more defects, from an independent adversarial review of WP-01 to WP-05.** Reviewing code
that has already passed every gate is worth doing, and this is the evidence:

1. **A hard soft-lock in dialogue.** `advance()` asked `_node.has_choices()` — the AUTHORED array
   — while the screen drew `available_choices()`. A node whose every choice fails its condition
   therefore rendered a box with no buttons that would not advance, could not be escaped
   (`closes_on_cancel` is false for a conversation, on purpose) and held the player's and the
   sensor's `&"dialogue"` tokens forever. Killing the process was the only way out. `advance()`
   now reads the filtered list and falls through, which ends the conversation and returns
   control — the same recoverable behaviour a dangling link already had.
2. **A non-`Node3D` area root left the curtain black permanently.** That failure path returned
   without lifting the fade, with the previous area already freed and `current_area_id` empty, so
   not even `reload_current_area()` could recover. Every failure path now goes through
   `_abandon()`, which lifts the curtain on the way out.
3. **A failed load left "Loading" pinned over the game for the rest of the session**, because the
   indicator hid only on `area_entered`. It now hides when the curtain lifts, which every path
   out of a transition does.
4. **A refused transition left a save's position override armed for the NEXT one.** Load a save
   whose area was renamed, then walk through any door, and the player is placed at coordinates
   authored for a different area — inside geometry, or outside the level. Cleared on every path
   that does not place the player.
5. **The loading readout could never appear during the boot load** — the one load, on a cold
   cache, that most needs it — because it showed only on `area_unloading`, which the first load
   does not emit. Progress now shows it as well as updating it.
6. **Nothing closed screens on an area change; `UiRoot.close_all()` was dead code** called only by
   tests. Travel does not lock the player, so a conversation opened during the 0.35s fade-out
   kept running over the newly loaded area with its speaker already freed. Same shape as WP-04's
   prompt-survives-an-area-change bug, one layer up. `UiRoot` now unwinds on `area_unloading`.
7. **Choice buttons and `choose(index)` indexed two different lists.** A dialogue box deliberately
   leaves the world running, so a flag written while it is open can hide an option and shift
   every index between the frame a button was built and the frame it was pressed — and the player
   takes a branch they did not pick, firing its effect. The UI now calls `take(choice)` with the
   object it actually drew, and a choice that has left the offer is REFUSED rather than resolved
   to a neighbour.
8. **`InteractionSensor._on_availability_changed` swapped `_current` without resetting the hold**,
   so a 1.5s hold on a slow chest carried over to an adjacent object that became available
   mid-hold and fired it on the next physics frame.

Findings 1, 6 and 7 have assertions. 2 to 5 are single-branch fixes in `Director` and the
indicator whose failure paths need a broken area scene to reach, which is a fixture this suite
has no way to build; they are covered by reading and by the boot run, and that is stated here
rather than implied.

**Connections:**

`Clock` -> `hour_passed` -> `NpcBrain.decide_for_hour`. `ScheduleDb` supplies the waypoint name;
`AreaRoot`'s `Waypoints/` node supplies the position; `NavigationRegion3D` supplies the path.
`PersistentState` stores the waypoint, so an NPC's whereabouts ride the save machinery that
already exists — keyed `obj/<area>/<npc>/waypoint`, so two NPCs cannot overwrite each other and
a second area cannot overwrite the first. The NPC's `Speaker` child emits
`Events.dialogue_requested` exactly as the standalone one did.

**Verified:**

```
--headless --import                                   clean
--headless --quit-after 120                           0 warnings, 0 errors
--headless res://tests/test_runner.tscn                555 passed, 0 failed, exit 0
  with one assertion deliberately broken               554 passed, 1 failed, exit 1
--headless --script tools/check_budgets.gd            73 files, 5638 lines, 0 violations
--headless --script tools/check_content.gd            PASS, incl. 1 schedule
--headless --quit-after 2400 -- --round-trips=20      nodes 135 -> 135 (+0), memory +9 KiB
```

**A whole day**, `--npc-day`, which is how the schedule criterion is measured — no assertion can
drive a navmesh, because `TestCase.run()` is synchronous and pathing needs physics frames:

```
06:00  Keeper   wants gate_post  WANDER   0.00m away  arrived
09:00  Keeper   wants gate_post  WANDER   0.00m away  arrived
12:00  Keeper   wants dais       WANDER   0.47m away  arrived
15:00  Keeper   wants dais       WANDER   0.47m away  arrived
20:00  Keeper   wants bench      SLEEP    0.48m away  arrived
23:00  Keeper   wants bench      SLEEP    0.48m away  arrived
02:00  Keeper   wants bench      SLEEP    0.48m away  arrived
```

02:00 resolving to the bench is the midnight wrap working: the keeper's day starts at 06:00, so
the small hours belong to the previous evening's block rather than to the morning's.

**Thirty NPCs**, `--npc-storm=30`: `16.598 ms/frame with 1 NPC, 16.675 with 31 (+0.077)`. The
floor is the 60Hz physics tick, and thirty more NPCs move it by less than a tenth of a
millisecond. Both numbers are printed rather than asserted against a threshold, because a
threshold picked on this machine would mean nothing on another.

**Two captures, examined.** At 12:30 the keeper stands at its dais post offering "Speak — The
Garden-Keeper"; at 21:30 it has walked to the bench and is lit by the west lantern. The first
attempt had it standing inside the player, because the dais waypoint was 1.3m from the spawn
marker; moved, and re-shot.

**Unblocks:**

WP-07's path actions, which need an NPC to act on, and WP-08's quests, which need one to talk to
across a schedule. `CharacterVisual` is now proven shared between the player and NPCs unchanged,
which was the claim in its header and is now a fact.

**Known gaps:**

An NPC cannot travel between areas — a schedule names a waypoint and the waypoint must be in the
area the NPC is standing in, so a keeper who goes indoors at night is not expressible yet.
`check_content.gd` pools waypoint names across all areas for exactly this reason, and says so:
it can catch a name that exists nowhere, not an NPC in the wrong area for its schedule. Wander is
a random offset on a timer, not a behaviour tree, and level-of-detail for offscreen NPCs is
deferred as the manifest says. NPCs do not collide with the player or with each other, which
keeps them from getting stuck and lets them overlap. And the navmesh is rebaked on every area
entry; at 25-42ms for these two areas that is invisible behind the curtain, but a large area will
eventually want a checked-in bake plus a staleness check rather than an unconditional rebake.

## 2026-08-26 — WP-13: weather you can see, and the leak the Dummy audio driver leaves behind

**Did:**

`Weather` had published a kind, a blend and an intensity since Phase 0, and the only thing
that had ever read them was one fog-density multiplier. It is now visible.

- `src/systems/weather/wetness_model.gd` — `WetnessModel`. A pure `RefCounted`: one 0..1 that
  rises over eight seconds of rain and falls back over twenty-six. No node, no material, no
  autoload.
- `src/gameplay/world/precipitation.gd` — `Precipitation`. One `GPUParticles3D` per kind that
  builds its own mesh, process material, draw material and — for snow — its own soft flake
  texture from a radial `GradientTexture2D`. Nothing authored, nothing loaded.
- `src/gameplay/world/weather_visuals.gd` — `WeatherVisuals`. The listener that was missing.
  One node per area; it owns the `MIX` table that says what each kind looks like, follows the
  player, cross-fades across a blend, steps the wetness and sets the ambience levels.
- `src/gameplay/world/surface_wetness.gd` — `SurfaceWetness`. Darkens and clearcoats an
  area's materials as they soak, on private duplicates.
- `src/systems/audio/ambience_bed.gd` — `AmbienceBed`, reachable as `Audio.beds`. Named
  layers, each at its own level, on procedurally generated filtered noise.
- `dev_capture.gd` gains `--wet=<0..1>` and `--dry-for=<seconds>`.
- Nine localization keys: `weather.*` per kind, plus `notify.weather.turns`.
- `tests/unit/presentation_test.gd` — 47 new assertions. 460 -> 507.

**Why:**

*Why the wetness model is a separate pure object.* Everything else about the weather can be
computed from Weather's state in one frame. Drying cannot — "it stopped raining forty seconds
ago" is memory, and memory is the part that drifts. Gotcha 10 says `TestCase.run()` is
synchronous, so a node that only dries in `_process` could never be asserted on; a
`RefCounted` can be stepped a thousand simulated seconds inside one test.

*Why nothing is authored.* Art is deferred indefinitely. A rain texture would be a dependency
this project has refused to take on, so the mesh is a quad and the flake is a gradient. It
also means the three emitters cannot drift apart in an inspector.

*Why `Precipitation` is told a weight instead of reading Weather.* An emitter that polled the
weather would be a second place the rules live, and the two would disagree the first time a
cross-fade was half done. Same split as Weather and EnvironmentDriver, one level down.

*Why `SurfaceWetness` duplicates its materials.* The terrain materials are sub-resources of
the area scene, and a sub-resource is shared across every instantiation of it. Writing
roughness onto one would leave the courtyard wet after an unload and reload on a clear day —
and would follow the player into any other area using the same material.

*Why a clearcoat and not just darkening.* The first captures came back reading as "in shadow"
rather than "wet". A low roughness only shows where the sun's mirror angle points, and on a
flat courtyard under a fixed camera it mostly does not. A clearcoat is literally a thin smooth
film over the surface; it reflects the sky, which is visible from any angle.

**Connects:**

`WeatherVisuals` reads `Weather.current/target/blend/intensity/is_wet/sheltered` and writes to
`Precipitation`, `SurfaceWetness` and `Audio.beds`. Nothing flows the other way — `Weather`
still MUST NOT render, and gained no line. The toast goes out on `Events.notify_requested`
like every other announcement, so `Weather` still does not know a screen exists. `AreaRoot`
already set `Weather.sheltered` for interiors and that now genuinely stops the rain.

**Verified:**

- `--headless --import` — exit 0, clean. Run twice; the first pass is where the five new
  `class_name` globals get registered, and every parse error before it was gotcha 1.
- `--headless --quit-after 120` — `Session ended after 1.0s — 0 warnings, 0 errors`, exit 0.
- `--headless res://tests/test_runner.tscn --quit-after 150` — **507 passed, 0 failed**,
  exit 0, no leaked instances.
- A deliberately broken assertion in `presentation_test.gd` → `506 passed, 1 failed`, exit 1,
  naming the assertion and its line. Reverted.
- `--headless --script tools/check_budgets.gd` — 73 files, 5,625 code lines, 0 warnings,
  0 violations, exit 0.
- `--headless --script tools/check_content.gd` — 92 localization keys, PASS, exit 0.
- **Seven windowed captures, every one opened and looked at**, all at
  `--resolution 960x540 --time=13:00 --freeze-time --shot-frame=40`:
  - `CLEAR` — bright green grass, warm orange dais, cream walls, no particles.
  - `RAIN --wet=1.0` — fine pale streaks across the whole frame, everything greyer, ground
    visibly darkened.
  - `STORM --wet=1.0` — markedly denser rain than `RAIN`, pale wind motes blowing through it,
    darker again. Unmistakably a third image and not a brighter second one.
  - `SNOW` — soft round flakes at varied sizes and depths, ground still dry, which is right:
    `is_wet()` is RAIN and STORM only.
  - The dry-out, three frames, all `CLEAR` so the ONLY variable is the wetness:
    `--wet=1.0` / `--wet=1.0 --dry-for=13` / `--wet=1.0 --dry-for=40`, logged as wetness
    `1.000` / `0.500` / `0.000`. Dark olive grass and dull walls -> a midpoint -> bright green
    grass and cream walls indistinguishable from the plain `CLEAR` capture. Indistinguishable
    by eye, not byte-identical: the two PNGs hash differently, as two renders of one frame
    do. That drying restores the *exact* authored albedo and roughness is proved by an
    assertion instead, which is the right tool for an exactness claim.
  - `STORM --goto=lantern_hall` — not one drop indoors, interior lighting untouched.

**One real bug and one engine trap, both found by running it:**

1. **`SurfaceWetness` was driven before it had collected anything.** `WeatherVisuals` sits
   under `Environment` and the wetness node under `Terrain`, so the driver's `_ready` ran
   first and called `apply()` at an empty list. Because `apply()` skips a value that has not
   moved, arriving in an area mid-downpour would have shown a dry courtyard until the wetness
   happened to change — and it does not change once it has reached its target. Now `apply()`
   records what was wanted and `_ready` paints it after collecting. Found by reading the boot
   log's line ordering, not by a failing assertion.
2. **Every `play()` against the Dummy audio driver leaks.** The test suite started reporting
   `6 ObjectDB instances were leaked at exit`: one `AudioStreamPlaybackWAV` per `play()` call
   — four — plus the two generated streams they held. The AudioServer releases a stopped
   playback on the NEXT MIX, and `--headless` quits before there is one. Stopping the players
   and nulling their streams in `_exit_tree` does nothing, because the server owns the
   playbacks, not the players. `AmbienceBed.is_audible()` now checks
   `AudioServer.get_driver_name()` — measured as `Dummy` headless and `WASAPI` windowed, not
   assumed — and skips playback it could not be heard through anyway. The levels are the real
   state and are what the assertions read.

**Unblocks:**

Footstep surfaces, which need to know the ground is wet and now can, from the same
`Weather.is_wet()` the visuals key off. Any area that wants weather needs one node and no
code. A fourth and fiftieth weather kind need a row in `MIX` and a CSV line, and the suite
fails if either is missing.

**Known gaps:**

`dev_capture.gd` is at 238 of its 250 code lines and is the next file to need splitting —
WP-14 owns it. The ambience is two layers of filtered noise, not sound design; there is still
no real audio in the project. Rain does not collide, so it falls through the terrace roof and
the arch — `ParticleProcessMaterial.collision_mode` is the seam and it was left off because it
costs a depth pass for a placeholder scene. Nothing splashes where a drop lands. Wetness is
per area and not saved, so walking out of a downpour into the hall and back resets the soak;
that is a `SaveSystem.register` away if it ever matters. This package added 562 code lines
against the board's ~500 guideline: 434 production (406 in five new files, 4 in
`audio_director.gd`, 24 in `dev_capture.gd`) and 128 of test.

## 2026-08-26 — WP-12: the menus, and the game stops booting into an area

**Did:**

Five menus, on the screen stack WP-02 built and never had a real consumer for.

- `src/ui/screens/menu_screen.gd` — `MenuScreen`. A titled column of focusable rows: panel,
  title, scroller, hint, and `add_row` / `add_note` / `refresh` / `focus_first` / `depart` /
  `push`. Written once, so the five menus below are 43 to 150 code lines each.
- `src/ui/screens/main_menu_screen.gd` — new game, continue, load, settings, controls, quit.
- `src/ui/screens/pause_menu_screen.gd` — resume, save, load, settings, controls, main menu,
  quit, over a status line naming the area and the playtime.
- `src/ui/screens/settings_screen.gd` — all 23 rows in `Settings.DEFAULTS`, **generated from
  the dictionary**, with bools, named enums, choice lists, percentages and multipliers, plus a
  reset row. Press a row or push left/right on it.
- `src/ui/screens/save_screen.gd` — the six slots with their headers, in either direction.
- `src/ui/screens/rebind_screen.gd` — every `Actions.REBINDABLE`, its key and its pad button.
- `src/systems/input/key_bindings.gd` — `KeyBindings`. Overrides in `user://input.cfg`, stored
  as integer codes. `Actions` gained `reset_bindings()` and one `KeyBindings.load_all()` call.
- `Director.start_new_game()` and `SaveSystem.latest_slot()`.
- `Events.main_menu_requested` and `Events.quit_requested`.
- `ScreenKeys` gained the pause binding, `menu_for()`, and `unwind()`.
- **`GameRoot` no longer requests an area.** It emits `main_menu_requested` and lifts the
  curtain. `FIRST_AREA` moved to `Director`, where area knowledge already lives.
- 86 CSV rows. `tests/unit/menus_test.gd` and `tests/unit/options_test.gd`: 257 new
  assertions, 460 -> 717.

**Why:**

`Settings` had declared 23 rows since Phase 0 with nothing reading seventeen of them, and the
board's own note said they existed "so the settings screen has something to bind to". So the
settings screen is **generated from `DEFAULTS`** rather than hand-listed: adding a setting is
one line in `settings.gd` and one CSV row, and there is no second list to fall out of step with
the first. The cost is that every row label is a computed key no text scan can find, which is
why `options_test.gd` loops `DEFAULTS` and asserts each one translates — the same trick the
prompt's verb keys use.

Rebinding lives in its own file because `Actions` owns the action NAMES and their DEFAULTS,
which is ADR-0003's whole point, while what one player has since changed belongs to their
machine like `Settings` does. Folding it in would also have taken `actions.gd` from 83 code
lines to 148 of its 150 — the shape of a file about to be given an exemption.

`MenuScreen` exists because the five menus differ only in what their rows say. That is also the
whole of "playable on a gamepad": a `VBoxContainer` of `Button`s already answers `ui_up`,
`ui_down` and `ui_accept`, so no screen in this package contains a cursor, a selected index, or
a direction-key handler.

**Connects:**

Nothing new was added to make the menus work. `pauses_world` and `UiRoot` do the pause; the
player takes its own `&"ui"` token on `Events.ui_mode_changed`; `is_gameplay_input_allowed()`
stays the one truth and no boolean joined it. No autoload was added.

The one genuinely new wire is that **`ScreenKeys` now closes the stack on
`area_change_requested`**, so no screen ever calls `close_all()` on the stack it is standing on.
That is what lets a menu row start a new game or restore a save and simply stop: the transition
it asked for is what dismisses it. It also fixes a latent bug nobody had hit — the inventory
open when a door fired would have survived the transition.

`GameRoot` is `core` and may not name a `ui` class, so the boot path is a bus signal, exactly
like `dialogue_requested`. The pause menu's "Main Menu" row uses the same one.

**Verified:**

```
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --import                                       # exit 0, no errors
"$G" --headless --quit-after 120                               # 0 warnings, 0 errors
"$G" --headless res://tests/test_runner.tscn --quit-after 250  # 717 passed, 0 failed
"$G" --headless --script tools/check_budgets.gd                # 76 files, 0 violations
"$G" --headless --script tools/check_content.gd                # PASS, 167 keys
"$G" --headless --quit-after 400 -- --new-game --cross-area-save   # WP-04 still holds
```

A deliberately broken assertion in `options_test.gd` reported
`FAILED: nothing is listening yet` and exited **1**.

Four windowed captures at 1280x720, each one actually looked at:
`--shot=... --shot-frame=40 --freeze-time` for the main menu, and
`--new-game --open-menu=pause` / `pause,settings` / `pause,controls` for the rest.

**A REAL-INPUT PROBE, added to `dev_capture.gd`, run windowed, read, and removed.** Gotcha 15:
`TestCase.run()` is synchronous, so no assertion can press a key. The probe fed real
`InputEventAction`s and a real `InputEventKey`, pressing AND releasing each in separate frames
because a `Button` acts on release. Its log, verbatim:

```
PROBE start: depth 0, gameplay allowed true
PROBE pause key -> top 'pause', depth 1, tree paused true
PROBE down x2 + accept -> top 'settings', depth 2
PROBE focused row 'video/bloom' = Off
PROBE ui_right -> 'video/bloom' = On
PROBE escape -> top 'pause', depth 1
PROBE controls open, first row: Move forward  —  W  /  Joypad Button 11 (D-pad Up)
PROBE row pressed, listening on 'move_up'
PROBE after K: listening '', row: Move forward  —  K  /  Joypad Button 11 (D-pad Up)
PROBE reset, row back to: Move forward  —  W  /  Joypad Button 11 (D-pad Up)
```

That line about the pad button surviving a keyboard rebind is the point of the whole
`KeyBindings` design, and it is the only place it is visible.

**Three bugs the engine caught that no static gate could:**

1. **A menu backed out of had no focused row, and a gamepad then did nothing at all.** Focus
   follows a sub-screen when one opens and does not come back on its own. The probe found it:
   the rebind half of the run could not reach the controls screen, because `ui_down` and
   `ui_accept` had nothing to act on. `UiScreen._opened` is documented as "each time the screen
   reaches the top of the stack" and `UiRoot` only ever called it once — so `_close` now
   notifies the screen it revealed, which is what that docstring always promised.
2. **Two translucent screens stacked let the lower one print through the upper one.** A capture
   showed the pause menu's status line running through the settings screen's first heading.
   Every screen dims rather than blanks on purpose, so `UiRoot._settle` now hides a covered
   screen along with disabling it — stack business, derived in one place.
3. **`InputEventJoypadButton.as_text()` prints every console's name for a button** — "Joypad
   Button 2 (Left Action, Sony Square, Xbox X, Nintendo Y)" — sixty characters that ran off the
   side of the controls screen and grew a horizontal scrollbar under it. `KeyBindings` now keeps
   the first name only, and no menu scrolls sideways.

**Unblocks:**

WP-08's journal and WP-11's map are `MenuScreen` subclasses and a row in `ScreenKeys.menu_for`.
WP-14's debug console has a screen contract to sit on. WP-15's accessibility pass has somewhere
to put its options, and every one of them already has a row.

**Known gaps:**

- **Thirteen settings still have no runtime consumer.** They can now all be seen and changed
  and they persist, but bloom, shadows, tilt-shift, camera shake, reduce-motion, high-contrast
  prompts, subtitles, hold-to-confirm, text scale, render scale, autosave and
  show-interact-hints are read by nothing yet. That is WP-13 and WP-15 work, not menu work.
  Ten do have consumers: the five volumes, `text_speed`, `run_is_toggle`, and the three video
  rows `Settings._apply_display` acts on.
- **The language row cycles one locale, because one locale is loaded.** Changing it stores the
  value and nothing calls `TranslationServer.set_locale`. Phase 2's runtime-language criterion
  is still open.
- **Rebinding does not warn about a duplicate.** Binding K to two actions is accepted silently.
- **`Actions.JUMP` is listed on the controls screen and this game has no jumping.** The action
  exists, so the screen shows it; pruning `REBINDABLE` is an ADR-0003 decision, not a menu one.
- **"Main Menu" does not unload the area.** It leaves it loaded behind an opaque, world-stopping
  screen, and the next New Game or Continue replaces it through the ordinary guarded transition.
  Deliberate: freeing it from under a menu would empty `Director.current_area_id`, so the next
  transition would believe it was the session's first and skip its fade-out.
- **This package is over the board's size guidance**: 11 files and roughly 700 new code lines
  against "about 8 files or 500". It was landed whole rather than split because the five menus
  share one base and one CSV block, and a half-landed menu set is a game with no way back to
  the main menu. Reported here rather than rounded down.

---

## 2026-08-26 — WP-05: dialogue, and a comma that had been eating text since WP-01

**Did:**

The largest unproven system. A conversation format, a runner, and the first screen in this game
that does not stop the world.

- `src/content/dialogue/` — `DialogueChoice`, `DialogueNode`, `Conversation`, `DialogueDb`.
  Data only; none of them touches an autoload, so `tools/check_content.gd` can still load them
  under `--script`.
- `src/systems/dialogue/dialogue_runner.gd` — `DialogueRunner`. Picks the next node, tests
  conditions, applies effects, announces lines. A component, not an autoload.
- `src/ui/screens/dialogue_screen.gd` — `DialogueScreen`. `pauses_world = false`,
  `closes_on_cancel = false`, typewriter reveal, focusable choices.
- `src/gameplay/interactables/speaker.gd` — `Speaker`. Names a conversation id and emits.
- `Events.dialogue_requested`, `GameEnums.FlagTest`, `GameEnums.FlagWrite`.
- `data/dialogue/gardener.tres` — five nodes, four choices, one branch on a flag.
- `tests/unit/dialogue_test.gd` — 46 new assertions. 414 -> 460.
- `tools/check_content.gd` now validates conversations, and catches unquoted CSV commas.

**Why:**

**A closed set of comparisons, not an expression language.** `FlagTest` has six values and
`FlagWrite` has five. The moment a conversation can contain an expression it needs a parser,
error reporting and a sandbox, and the authored `.tres` stops being reviewable in a diff. When
six comparisons are genuinely not enough, the honest move is a seventh, not a grammar.

**Nodes are an ordered array and the runner falls through.** The entry point is the first node
whose condition passes, not `nodes[0]`, and a skipped node falls through to the next in authored
order. That makes the commonest shape in the game — "if we have met, greet me differently" — two
nodes in sequence with no wiring at all. Lookup by id still exists for `next_node` and
`target_node`, but order is what a writer edits and an array is what diffs cleanly.

**Effects fire on arrival, not departure**, so a node has the same consequence however it was
reached. That is why a choice carries a condition but no effect.

**A failing choice is omitted, not shown disabled** — the opposite of how a locked gate behaves,
deliberately. A gate you cannot open teaches you there is something to come back for; a reply
you cannot give teaches you only that the writer thought of it. `choose(index)` therefore
indexes what is on screen, not the authored array, and there is an assertion for exactly that
because indexing the wrong one silently takes the wrong branch.

**`Speaker` goes through the bus.** It is in the gameplay layer and a dialogue box is in the ui
layer, and dependencies here point downward only. The first draft of this file reached for
`UiRoot` and `DialogueScreen` directly; that is a layer violation, so it now emits
`Events.dialogue_requested` and stops, exactly as `AreaDoor` emits `area_change_requested`
rather than loading an area itself. `ScreenKeys` listens, because it is already the one place a
thing becomes a screen.

**A conversation is not saved, and that is a decision.** Persisting a position means writing a
node id into the save file, which makes every node id in every `.tres` a permanent public
identifier: rename one and old saves load into a position that no longer exists. So the save
section exists, is always empty, and logs a warning naming the conversation it discarded. A save
taken mid-conversation reloads with the conversation over and control returned — recoverable and
obvious, where the alternative fails silently, later, in someone else's save file. That is the
"or explicitly refuses to be saved mid-conversation" half of the exit criterion, chosen on
purpose over the other half.

**A defect from WP-01, found by a capture:**

`object.lever.gate.on` read `The lever gives with a heavy clack. Somewhere north, iron shifts.`
with no quotes, so the CSV parser cut it at the comma and the lever's toast had said
`Somewhere north` for three packages. Nothing caught it: the key still resolved, `tr()` still
returned a string, and the line quietly lost its second half. `talk.gardener.menu` had the same
fault, which is how it surfaced — the first dialogue capture showed `Well? Ask` where the line
reads `Well? Ask, or do not.` Both rows are quoted now, and `check_content.gd` fails any row
that parses to more than two columns. Proved by adding a bad row and watching the gate bite.

**Connections:**

`Speaker` -> `Events.dialogue_requested` -> `ScreenKeys` -> `UiRoot.open(DialogueScreen)` ->
`DialogueRunner.begin()`. The runner emits `Events.dialogue_started`, which
`PlayerController` and `InteractionSensor` have listened for since Phase 0 — each takes its own
`&"dialogue"` token, so nothing in this package locks anybody. `DialogueDb` reuses
`ItemDb.resource_paths()` rather than copying it, so the export-time `.remap` handling has one
implementation. Conditions read `Flags`; effects write `Flags`; nothing else in the package
touches either. `gameplay/text_speed` gets its first consumer since it was declared.

**Verified:**

```
--headless --import                                   clean
--headless --quit-after 120                           0 warnings, 0 errors
--headless res://tests/test_runner.tscn                460 passed, 0 failed, exit 0
  with one assertion deliberately broken               459 passed, 1 failed, exit 1
--headless --script tools/check_budgets.gd            67 files, 5063 lines, 0 violations
--headless --script tools/check_content.gd            PASS, incl. 1 conversation, 83 keys
```

**Captured and looked at**, three times. The first showed the truncated line and the third of
three choices clipped off the bottom edge — the box is bottom-anchored, so anything that does
not fit is simply gone, and it was sized from the common case instead of the worst one. Height
went 260 -> 380 and the CSV rows were quoted. The third capture shows the full line, all three
choices, the first focused, and the courtyard still lit and running above the box.

**The real input path**, proved with a temporary probe per gotcha 15 and then removed:

```
TEMP target=Gardener locked=false
TEMP after INTERACT: depth=1 node=greet_first locked=true suspended=true
TEMP world paused=false clock ticking=true
TEMP after advance: node=menu choices=3
TEMP focus=Who are you?
TEMP after choosing: node=who met=true
TEMP after end: depth=0 locked=false suspended=false
```

`world paused=false, clock ticking=true` is the line that matters: this is the first screen to
exercise the OVERLAY path `UiRoot` has had since WP-02, and it is the first proof that the
distinction between OVERLAY and MODAL was worth building two packages early.

One probe artifact worth recording: a synthetic `ui_accept` press alone never fires a `Button`,
because `BaseButton` acts on RELEASE by default. The probe has to send both. That is a fact
about probes, not a defect.

**Unblocks:**

WP-06's NPCs, which need something to say before they are worth animating, and WP-08's quests,
which need a conversation that can set a flag. `Speaker` is already the shape an NPC's talk
component will take. The overlay path is now walked by something real, so WP-12's menus can
assume it works.

**Known gaps:**

One condition and one effect per node. The seam is `_apply_effect` in the runner plus one field
becoming an array, and no authored `.tres` is invalidated by that change — but it is a real
limit and a conversation that wants "set two flags" cannot say so today. No portraits: the
format has a `speaker_key` and no portrait field, because art is deferred and a field nothing
reads is a guess. No barks, no auto-advance, no history log, no skip-all. The reveal speed is
one setting and one constant; a per-line pause or emphasis would need markup the format does not
have. And a conversation still cannot be entered from anything but a `Speaker` — a trigger
volume that starts a conversation would work today by emitting the same signal, but nothing
does it yet.

## 2026-08-26 — WP-04: a second area, and three bugs only a second area could find

**Did:**

`Director` has swapped two areas. It was written, guarded and logged in Phase 0 and had never
actually done the thing it exists for.

- `scenes/areas/lantern_hall/lantern_hall.tscn` — an interior. `sheltered = true`,
  `follow_clock = false`, its own lanterns, open toward the camera.
- `src/gameplay/interactables/area_door.gd` — `AreaDoor`, the one object that asks to travel.
  It emits `Events.area_change_requested` and does nothing else.
- `src/ui/hud/loading_indicator.gd` — the only thing in the game drawn ABOVE `ScreenFade`.
- `Events.area_load_progress(area_id, ratio)`, emitted from the load loop that was already
  collecting the number and throwing it away.
- `Director.WARM_UP_FRAMES` — the curtain is held three frames after the area enters the tree,
  so shader compilation happens behind black.
- `EnvironmentDriver` gained an Interior group.
- `dev_capture.gd` gained `--round-trips=<n>`, `--cross-area-save` and `--goto=<area>`.
- `tests/unit/transitions_test.gd` — 44 new assertions. 370 -> 414.

**Why:**

**A door names an id and nothing else.** It does not load, fade, or place the player. Every
transition goes through one guarded path, and a door that ran its own would be the start of a
second, unguarded one — which is how two doors firing at once leaves two areas in the tree.

**The loading indicator is the one exception to gotcha 12.** `ScreenFade` must be the last child
of `UILayer` so the curtain covers every screen. The indicator has to be legible *while* the
curtain is up, so it is the single node placed after it. Child order is draw order, and that
ordering is the whole mechanism.

**Twenty round trips is a RUN, not an assertion.** `TestCase.run()` is synchronous and a threaded
load needs frames. So the criterion is measured by `--round-trips=20`, which also fires a second
travel request in the same frame each way, so the re-entrancy guard is exercised forty times.

**Three real defects, none of which any earlier package could have exposed:**

1. **`DictRead.get_name()` never worked.** `Resource` declares `resource_name` with the getter
   `get_name`, and a GDScript *is* a Resource, so the static call dispatched to the native
   zero-argument method and threw at runtime — while compiling perfectly. The one caller was
   `Director._apply_save`, which meant **loading a save had never restored the area**. It looked
   fine for three packages because with one area you always reloaded into the area you were
   already in. Renamed `get_string_name`. Same family as `Area3D.priority` and
   `class_name Container`, and the third time this project has been bitten by it.

2. **A freed object compares EQUAL to `null` in Godot 4.** `InteractionSensor` pruned its
   candidate list but never validated `_current`, so after an area unloaded it held a dangling
   reference — and `best != _current` reported "unchanged", so nothing was re-announced and the
   prompt kept offering an Iron Lever in an area that no longer existed. The obvious guard,
   `if _current != null`, does not fire for a dangling reference. `_announced_id: int` now
   carries the identity, because an int survives the object it names. A freed instance also
   cannot be *passed* to a parameter typed `Interactable` — the argument type check itself
   fails — so the liveness check takes no argument and reads the field in place.

3. **`follow_clock = false` did not mean "do not use the clock".** It only stopped the driver
   *updating*; `_ready()` still called `_apply_now()` once, so the first interior ever built
   inherited whatever hour it was entered at and had its sun hidden below the horizon. Entered
   at 02:30 it was pitch black; entered at noon it was fine. From the same scene file. An
   interior now has its own authored ambient, fog and background, applied once, and the outdoor
   path never touches its sun.

**Connections:**

`AreaDoor` -> `Events.area_change_requested` -> `Director` -> `area_unloading` /
`area_load_progress` / `area_entered` -> `LoadingIndicator` and `ScreenFade`. `AreaRoot` still
configures weather and audio on entry; `EnvironmentDriver` reads `Clock` outdoors and nothing
indoors. `TriggerVolume`, built in WP-01 for exactly this, is still available as a walk-through
entry and is deliberately not used yet — the hall is entered deliberately, through a door.

**Verified:**

```
--headless --import                                   clean
--headless --quit-after 120                           0 warnings, 0 errors
--headless res://tests/test_runner.tscn                414 passed, 0 failed, exit 0
  with one assertion deliberately broken               413 passed, 1 failed, exit 1
--headless --script tools/check_budgets.gd            59 files, 4441 lines, 0 violations
--headless --script tools/check_content.gd            PASS
```

**Twenty round trips**, `--round-trips=20`:

```
--round-trips 20 from 'courtyard': 120 nodes, 31417 KiB
  trip 1/20: 120 nodes, 31331 KiB    ...    trip 20/20: 120 nodes, 31332 KiB
--round-trips done: nodes 120 -> 120 (+0), memory 31417 -> 31404 KiB (-12)
```

Node count is exactly flat across all twenty. Memory moves by 12 KiB, downward, which is noise.
The forty warnings are the forty second-requests the guard refused, two per trip — the
"two transitions in one frame are refused" criterion, exercised rather than asserted.

**World state on both sides**, `--cross-area-save`:

```
hall coffer emptied: true
saved in 'lantern_hall': OK
wiped: carrying 0, coffer emptied=false        <- deliberately destroyed before reloading
loaded: OK
after reload: area='lantern_hall', carrying 3
coffer still empty: true
```

Saved in the hall and reloaded from the courtyard, deliberately: a save taken where the reload
already is cannot tell "the area was restored" from "the area never changed", which is exactly
how the broken `get_name` hid for three packages. The wipe matters for the same reason — without
it, a value nobody cleared passes for a value that was restored.

**Both areas captured and looked at.** The hall took four attempts, and each one was a real
defect rather than a tweak: pitch black (bug 3), then a full frame of wall because the camera
sits fourteen units back and the room was closed on the camera side, then the door slab
occluding the room from the foreground, then correct. The stale "Use Iron Lever" prompt was
visible in every one of those captures and is what led to bug 2.

**Unblocks:**

WP-05's dialogue and WP-06's NPCs now have somewhere other than the courtyard to be, and WP-11's
fast travel has a real destination to travel to. More importantly the transition path is no
longer theoretical: anything that needs to happen across an area boundary can now be tested
against something that actually crosses one.

**Known gaps:**

`Director` still does not cancel its threaded load on shutdown, which is gotcha 13 and remains
WP-14's. `UiRoot` does not close its screens on `area_unloading`; it cannot currently matter,
because travel requires gameplay input and a modal screen suspends it, but a load triggered from
a save menu in WP-12 will need it. The loading indicator shows a percentage only once the loader
reports one, which for a small area is never — both areas here load in under a frame, so the
"Loading" word is what is actually seen. Interior lighting is four exported values applied once;
a room that wants light that changes has no mechanism yet, and should get one when something
actually needs it.

## 2026-08-26 — WP-03: the HUD clock and the inventory screen

**Did:**

The screen stack got its first real occupants. A HUD clock readout, an inventory screen that
renders what the player is actually carrying, the one node that binds `I` to it, twenty-two
new localization rows, and a new test case file. `StubScreen` is gone.

- `src/ui/hud/hud_clock.gd` — a `Label` on `Events.minute_passed` showing day, time and the
  localized phase name. Pausable on purpose: behind an open menu no in-game minute passes, so
  a clock that kept ticking would be lying.
- `src/ui/screens/inventory_screen.gd` — a `UiScreen`. Reads `Inventory.ids()`, emits a
  heading wherever the category changes, and a focusable row per item. Rebuilds on
  `Events.inventory_changed`, connected only while it is open.
- `src/ui/root/screen_keys.gd` — `ScreenKeys`. The whole action-to-screen table, which today
  has one row. `PROCESS_MODE_ALWAYS`, so the key that opened a screen also closes it.
- `tests/unit/screens_test.gd` — 61 new assertions. 294 -> 355.
- `dev_capture.gd` traded `--open-screen` for `--give=<list>` and `--open-inventory`, so a
  capture shows real rows produced by the real `Inventory.add()`.

**Why:**

**The HUD is a layer, not a class.** The obvious move was a `Hud` node owning the clock, the
prompt and the toasts. It was rejected: those three already exist as independent siblings under
`UILayer`, each subscribing to the one signal it draws, and a parent whose only job is to
forward signals to them adds a hop and a place for the fourth readout to accumulate. The HUD is
the set of nodes on that layer.

**The carrier is injected, not looked up.** `InventoryScreen.for_carrier(who)` mirrors the
interaction contract's `attempt(who)`. The same screen shows an NPC's satchel or a stash
without knowing that `Director` or a player exists, and a test hands it a bare `Node` with an
`Inventory` child.

**The screen holds no rules, and no pause.** It declares `pauses_world` and renders. It never
touches `get_tree().paused`, never locks the player, and never asks whether another screen is
open. Nothing in WP-02 had to be widened to make that work, which is the result WP-02 was
scheduled to produce.

**A screen declares its flags in `_init`, not `_build`.** Found while repointing `ui_test.gd`:
`_build` runs from `_ready`, i.e. *after* a caller has set a flag, so `StubScreen` setting
`pauses_world = true` there silently discarded the overlay test's `pauses_world = false`. The
overlay case had been passing vacuously since WP-02 — it asserted "the world stays paused" of a
screen that was, unknown to it, still a modal. `InventoryScreen` sets identity in `_init`, the
test now asserts the override survives `_ready`, and it fails if that regresses.

**Rows are `Button`s, and that is the whole of the focus work.** A `VBoxContainer` of focusable
children already answers `ui_up` and `ui_down`, which are bound to arrows, the d-pad and the
left stick. Pressing a row does nothing yet; tooltips and use are later packages.

**Connections:**

`Clock` -> `minute_passed` -> the HUD. `Inventory` -> `inventory_changed` -> the screen.
`Actions.INVENTORY` -> `ScreenKeys` -> `UiRoot.open()`. `UiRoot` -> `ui_mode_changed` -> the
player's and the sensor's own `&"ui"` tokens, unchanged from WP-02. `ItemDb` supplies
`name_key` and `category`; the screen never reads a `.tres`.

**Verified:**

```
--headless --import                                   clean
--headless --quit-after 120                           0 warnings, 0 errors
--headless res://tests/test_runner.tscn                355 passed, 0 failed, exit 0
  with one assertion deliberately broken               354 passed, 1 failed, exit 1
--headless --script tools/check_budgets.gd            56 files, 4152 lines, 0 violations
--headless --script tools/check_content.gd            PASS
--resolution 960x540 -- --shot=... --open-inventory   looked at, twice: 18:40 and 12:20
```

Two windowed captures were opened and examined, not merely produced. Both show the rows grouped
under "Key Items" and "Materials" with localized names and counts, the focus ring on the first
row, "Escape to close" at the foot, the clock top right, and the courtyard still drawn and
stopped behind the panel. The first capture was at `DIM` alpha 0.88 and the world behind it was
nearly invisible; lowered to 0.78 and re-shot at midday, where the dais and the character read
clearly through it.

Headless cannot see any of that, and it also cannot press a key: `TestCase.run()` is
synchronous, so no assertion can span the frames an input event needs. So the input path was
proved by a **temporary probe** added to `dev_capture.gd`, run windowed, and then removed. It
fed real `InputEventAction`s into the live tree and logged the result:

```
TEMP pressed inventory      -> Mode -> MODAL, Opened 'inventory' at depth 1
TEMP after I: depth=1, gameplay=false, player locked=true
TEMP focus after open: Rose Key  x1
TEMP focus after ui_down: Rose Petal  x7
TEMP focus after 2x ui_down: Chipped Stone  x2
TEMP focus after ui_up: Rose Petal  x7
TEMP pressed cancel         -> Mode -> GAMEPLAY, Closed 'inventory', depth now 0
TEMP after Escape: depth=0, gameplay=true, locked=false
TEMP toggle twice: depth=0
```

**Unblocks:**

Every remaining screen. The pause menu, the journal, the map and the settings screen are now
each a `UiScreen` subclass plus a row in `ScreenKeys`, with no new pause, no new boolean and no
new signal. WP-05's dialogue box is the first `pauses_world = false` occupant, and the overlay
assertion above is now a real guard for it rather than a vacuous one.

**Known gaps:**

A row does nothing when pressed — there is no use, no tooltip, no sorting and no drag-and-drop,
all deferred by the package. The screen rebuilds every row on any change, which is fine for a
few dozen entries and would not be for a few hundred. `refresh()` frees the old rows with
`queue_free()`, so within a single frame the freed children are still present; the test skips
`is_queued_for_deletion()` children and any future reader must too. The HUD clock is drawn
beneath the screens, so an open inventory dims it — legible, and arguably right, but it is a
choice rather than an accident. Still no hard-coded-string audit tool: the enum-built keys
(`verb.*`, `refusal.*`, `item.category.*`, `time.phase.*`) are each covered by a loop in the
suite, and everything else is caught only by review.

## 2026-08-26 — WP-02: the screen stack, pause semantics and a token input lock

**Did:**

- `src/core/util/input_lock.gd` — `InputLock`, a set of named holds. `lock(&"dialogue")`,
  `release(&"dialogue")`, `is_locked()`, `holders()`. Twenty-one code lines.
- `src/ui/root/ui_root.gd` — `UiRoot`, the screen stack. `open()` / `close_top()` /
  `close_all()`, `is_gameplay_input_allowed()` as the single truth, and the whole pause table
  written down in its header. Found by group, not by path: `UiRoot.find(node)`.
- `src/ui/screens/ui_screen.gd` — `UiScreen`, the contract every screen satisfies. A screen
  declares `pauses_world` and `closes_on_cancel` and then renders. It never touches
  `get_tree().paused`, never locks the player, never frees itself.
- `src/ui/screens/stub_screen.gd` — scaffolding, marked for deletion once two real screens
  exist. It exists so this package could be verified without WP-03.
- `GameEnums.UiMode { GAMEPLAY, OVERLAY, MODAL }` and `Events.ui_mode_changed(mode)`, emitted
  by UiRoot and by nothing else.
- **Deleted `PlayerController.set_input_locked(bool)`.** Its four callers now hold named
  tokens: `&"dialogue"`, `&"climb"`, `&"ui"`.
- `InteractionSensor` grew its own `InputLock` and now knows an open screen exists at all,
  which it previously did not. `InteractPrompt` hides itself while the mode is not GAMEPLAY.
- Four nodes opted out of pause in their own `_ready()`: `Audio`, `Director`,
  `NotificationToast`, `DevCapture`. `ScreenFade` already had.
- `scenes/boot/game_root.tscn` gained `UiRoot`, and `ScreenFade` moved to be the LAST child
  of `UILayer` — a curtain that does not cover the screens is not a curtain.
- `--open-screen` on `dev_capture.gd`, so the capture can photograph a paused world.
- `tests/unit/ui_test.gd`, 79 assertions. Suite is 215 -> 294.

**Why:**

Nothing in this project had a home for modal UI. The only hand-over mechanism was one boolean
behind `set_input_locked(bool)`, and WP-01 gave it a second caller, which is when a boolean
stops working: dialogue locks the player, a climb starts and finishes inside the conversation,
the climb's own `set_input_locked(false)` clears the dialogue's hold, and the player strolls
away mid-sentence. Nothing errors. Nothing logs. It reads as a physics bug.

A count would fail the other way — lock twice, release once, and the lock is stranded with
nothing to point at. Named tokens are idempotent, so a doubled `dialogue_started` is free, and
`holders()` can name whoever is still holding when something does go wrong.

The stack had to come before any screen, which is why this is WP-02 and the inventory screen
is WP-03. Build a screen first and you get one boolean per screen, forever, each owned by a
different file and each able to clear the others.

**On pause, deliberately:** this does set `get_tree().paused`, but which nodes that actually
stops was decided node by node, and the table lives in `ui_root.gd`'s header. Clock and
Weather stop, because in-game time must not pass behind a menu. Audio does not, because the
score cutting out is the one thing every player notices — and note it is the autoload itself
that needed the opt-out, since the cross-fade tweens are created on it. Director does not,
because a transition in flight would otherwise strand the game on black. Each of those is set
in the owning node's own `_ready()`, never from UiRoot: a central pause that reaches into ten
nodes is the god object all over again.

**Connects:**

UiRoot announces `ui_mode_changed`; `PlayerController`, `InteractionSensor` and
`InteractPrompt` listen. UiRoot does not know the player exists, and the player does not know
which screen opened — it takes one `&"ui"` token and gives it back. The player and the sensor
hold *separate* locks, because the sensor lives in `src/systems/` and the controller in
`src/gameplay/`, and reaching upward across that line is what the layer rule forbids.

**Verified:**

```
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --import                                        # clean
"$G" --headless --quit-after 30                                 # "0 warnings, 0 errors", x3, zero ERROR/WARNING lines
"$G" --headless res://tests/test_runner.tscn --quit-after 150   # 294 passed, 0 failed, exit 0
"$G" --headless --script tools/check_budgets.gd                 # 53 files, 3879 lines, 0 violations, exit 0
"$G" --headless --script tools/check_content.gd                 # PASS, exit 0
```

A deliberately inverted assertion (`get_tree().paused` expected `false`) gave
`293 passed, 1 failed` and **exit 1**, then was restored.

Windowed captures at 960x540, `--time=18:40 --freeze-time`:

- without a screen: the lit courtyard, the player, and `Use Iron Lever` on the prompt.
- `--open-screen`, frame 45: the stub screen centred and correctly sized over the world, the
  world still drawn behind it through the 0.82-alpha panel, **and the interaction prompt
  gone** — which is the prompt's new `ui_mode_changed` handler, visible in a photograph.
- `--open-screen`, frame 16: the fade curtain still partly up **over** the screen text. By
  frame 45 it has fully lifted. So the fade both draws above the screens and keeps tweening
  while the tree is paused, which is the pause table proving itself.

A throwaway probe scene (deleted afterwards) drove the live tree with a real injected
`InputEventAction`, because the suite is synchronous and cannot await a frame:

```
stack found: true              opened: true
depth 1, paused true, gameplay allowed false, player holders [&"ui"]
injected CANCEL
depth 0, paused false, gameplay allowed true, player holders []
```

The pause table is asserted, not merely documented: `ui_test.gd` opens a modal and reads
`can_process()` off `Clock`, `Weather`, `Audio`, `Director`, the stack, the screen and the
player. That confirmed empirically what would otherwise have been a guess about Godot's
default process mode for autoloads — they are pausable, so `Audio` genuinely needed the line.

**Unblocks:**

Every screen in the game. WP-03 (HUD and inventory screen) is now a `UiScreen` subclass with
content in it and nothing else — no new pause, no new boolean, no new signal.

**Known gaps:**

- Pre-existing, found while re-running the ladder and reproduced at baseline: `--quit-after
  30` does not reliably finish the threaded area load on a cold cache, and quitting mid-load
  prints spurious `courtyard.tscn` parse errors and leaked RIDs AFTER the run has already
  logged `0 warnings, 0 errors`. Documented as gotcha 13; the boot rung is now `--quit-after
  120` in `CLAUDE.md` and `CONTEXT.md`. The real fix is for `Director` to cancel its load on
  shutdown, which belongs in WP-14.
- No audio assets exist, so "music keeps playing" is verified as `Audio.can_process() == true`
  under pause, not by ear. That is the strongest claim available until there is an `.ogg`.
- Nothing gives a screen keyboard focus yet, so controller and keyboard navigation within a
  screen is unbuilt. It belongs with the first screen that has something to focus (WP-03).
- `Actions.PAUSE` and `Actions.CANCEL` share Escape and both merely close the top screen.
  Nothing *opens* a screen from gameplay input yet, deliberately — the pause menu is WP-12.
- `StubScreen` is scaffolding. Delete it when two real screens exist.

---

## 2026-08-26 — WP-01: triggers, resting and authored climbing

**Did:**

Three new interactables, the clock call they needed, and a climb state on the player body.

- `TriggerVolume` — an `Area3D` on `Layers.TRIGGER`, once-or-repeat, persisted by `object_id`.
  It sets a world flag and emits `Events.trigger_fired`, and that is all it does.
- `RestPoint` — the `SIT` verb, skipping to a target hour, with an optional `night_only` gate
  that refuses with `WRONG_TIME`.
- `Clock.skip_to_hour(hour)` — routed through `set_time`, returning the minutes skipped.
- `ClimbPoint` plus `can_climb` / `begin_climb` / `climb_step` on `PlayerController`.
- Prefabs in `scenes/objects/`, a stone terrace and all three objects placed in the courtyard,
  four CSV rows, `RefusalReason.NOT_GROUNDED`, and `--skip-to-hour=` on the dev capture.
- `tests/unit/traversal_test.gd`, 50 assertions. The suite is now 215.

**Why:**

The `Triggers/` node, `Layers.TRIGGER` and the inventory rows for sittables and climbables had
all existed since Phase 0 with nothing populating them. Three specific reasons shaped the code:

- **A trigger must not name its consequence.** `@export var door_to_open` is the same trap the
  lever avoids: the second time two things must react to one crossing, the coupling has to be
  undone. It sets a flag and announces itself; anything may watch either.
- **A time skip is one event, not a fast-forward.** Sleeping eight hours through
  `advance_minutes` emits 480 `minute_passed` signals, and any listener doing real work per
  minute does it 480 times in one frame. `skip_to_hour` is a single `set_time`.
- **`NOT_GROUNDED` is a new refusal reason, not a silent no.** A climb refused mid-air with no
  explanation is indistinguishable from a broken button, and this project's whole position on
  refusal is that the player should be told why.

**Connects:**

`ClimbPoint` asks the mover `can_climb()` and calls `begin_climb()` — it never writes a
position itself, so `PlayerController`'s boundary holds and interaction stays out of it.
`RestPoint` calls `Clock`, and everything downstream of the clock — the environment driver,
and later NPC schedules — reacts without knowing a bench exists. `TriggerVolume` reuses
`PersistentState` unchanged; it is not an `Interactable`, because nobody presses it.

**Verified:**

- `--headless --import` — clean.
- `--headless --quit-after 30` — **0 warnings, 0 errors**.
- `--headless res://tests/test_runner.tscn --quit-after 150` — **215 passed, 0 failed**,
  exit 0. A deliberately broken assertion gave 211/1 and exit 1.
- `--headless --script tools/check_budgets.gd` — 48 files, 3500 code lines, 0 violations,
  exit 0.
- `--headless --script tools/check_content.gd` — PASS, exit 0.
- Two windowed captures at 960x540 from the same `--time=06:30 --freeze-time` start, the
  second adding `--skip-to-hour=20`: warm dawn with south-cast shadows becomes cool night
  with both lantern pools lit. **The lighting genuinely changed**, which is the thing headless
  cannot tell you.
- A third capture with the spawn temporarily moved beside the terrace shows the ladder flush
  to the stone face and the prompt reading "Climb Trellis Ladder"; a fourth, from the top
  marker, shows the body standing on the terrace with the same prompt still offered, so the
  descent is reachable. Spawn restored afterwards.

**Two real bugs the engine caught, neither visible in the source:**

1. **The climb oscillated on its corner forever.** The path deliberately turns at the top —
   up-then-over ascending, over-then-down descending — because a straight line from the foot
   of a ladder to the ledge above passes *through* the ledge, and a climb that writes
   `global_position` has no collision left to stop it. But without a latch, the frame after
   arriving at the waypoint steps off towards the target, the next frame sees the body is no
   longer at the waypoint and steers back. 600 test steps, no convergence. Fixed with
   `_climb_turned`.
2. **The dais trigger toasted at spawn, from three metres away.** A spawning player exists at
   the area origin for one frame before `Director` places them on the spawn marker, so a
   trigger anywhere near that origin fires on load, every load. `TriggerVolume` now arms two
   physics frames late. Verified in both directions: no spawn toast now, and with the trigger
   temporarily moved onto the spawn point it still fires through `body_entered` under real
   physics, with the flag landing under its `object_id`.

**Unblocks:**

`Clock.skip_to_hour` is what NPC schedules (WP-06) need to be testable — a schedule you have
to wait twenty real minutes to observe is not one you will ever debug. Trigger volumes give
area transitions (WP-04) their entry mechanism, and give quests (WP-08) a way to fire a step
from a place rather than from an object.

**Known gaps:**

The unit test drives `fire()` directly and asserts the wiring (layer, mask, one `body_entered`
connection); the physical entry path is proven by the windowed run, not by the suite, because
`TestCase.run()` is synchronous and cannot wait on a physics frame. For the same reason the
*grounded* half of the climb refusal is asserted only in its negative direction — a body that
has never called `move_and_slide` is mid-air by definition, which is exactly the case worth
testing. The arm delay means anything still standing inside a volume when it arms is treated
as having entered; that is deliberate, and correct for a save reloaded inside a region.
`RestPoint` has no `PersistentState` because it has nothing to remember.


## 2026-08-25 — Work sliced into one-chat packages, and a roadmap to skeleton-complete

**Did:**

No gameplay code. Added `docs/WORK_PACKAGES.md`: fifteen packages from here to
skeleton-complete, in dependency order, each sized to one chat and each naming the exact files
that chat should read. Wired it into all four entry points — `CLAUDE.md`, `README.md`,
`docs/CONTEXT.md` and `docs/ROADMAP.md` — and put the per-chat open/close protocol in
`CLAUDE.md`, since that is the file a new session reads automatically.

**Why:**

A chat context window is the binding constraint on this project. This session hit usage limits
three times, and twice a delegated fan-out died mid-flight after burning several hundred
thousand tokens. Work has to be sliced so one chat finishes one coherent part.

The structure was already fine — `src/core` is 590 code lines, `src/systems` 725,
`src/gameplay` 867, `src/ui` 117 — and the downward-only layer rule means a package never has
to read upward. **The missing piece was not structure, it was a manifest.** A new session had
no way to know which subset to load, so it loaded too much. Every package now carries an
explicit file list, which is the load-bearing part of the whole document.

Also settled what "skeleton complete" means, because the phrase was doing a lot of unexamined
work: every system on the inventory has a working minimal implementation plus one piece of
placeholder content proving it. That is the standard items were held to — three throwaway
`.tres` files proved the pattern and the fiftieth item needs no code. After that point,
everything remaining is content.

**Connects:**

The board is the executable version of `ROADMAP.md`, and that file now says so, so the two
cannot silently drift. Dependency order is recorded with reasons rather than left implicit —
UI foundation before any screen, because a screen built first forces an ad-hoc pause and a
boolean per screen; dialogue before quests and path actions, because both are driven by it;
world map after a second area exists, because it is meaningless with one.

WP-15 carries a specific obligation: it must settle ADR-0006's open question. Items are found
by scanning a directory, verified in the editor and headless only, and the export preset must
export *all* resources or the catalogue ships empty.

**Decisions taken with the owner:** all four optional systems are IN the skeleton — path
actions, traversal equipment, world map and fast travel, crafting and gathering. Nothing on
the inventory is cut. Narrative systems are built against placeholder story; the real story is
content, supplied later.

**Verified:**

Docs-only, so the ladder is a regression check rather than a proof: boot `0 warnings, 0
errors`, tests 165 passed / 0 failed, `check_content` PASS. Every entry point references the
board.

**Unblocks:**

WP-01, triggers and traversal, in a fresh chat: trigger volumes (the folder, the collision
layer and the inventory row all exist and nothing populates them), a rest point with
`Clock.skip_to_hour`, and climb points — the authored vertical movement that "no jumping"
implies.

**Known gaps:**

Packages 02 through 15 are specified at goal-plus-manifest depth, not to WP-01's detail. That
is deliberate: writing detailed plans for work fourteen chats away is exactly the speculative
architecture this project keeps deleting. Each gets its detail when it comes up.

---

## 2026-08-25 — Items, inventory, pickups and chests: the demo loop closes

**Did:**

Planned this one properly before writing anything, because the last two attempts at
delegating research both died on usage limits. Two Explore agents mined the three surviving
audit reports and verified the existing seams; one design agent produced an implementation
plan; the whole thing was settled with the owner before line one. That paid for itself twice
over, below.

Shipped in two commits. First, prerequisites (`dd90da0`):

- **Layer order corrected.** The declared order put `content` *above* `gameplay`, but a
  `Pickup` must reference an `ItemDefinition` — an upward dependency failing ADR-0001's own
  test. Content is data, not a consumer: `core -> content -> systems -> gameplay -> ui`.
  Recorded as an ADR-0001 amendment rather than quietly fixed.
- **Signal payloads.** `notify_requested` had no substitution slot, so a toast could not say
  "Taken: Rose Key", and `interaction_refused` could not name the missing item. Both now carry
  a `Dictionary`; both had zero emitters, so it was free then and expensive later.
- **Per-section save versions.** `register()` takes a version, sections store as
  `{"v": n, "data": {…}}`, and appliers migrate themselves. One envelope version would have
  forced `_migrate` to understand every section — the god object via the back door.
- **`Flags` hands out deep copies** from `get_dict`/`get_array`. Godot passes Dictionaries by
  reference, so returning the stored object let a caller mutate world state without
  `set_flag`, meaning `flag_changed` never fired.
- **Test suite split** into `tests/framework/test_case.gd` plus `tests/unit/*.gd`, because the
  runner was at 184 of its 250 lines and the item cases would not fit. Raising the budget is
  the exemption the checker's own header forbids.

Then the feature:

- **`ItemDefinition`** — the project's first `Resource`. Four fields: `id`, `name_key`,
  `category`, `max_stack`. Five more were cut (`icon`, `description_key`, `value`, `tags`,
  `world_scene`) because nothing displays or reads them and adding one later edits one script
  while leaving every `.tres` valid.
- **`ItemDb`** — a static class, not an autoload, that scans `data/items`. ADR-0006.
- **`Inventory`** — a component on the player, with `can_accept()` as the single capacity seam.
- **`Pickup`**, **`ItemContainer`**, and `Gate.requires_item`.
- **`tools/check_content.gd`** — duplicate object ids, id/filename mismatches, localization keys
  missing from the CSV, and `ItemDefinition` files filed outside `data/items`.
- Courtyard content: a rose key on the dais, a wicker chest, an east gate that wants the key.

**Why:**

Items had to be next because they were the last missing piece of the Phase 1 loop *and* the
project's first typed `Resource`. `ARCHITECTURE.md` has claimed since day one that "adding the
fiftieth item must not touch a single line of code", and that claim had never been exercised —
the audit called it unrunnable rather than untested. It is now tested by a case that counts the
`.tres` files on disk instead of hard-coding three, so adding a fourth item keeps it passing.

Two design points worth keeping. **The inventory is not an autoload**: interactables are already
handed the interactor by `attempt(who)`, so `Inventory.of(who)` needs no global and works for an
NPC or a stash, whereas a global would hard-code "one bag in the universe" into every
interactable in the game. **The lever and the gate still know nothing about each other** — one
publishes a flag, the other reads one, and now a third thing can demand a carried item instead.

**Connects:**

Persistence added *zero* new machinery. `PersistentState.store(&"taken", true)` writes
`obj/<area>/<object>/taken` into `Flags`, which is already a tested save participant, so a
pickup that is gone stays gone because `flags` is applied before the area is even requested.
That is the whole return on ADR-0005. `Pickup` deliberately does not free itself — the sensor
may hold a reference inside the very call that took the item — it goes unavailable,
unmonitorable and invisible instead.

**Verified:**

- Type gate clean on every new script; `--import` clean.
- Boot: courtyard with **6 interactables**, `0 warnings, 0 errors`.
- Tests: **165 passed, 0 failed**, exit 0, no leaked instances. A deliberately broken
  assertion exits 1.
- `check_budgets`: 44 files, 3,202 code lines, **0 violations**.
- `check_content`: PASS — and proven to fail. A scratch copy with a mismatched item id, a
  duplicate `object_id`, a misspelled localization key and a stray definition produced four
  precise `file:line` violations and exit 1.
- Visual capture at 10:15 shows the placeholder-marker key on the dais and the chest, both
  casting shadows, with the localized prompt reading "Read  Weathered Notice".

**Two things the planning caught that would have cost real time:**

1. **`class_name Container` does not compile.** `Container` is a native Godot class (the
   `Control` base), so it would have cascaded into every subclass as "could not resolve class" —
   the same trap as `Area3D.priority`. Verified against the engine's own class list, and the
   chest is `ItemContainer`.
2. **Resource-typed `@export` from a hand-authored `.tscn` works** with no `node_paths` header,
   unlike Node-typed ones. Probed before authoring any prefab against the assumption.

And one bug the refactor caught in its own new helper: a one-step `spawn()` added nodes to the
tree before the caller could set `object_id`, which `Interactable` forwards in `_enter_tree` —
so it arrived too late and persistence silently died. Split into `build()` and `attach()` so the
ordering lives in the API rather than a comment.

**Unblocks:**

Trigger volumes and a rest point, then the screen stack that the inventory UI needs. Phase 1's
remaining exit criteria are now the walk-and-face check and a real save/quit/relaunch.

**Known gaps:**

**The export path is unproven** and this matters: items are found by scanning a directory,
verified in the editor and headless only. There is no export preset, and it must export *all*
resources or the catalogue ships empty — written up in ADR-0006 rather than left as a surprise.
No trigger volumes yet, no screen of any kind, no item instances (deferred until something has
durability), no equipment. The sprite sheet layout is still two hardcoded constants. Only one
area exists, so the transition code has still never swapped two.

---

## 2026-08-24 — Object identity, and the interaction loop end to end

**Did:**

- **ADR-0005: authored object identity.** Every persistent object carries a `PersistentState`
  child with an `object_id`, unique within its area. State is written through `Flags` under
  `obj/<area_id>/<object_id>/<field>`. Rejected node-path identity, which is free but couples
  identity to scene structure: renaming a node silently orphans its state, the chest refills,
  and nothing errors. Rejected generated UUIDs as unreadable in a save file and in a diff.
  No new autoload — `Flags` is already a generic store and already a tested save participant.
- **`Interactable`**, a deliberately shallow base class over `Area3D`. Subclasses override
  `refusal()` and `perform()`; detection, ranking, prompts, refusal messaging, one-shot
  handling and hold-to-confirm are all handled once. Chose a base class over a duck-typed
  component because warnings-as-errors forbids calling a method on an untyped value, so a
  component would need a cast at every call site.
- **`InteractionSensor`** on the player. Ranks candidates by authored priority, then
  proximity, then how squarely the player faces the target, with ties broken by node name so
  physics callback order cannot reshuffle the prompt between frames. Tab cycles overlapping
  targets. Hold-to-confirm is supported and drawn as a progress bar.
- **Three interactables:** `Readable` (signs), `Lever` (toggles a persistent flag), `Gate`
  (refuses with a reason until a flag is set, then opens and stays open).
- **Localized UI:** `InteractPrompt` and `NotificationToast`, plus `localization/strings.csv`
  with 28 keys wired through `tr()`. This closes the "zero `tr()` calls" audit finding —
  there is now no code path by which raw player-facing text reaches the screen.
- Placed a notice, a lever and a north gate in the courtyard as instanced prefabs from
  `scenes/objects/`.

**Why:**

The audit named object identity as the thing blocking everything else, because interaction,
items, containers and doors all persist state through it, and retrofitting it means touching
every scene. It had to be decided before content existed.

The lever deliberately does not know what it opens. The tempting design is
`@export var door_to_open`, which couples every lever to one consequence; the second time a
lever needs to do two things, the coupling has to be undone. The lever owns a flag and
anything may watch it, so one lever can gate five things without knowing they exist.

Refusal is a first-class result rather than a hidden prompt. Hiding the prompt on a locked
gate is cheaper but worse: the player cannot tell a locked door from scenery, so they never
learn there is something to come back for.

**Connects:**

`PersistentState` walks up to the enclosing `AreaRoot` for its namespace, so an id only has to
be unique within one area file. `Interactable` forwards `object_id` to that child in
`_enter_tree`, which runs top-down before any child `_ready`, so an instanced prefab sets its
identity with one root-level property override instead of a child-node edit that hand-authored
`.tscn` files cannot express robustly. Interaction input is read by the sensor, not by
`PlayerController`, because the controller's own MUST NOT line forbids it knowing about
interaction; the comment claiming "one of only two scripts allowed to read input" was corrected.

**Verified:**

- Type gate clean on all eight new scripts.
- `--headless --import` clean; boot loads the courtyard with 3 interactables,
  **0 warnings, 0 errors**.
- Test suite **74 passed, 0 failed**, exit 0. The new cases drive the whole loop with no
  simulated keypress: the gate is offered and refuses with LOCKED, the lever publishes its
  flag, the same gate then opens, its state lands at `obj/global/t_gate/open`, and after the
  node is freed and re-instantiated it is *still open* — which is what an area reload does.
  Clearing one object's state leaves unrelated flags intact.
- `check_budgets.gd` — 32 files, 2,485 code lines, 0 violations. It caught one of these very
  test functions at 42 lines against the 40 limit; the function was split rather than the
  budget raised.
- Visual capture at 09:30 shows the prompt reading "Read  Weathered Notice", both words
  resolved through the translation table.

**Unblocks:**

Items and inventory, which is the last big piece of the demo loop, and which will be the first
typed `Resource` content class — the thing that finally tests the "adding the fiftieth item
touches no code" claim.

**Known gaps:**

Still zero typed `Resource` content classes. No duplicate-`object_id` detection, so two objects
sharing an id inside one area would silently share state; a content validator scanning scenes
would catch it. No hard-coded-string audit, so the localization rule is enforced by discipline
rather than mechanically. Trigger volumes still have a folder, a collision layer and no system.
The gate opens but leads nowhere, because there is only one area.

Two engine traps cost time and are now recorded in `CONTEXT.md`: `Area3D` already defines
`priority`, and redefining it is a parse error that cascades into every subclass as "could not
resolve class"; and `set_anchors_preset()` leaves offsets at zero, producing a zero-size
Control whose text spills off the screen.

---

## 2026-08-24 — Audit: four defects fixed, and rung 4 of the ladder made real

**Did:**

Audited the Phase 0 skeleton, fixed every confirmed defect, and built the test suite.

- **Toggle-run did nothing.** `_is_running()` polled `Input.is_action_just_pressed` and is
  called twice per frame (from `_current_speed()` and `_update_state()`), so the toggle
  flipped twice and netted to zero. Polling moved into `_poll_run_toggle()`, called once at
  the top of `_physics_process`, and `_is_running()` is now a pure query.
- **A missing area left the screen permanently black.** `ScreenFade` starts opaque and only
  `Director` lifts it, so the early-return in `game_root.gd` stranded the player. It now logs
  an error naming the expected path and requests the fade-in regardless.
- **`player_yaw` was saved and never read.** Written to every save since the first commit,
  read nowhere, so facing was silently lost on load. Restored via `_yaw_override`.
- **A fresh clone did not run at all.** Proved by cloning the repo to a scratch directory:
  `class_name` globals live in `.godot/global_script_class_cache.cfg`, which is generated and
  correctly gitignored, so `events.gd` could not resolve `GameEnums`, the `Events` autoload
  failed to instantiate, and the console filled with parse errors that look like broken code.
  One `--headless --import` fixes it. Now documented in `README.md`, `CLAUDE.md` and
  `docs/CONTEXT.md`.
- **The silent fallback that hid a bug is now loud.** `EnvironmentDriver`'s sibling discovery
  reported at `Log.debug`; it is a `Log.warn` now, so an unwired scene reference cannot hide
  behind a working-looking day/night cycle again. Also added the canonical
  `node_paths=PackedStringArray(...)` header to the `EnvironmentDriver` node in
  `courtyard.tscn`, which is the documented serialization for node-typed exports.
- **Built `tests/test_runner.gd` + `.tscn`:** 55 assertions over `DictRead` coercion, `Flags`
  including no-op-set silence, `Clock` hour/day rollover and midnight-crossing arithmetic,
  `Weather` force and shelter, and a full save round-trip.
- Added `docs/CONTEXT.md`, a one-minute state snapshot for a new session, linked from the top
  of `CLAUDE.md` and the first row of the README table.

**Why:**

Two of the four Veilbound failure modes had already reappeared in miniature, in this project,
at 1/600th scale. `ROADMAP.md` marked "a save participant can register, and the save envelope
round-trips" as a met Phase 0 exit criterion when only the registration had ever been observed,
as a log line — the save path had never once executed. That is precisely the
409-passing-checks pathology. The criterion is now genuinely true, and the roadmap records
that it was wrongly claimed a day earlier rather than quietly correcting itself.

**Connects:**

Rung 4 had to become a **scene** entered positionally, not the `--script` tool the
architecture document specified. Under `--headless --script` the autoload *nodes* are created
but the autoload *identifiers* fail to compile (`Compile Error: Identifier not found: Log`),
so no test touching a system could ever have run that way. The documented command could not
have worked; it is corrected in `ARCHITECTURE.md`, `README.md`, `CLAUDE.md` and `CONTEXT.md`.

**Verified:**

- Type gate clean on all four edited scripts.
- `--headless --import` clean.
- `--headless --quit-after 60` — loads the courtyard, `0 warnings, 0 errors`.
- `--headless res://tests/test_runner.tscn --quit-after 150` — **55 passed, 0 failed**, exit 0.
  A deliberately broken assertion was confirmed to produce exit 1, so the gate genuinely fails.
- `tools/check_budgets.gd` — 24 files, 2,026 code lines, 0 violations, exit 0.

**Unblocks:**

Interaction, items and world objects can now be built against a suite that will catch a
regression in save, time or flags, rather than against a boot log.

**Known gaps:**

Still zero typed `Resource` content classes and zero `tr()` calls, so the "adding the
fiftieth item touches no code" test in `ARCHITECTURE.md` cannot yet be run even once, and the
no-hard-coded-strings rule has a document but no mechanism. No stable-object-ID scheme, which
blocks object persistence and is the next thing to decide. Trigger volumes have a folder, a
collision layer and no system. The audit that found this was itself incomplete — three of five
dimensions landed before the run hit a weekly usage limit; correctness and Godot-API review
were done by hand instead, and the surviving reports are in the scratchpad, not the repo.

---

## 2026-08-23 — Phase 0 foundation, and a lit courtyard with a character in it

**Did:**

Created the project from an empty folder.

- **Structure:** 80 directories in five code layers (`core`, `systems`, `gameplay`,
  `content`, `ui`), plus `scenes`, `data`, `assets`, `localization`, `tests`, `tools`, `docs`.
  Git initialised on `main`. `.gitignore` and `.gitattributes` written, including a note that
  `*.uid` and `*.import` files **must** be committed.
- **Engine config** (`project.godot`): Forward+, MSAA 4x, TAA deliberately off, debanding on,
  occlusion culling on, gravity 24, ten named collision layers, editor folder colours, and
  GDScript warnings-as-errors.
- **Ten autoloads:** `Log`, `Events`, `Actions`, `Settings`, `SaveSystem`, `Flags`, `Clock`,
  `Weather`, `Audio`, `Director`.
- **Utilities:** `Layers`, `GameEnums`, `DictRead`.
- **Gameplay:** `HD2DCameraRig`, `CharacterVisual`, `PlayerController`, `EnvironmentDriver`,
  `AreaRoot`, screen fade, game root.
- **Tools:** procedural placeholder art generator, and `DevCapture` for screenshots and
  command-line control of time and weather.
- **Content:** the `courtyard` area and the player scene.
- **Docs:** this log, `ARCHITECTURE.md`, `SYSTEMS_INVENTORY.md`, `ROADMAP.md`,
  `CONVENTIONS.md`, and decision records.

**Why:**

The previous project died of four things, all recorded in its own debt register: god objects
(`main.gd` at 3,983 lines), code that passed 409 static checks while never once running in a
real engine frame, 200 hard-coded strings, and eleven regions of breadth with no proven
slice. Every structural decision here targets one of those. The two strongest levers are
warnings-as-errors, which makes untyped and unsafe code fail to parse at all, and the
verification ladder, which makes "it runs" a command rather than an opinion.

**Connects:**

`Log` and `Events` sit at the bottom and depend on nothing, so everything may use them.
`Events` is the single declared home for every cross-system signal, which makes it the
connection map — reading that one file shows how the game is wired. `SaveSystem` knows
nothing about game content: systems register a pair of callables, so adding a saveable system
never edits the save code. `Clock` publishes time and refuses to interpret it;
`EnvironmentDriver` consumes it and turns it into light. `Director` owns every area
transition behind one guarded path so two doors cannot fire at once. `GameRoot` spawns the
player once and `Director` repositions them per area, so walking out and back in cannot lose
state.

**Verified:**

- `--headless --import` — clean, no errors.
- `--headless --quit-after 30` — boots, loads the courtyard, spawns the player, exits 0 with
  **0 warnings and 0 errors**.
- Parse and type gate over all 18 scripts — every one clean under warnings-as-errors.
- Deliberately broken script → exit 1 naming the file and line, so the gate genuinely fails.
- Visual capture at 06:50, 12:30, 18:40 and 22:00, plus a forced storm. Dawn shows warm low
  light and long raked shadows; night shows cold ambient with two warm lantern pools and the
  character lit by them. **The character sprite casts a real shadow**, which confirms
  `ALPHA_CUT_DISCARD` is behaving as intended.

**Two real bugs found and fixed by that visual pass**, neither of which any static check
would have caught:

1. The character was invisible. `centered = false` with a negative Y offset pushed the sprite
   1.68 m below the ground. Now centred and lifted by half a cell height, derived from the
   texture rather than hard-coded.
2. Every hour of the day rendered identically. `EnvironmentDriver`'s `sun` and `moon`
   `@export` references were never wired in the area scene, so the driver held `null` and the
   directional light stayed frozen at its default energy forever. Wired explicitly, **and**
   the driver now discovers its own siblings by name and logs a warning when it has to — so
   the same silent failure cannot recur.

The second one is the whole argument for rung 5 of the ladder. A day/night system that
compiles, runs, logs correct times, reports no errors, and lights nothing.

**Unblocks:**

The interaction, item and object systems, which are the next milestone. They have somewhere
to live (`Interactables/` in every area), a way to be found (`Layers.INTERACT_MASK`), a way to
announce themselves (four interaction signals already declared in `Events`), a way to persist
(`Flags` plus the area's `flag_key()` namespace), and a way to be seen (placeholder art plus
capture).

**Known gaps:**

No test runner yet, so rung 4 of the ladder is unused. No audio
assets, so every audio path is written but unexercised. Weather publishes state but nothing
renders rain. Only one area exists, so the transition code has never actually swapped two
areas. Input actions do not appear in the editor's Input Map panel, which is a known accepted
trade-off.

---

## 2026-08-26 — T2.0 · The export proof

**Did.** Built the first export this project has ever had, ran it, and found out whether an
exported build finds content that nothing references. It does. Also found a second, unrelated
export-only defect while looking, and gated it.

- `export_presets.cfg` — one Windows Desktop preset, committed. `export_filter="all_resources"`,
  and the file's header carries the measurement rather than a preference.
- `src/systems/debug/catalogue_report.gd` — reports each catalogue's count, root and resolved
  paths at boot, behind `OS.is_debug_build()`. Fifth root node in `scenes/boot/game_root.tscn`.
- `tools/check_content.gd` — `_check_editable_instances()`, 189 → 237 of 250 code lines.
- `tests/unit/export_test.gd` — 19 assertions, registered in `test_runner.gd`. 911 → 930.
- `scenes/areas/courtyard/courtyard.tscn` — the missing `[editable path="Actors/Keeper"]`.
- `docs/NEW_GAME.md` § 7 Export; ADR-0006's honest limit closed; inventory, roadmap and board.

**Why.** The three registries find items, conversations and schedules by DIRECTORY SCAN
(ADR-0006), so most of `data/**` is nobody's dependency, and Godot's exporter walks dependencies.
If it omitted them every catalogue would ship empty and NOTHING here could see it — every ladder
rung, both CI jobs, `check_content` and 911 assertions run from `res://` in the editor. Cheap to
test, architectural to fix, so it was sequenced ahead of T2.1 by risk.

**Connects.** `CatalogueReport` asks the same three registries the game asks, so it cannot report
a number the game does not have. It joins `dev_capture`/`dev_probes`/`dev_stage` in the one
directory `check_boundary` exempts, and it needs no exemption of its own: a count readout names no
demo content. The new gate lives beside `check_content`'s other scene checks because it is a
statement about whether the DEMO is well formed, not about whether the engine knows the demo
exists — the same seam that split `check_boundary` out in T1.2.

**Verified.**

```
--headless --import                             0 SCRIPT ERROR / Parse Error
--headless --quit-after 120                     Session ended after 1.3s - 0 warnings, 0 errors
--headless res://tests/test_runner.tscn         930 passed, 0 failed, 0 skipped   exit 0
--headless --script tools/check_budgets.gd      exit 0  (check_content 237/250)
--headless --script tools/check_content.gd      PASS    exit 0  (16 scenes)
--headless --script tools/check_boundary.gd     PASS    exit 0  (95 scripts, 14 exempted)
stripped (data/ + scenes/areas/ moved aside)    880 passed, 0 failed, 12 skipped  exit 0
```

The export itself, and the numbers from both sides:

```
--headless --export-debug "Windows Desktop" .../build/windows/game.exe    exit 0

editor    origin: template=false editor=true debug=true exe=Godot_v4.7.2-stable_win64.exe
          items: 3 found in res://data/items -> [rose_key.tres, rose_petal.tres, stone_chip.tres]
          dialogue: 1 found in res://data/dialogue -> [gardener.tres]
          schedules: 1 found in res://data/schedules -> [keeper.tres]

exported  origin: template=true editor=false debug=true exe=game.exe
          items: 3 found in res://data/items -> [rose_key.tres, rose_petal.tres, stone_chip.tres]
          dialogue: 1 found in res://data/dialogue -> [gardener.tres]
          schedules: 1 found in res://data/schedules -> [keeper.tres]
          Session ended after 1.3s - 0 warnings, 0 errors
```

(Paths abbreviated to their file names here; the real lines carry the full `res://data/...` path,
which is the point — a partial ship is worse than an empty one and only the paths show it.)

Run from a scratch directory holding only `game.exe`, `game.console.exe` and `game.pck` — no
`project.godot`, no loose `data/`. The exported build also USED the content:
`--give=item/rose_key,item/rose_petal:3` logged `+1 item/rose_key` and `+3 item/rose_petal`, so the
definitions loaded through the pack's `.remap` indirection rather than merely being counted.

Both new gates proved RED before green (gotcha 23):

```
[editable] line deleted     !! courtyard.tscn:337 overrides 'Actors/Keeper/PersistentState'
                               inside the instance 'Actors/Keeper' with no
                               [editable path="Actors/Keeper"] - the override is DROPPED in an
                               exported build       (+3 more)   FAIL - 4 content violation(s)

REQUIRED_FILTER = "scenes"  FAIL the preset ships every resource, not only dependencies
                            - expected scenes, got all_resources               exit 1
```

And the readout itself was proved to fail, which is the part no gate can do —
`exclude_filter="data/*"` exported and booted cleanly to the main menu:

```
items: 0 found in res://data/items -> []
[WARN] items catalogue is EMPTY in an exported build - check export_filter   (x3)
Session ended after 1.5s - 3 warnings, 0 errors
```

**The four measured facts.** `export_filter="all_resources"` stores all seven `data/**` resources;
`export_filter="scenes"` stores **zero**. `ResourceLoader.list_directory()` works through the pack
— it returns the `.tres` path for a stored `.tres.remap`, which is the first evidence ADR-0006's
choice of the undocumented method was right. `include_filter="*.tres"` is the plausible wrong fix:
the include filter is for NON-resource files and changes nothing. And a narrowed `export_filter`
fails LOUDLY, not silently — it also strips the `class_name` scripts nobody depends on
(`GameConfig`, `GameEnums`, `DictRead`, `KeyBindings`) and the build dies at boot on parse errors.
The silent version needs an *exclude* filter, which is why the readout warns rather than only
reporting.

**The second defect, which is why running this early paid for itself.** The exported build printed
three lines the editor never did: `Keeper has a PersistentState with no object_id`, `Talk has no
label_key`, `Talk names no conversation`. `courtyard.tscn` overrode those properties on nodes
INSIDE its instanced `npc.tscn` with no `[editable path="Actors/Keeper"]`. The text loader applies
such overrides; the export's `.tscn` → binary `.scn` conversion DROPS them. So the demo's NPC
shipped with no identity, no prompt and no conversation, and its schedule never ran — while every
rung, both CI jobs and 930 assertions stayed green throughout. Stale `index=` values were the first
hypothesis and were ruled out by correcting them (4,5,6,7 → 3,4,5,6) and re-exporting: no change,
same three lines. Adding the marker fixed it completely, including
`obj/courtyard/keeper/waypoint = dais` reappearing in the log.

**Setup, recorded because it is not obvious.** No export template was installed. They come only in
`Godot_v4.7.2-stable_export_templates.tpz` (1.28 GB); the four Windows x86_64 files plus
`version.txt` were extracted into `%APPDATA%/Godot/export_templates/4.7.2.stable/`.
`--export-pack` needs no template at all and is enough to see WHICH files ship; only a real
template proves they are FOUND at runtime, which is the actual question.

**Unblocks.** T2.1 (art contract seams) can now be built on a content pipeline proven end to end
rather than assumed. Every package after this one inherits a working preset and a boot-time readout
that makes a content regression visible in the one place it was previously invisible.

**Gaps.**
- **No CI export rung.** A GPU-less runner has no platform template. Same honesty as T1.4's stance
  on the windowed capture: stated as impossible, not quietly dropped.
- **Windows only.** Other platforms each need their own template and are a consuming game's call.
- **The readout is debug-only, by design.** A release export prints nothing, so verifying a release
  build's content would need a different mechanism. Nothing needs it yet; noted so the absence is a
  decision rather than an oversight.
- **The `[editable]` gate reads text.** Same limit as `check_boundary`: a scene assembled at
  runtime, or an override written by a tool, is invisible to it.
- **`tools/check_content.gd` is at 237 of 250 code lines.** The next check added to it will not
  fit, and the seam is already visible: the scene checks are a different question from the
  content-registry checks.

**CI green**, run [32995130430](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32995130430), both jobs: `930 passed, 0 failed, 0 skipped` full and `880 passed, 0 failed, 12 skipped` stripped — the hand-run numbers exactly.

---

## 2026-08-27 — T2.1 · Art contract seams

**Did.** Moved the two things that made "a second, visually different game starts from this
without editing `src/`" false: the sprite sheet's dimensions, and the UI's look. Both are now
authored data, and both were proved by swapping something and looking at the result.

- `src/content/art/sprite_sheet_layout.gd` — new, 34 code lines. `facings`, `frames`,
  `animations`, `cell_size`, `idle_row`, `walk_row`, plus `sheet_rows()`, `sheet_size()`,
  `sector_radians()`, `column_for_angle()`, `animation_for()`, `frame_index()`, `problems()`.
- `src/gameplay/character/character_visual.gd` — `FACING_COUNT`, `FRAME_COUNT`, the literal
  `TAU / 8.0` and `_cell_height()` all gone; a `layout` `@export` in their place, and every
  dependent number read from it. 95 → 107 code lines.
- `assets/placeholder/character_layout.tres` — the old constants, moved out unchanged: 8x4, 32x48.
- `assets/placeholder/character_alt_layout.tres` + `character_alt.png` — 4 facings, 3 frames in
  2 blocks, 24x40. Disagrees with the default on every number, which is the point.
- `assets/theme/ui_theme.tres` — new, wired as `gui/theme/custom`. Nine type variations carrying
  font sizes, a `UiPalette` of four colours, a `UiMetrics` of six insets.
- The five styled files — `menu_screen.gd`, `dialogue_screen.gd`, `inventory_screen.gd`,
  `hud_clock.gd`, `loading_indicator.gd` — now hold no colour and no font size of their own.
- `tools/gen_placeholders.gd` — `_build_alt_sheet()`, 95 → 129 code lines.
- `tests/unit/art_contract_test.gd` — 83 assertions. Suite 930 → **1013**.
- `scenes/characters/player.tscn`, `npc.tscn` — the layout wired; inventory, roadmap, board.

**Why.** `FACING_COUNT = 8` and `FRAME_COUNT = 4` were constants in `CharacterVisual`, and the
sector maths was a **separate literal `TAU / 8.0`** that had to agree with them by hand. Two
places holding one number, and a game with a four-facing sheet would have needed a code edit —
the one thing a template must never ask for. There was no animation-row offset either, so
idle-versus-walk was not unimplemented but *structurally impossible*: one cycle, nowhere to put a
second. Meanwhile the UI look was constants in five screen files with the accent colour written
out three times in two slightly different values, so a restyle was five edits that would drift and
a consuming game had nowhere to put its own look but a fork of the screens.

**Connects.** The layout lives in `src/content/` because it is a data shape, so anything may read
it, and like `item_definition.gd` it touches no autoload — `tools/` loads content classes under
`--script`, where autoload identifiers do not resolve, so one `Log` call there would break a build
gate. `SpriteSheetLayout` was checked against the API dump first (`AudioBusLayout` is the only
near-miss; `Resource` declares none of the six field names) — the fifth time this project has
gone looking after `Area3D.priority`, `class_name Container`, `DictRead.get_name` and
`ItemDb.reload()`. The theme goes through `gui/theme/custom` rather than being handed to
`UiRoot`, so it reaches the HUD too — which is drawn *under* `UiRoot` and would otherwise have
been missed. Assertions for the pure functions, a capture for the picture: the same division
`export_test.gd` drew in T2.0 when it asserted its own blindness rather than implying it.

**A FACING IS NOT A COLUMN, and the obvious implementation re-creates the bug.** Mapping
`GameEnums.Facing` down onto `layout.facings` — `int(facing) * facings / 8` — puts the number 8
back in the code in a second place, exactly where it was. So the two are quantised *separately
from the same angle*: `_facing` from `GameEnums.Facing.size()`, because eight is how many
directions the **game** reasons about, and `_column` from `layout.facings`, because that is how
many the **art** distinguishes. Neither reads a literal, and when `facings == 8` they agree by
construction — which is why nothing about the existing sheet moved.

**THE PALETTE IS NOT COPIED INTO THE VARIATIONS, and that is the whole design.** A `Theme` has no
variables, so a colour repeated into nine variations is nine places to change and "one Theme edit
restyles every screen" would be false. The variations carry only `font_size`, the one thing that
genuinely differs by role; the screens read the four colours and six insets by name. It costs a
`get_theme_color` call per screen and buys the criterion outright.

**Three values were deliberately UNIFIED, and this is the package's only visual change.** The
dialogue box's dim was `0.03, 0.02, 0.05, 0.72` against the inventory's `0.04, 0.03, 0.06, 0.78`;
its speaker tint `0.90, 0.78, 0.55` against the others' `0.86, 0.74, 0.52`; its hint 16pt against
18. Nobody chose those differences — they are duplication, and preserving them would have meant
palette entries that exist to keep a typo. Two column separations moved 2px and 4px likewise.

**Verified.** Both criteria are visual claims and neither is an assertion.

```
--headless --import                       exit 0, ZERO SCRIPT ERROR / Parse Error lines
--headless --quit-after 120               Session ended after 1.3s — 0 warnings, 0 errors
tests/test_runner.tscn --quit-after 400   1013 passed, 0 failed, 0 skipped   exit 0
tools/check_budgets.gd                    exit 0
tools/check_content.gd                    exit 0   (still 237/250; nothing added to it)
tools/check_boundary.gd                   exit 0
--resolution 960x540 ... --time=18:40     looked at; unchanged from before the refactor
```

*Criterion 1 — a sheet with a different cell and frame count, no code changed.* Two `ExtResource`
paths in `player.tscn` repointed at the alt pair, nothing else, reverted after. The probe and the
picture agree exactly:

```
default, standing   frame=0/32   size_px=(256.0, 192.0)
alt,     standing   frame=0/24   size_px=(96.0, 240.0)
alt,     walking    frame=19/24  size_px=(96.0, 240.0)
```

`frame=19` decodes to row 4, i.e. block 1 (walk), frame 1, column 3. The zoomed capture shows the
orange walk-block body, **four** pips down the left edge, **two** along the foot, no eyes, and
legs offset — block 1, frame 1, column 3. `(1*3 + 1) * 4 + 3 = 19`. Standing, the same crop showed
the green idle body with one pip each way and eyes. The NPC beside the player kept the 8x4 sheet
throughout, which is the incidental proof that a layout is per-node and not global.

*Criterion 2 — one `Theme` change restyles every screen.* Six lines of `ui_theme.tres` and no
other file: `text` white → near-black, `accent` gold → deep red, `dim`/`solid` near-black →
parchment, `margin` 64 → 120, `TitleText` 40 → 56. Captures before and after of the main menu and
of the inventory screen over a frozen world. Both restyled completely; the HUD clock followed
without being mentioned. Reverted.

*Both new gates proved RED before green (gotcha 23).* Putting
`add_theme_font_size_override(&"font_size", 22)` back in `hud_clock.gd` — the exact regression the
gate exists for — gave `FAILED: hud_clock.gd writes down no font size — expected 0, got 1`, exit 1.
Changing `frames = 3` to `4` in the alt layout gave `FAILED: the alt layout is 3 frames in 2
blocks — expected [3, 2], got [4, 2]` plus `FAILED: the two layouts disagree on the frame count`,
exit 1. Both reverted, both green.

**A temporary probe, added and removed as gotcha 15 prescribes.** `CharacterVisual.describe()`
had existed with no caller since Phase 0, so no run had ever printed which cell was drawn. A
`_temporary_t21_probe()` in `dev_capture.gd` logged it at the shutter and a `_temporary_t21_walk()`
pressed `move_left` twelve frames before the shot — an assertion cannot press a key and
`TestCase.run()` never reaches a frame. Both quoted above, both removed;
`git diff src/systems/debug/dev_capture.gd` is empty.

**EVERY CELL OF THE ALT SHEET IS SELF-LABELLING, because gotcha 2 has a sharper form here.** A
day/night system that lights nothing is at least obviously wrong on screen. A character drawn from
the *wrong cell* still looks like a character — upright, lit, facing *some* direction. So the
capture cannot be judged, it has to be read, and each cell carries `column + 1` pips down its left
edge and `frame + 1` along its foot with a different tint per animation block. That is what made
`frame=19` a checkable prediction rather than a number to take on trust.

**Unblocks.** T2.2 can now document an art contract that exists rather than describing intent —
`ART_CONTRACT.md` is `SpriteSheetLayout`'s header plus the theme's, and both were written to be
read by a consuming game. A game with four-direction art, or a six-frame cycle, or a separate idle
needs no engine change. And the environment post-stack, the shared materials and the per-area
camera exports left below all now have a worked precedent for the shape they should take.

**Gaps.**
- **The theme does not set the `Button` styleboxes**, so `MenuRow` and `ChoiceRow` still draw
  Godot's default dark panel. The parchment capture showed it plainly: every row stayed
  dark-on-light while the rest of the screen restyled. The seam is right and in the same file
  (`MenuRow/styles/normal`), it is simply unpopulated — and a consuming game with a light palette
  hits it immediately, which makes it T2.2's business to say so at minimum.
- **Five of the roadmap's nine T2.1 items are left**, in its own order, because the package hit
  its file budget: shared materials, the environment post-stack as `@export`s, per-area camera
  exports, the texture import defaults and the Git LFS lines. Half-doing five seams is worse than
  finishing two.
- **The texture import defaults have a reason beyond budget.** `[importer_defaults]` is an
  undocumented editor-managed section — absent from `--headless --doctool` — so it cannot be
  checked against the API dump the way this project requires, and hand-authoring an undocumented
  format is exactly the kind of change that looks applied and does nothing. The per-file values
  already committed are correct for pixel art. One latent hazard worth naming for whoever picks it
  up: every `.import` carries `detect_3d/compress_to=1`, and these sheets *are* used in 3D, so a
  re-import could switch them to VRAM compression and put block artefacts through pixel art.
- **The Git LFS lines stay commented, deliberately.** The `.gitattributes` comment is right: LFS
  pointers for a 2 KB placeholder are pure overhead, and enabling them would put the CI checkout
  on a dependency it does not currently have. Enable when real art arrives, which is what it says.
- **`animations` is authored, not inferred.** A layout claiming more blocks than the sheet has is
  caught by `problems()` only when a texture is supplied, which `CharacterVisual` does and a bare
  `.tres` review does not.

**CI green**, run [32998836688](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32998836688), both jobs: `1013 passed, 0 failed, 0 skipped` full and
`963 passed, 0 failed, 12 skipped` stripped — 880 + 83, reproducing T2.0's stripped number exactly.
All 83 new assertions run in a stripped template, because the case names `assets/` and never `data/`.

## 2026-08-27 — T2.2 · Consumer documentation

**Did.** Wrote the four documents a consuming game needs, and then closed Phase T2's last exit
criterion by *performing* it rather than claiming it.

- `docs/AUTHORING.md` — new. Task-first: add an area, an interactable object, an item, a
  conversation, an NPC. The ten required children of an area root, a complete minimal area
  written out in full, the navmesh settings that will otherwise strand an NPC, the
  `[editable path=...]` trap, the localization rules, the debug flags that drive the game, and a
  table of what each gate catches.
- `docs/ART_CONTRACT.md` — new. The sheet grid (facings across, frames down, grouped into
  animation blocks), the declared-not-derived cell size, the `Sprite3D` settings and what they
  demand of the art, the import settings and the `detect_3d/compress_to` hazard, the theme's
  three-way split, and the `Button` stylebox gap stated plainly.
- `docs/TESTING.md` — new. The five rules of this suite that each cost an hour: it is a scene,
  `run()` is synchronous, every case declares a plan, the plan is provably not enough on its own,
  and an unlisted case never runs. Plus the fixture rule and how to prove a gate.
- `docs/ARCHITECTURE.md` — a new § **The extension surface**, three tiers. Also corrected: the
  area diagram listed eight children and was missing `Navigation/` and `Waypoints/`; two "known
  limitations" had been false since T2.0 and WP-13.
- `tests/unit/docs_test.gd` — new, 68 outcomes, computed. Suite 1013 → **1081**.
- `CLAUDE.md` — the flat "Read next" list becomes a doc-router table. `docs/CONTEXT.md` — same.
- `docs/SYSTEMS_INVENTORY.md` — two new rows, and the area-root row corrected to ten children.

**Why.** Everything this template can do was documented in **file headers**. They are excellent,
and they are the wrong shape for a consumer: a header is found by already knowing which file to
open. Nothing started from "I want to add an area" and ended at a working area, and the extension
surface — which classes a game may subclass and which are the engine's own business — did not
exist anywhere at all, which is the thing most likely to be got wrong by someone moving fast.

**Connects.** T1.2 wrote `NEW_GAME.md` (what to delete); this is what to write afterwards. T2.1
wrote two headers deliberately aimed at a consuming game, `sprite_sheet_layout.gd` and
`ui_theme.tres`; `ART_CONTRACT.md` is their consumer-facing form and carries the one gap T2.1
left. `TESTING.md` is T1.3's two crash mechanisms and the fixture rule, written for someone who
was not there.

**Verified.** The criterion was PERFORMED. A new area, a new NPC with a schedule and a new
four-node conversation were authored from `AUTHORING.md` alone — nothing copied from an existing
area, and `src/` not consulted while writing them. Full ladder green with the new content in:
import exit 0 with zero `SCRIPT ERROR` / `Parse Error`, boot `0 warnings, 0 errors`,
`1101 passed, 0 failed, 0 skipped`, all three checkers exit 0 — `check_content` including the
`[editable]` gate. The capture was looked at: the NPC stands in the new area with the dialogue box
open on its first-meeting line, speaker name resolved. Then the content was **deleted** — it was a
test of the documents, not new demo content, and `TEMPLATE.md` is explicit that the demo does not
get deepened. Final ladder after deletion: `1081 passed, 0 failed, 0 skipped`, everything else
green, and the demo courtyard capture at 18:40 unchanged.

**Six defects the walkthrough found**, each fixed:

1. The documented capture command never leaves the main menu. `--shot` alone photographs the
   title screen — the first PNG produced in this package is the menu. `--new-game` is required,
   and no document mentioned the debug harness flags at all. Now a table of eight.
2. The gate table claimed the boot rung catches "an unresolvable first area". It does not:
   `--headless --quit-after 120` stops at the menu, loads no area, and still reports
   `0 warnings, 0 errors`. Gotcha 22's family — a rung reporting clean about work it never did.
3. `--stand-by=` takes a NODE NAME, not an `object_id`, and the id is what the document had just
   told the author to set. `--stand-by found no node called 'ferryman_talk'`.
4. The NPC placement example omitted its own `[ext_resource]` line, so it could not be used as
   written.
5. The navmesh example implied a healthy bake is a big number. A flat floor bakes **2** polygons.
6. The suggested capture hour, 18:40, renders a propless new area very nearly black — which looks
   exactly like a lighting bug.

Two things it confirmed rather than corrected: an override on a node inside an instance needs no
`index=` (the name resolves it — the stale indices in the courtyard really were the red herring
T2.0 called them), and one `[editable path=...]` covers both overridden children of one instance.

**The gate was proved red twice, once by accident and once on purpose (gotcha 23).**

Accidentally, on its first run — and this is why `DEVLOG.md` is now exempt from the path scan:

```
FAILED: DEVLOG.md names res://tests/unit/zz_probe_test.gd, which exists — expected true, got false
```

That path is a temporary probe T1.3 created to prove the runner fails on a crash, quoted by name
and then correctly deleted. A history necessarily names files it removed on purpose. Everything a
reader is meant to *follow* is still scanned.

Deliberately, with two planted violations — renaming `walk_row` in `ART_CONTRACT.md`'s worked
layout, and repointing one script path in `AUTHORING.md` at a file that does not exist:

```
=== 1074 passed, 6 failed, 0 skipped ===
FAILED: AUTHORING.md names res://src/content/items/item_definition_moved.gd, which exists — expected true, got false
FAILED: ART_CONTRACT.md documents sprite_sheet_layout.gd.walk_row_renamed — expected true, got false
FAILED: AUTHORING.md documents item_definition_moved.gd.id — expected true, got false
FAILED: AUTHORING.md documents item_definition_moved.gd.name_key — expected true, got false
FAILED: AUTHORING.md documents item_definition_moved.gd.category — expected true, got false
```

Exit 1. Both reverted: `1081 passed, 0 failed, 0 skipped`, exit 0.

**Why a test for prose at all, and what it deliberately does not do.** Most of this package is not
assertable and a test that restated the prose would be worse than none. But two things in a
consumer document are facts about this repository and both rot in silence: a `res://` path that no
longer resolves, and a field name in a worked example that was renamed. Both are found by a
reader, once, following the document into a dead end and concluding the template is broken. The
class-to-property mapping is read out of each fenced block's own script `ext_resource` lines
rather than from a list in the test, so there is no second list to go stale. Paths under the
content roots are skipped when absent, because a stripped template has deleted exactly the files
`docs/` teaches by example with.

**The `Button` stylebox gap was left unfixed, on purpose.** One addition to `ui_theme.tres`, no
code, and tempting. But a stylebox has to be *designed*, and the only palette to design against is
the placeholder one — so it would be a decision shipped as a default, from the package whose job
is to describe the template honestly rather than change it. Stated instead in the three places a
consumer reaches: `ART_CONTRACT.md`, `ARCHITECTURE.md`'s limitations, `CONTEXT.md`. The menu
capture taken during the walkthrough shows it: every row drawing Godot's default dark panel.

**Unblocks.** Phase T2 is complete — all four exit criteria ticked. A consuming game can now strip
the template (`NEW_GAME.md`), author content (`AUTHORING.md`), bring art (`ART_CONTRACT.md`), keep
the suite honest (`TESTING.md`) and know what it may extend (`ARCHITECTURE.md`).

**Gaps.** The documents cover authoring, art and testing; they do **not** cover saving, settings,
audio or the flag namespace, because a consuming game does not author those. Whether that stays
true is a question for the first real game. `docs_test.gd` checks that documented paths and fields
*exist*; it cannot check that a documented *sentence* is true — the walkthrough is the only thing
that does, and it has to be redone by hand whenever the authoring surface changes. Nothing yet
describes how a game already forked from this base receives a later fix to it; that is Phase T4.
And the five T2.1 leftovers are still open — shared materials, the environment post-stack and
camera framing as `@export`s, the texture import defaults, the LFS lines — now documented as open
seams rather than silently absent.

**CI, both jobs, run 33086307621.** Full checkout: `1081 passed, 0 failed, 0 skipped`. Stripped
template: `1027 passed, 0 failed, 16 skipped` — up from T1.3's twelve, and the four new skips are
exactly the doc-named paths under the content roots, which a stripped checkout has correctly
deleted. `check_budgets`, `check_content` and `check_boundary` PASS in both. That the same
documents pass in a template with no game in it is a better proof of the skip design than the
assertion for it would have been.

---

## 2026-08-27 — WP-08 · Quests

**Did.** Built the quest system: two content `Resource`s, the fourth directory-scan registry, a
tracker that turns flag changes into progress, a journal screen on `J`, one placeholder quest, and
49 new assertions. Extracted the `FlagTest` evaluator into `FlagQuery` so a dialogue condition and a
quest step share one implementation. Split `tools/check_content.gd`, which had 13 lines of budget
left. Phase T3's first package.

**Why.** Quests were the one system in the catalogue with **no proof at all**, and Phase T2's
replacement for the retracted "depth before breadth" is breadth of systems, one shallow proof each.
Everything a quest needs already existed and nothing joined it up.

**The decision the package turns on: a step names a FLAG CONDITION, never a callback.** Same closed
set of six comparisons a dialogue condition uses. Two consequences, and both are the point:

1. **A quest is authored data.** Adding the fiftieth touches no code, which is ADR-0006's test.
2. **Nothing has to know quests exist.** The placeholder quest is built entirely out of flags the
   demo was already writing: a conversation effect (`met/gardener`) starts it, the courtyard lever
   (`area/courtyard/gate_unlocked`) advances it, the dais trigger volume
   (`area/courtyard/dais_entered`) completes it. **None of those three files was touched.** That is
   the trigger-volume rule — a trigger never names its consequence — applied to narrative state.

**Derived, except for two latches.** `flags.gd`'s own header says derive what can be derived, and
almost all of this is: the current objective is the first step whose test fails, asked live every
time a flag moves. Two things genuinely cannot be derived. That a quest **started** — its start
condition is a flag, and clearing that flag must not un-give a quest carried for three hours. That
a quest **completed** — a step may test `AT_LEAST 3` on a counter, and a later decrement must not
reopen a finished quest. Those two are the whole save section, held as **two lists of quest ids**;
never an enum ordinal, which is the ADR-0005 rule this project has already been bitten by. The
current objective is deliberately NOT latched, so clearing the flag behind objective two on an
active quest brings objective two back. Both halves are asserted — a latch nothing tests is
indistinguishable from a cache.

**A completed quest grants nothing.** It emits `Events.quest_completed` and stops. A `reward_item`
field would put `Inventory` and a player — both `gameplay` — inside a `systems` tracker, and `src/`
points downward only. Anything that wants to hand over an item listens to the signal; anything that
wants to gate a conversation tests the flag the last step tested, with no code at all.

**FlagQuery was extracted rather than copied.** `DialogueRunner._passes` was the only evaluator of
`FlagTest`; a quest step asks the identical question with the identical meaning, and a second copy
of a rule eventually disagrees with the first — the failure would surface as a quest that will not
complete for a flag a conversation is perfectly happy with. Same reasoning that makes a weather
emitter be TOLD its weight rather than read `Weather`, and a theme colour live once rather than per
variation. `quests_test.gd` fails if the table grows back in either file, which is the gate
`art_contract_test.gd` established for sheet dimensions.

**The fourth registry came due on a note `schedule_db.gd` left, and it was reconsidered rather than
ignored.** That header said "three is a pattern, four is a problem — if a fourth registry appears,
that is the moment to reconsider." Reconsidered; verdict: keep the copy. GDScript has no generics,
so a shared base could only cache `Resource` and hand it back untyped, making `definition()`,
`conversation()`, `schedule()` and `quest()` a cast at every call site — and static typing is
non-negotiable #2, not a preference. What IS genuinely shared already is shared: `QuestDb` calls
`ItemDb.resource_paths()` rather than copying the `.remap` handling. The refactor that would pay is
a base holding the cache plus a thin typed façade each, which touches four registries and four
areas of the suite. It is **T3.1 on the board** with the reasoning, not a shrug.

**`check_content.gd` split, and the seam was already in the reasoning.** 237 of 250, and the quest
checks did not fit. `tools/content_scenes.gd` takes the scene *text* scans (duplicate `object_id`,
`_key` literals, the `[editable]` marker) — they need no class registered and keep working on a
scene that is broken for an unrelated reason; what stayed asks the *registries* what they loaded.
Still one command and one CI rung: it is a `RefCounted` the entry point instantiates, not a second
`SceneTree` tool. 237 → 178 + 102. Fifth split the budget checker has exposed.

**The quest checks print the flags rather than validating them.** A flag can be written from a
scene, a conversation, a path action or another quest, and the writer that matters most is a runtime
one — `PersistentState` builds `obj/<area>/<object>/<field>` at load. A checker that failed on any
flag with no findable writer would be wrong most times it fired, and a partial check that looks
complete is exactly what this project exists to prevent. So they go where a reviewer reads them:

```
  quests: 1
     quest/keepers_errand   2 steps, starts on met/gardener is_true
        unlock              done when area/courtyard/gate_unlocked is_true
        dais                done when area/courtyard/dais_entered is_true
```

**Connects.** `Events.quest_started` / `quest_advanced` / `quest_completed` were declared in Phase 0
and had no emitter and no listener until now; the tracker emits all three and the journal listens to
all three. `Flags` gains its first derived consumer. `SaveSystem` gains a fifth participant.
`ScreenKeys` gains the journal binding its own header predicted would land there rather than in a
file of its own. `CatalogueReport` gains the fourth row it said a fourth registry would cost.
`Fixtures` gains the fourth redirect. `Actions.JOURNAL` had existed unbound since Phase 0.

### Verified

**Ladder, all green.** `--headless --import` exit 0, **zero** `SCRIPT ERROR` / `Parse Error` lines
(gotcha 22 — the boot rung cannot see those). Boot `--quit-after 120`: `0 warnings, 0 errors`, with
`quests: 1 found in res://data/quests -> ["res://data/quests/keepers_errand.tres"]` and
`Quest tracker ready over 1 quest(s)`. Suite: **1149 passed, 0 failed, 0 skipped**, exit 0 (1081 →
1149: 49 in `quests_test.gd`, 2 in `export_test.gd` for the fourth catalogue line, and 17 more that
`docs_test.gd` COMPUTED from the new worked quest example in `AUTHORING.md` — the docs gate
covering its own new content, which is what a computed plan is for). `check_budgets`,
`check_content` and `check_boundary` all exit 0.

`check_boundary` now derives `quest/keepers_errand` and `keepers_errand` among its 14 demo names and
finds neither in any of the 104 engine scripts it scans:

```
  demo names derived: 14 — ["courtyard", "lantern_hall", "talk/gardener", "gardener",
  "item/rose_key", "rose_key", "item/rose_petal", "rose_petal", "item/stone_chip", "stone_chip",
  "quest/keepers_errand", "keepers_errand", "schedule/keeper", "keeper"]
  engine scripts scanned: 104 ... PASS
```

**GATE ONE PROVED RED, THEN GREEN (gotcha 23).** The real authoring mistake, not a convenient one:
one letter added to a step's `summary_key` in the authored quest.

```
  quests: 1
     quest/keepers_errand   2 steps, starts on met/gardener is_true
        dais                done when area/courtyard/dais_entered is_true
  !! quest/keepers_errand/dais summary_key 'quest.keepers_errand.step.daiss' is not in the CSV
FAIL — 1 content violation(s)
PLANTED exit=1
```

Reverted:

```
PASS
REVERTED exit=0
```

**GATE TWO PROVED RED, THEN GREEN.** The failure `FlagQuery` exists to prevent: a second copy of the
comparison table appended to `dialogue_runner.gd`.

```
FAIL and it no longer carries its own copy of the comparison table — expected false, got true
=== 1148 passed, 1 failed, 0 skipped ===
PLANTED exit=1
```

Reverted:

```
=== 1149 passed, 0 failed, 0 skipped ===
REVERTED exit=0
```

**ONE DEFECT, FOUND BY THE CAPTURE AND BY NO GATE.** `--flag=` set its flag during argument parsing,
and `--new-game` **clears every flag** — so the first capture photographed a journal with no quest
in it, and the run reported `0 warnings, 0 errors` throughout. The log is what shows it: the
`--flag` line lands *before* `Quest tracker ready`, and no `quest/keepers_errand: started` line
follows.

```
21:47:01 [INFO ] [test  ] --flag met/gardener = true by command line
21:47:01 [INFO ] [quest ] Quest tracker ready over 1 quest(s)
21:47:01 [INFO ] [test  ] --new-game requested 'courtyard'
21:47:02 [INFO ] [test  ] --open-menu journal pushed: true
```

`_force_flag` now waits for the area the way `_open_menu` does, and the same run reads:

```
21:47:50 [INFO ] [quest ] quest/keepers_errand: started [&"quest/keepers_errand"]
21:47:50 [INFO ] [quest ] quest/keepers_errand: advanced [&"quest/keepers_errand", &"unlock"]
21:47:50 [INFO ] [test  ] --flag met/gardener = true by command line
21:47:50 [INFO ] [test  ] --open-menu journal pushed: true
```

This is gotcha 31's family: not a rung blind to an error, but staging that ran before the thing it
was staging for. Worth knowing for any future `--` flag that poses state a `--new-game` resets.

**THE INPUT PATH, PROVED BY A TEMPORARY PROBE, THEN REMOVED** (gotcha 15 — `TestCase.run()` is
synchronous, so no assertion can press a key). Added to `dev_stage.gd`, run windowed with real
`InputEventAction`s, and deleted; `git diff src/systems/debug/` shows only the `--flag` addition.
The probe, verbatim:

```gdscript
## TEMPORARY WP-08 PROBE. Removed before the package closed; quoted verbatim in DEVLOG.md.
func _probe_journal_key() -> void:
	await _wait_for_area()
	for _i: int in 40:
		await get_tree().physics_frame
	var stack: UiRoot = UiRoot.find(self)
	Log.info("test", "PROBE before: depth=%d top=%s" % [
		stack.depth(), stack.top().screen_id if stack.top() != null else &"NONE"])
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = Actions.JOURNAL
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().physics_frame
	Log.info("test", "PROBE after press: depth=%d top=%s" % [
		stack.depth(), stack.top().screen_id if stack.top() != null else &"NONE"])
```

Its output, from `--resolution 960x540 --quit-after 200 -- --new-game --flag=met/gardener:true
--probe-journal-key --time=12:00 --freeze-time`:

```
PROBE before: depth=0 top=NONE
PROBE after press: depth=1 top=journal
PROBE after second press: depth=0 top=NONE
0 warnings, 0 errors
```

So `J` opens the journal and `J` closes it, through `_unhandled_input` and the real action, and the
toggle only fires while the journal is itself on top.

**TWO WINDOWED CAPTURES, LOOKED AT.** Both at midday, `--new-game --shot-frame=70 --quit-after 90`,
because no ordinary run enters an area (gotcha 31) and a new capture at 18:40 renders near-black.

1. `--flag=met/gardener:true --open-menu=journal` — the journal over a live courtyard: **Journal /
   Underway / The Keeper's Errand / — Unlock the north gate.** with the **New errand: The Keeper's
   Errand** toast at the top and *Escape to close* at the foot. The world, the player and the keeper
   are visible through the translucent dim, which is how the capture shows the screen stopped the
   world rather than replaced it.
2. All three flags — the same screen reading **Settled / The Keeper's Errand / — Nothing left to
   do.** A third run at `--shot-frame=300 --quit-after 340` catches the second toast in the queue,
   **The Keeper's Errand is settled**, since the *New errand* toast holds the first three seconds.

**The `Button` styleboxes were left unpopulated, deliberately, and the captures are why the claim is
checkable.** The journal's rows draw Godot's default dark panel — visible in both PNGs as the wide
bordered bars. Legible against the shipped dark palette, so the journal did not force the decision,
and T2.2's reasoning for not shipping a guessed stylebox holds. Stated, not silently skipped.

### Unblocks

WP-11's map markers (a marker is a listener on `quest_advanced`, which now has an emitter), WP-09's
plot gating (a chapter is a quest start condition), and any consuming game's main narrative spine.
T3.1, the registry refactor, is now scoped by an actual fourth copy rather than by anticipation.

### Gaps

- **A QUEST STEP CANNOT READ AN ITEM COUNT, and the original exit criterion "completed by an item
  handover" is therefore NOT met.** `Inventory` keeps counts, not flags. This is the honest cost of
  "a step is a flag condition", and the seam is a `Pickup` or `ItemContainer` that writes a flag —
  a template change, recorded in `ARCHITECTURE.md`'s limitations and in `AUTHORING.md` § Add a
  quest so an author hits the note before the wall, rather than routing around it under `src/`.
- No branching, no failure state, no timed quests, no rewards beyond a flag, and no sorting,
  filtering or detail pane in the journal. One shallow proof; `TEMPLATE.md` is explicit that the
  demo does not get deepened.
- `quest_advanced` fires on the frame a quest starts as well, because the first objective becoming
  current IS an advance and a marker needs to hear it. Only the TOAST is suppressed there. Correct,
  and worth knowing before writing a listener that assumes the two are exclusive.
- The tracker is a node in the boot scene, so a game that replaces `game_root.tscn` loses quests
  silently. `CatalogueReport` sits there on the same terms and neither is asserted to be present.

**CI green, run 33091433887, job logs read rather than the tick** (gotcha 26 — the run listing lags
and the tick is not the evidence). Full checkout: **1149 passed, 0 failed, 0 skipped**, with
`quests: 1` in `check_content`. Stripped template: **1094 passed, 0 failed, 16 skipped**, with
`quests: 0` — an empty quest folder is not an error, which is T1.2's finding holding for the fourth
registry the day it was added. All three checkers PASS in both jobs, and the skip is named rather
than silent:

```
SKIPPED: quests_test: authored quests validate (this checkout has no quests in data/quests)
  — 0 assertion(s) not run
```

Zero rather than one because `quests_test.gd`'s plan is COMPUTED from the number of authored quests
(`transitions_test.gd`'s shape, sanctioned in `docs/TESTING.md`), so a stripped run's plan is
already smaller by exactly that assertion — the skip is there to SAY it gave one up, not to pad a
count. The push run (33091433975) and the pull-request run (33091486449) are green as well.

**Commit `a00ddda` on `claude/wp-08-quests`, PR #16**, stacked onto `claude/t2-2-consumer-docs`
(#15) rather than `main`, matching the rest of the chain.
