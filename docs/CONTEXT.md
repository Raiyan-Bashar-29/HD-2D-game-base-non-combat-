# Context — read this first, it takes one minute

A state snapshot for a new session. `CLAUDE.md` has the *rules*; this file has the *situation*.
Keep it short. When it drifts from reality, fix it in the same commit as the change.

**Last updated:** 2026-08-26 · T1.3 (test fixtures + framework hardening) complete

> **This is a TEMPLATE, not a game.** Read [`TEMPLATE.md`](TEMPLATE.md) — it is short, and the
> roadmap, the board and parts of this file were written before that reframing. The courtyard and
> the garden-keeper are *proof that a system works*, not the product.

## Which branch to work from

Every package — WP-01 through WP-07, plus WP-12 and WP-13 — is on **`claude/integration`** (PR
#10 into `main`); the reframing docs are on **`claude/template-reframing`** (PR #11); T1.2 is on
**`claude/t1-2-boundary`**, branched from the reframing tip; T1.3 is on
**`claude/t1-3-fixtures`**, branched from T1.2. The nine earlier PRs are superseded.

**Branch new work from `claude/t1-3-fixtures`**, or from `main` once #10, #11, T1.2 and T1.3 have
landed. The older
per-package branches (`claude/wp-04-second-area`, `claude/wp-05-dialogue`, `claude/wp-06-npcs`,
`claude/wp-07-path-actions`, `claude/wp-12-menus`, `claude/wp-13-presentation`) are history and
should not be built on.

**Remote:** https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-

## What this is

A reusable BASE TEMPLATE for HD-2D exploration games. Godot 4.7.2, GDScript.
Visual reference: Octopath Traveler I/II/0, The Adventures of Elliot.

**No combat.** Explicitly retracted by the owner — not an oversight. **Art is deferred**;
everything runs on procedural placeholders, permanently â the template ships an art *contract*,
never art, and each game brings its own. The goal is a skeleton with a home for every system a
game built on this will need, so a new game is content and data rather than new architecture.

## Where it stands

Phase 0 complete, Phase 1 COMPLETE, Phase 2 well under way, Phase T1 three quarters done. 98
files, 8,100 code lines,
18 scenes, 2 areas, 3 items, 1 conversation, 1 schedule, 2 path actions.
Boots headless with **0 warnings, 0 errors**.

**Works, and verified by running it:** logging with rotation · signal registry (`events.gd`) ·
input actions · settings · save/load with atomic writes and versioning · plot flags · area
director with a re-entrancy guard and threaded loading · world clock · weather state · audio
buses · HD-2D camera rig with tilt-shift DOF · billboarded lit shadow-casting 8-way character ·
camera-relative walk/run/sneak · day/night lighting · screen fade · dev screenshot capture ·
placeholder art generator · line-budget checker · a headless test suite (911 assertions) that
builds its own content and passes with the demo deleted, and that FAILS on a case which crashes,
returns early, asserts nothing, or is not listed in the runner ·
an engine/demo boundary gate that derives the demo ids and fails on any of them in src/ ·
interaction sensor with ranking and Tab-cycling · Interactable contract · localized prompt and
toasts · readable signs · levers · gates gated by flag or by a carried key · per-object
persistence (ADR-0005) · typed item definitions found by directory scan (ADR-0006) · an
inventory component with a capacity seam · pickups · take-all chests · a content validator ·
trigger volumes that fire on entry · a rest point that skips hours · authored climb points ·
a screen stack with real pause semantics · a token input lock · a HUD clock readout · an
inventory screen with focus navigation · one action-to-screen binding · a SECOND area, an
interior, and a door that really travels · a loading readout drawn above the curtain ·
shader warm-up behind black · a dialogue runner with conditions, branches and effects · a
non-pausing dialogue box with a typewriter reveal · an authorable .tres conversation format ·
a navmesh baked from each area's own geometry · an NPC that keeps a timetable and can be
talked to · schedules as authored data · path actions with a standing that gates them and
that they move Â· **weather you can see**: generated rain, snow and wind emitters driven by
`Weather.intensity()`, surfaces that darken and gain a wet clearcoat and then dry out over
twenty-six seconds, and a layered ambience bed on procedurally generated noise.

**Not built:** quests · hard-coded-string audit · item instances (durability) · equipment ·
item tooltips, sorting and drag-and-drop · CI, so the ladder is still seven commands a human
types (T1.4).

## Known defects

**Fixed 2026-08-26 in T1.3, and it had been wrong since ADR-0006:**

1. **`ItemDb.reload()` had never called our function.** `Script` declares `reload()`, and
   `ItemDb` as an identifier IS the GDScript object, so the static call dispatched to
   `Script.reload()` — which reloads the script and resets its static variables. That happens to
   do exactly what our `reload()` was written to do, so nothing broke and no test could see it.
   It surfaced only when a redirectable `content_dir` was added: the assignment stuck, and the
   next `reload()` silently reset it. Proved with a print inside `_ensure_loaded()` that
   `ItemDb.reload()` never reached. All three registries now expose `rescan()`. Fourth
   native-name collision in this project, after `Area3D.priority`, `class_name Container` and
   `DictRead.get_name` — see gotcha 17, and note that a *static* function is no exception.
2. **The test suite could not fail on a crash**, which invalidated every green result the project
   had. Fixed with two mechanisms, because the first was measurably not enough — see gotcha 24.

**Fixed 2026-08-26 in T1.2, both found by doing rather than by a gate:**

1. **`dev_capture.gd` had failed to parse since the WP-13 merge and every rung stayed green.**
   `await _settled()` was added without the function, so F12, `--shot`, `--time`, `--freeze-time`
   and `--weather` were all dead for a package. See gotcha 22: `0 warnings, 0 errors` counts
   `Log.error` calls, not engine parse errors. Found by grepping `--headless --import`.
2. **A stripped template failed its own content gate on step one of `docs/NEW_GAME.md`**, because
   the three content registries reported an empty folder as a problem. Found by actually
   performing the checklist instead of writing it.

**Fixed 2026-08-26 in WP-13, both found by running it and neither by a static gate:**

1. **`SurfaceWetness` was driven before it had collected anything to drive.** `WeatherVisuals`
   readies before it, and `apply()` skips a value that has not moved â so arriving in an area
   mid-downpour would have shown a dry courtyard forever. Found by reading the line ORDER in the
   boot log, not by a failing test.
2. **Every `play()` against the Dummy audio driver leaks an instance.** See the audio gotcha.


**Fixed 2026-08-26 in WP-06. Three found by running it, eight more by an independent
adversarial review of code that had already passed every gate:**

1. **A HARD SOFT-LOCK in dialogue.** `advance()` asked the AUTHORED choice array while the
   screen drew the FILTERED one, so a node whose every choice failed its condition rendered a
   box with no buttons that would not advance and could not be escaped, holding the player's
   and the sensor's tokens until the process was killed. `advance()` now reads
   `available_choices()`.
2. **The navmesh baked EMPTY and said nothing.** `SOURCE_GEOMETRY_ROOT_NODE_CHILDREN` parses
   children of the `NavigationRegion3D`, which has none. An empty bake takes 0ms, so "baked in
   0ms" is what the failure looks like. Now group-sourced, and the log reports the polygon count
   and errors at zero.
3. **The navmesh bridged a step the body cannot climb.** `agent_max_climb` was above the dais's
   0.4m riser, but `move_and_slide()` has NO step-up, so the NPC walked into it and stopped
   while the agent insisted it had not arrived â silently. See the settled decision below.
4. **A non-`Node3D` area root left the curtain black forever**, with the old area already freed
   and `current_area_id` empty, so not even `reload_current_area()` could recover. Every failure
   path now goes through `Director._abandon()`, which lifts the fade on the way out.
5. **A failed load left "Loading" pinned over the game** for the rest of the session. It now
   hides when the curtain lifts, which every path out of a transition does.
6. **A refused transition left a save's position override armed for the NEXT one**, teleporting
   the player to coordinates authored for a different area. Cleared on every path that does not
   place the player.
7. **The loading readout could never appear during the boot load** â the one load, on a cold
   cache, that most needs it. Progress now shows it as well as updating it.
8. **Nothing closed screens on an area change; `UiRoot.close_all()` was dead code.** Travel does
   not lock the player, so a conversation opened during the fade-out kept running over the new
   area with its speaker freed. `UiRoot` now unwinds on `area_unloading`.
9. **Choice buttons and `choose(index)` indexed two different lists.** The world runs behind a
   dialogue box, so a flag written while it is open shifts every index between drawing a button
   and pressing it. The UI now calls `take(choice)` with the object it drew.
10. **`InteractionSensor._on_availability_changed` swapped `_current` without resetting the
    hold**, so a part-finished hold fired an adjacent object that became available mid-hold.

**Fixed 2026-08-26 in WP-05, found by a capture:**

1. **An unquoted comma in `strings.csv` had been eating text since WP-01.**
   `object.lever.gate.on` was cut at its comma, so the lever toast had read `Somewhere north`
   for three packages. Nothing caught it: the key still resolved and `tr()` still returned a
   string. Both offending rows are quoted, and `check_content.gd` now FAILS any row that parses
   to more than two columns. A translator adding a comma cannot reintroduce it silently.

**Fixed 2026-08-26 in WP-04. All three were invisible until a SECOND area existed, and all
three compiled cleanly and passed every static gate:**

1. **`DictRead.get_name()` never worked, and loading a save had never restored the area.**
   `Resource` declares `resource_name` with the getter `get_name`, and a GDScript *is* a
   Resource, so the static call dispatched to the native zero-argument method and threw at
   runtime. Its one caller was `Director._apply_save`. With one area it looked fine, because
   you always reloaded into the area you were already in. Now `get_string_name`.
2. **The interaction prompt survived an area change**, offering an Iron Lever in an area that
   no longer existed. `InteractionSensor` pruned its candidate list but never validated
   `_current`, and **a freed object compares EQUAL to `null` in Godot 4** — so
   `best != _current` reported "unchanged" and nothing was re-announced. `_announced_id: int`
   now carries the identity, because an int survives the object it names.
3. **`follow_clock = false` did not mean "do not use the clock".** It only stopped the driver
   *updating*; `_ready()` still sampled the clock once, so the first interior ever built was
   pitch black when entered at 02:30 and fine at noon, from the same scene file. An interior
   now has its own authored ambient, fog and background.

**Fixed 2026-08-26 in WP-01, both found by running the engine, neither visible in the source:**

1. **A climb oscillated on its corner forever.** The path turns at the top on purpose — a
   straight line from the foot of a ladder to the ledge above passes *through* the ledge, and
   a climb that writes `global_position` has no collision left to stop it. But the corner has
   to latch: without it, the frame after arriving at the waypoint steps off towards the
   target, and the next frame steers back. 600 test steps, no convergence.
2. **A trigger volume near the area origin fired at spawn.** The player exists at the origin
   for one frame before `Director` places them on the spawn marker, so the courtyard's dais
   trigger toasted from three metres away, on every load. `TriggerVolume` now arms two
   physics frames late.

**Fixed 2026-08-24, all four found by audit and each verified after the fix:**

1. Toggle-run did nothing. `_is_running()` polled `is_action_just_pressed` and is called
   twice per frame, so the toggle flipped twice and netted to zero. Polling moved to
   `_poll_run_toggle()`, called once at the top of `_physics_process`.
2. A missing area left the opaque fade up forever with no recovery. `game_root.gd` now logs
   an error and requests the fade-in regardless.
3. `player_yaw` was written to every save and never read back, so facing was silently lost.
   Restored via `_yaw_override`.
4. **A fresh clone did not run at all.** `class_name` globals live in the gitignored
   `.godot/` cache, so `events.gd` could not resolve `GameEnums`, the `Events` autoload
   failed, and the console filled with parse errors that looked like broken code. Fix is
   documentation: run `--headless --import` once after cloning. Now stated in `README.md`
   and `CLAUDE.md`.

**Not defects, but known and deliberate:**

- `Weather` keeps rolling during a visual capture unless `--freeze-time` is passed, so an
  un-frozen screenshot is not reproducible.
- The environment driver rebuilds a `Dictionary` every frame in `_sample()`. Measured as
  harmless at this scale; revisit if the frame budget tightens.
- 17 of the 23 settings have no consumer yet. They are declared so the settings screen has
  something to bind to, not because anything reads them.

## Decisions already made — do not re-litigate

- **GDScript, not C#.** The installed engine is the standard build; .NET is not available.
- **Warnings are errors.** `var x = 5` does not parse. Read untyped data via `DictRead`, never
  `int(value)` on a `Variant`.
- **Input actions live in code** (`src/systems/input/actions.gd`), so the editor's Input Map
  panel looks empty. Intentional — ADR-0003.
- **Ten autoloads, no `GameManager`.** Adding one requires an ADR.
- **No jumping.** Vertical movement is authored: a `ClimbPoint` names two markers and asks
  `PlayerController.begin_climb()`. The climb turns its corner at the *top* end, both going
  up and coming down, so it never cuts through the ledge.
- **A climb is refused, not hidden.** Mid-air gets `RefusalReason.NOT_GROUNDED` with a
  message, on the same reasoning that makes a locked gate offer its prompt.
- **A trigger volume never names its consequence.** It sets a flag and emits
  `Events.trigger_fired`; anything may watch either. Same reasoning as the lever.
- **A time skip is one event.** `Clock.skip_to_hour` routes through `set_time`, never
  `advance_minutes` — an eight-hour sleep must not emit 480 `minute_passed` signals.
- **Inventory is a component, not an autoload.** Interactables are handed the interactor, so
  `Inventory.of(who)` needs no global and works for an NPC or a stash too. A global would
  hard-code "one bag in the universe" into every interactable.
- **Capacity is unlimited**, behind `can_accept()`. Slots or weight go in that one method.
- **`ItemCategory` stays an enum.** The eight values are a closed set and a new *item* never
  needs a new category, so it does not violate the no-code-per-item rule.
- **Item instances are deferred** until something actually has durability; `{id, count}` is
  enough. Never persist an enum ordinal — persist ids.
- **Input is held by NAMED TOKENS, never a boolean.** `InputLock` on the player and on the
  interaction sensor. `lock(&"dialogue")`, `release(&"dialogue")`. A boolean broke the moment
  WP-01 gave it a second caller, and a counter would strand instead. Do not reintroduce
  `set_input_locked(bool)` as a convenience over the top of it.
- **A screen never pauses anything itself.** It declares `pauses_world` and `closes_on_cancel`
  as a `UiScreen`, and `UiRoot` does the rest. `UiRoot.is_gameplay_input_allowed()` is the one
  truth; everything else listens to `Events.ui_mode_changed`.
- **A screen declares its flags in `_init`, never in `_build`.** `_build` runs from `_ready`,
  i.e. after a caller has had its chance to override one, so setting `pauses_world` there
  silently discards an overlay's request to keep the world running. `StubScreen` did exactly
  that and made the overlay assertion in `ui_test.gd` pass vacuously for a whole package.
- **The HUD is a layer, not a class.** The clock, the prompt and the toasts are independent
  siblings under `UILayer`, each subscribing to the one signal it draws. There is no `Hud`
  node owning them, and adding one would only create somewhere for the fourth readout to
  accumulate.
- **An inventory screen is handed its carrier**, `InventoryScreen.for_carrier(who)`, on the
  same reasoning as `Inventory.of(who)`: the same window shows an NPC's satchel or a stash.
- **One node binds actions to screens.** `ScreenKeys`, under `UILayer`. The journal key and
  the map key join it there rather than each finding a different home, which is how a boolean
  per screen was born last time.
- **A dialogue condition is a CLOSED SET of comparisons, never an expression.** `FlagTest` has
  six values, `FlagWrite` has five. The moment a conversation can hold an expression it needs a
  parser, error reporting and a sandbox, and the .tres stops being reviewable in a diff. When
  six are genuinely not enough, add a seventh, not a grammar.
- **A conversation is an ORDERED ARRAY and the runner falls through.** The entry point is the
  first node whose condition passes, not `nodes[0]`, and a skipped node falls through to the
  next in authored order. That is what makes "if we have met, greet me differently" two nodes
  and no wiring. Effects fire on ARRIVAL, so a node has the same consequence however reached,
  which is why a choice has a condition but no effect.
- **A failing choice is OMITTED, not shown disabled** — the opposite of a locked gate, on
  purpose. A gate you cannot open teaches you there is something to come back for; a reply you
  cannot give teaches you only that the writer thought of it. So `choose(index)` indexes what is
  ON SCREEN, not the authored array.
- **A conversation is NOT SAVED.** Persisting a position writes a node id into the save file,
  making every node id in every .tres a permanent public identifier — rename one and old saves
  load into a position that no longer exists. The section exists, is always empty, and logs what
  it discarded. A save taken mid-conversation reloads with the conversation over and control
  returned.
- **A waypoint must be somewhere the BODY can walk, which is not the same as somewhere the
  navmesh covers.** A `NavigationMesh` bakes `agent_max_climb` into the walkable surface and
  will happily bridge a knee-high step, but `CharacterBody3D.move_and_slide()` has no step-up at
  all. This game has no jumping and authored vertical movement, so the climb limit is kept BELOW
  anything the body cannot manage and waypoints sit on the ground.
- **A navmesh is baked at load, never checked in.** A committed one goes stale the moment
  someone moves a wall, and a stale navmesh fails silently. It is baked behind the same curtain
  that already hides the shader warm-up, and the polygon count is logged so an empty bake is an
  error rather than silence.
- **A schedule names a WAYPOINT, not a position**, and has no `until_hour`: an entry runs until
  the next begins and the last wraps past midnight, so a day is always completely covered and
  two entries cannot disagree about who owns 14:00.
- **A UI takes a dialogue choice by IDENTITY, never by index.** `take(choice)`, not
  `choose(index)`. A conversation leaves the world running, so any flag written while the box is
  open can shift every index under the player's finger.
- **`Weather` renders NOTHING, and `WeatherVisuals` decides NOTHING.** Every number in the
  visuals is read from `Weather`; the toast on a change is emitted by the visuals, so the state
  machine still does not know a screen exists.
- **A weather emitter is TOLD its weight; it never polls.** One that read `Weather` itself would
  be a second place the rules live, and the two would disagree mid cross-fade.
- **Weather particles are GENERATED, never authored.** Art is deferred indefinitely, so a rain
  texture is a dependency this project will not take.
- **`SurfaceWetness` duplicates every material it touches**, or a scene's shared sub-resources
  would leave the courtyard wet after a reload on a clear day.
- **Wetness is a pure `RefCounted`, not a node field**, because drying is the only part with
  memory and no assertion can wait for a `_process` frame.
- **A REFUSAL and a FAILURE are different things.** A refusal happens before anything: the
  player is told why and nothing changes. A failure happens after committing: the action ran, it
  did not work, and it COST something. An action that could only refuse is a lock with extra
  steps; one that could only fail gives the player no way to read the situation first. Path
  actions have both, and `once` applies to SUCCESS only, or a single early failure would lock
  the player out forever with no way back.
- **A path action is a THRESHOLD, never a dice roll.** A random one makes the player save-scum,
  and a save-scummed mechanic is experienced as a slot machine rather than as a relationship.
- **Standing is a namespace over `Flags`, not a store**, keyed `standing/<who>` and NOT through
  `PersistentState` â that namespaces per area, which is right for a chest and wrong for a
  person: the keeper who dislikes you in the courtyard must still dislike you in the hall.
- **An NPC's actions are overlapping Interactables, not a menu.** The sensor already ranks and
  Tab-cycles between overlapping targets; a menu would be a second selection mechanism competing
  with the first.
- **A door names an id and a spawn, and nothing else.** `AreaDoor` emits
  `Events.area_change_requested` and stops. It does not load, fade or place the player.
  `Director` owns the sequence and the guard, and nothing else calls `change_area()` — a door
  that ran its own transition would be a second, unguarded path, which is how two doors firing
  at once leaves two areas in the tree.
- **An interior has its own light, not a frozen sample of the outdoor one.** `follow_clock =
  false` now means the Interior group on `EnvironmentDriver` is applied once and the outdoor
  path never touches that area's sun. It used to mean only "stop updating", which is not the
  same thing and made an interior's brightness depend on the hour it was entered at.
- **The loading indicator is the ONE node after `ScreenFade`.** Gotcha 12 says the curtain must
  be the last child of `UILayer` so it covers every screen. The indicator has to be readable
  *while* the curtain is up, so it is the single deliberate exception, and there should not be
  a second one.
- **Pause is per node, not global.** `get_tree().paused` is set by UiRoot, but each node
  decides for itself in its own `_ready()`. The full table is the header of
  `src/ui/root/ui_root.gd`. Clock and Weather stop; Audio, Director, ScreenFade,
  NotificationToast and DevCapture do not.
- **A TEST BUILDS ITS OWN CONTENT, and a test that names demo content is testing the demo.**
  `tests/framework/fixtures.gd` is the seam, and its rule is one line: **in memory when a system
  is HANDED content, on disk when a system LOOKS IT UP BY ID.** The three registries scan a
  directory (ADR-0006) and cache statically, so an in-memory `ItemDefinition` is invisible to
  `Inventory.add(id)`; the fixtures write `.tres` files to `user://test_fixtures/` and point
  `content_dir` there. A test-only injection method on each registry was rejected: a backdoor in
  engine code that exists for the suite and nothing else is worse than a temp folder, and going
  out through `ResourceSaver` and back through the real scan proves the authoring round trip as a
  side effect. Since T1.3 `check_boundary` scans `tests/` too, so this is a gate, not a habit.
- **A CASE THAT ASSERTS THINGS ABOUT THE DEMO SKIPS LOUDLY, never silently.** `skip()` stands in
  for the assertions it replaces, so the plan is the same number with or without `data/` and a
  stripped run prints what it gave up. `861 passed, 0 failed, 12 skipped` is a different claim
  from `861 passed`, and the difference is the whole point.
- **EVERY CASE DECLARES A PLAN, and the number is maintained by hand.** TAP's `1..N`. It is the
  only thing that can see a crash that swallowed an assertion, an early return, a commented-out
  block, or a case that asserts nothing — see gotcha 24 for why nothing cheaper works. A stale
  plan fails loudly with both numbers and the case name, so it is self-correcting friction rather
  than a trap.
- **A CONTENT ROOT IS A `static var`, NOT A CONST.** `ItemDb.content_dir` and its two siblings.
  A game may keep its items somewhere else, and the fixtures do. `ItemDb.ITEM_DIR` is now the
  DEFAULT, not the answer, and `tools/check_content.gd` validates whatever the root currently is.
- **NO FILE UNDER `src/` OR `tests/` MAY NAME DEMO CONTENT**, and since T1.2 `tools/check_boundary.gd` is
  what says so. It derives the forbidden names from `scenes/areas/` and the ids in `data/`
  rather than listing them, so it cannot go stale. **Comments are exempt, code is not:** a `##`
  line saying `data/items/rose_key.tres must declare id = &"item/rose_key"` is teaching by
  example and changes nothing; a `const` changes behaviour. One directory is exempt,
  `src/systems/debug/`, because those three files exist to drive the demo — and the exemption is
  conditional on their argument parsing staying behind `OS.is_debug_build()`, which the same
  tool checks. Do not widen the exemption; a second exempt directory means the rule is gone.
- **A GAME-SPECIFIC ANSWER LIVES IN `project.godot`, read through `GameConfig`.** The starting
  area is `[game] world/first_area`, the game's name is `application/config/name`, and
  `src/core/util/game_config.gd` is the only place under `src/` that reads either. An `@export`
  on the boot scene was rejected: `scenes/boot/` is engine too, so that would have moved the
  leak, not closed it. An empty `first_area` is a legal state — a template nobody has put a game
  in yet — and `Director` says so instead of clearing the flags and going quiet.
- **AN EMPTY CONTENT FOLDER IS NOT AN ERROR.** `ItemDb`, `DialogueDb` and `ScheduleDb` used to
  report "no items found" as a problem, which made a stripped template fail its own gate on step
  one of `docs/NEW_GAME.md`. A file that is present and does not load is the error, and it is
  reported per file. Whether a game needs items is that game's question, not this base's.
- Six ADRs in `docs/decisions/` cover the layered `src/`, warnings-as-errors, the input map,
  and save-via-callables.

## Verify before claiming anything is done

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --check-only --script <file>   # type gate
"$G" --headless --import                       # scenes and resources
"$G" --headless --quit-after 120               # must end "0 warnings, 0 errors"
"$G" --headless res://tests/test_runner.tscn --quit-after 400   # 911 assertions, exit 1 on fail
"$G" --headless --script tools/check_budgets.gd            # must exit 0
"$G" --headless --script tools/check_content.gd            # must exit 0
"$G" --headless --script tools/check_boundary.gd           # must exit 0 — src/ and tests/ name no demo content
"$G" --resolution 960x540 --quit-after 55 -- --shot=<path> --time=18:40 --freeze-time
```

## Twenty-four gotchas that each cost an hour

1. Autoload identifiers (`Log`, `Events`, …) **do not resolve** under `--check-only`. That
   error is expected. Rungs 2 and 3 are the real compile check.
2. `--headless` uses a dummy rasteriser and **shades nothing**. Visual claims need the
   windowed capture. A day/night system once ran, logged correct times, reported no errors and
   lit nothing — because one `@export` was unwired in the scene.
3. Author with 4 spaces, then `unexpand -t 4 --first-only` before saving. Tabs are the project
   style, and mixed indentation is a parse error.
4. The test suite is a SCENE entered positionally, never `--script`. Under `--script` the
   autoload identifiers fail to compile, so no test touching a system can run that way.
5. Do not name an `` after a native member. `Area3D` already has `priority`, so ours
   is `interact_priority`; redefining a native member is a parse error that cascades into
   every subclass as "could not resolve class".
6. `set_anchors_preset()` leaves offsets at zero, giving a zero-size Control whose text spills
   off screen. Use `set_anchors_and_offsets_preset()`.
7. `Container` is a NATIVE Godot class. `class_name Container` is a parse error that cascades
   into every subclass as "could not resolve class". Ours is `ItemContainer`. Check a name
   against the API dump before claiming it.
8. Configure an interactable BEFORE `add_child`. `object_id` is forwarded to `PersistentState`
   in `_enter_tree`, so anything set afterwards is too late and the object silently stops
   persisting. `TestCase.build()` then `attach()` exists to make that ordering explicit.
9. A body spawns at the area **origin** and is placed on its spawn marker a frame later, so
   an `Area3D` sitting near the origin sees it pass through. `TriggerVolume` arms two physics
   frames late for exactly this reason. Anything else that watches for bodies needs the same
   guard.
10. `TestCase.run()` is **synchronous** — the runner calls it, it does not await it. So no
    test can wait on a physics frame, which is why interactions are driven through `attempt()`
    and a climb through `climb_step(delta)` in a bounded loop. A test that needs a real
    physics step belongs in the windowed run instead.
11. **Autoloads are PAUSABLE by default**, so `get_tree().paused` silently stops `Clock`,
    `Weather` and `Audio` alike. Audio has to opt out explicitly or the score cuts out the
    moment a menu opens — and it is the autoload *node* that needs it, not just the
    `AudioStreamPlayer` children, because the cross-fade tweens are created on the node.
    Verified with `can_process()` in `tests/unit/ui_test.gd`, not assumed.
12. **Child order in a `CanvasLayer` is draw order.** `ScreenFade` has to come after every
    SCREEN or the curtain does not cover them. It was the first child until WP-02. Since WP-04
    exactly one node sits after it, `LoadingIndicator`, which has to be readable while the
    curtain is up — that is the only deliberate exception and there should not be a second.
13. **Use `--quit-after 120` for the boot rung, not 30.** The area load is threaded, and 30
    frames does not reliably finish it on a cold cache — quitting mid-load aborts the loader
    thread and prints spurious `Parse Error` lines for `courtyard.tscn` plus leaked RIDs,
    *after* the run has already reported `0 warnings, 0 errors`. Pre-existing and reproducible
    at any commit; the real fix is for `Director` to cancel its load on shutdown (WP-14).
14. **`x if c else [] as Array[StringName]` is a RUNTIME cast failure.** The empty literal is
    a plain `Array`, the ternary takes its type from it, and the assignment throws every time
    the condition is false. It compiles, the boot run is clean, and the test suite still
    reports every assertion passing — the only trace is a `SCRIPT ERROR` line in the output.
    Declare the typed local, then assign inside an `if`.
15. **No assertion can press a key.** `TestCase.run()` is synchronous, so an input event never
    reaches the frame that would deliver it. An input path is proved by a TEMPORARY probe
    added to `dev_capture.gd`, run windowed with real `InputEventAction`s, read in the log,
    and then removed. WP-03's probe is quoted verbatim in `DEVLOG.md`; copy its shape.
16. **A FREED object compares EQUAL to `null` in Godot 4.** So `if thing != null` does NOT
    fire for a dangling reference, and `a != b` against one reports "unchanged". Only
    `is_instance_valid()` tells the truth. Worse, a freed instance cannot even be PASSED to a
    typed parameter — the argument type check itself fails with "previously freed" — so a
    dangling reference must never cross a call boundary; read the field in place. This kept a
    prompt for an unloaded area on screen through three packages.
17. **Check a name against the API dump before using it, EVERY time — static functions
    included.** `Resource` declares `resource_name` with the getter `get_name`, and a GDScript
    is a Resource, so `DictRead.get_name(...)` compiled and then dispatched to the native
    zero-argument method at runtime. Third time this project has been bitten by a native-name
    collision, after `Area3D.priority` and `class_name Container`. Regenerate with
    `--headless --doctool <dir>` and grep it.
18. **A navmesh bake that finds nothing takes NO TIME and reports SUCCESS.** `bake_navigation_mesh`
    on a region whose geometry mode does not actually reach the terrain produces zero polygons,
    logs nothing, and every NPC then concludes it has already arrived, everywhere. Always report
    `navigation_mesh.get_polygon_count()` and treat zero as an error. Godot's default
    `SOURCE_GEOMETRY_ROOT_NODE_CHILDREN` parses the children of the `NavigationRegion3D` itself,
    which in this project's area layout has none — the terrain is a sibling, so the areas use
    `SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN` with the group `navmesh_source`.
19. **`agent_max_climb` describes an abstraction the character controller does not implement.**
    The bake will bridge a knee-high step; `CharacterBody3D.move_and_slide()` has no step-up at
    all, so the body walks into the riser and stops while the agent reports "not finished"
    forever. Keep the climb limit below anything the body cannot manage. Related: do not ask the
    navigation map anything before it has synchronised — an unsynchronised map answers
    "unreachable" to everything, and acting on that answer strands an agent at the origin.
20. **Under `--headless` the audio driver is `Dummy`, and every `play()` against it LEAKS.**
    The AudioServer releases a stopped playback on the next mix and headless quits before there
    is one, so each `play()` shows up as a leaked ObjectDB instance along with its stream.
    Stopping the player and nulling its stream in `_exit_tree` does NOT help â the server owns
    the playback. Anything that starts a sound gates on `AmbienceBed.is_audible()`, which reads
    `AudioServer.get_driver_name()`: measured as `Dummy` headless, `WASAPI` windowed.
21. **An asynchronous system needs a PERSISTENCE test, not just a delay before you ask it.**
    `NavigationAgent3D` recomputes its path over frames, so the frame after a target moves it
    answers "unreachable" to a question it has not finished thinking about. WP-06 added a delay
    before the first question and it was still wrong â the keeper reported "cannot reach" in
    windowed runs and never in headless ones, because a WANDER activity re-targets every few
    seconds and only real-framerate timing landed inside the window. The answer must now hold
    for thirty consecutive physics frames, and a new target clears the evidence. Anything asked
    of an async subsystem should be treated the same way.
22. **"0 warnings, 0 errors" DOES NOT MEAN THE SCRIPTS COMPILED.** `Log` counts its own
    `Log.warn` and `Log.error` calls; an engine-level `Parse Error` is neither, so a file that
    fails to load prints a `SCRIPT ERROR` on stderr and the boot rung still reports a clean
    session. `dev_capture.gd` was dead for a whole package this way — the WP-13 merge added
    `await _settled()` without the function, and F12, `--shot`, `--time` and `--weather` were all
    broken while every rung stayed green. **Rung 2, `--headless --import`, is the compile check.**
    Grep its output for `SCRIPT ERROR` and `Parse Error` and require zero; do not read only the
    last line of rung 3.
23. **A GATE THAT NEVER FAILS HAS NEVER BEEN TESTED.** Every checker added since T1.2 is proved
    by planting a violation, watching it exit 1, removing it, and watching it exit 0 — both
    quoted in `DEVLOG.md`. This costs two minutes and is the only thing separating a gate from a
    reassuring printout. `tools/check_boundary.gd` also gets it wrong in a way no failure can
    show: it reads text, so a computed id or a name that exists in neither `data/` nor
    `scenes/areas/` passes silently. Its header lists what it cannot see, and that list is part
    of the gate.

24. **A GDScript RUNTIME ERROR ABORTS ONLY THE INNERMOST FRAME, so a crashing test passed for
    the life of the project.** Probed: a null dereference three frames deep printed its
    `SCRIPT ERROR`, and both the calling function and `_ready()` above it ran to completion. So
    the runner sees a case that returned normally, and a completion sentinel at the end of
    `run()` cannot work either — it is reached. T1.3 needed TWO mechanisms, and the second was
    added because the first was measured and found wanting: a declared PLAN catches every crash
    that swallows an assertion, but a crash planted in a leaf helper with nothing asserted after
    it still reported `2/2` and exit 0. `tests/framework/error_watch.gd` — an `OS.add_logger`
    `Logger` counting `ERROR_TYPE_SCRIPT` — is the only thing in the engine that sees that one.
    Related and useful: `get_tree().quit(1)` followed later by `quit(0)` exits 0, last call wins,
    which is why the runner ARMS its exit code to failure on its first line.

## How work is sliced

**One package, one chat** — see [`docs/WORK_PACKAGES.md`](WORK_PACKAGES.md), which is the
board of fifteen packages from here to skeleton-complete. Each names the exact files that chat
should read, so a session loads a few hundred lines instead of three thousand. The layer rule
(`core -> content -> systems -> gameplay -> ui`, downward only) is what makes that possible: a
package never has to read upward.
**Next package: T1.4 — CI, automating the ladder.** See the board and [`TEMPLATE.md`](TEMPLATE.md).
**Next package: T1.2 â the engine/demo boundary.** See the board and [`TEMPLATE.md`](TEMPLATE.md).
The original WP-08 through WP-15 continue after the T1 and T2 phases, several of them re-framed.

## Plan — where this is going

**Phase 1 is complete and Phase 2 is well under way.** The demo loop works end to end: walk a lit
courtyard through a day/night cycle, be prompted, read a sign, throw a lever, take an item,
empty a chest, be refused by a gate that wants a key, open it once you carry the key, cross a
volume that fires once, rest on a bench and watch the light change, climb a trellis to a terrace
and back down, press I at any point to see what you are carrying in a window that stops the
world — then walk north through a door into a lantern-lit hall that has never heard of the sun,
and come back, and ask the garden-keeper who they are and what lies behind the north gate, in a
box that leaves the world running behind it. Every one of those changes survives a save and a
reload, including from the far side of an area that is no longer loaded. All of it is covered
by 460 headless assertions.

**Next, in this order.** The order matters and is not arbitrary:

1. **Path actions** (WP-07), the non-combat NPC verbs in the spirit of Octopath's Scrutinise
   and Inquire. There is now an NPC to use them on.
2. **Quests** (WP-08), which need a conversation that can set a flag and an NPC to talk to.
   Both exist.

**Then the rest of Phase 2:** NPC schedules, navigation baking, weather visuals.

**Still open, and expensive later:**
- **Sprite sheet layout is hardcoded.** `CharacterVisual` has `FACING_COUNT = 8` and
  `FRAME_COUNT = 4` as constants; a different sheet needs a code edit. Should be a resource.
- **The export path is unproven.** Items are found by scanning a directory, which is verified
  in the editor and headless only. There is no export preset yet, and it must export *all*
  resources or the item catalogue ships empty. See ADR-0006.
- **No hard-coded-string audit.** Computed keys (`verb.*`, `refusal.*`) are covered by an enum
  loop in the test suite, but literal player-facing text in code is still caught only by review.

## Read next

`CLAUDE.md` (rules) · `docs/ARCHITECTURE.md` · `docs/SYSTEMS_INVENTORY.md` ·
`docs/ROADMAP.md` · `docs/DEVLOG.md` · `src/core/events/events.gd` (the connection map)
