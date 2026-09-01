# Context — read this first, it takes one minute

A state snapshot for a new session. `CLAUDE.md` has the *rules*; this file has the *situation*.
Keep it short. When it drifts from reality, fix it in the same commit as the change.

**Last updated:** 2026-08-31 · **T3.3 (a quest step that reads an ITEM COUNT) complete —
`PENDING`, PR #21. Sixth package of Phase T3, and the one row on the board that was breadth of
EXPRESSION rather than polish: "bring me three petals" was not authorable, which is a limit on what
a consuming game can SAY.** WP-09 costed two designs and closed neither. The second — a `systems`
tracker reading a `gameplay` inventory — is not a design, it is the layer rule being broken, and
WP-08 had already refused exactly that over a `reward_item` field. So the choice was the first
(mirror the counts into `Flags`) or nothing, and the whole question was whether its stated cost —
the same number saved twice, by two participants — is real. **It is not, and `flags.gd`'s own header
is why:** *anything recomputable does not belong in the store*, and a count mirrored from the bag is
recomputable by definition. So `Flags.declare_derived(prefix)` keeps `bag/<carrier_id>/<item id>`
readable, announced on `flag_changed` and visible to `FlagQuery`, and OUT of the save file —
`Inventory.SAVE_VERSION` did not move and there is no migration. **The inversion is the whole
package: a tracker reading a bag points UP, a bag publishing a flag points DOWN**, and the quest
system was not touched — no field on `QuestStep`, no knowledge in `QuestTracker`, and a test now
FAILS if either learns what an inventory is. Sixth namespace-over-`Flags`, and the first whose value
is a NUMBER. 66 new assertions, three `check_content` branches each proved red then green, two
windowed captures LOOKED AT, and one latent defect the design could not tolerate: **a new game did
not empty the bag.**

*(Previously: T3.1, one scan behind five typed façades — `767fbe3`, PR #20. Five catalogues carried
five copies of the same scan-and-validate, and both earlier costings were right about the wrong
half: the duplication was in the SCAN, not the cache, so the base went on the **resource**
(`ContentEntry`) and the shared part is a **function** — `ContentScan.into()` fills the CALLER'S own
typed dictionary, so there is no cast at any call site. New gotcha 37: a base-class `static var` is
ONE storage shared by every subclass.
Before that: WP-09b, attributes and surface-aware footsteps — `da126d9`, PR #19. An attribute is
the flag `attr/<who>/<name>`, an integer number of steps clamped to ±4 — the **fifth** use of
namespace-over-`Flags` — and it ships with EXACTLY ONE consumer,
`PlayerController.current_speed()`, with the attribute's name declared as a const on that consumer
so **an attribute nobody reads has nowhere to be written down**. A surface is `metadata/surface` on
area geometry, inherited from the nearest tagged ancestor, and a step's sound is DERIVED FROM THE
SURFACE'S NAME rather than looked up in a table — so a game that authors `sand` hears it without
editing `src/`, and no table of names ever appears under `src/` for `check_boundary` to fail on.
Before that: WP-11, the world map — `cf3f3a1`, PR #18. An `AreaDef` .tres per area in
`data/areas/`, found by the fifth directory-scan registry, and **discovery is the flag
`map/<area id>` with no store behind it**. `WorldMap` under `GameRoot` turns arrival into discovery
and emits the same `area_change_requested` an `AreaDoor` emits; `MapScreen` on `M` draws one dot
per def at its authored normalised position and names no area.
Before that: WP-09, equipment — `1b3d799`, PR #17. An `ItemDefinition` gained one field and
`Equipment` is a component that owns no
dictionary: a slot is the flag `equip/<wearer>/<item>`, so a `Gate`, a `QuestStep` and a
`DialogueChoice` all gate on what is in hand with no code and no new field in any of them. `Gate`
was not touched to make the demo's equip-gated arch work; its other two thirds are `09b`.
Before that: WP-08, quests — a quest is authored data, every step names a FLAG CONDITION rather
than a callback, and the placeholder quest is driven entirely by flags the demo was already
writing. Before that: T2.2, consumer documentation — **Phase T2 is closed, and its last criterion
was PERFORMED**, six doc defects found by authoring from the docs alone.)*

> **This is a TEMPLATE, not a game.** Read [`TEMPLATE.md`](TEMPLATE.md) — it is short, and the
> roadmap, the board and parts of this file were written before that reframing. The courtyard and
> the garden-keeper are *proof that a system works*, not the product.

## Which branch to work from

Every package — WP-01 through WP-07, plus WP-12 and WP-13 — is on **`claude/integration`** (PR
#10 into `main`); the reframing docs are on **`claude/template-reframing`** (PR #11); T1.2 is on
**`claude/t1-2-boundary`**, branched from the reframing tip; T1.3 is on
**`claude/t1-3-fixtures`**, branched from T1.2; T1.4 is on **`claude/t1-4-ci`**, branched from
T1.3; T2.0 is on **`claude/t2-0-export-proof`**, branched from T1.4; T2.1 is on
**`claude/t2-1-art-contract`**, branched from T2.0; T2.2 is on **`claude/t2-2-consumer-docs`**,
branched from T2.1; WP-08 is on **`claude/wp-08-quests`**, branched from T2.2; WP-09 is on
**`claude/wp-09-character`**, branched from WP-08; WP-11 is on **`claude/wp-11-worldmap`**,
branched from WP-09; WP-09b is on **`claude/wp-09b-attributes`**, branched from WP-11; T3.1 is on
**`claude/t3-1-registry`**, branched from WP-09b; T3.3 is on **`claude/t3-3-item-count`**, branched from T3.1. The nine earlier PRs are superseded.

**Branch new work from `claude/t3-3-item-count`**, or from `main` once #10, #11, T1.2-T1.4,
T2.0, T2.1, T2.2, WP-08, WP-09, WP-11, WP-09b, T3.1 and T3.3 have landed. The older
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

Phase 0 complete, Phase 1 COMPLETE, Phase 2 well under way, **Phase T1 COMPLETE, Phase T2
COMPLETE as of T2.2, and Phase T3 OPEN with WP-08, WP-09, WP-11, WP-09b, T3.1 and T3.3 done.**
127 files, 10,869 code lines, 16 scenes, 2 areas, 4 items, 1 conversation, 1 schedule, 1 quest of
three steps (one of them a COUNT), 2 mapped areas, 2 path actions, 2 sprite sheet layouts,
3 tagged surfaces.
Boots headless with **0 warnings, 0 errors**.

**Works, and verified by running it:** logging with rotation · signal registry (`events.gd`) ·
input actions · settings · save/load with atomic writes and versioning · plot flags · area
director with a re-entrancy guard and threaded loading · world clock · weather state · audio
buses · HD-2D camera rig with tilt-shift DOF · billboarded lit shadow-casting 8-way character ·
camera-relative walk/run/sneak · day/night lighting · screen fade · dev screenshot capture ·
placeholder art generator · line-budget checker · a headless test suite (1,468 assertions) that
builds its own content and passes with the demo deleted, and that FAILS on a case which crashes,
returns early, asserts nothing, or is not listed in the runner ·
an engine/demo boundary gate that derives the demo ids and fails on any of them in src/ ·
**CI that runs six of the seven rungs on every push, PR and manual dispatch**, in two jobs (full
checkout and a stripped template), on a downloaded engine whose SHA512 and build string are both
verified — proved red on a broken assertion and green again ·
interaction sensor with ranking and Tab-cycling · Interactable contract · localized prompt and
toasts · readable signs · levers · gates gated by flag or by a carried key · per-object
persistence (ADR-0005) · typed item definitions found by directory scan (ADR-0006), and since T3.1 **ONE scan behind all
five catalogues** — `ContentScan.into()` fills each registry's own TYPED dictionary, so the five
façades keep their own content root, cache and accessor and nothing anywhere is a cast · an
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
twenty-six seconds, and a layered ambience bed on procedurally generated noise ·
**an exported build that finds its content**: a committed Windows preset, and a boot-time readout
of every catalogue's count and resolved paths that WARNS on an empty one in an export ·
**an art CONTRACT rather than art**: a `SpriteSheetLayout` resource carrying facings, frames,
cell size and animation blocks, with the direction sectors DERIVED from the facing count, so a
sheet with a different cell and frame count was swapped in with no code change at all · a project
`Theme` at `assets/theme/ui_theme.tres` wired as `gui/theme/custom`, holding every font size,
colour and inset the UI draws with, so one edit to that one file restyled the menu, the inventory
screen and the HUD at once. Both demonstrated by windowed captures that were LOOKED AT ·
**documentation a consumer can actually start from**: `AUTHORING.md`, `ART_CONTRACT.md`,
`TESTING.md` and an extension surface, routed to from `CLAUDE.md` and this file, and proved by
authoring a new area, NPC and conversation from them alone — plus a gate that fails on a
documented path or worked-example field the engine no longer has ·
**quests as authored data**: `Quest` / `QuestStep` .tres found by the fourth directory-scan
registry, every step naming a FLAG CONDITION rather than a callback, a `QuestTracker` that derives
progress from `Flags` and latches only the two things that cannot be derived, and a journal screen
on `J` — the placeholder quest is started by the keeper's conversation, advanced by the courtyard
lever and completed by the dais trigger volume, and **none of those three files was touched**.
Two windowed captures LOOKED AT, and the `J` key proved by a temporary probe that was removed ·
**equipment as a FLAG rather than a store**: `Equipment` is a component beside `Inventory` that owns
no dictionary — a slot is `equip/<wearer>/<item id>`, so it is already saved, already announced on
`flag_changed`, and a `Gate`, a `QuestStep`, a `DialogueChoice` and a `ClimbPoint` gate on what is
in hand **with no code and no new field in any of them**; the demo's equip-gated arch works with
`Gate` untouched. Enter on a satchel row holds or stows, proved by a temporary probe that was
removed. Three windowed captures LOOKED AT and READ · **a WORLD MAP whose discovery is a flag**: `AreaDef` .tres per area in `data/areas/`, found by the
fifth directory-scan registry, carrying the map position, the arrival spawn and
`known_from_start`; `WorldMap` under `GameRoot` turns `area_entered` into the flag `map/<area id>`
and emits the same `area_change_requested` an `AreaDoor` emits, so `Director` still owns every
transition; `MapScreen` on `M` draws one dot per def at its authored NORMALISED position in three
states, and names no area anywhere. Discovery needs no save section, no migration and no code in
anything that reveals a place — `--flag=map/<id>:true` is the second capture and a conversation
effect writes the identical key. Three windowed captures LOOKED AT and READ ·
**a refusal can carry an AUTHORED line**:
`Gate.locked_key` and `PathAction.refusal_key` had both been declared, validated by `check_content`
and read by nothing, and the player got a generic message about a different door ·
**an ATTRIBUTE with exactly one consumer, and GROUND you can hear**: `attr/<who>/<name>` is the
FIFTH namespace over `Flags` — an integer number of steps clamped to ±4, with no resource, no
registry and no save section — and `PlayerController.current_speed()` scales every gait by `pace`,
measured windowed at 2.861 m against 4.687 m over the same 60 frames. The attribute's NAME is a
const on its consumer, so an attribute nobody reads has nowhere to be written down.
`metadata/surface` tags an area's geometry and is INHERITED from the nearest tagged ancestor, so
the courtyard tags `Terrain` once and overrides two floors; a `Footsteps` component probes down,
steps every 1.7 m and GENERATES the sound from the surface's name, so `sand` is audible the day a
game writes it and no table of surface names ever exists under `src/`. Three surfaces reported
correctly in a windowed run, one of them inherited, and the sound following each ·
**"BRING ME THREE PETALS", AND THE QUEST SYSTEM STILL DOES NOT KNOW WHAT AN INVENTORY IS**:
`Inventory` publishes each count as `bag/<carrier_id>/<item id>` — the SIXTH namespace over `Flags`
and the first whose value is a number — so a step is `AT_LEAST 3` on that key, `QuestStep` gained
no field and `QuestTracker` gained no knowledge, and the dependency points DOWN from `gameplay` to
`core` rather than up from `systems` to `gameplay`. The mirror is declared DERIVED, so it is
readable and announced but never saved and no save version moved. A step reopens when a count falls
and a completed quest does not — WP-08's asymmetry, tested at last against something that really
decrements. The journal draws `— Gather three rose petals.   2 / 3` and still reads no flag. Two
windowed captures LOOKED AT and READ, differing by exactly one petal.

**Not built:** hard-coded-string audit · item instances (durability) ·
footstep PARTICLES, and a second attribute with a consumer — naming one is free, reading one is a
line of engine code ·
an equipment SCREEN, a character sheet, and no attribute gates an interaction ·
item tooltips, sorting and drag-and-drop · fog of war, map zoom and pan, map art, travel costs and
objective markers on the map — `quest_advanced` has an emitter, so markers are a listener and one
more marker state · **a quest step that TAKES the items it counted** — a step can REQUIRE N of an
item id since T3.3, and WP-08's layer refusal is unchanged: a completed quest emits
`quest_completed` and stops, so handing anything over is a listener's job · a DEPARTURE-side travel
point, which is a game policy rather than a mechanism · branch protection, so CI reports but nothing stops a
red branch merging · no CI export rung (a GPU-less runner has no platform template) · export
presets for platforms other than Windows · a release-build content readout, since the debug gate
means a release export prints nothing · a counted step whose CARRIER is validated by a gate — the
item id is checked, the carrier is an `@export` in a scene `check_content` does not open. The theme does not yet set the
`Button` styleboxes, so a light palette leaves every menu row drawing Godot's default dark
panel — the seam is right and in the same file, simply unpopulated. Third package to leave
them, each time for a stated reason.
Five of T2.1's nine roadmap items are also left: shared materials, the environment post-stack as
`@export`s, per-area camera exports, the texture import defaults and the Git LFS lines.

## Known defects

**Fixed 2026-08-27 in WP-09, and both had been wrong for packages while every rung stayed green:**

1. **`Gate.locked_key` and `PathAction.refusal_key` were DECLARED, VALIDATED AND READ BY NOTHING.**
   Since WP-01 and WP-07 respectively. Authored content set them, `check_content` required a CSV
   row for them, and `interact_prompt.gd` computed `refusal.<reason>` from the enum and never asked
   the object — so every gate in the game told the player "It will not budge. Something holds it
   shut." whatever its author had written, and `PathAction.refusal_key`'s own comment claimed it was
   "shown for the LOW_STANDING refusal". This is gotcha 2's shape in its most invisible form: a
   message that is merely WRONG looks exactly like a message that is right, so eight rungs, both CI
   jobs and 1,149 assertions were green over it. Found by looking for where an equip-gated gate
   would say "you need a light". `interaction_refused` now carries a `message_key`, and the
   authored line is photographed in WP-09's second capture.
2. **The satchel screen redrew only on `inventory_changed`.** So equipping from anywhere other than
   a row press left a held item drawn as merely carried — the first WP-09 capture photographed
   exactly that while the log said `player equipped`. Found by a capture, not by a gate; the screen
   was still right about the bag, so nothing could fail. See gotcha 34.

**Also fixed 2026-08-27 in WP-09, and it is gotcha 32 for the third time:** `--open-inventory` did
not wait for the area, so with `--new-game` it drew over the title screen and the arriving
transition unwound it. Third staging flag to need that wait after `--open-menu` and `--flag`, and
`dev_stage.gd` now says any flag that puts something on screen needs it.


**Fixed 2026-08-26 in T2.0, and it was invisible until an export existed:**

1. **A missing `[editable]` marker silently dropped every instance override in an exported build.**
   `courtyard.tscn` set `object_id`, `label_key` and `conversation_id` on two nodes INSIDE its
   instanced `npc.tscn` with no `[editable path="Actors/Keeper"]`. From source the text loader
   applies them; an export converts `.tscn` to binary `.scn` and the conversion DROPS overrides on
   a non-editable instance. So the shipped keeper had no identity, no prompt, no conversation and
   never ran its schedule — while every ladder rung, both CI jobs and 930 assertions stayed green.
   This project hand-authors its `.tscn` files, so the marker the editor would have written is
   exactly what a hand-authored scene forgets. Now a `tools/check_content.gd` gate, proved red on
   the real bug. See gotcha 27.

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
- **ONE content scan, five typed façades — and the base is on the RESOURCE, not the registry.**
  `ContentScan.into()` is the only scan-and-validate in the project; `ContentEntry` is the base
  every catalogued `.tres` extends. Each registry keeps its own `content_dir`, its own typed
  cache and its own typed accessor, because a base-class `static var` is ONE storage shared by
  every subclass (gotcha 37) and because an untyped accessor is against non-negotiable #2.
  Settled by T3.1 after WP-08 and WP-11 costed it twice. Do not re-argue it, and do not "finish
  the job" by moving `has()`/`count()`/`rescan()` onto a base — those name their own type.
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
- **`export_filter="all_resources"` IS PART OF THE ENGINE CONTRACT, NOT A PREFERENCE.** The three
  registries find content by directory scan, so those resources are nobody's dependency and only
  that setting ships them — measured both ways in T2.0, and asserted by `tests/unit/export_test.gd`
  so a consuming game that narrows it fails rung 4 instead of shipping empty catalogues.
- **THE EXPORT IS VERIFIED BY A DEBUG BUILD, AND THE READOUT NEVER REACHES A PLAYER.**
  `CatalogueReport` reports every catalogue's count and RESOLVED PATHS at boot, behind
  `OS.is_debug_build()`. The paths and not only the counts, because a partial ship is worse than an
  empty one: three of four items is a plausible number. It ASKS the same registries the game asks —
  a reporter that did its own scan would be reporting on itself.
- **AN EXPORT PROOF CANNOT BE AN ASSERTION, and the suite says so out loud.** A test running under
  `res://` cannot test a build it is not running in, so `export_test.gd` asserts
  `is_exported() == false` rather than leaving the blindness implied. The proof is a RUN of the
  exported executable with both sides' numbers quoted in `DEVLOG.md`. There is deliberately no CI
  export rung: a GPU-less runner has no platform template, the same honesty T1.4 applied to the
  windowed capture.
- **A FACING IS NOT A COLUMN, and the sector width lives in exactly one place.** `GameEnums.Facing`
  has eight values because eight is how many directions the GAME reasons about; `layout.facings` is
  how many the ART distinguishes. The two are quantised SEPARATELY from the same angle — the enum
  from `GameEnums.Facing.size()`, the column from `SpriteSheetLayout.column_for_angle()` — because
  the obvious alternative, mapping the enum down with `int(facing) * facings / 8`, puts the number 8
  back in the code in a second place, which is the exact bug T2.1 existed to remove. When
  `facings == 8` they agree by construction, so the existing sheet did not move.
- **NO SHEET DIMENSION LIVES IN CODE.** `SpriteSheetLayout` is the art CONTRACT: facings, frames,
  animation blocks, cell size and the idle/walk row offsets. `CharacterVisual` reads all of it and
  holds none of it, and `tests/unit/art_contract_test.gd` FAILS if `character_visual.gd` regains a
  `TAU / 8` or a `FACING_COUNT`. The cell size is DECLARED and validated against the texture rather
  than divided out of it, so a sheet of the wrong size is a named problem instead of every
  character in the game silently misplaced.
- **AN UNWIRED `layout` IS LEGAL AND LOUD.** `CharacterVisual` falls back to 8x4/32x48 and WARNS,
  naming the node. Gotcha 2's whole lesson is that a silent default looks exactly like success, so
  the fallback exists to keep a node recognisable while the log says it is unwired — it is not a
  fallback anything should rely on.
- **THE UI LOOK IS ONE FILE, AND THE PALETTE IS NOT COPIED INTO THE VARIATIONS.**
  `assets/theme/ui_theme.tres`, wired as `gui/theme/custom` so it reaches the HUD too — which is
  drawn UNDER `UiRoot` and would have been missed by handing the theme to the stack. Type variations
  carry ONLY `font_size`, the one thing that genuinely differs by role; the four colours and six
  insets live once each in `UiPalette` and `UiMetrics` and the screens read them by name. A `Theme`
  resource has no variables, so a colour repeated into nine variations would be nine places to
  change and "one Theme edit restyles every screen" would simply be false. A test case fails if any
  of the five styled files writes a `Color(` or an `add_theme_font_size_override` down again.
- **A DOCUMENT IS TASK-FIRST OR IT IS A FILE HEADER.** The headers in this project are good and
  are found only by already knowing which file to open. `AUTHORING.md` therefore starts from
  "I want to add an area", not from `AreaRoot`, and the four consumer documents are routed to from
  both `CLAUDE.md`'s table and `CONTEXT.md` — a document nobody is routed to is a document nobody
  reads. The extension surface went into `ARCHITECTURE.md` rather than `AUTHORING.md` because
  `AUTHORING.md` opens with "you never edit `src/`" and a section on subclassing underneath that
  would contradict it.
- **A DOCUMENTATION CRITERION IS PERFORMED, NEVER ASSERTED.** T2.2's exit criterion was closed by
  authoring a real area, NPC and conversation from the documents alone and running them; the
  deliverable of that exercise is the list of six things the documents got wrong. A walkthrough
  that works first time means the author was still reading from memory.
- **THE DOCS ARE GATED FOR EXISTENCE, NOT FOR TRUTH.** `tests/unit/docs_test.gd` asserts that every
  `res://` path the documents name resolves and that every property in a worked `.tres` example
  exists on the class that block declares. It cannot check that a documented *sentence* is true —
  only a walkthrough does that. `DEVLOG.md` is exempt from the path scan, because a history
  necessarily names files it correctly removed.
- **A QUEST STEP NAMES A FLAG CONDITION, NEVER A CALLBACK.** The same closed set of six comparisons
  `GameEnums.FlagTest` gives a dialogue condition, evaluated by the same `FlagQuery.passes` both
  call. That is what makes a quest authored data (adding the fiftieth touches no code, ADR-0006's
  test) and it is what lets the rest of the game feed a quest without knowing quests exist — the
  placeholder quest is started by a conversation effect, advanced by the courtyard lever and
  completed by the dais trigger volume, and none of those three files was touched. The cost is
  stated rather than hidden: **a step cannot read an item count**, because `Inventory` keeps counts
  and not flags, so "bring me three petals" is not authorable and the seam is a `Pickup` that writes
  a flag.
- **QUEST PROGRESS IS DERIVED; EXACTLY TWO THINGS ARE LATCHED.** `flags.gd` says derive what can be
  derived, and the current objective is the first step whose test fails, asked live on every flag
  change. Two things cannot be derived: that a quest STARTED (clearing its start flag must not
  un-give a quest carried for three hours) and that it COMPLETED (a step testing `AT_LEAST 3` on a
  counter must not reopen when something decrements it). Those two are the whole save section, held
  as **two lists of quest ids** — never an enum ordinal. An ACTIVE quest's objective is deliberately
  NOT latched, so clearing the flag behind objective two brings objective two back; a per-step latch
  would double the saved state to remove a behaviour nobody has asked for. Both halves are asserted,
  because a latch nothing tests is indistinguishable from a cache.
- **A COMPLETED QUEST GRANTS NOTHING.** It emits `Events.quest_completed` and stops. A `reward_item`
  field would put `Inventory` and a player — both `gameplay` — inside a `systems` tracker, and
  `src/` points downward only. Anything that wants to hand over an item listens; anything that wants
  to gate a conversation tests the flag the last step tested, with no code at all. Same reasoning
  that keeps `Weather` from drawing rain.
- **THE FLAG-TEST TABLE LIVES IN EXACTLY ONE FILE**, `src/core/state/flag_query.gd`, extracted from
  `DialogueRunner` when a quest step began asking the identical question. Two copies of a rule
  eventually disagree, and the disagreement would surface as a quest that will not complete for a
  flag a conversation is perfectly happy with. A test fails if the table grows back in either file —
  the gate `art_contract_test.gd` established for sheet dimensions. Only the READ half is shared:
  `FlagWrite` still has one caller, and a shared file serving one consumer is not a seam.
- **THE FOURTH REGISTRY WAS RECONSIDERED AND THE COPY WAS KEPT.** `schedule_db.gd` said "three is a
  pattern, four is a problem — if a fourth registry appears, that is the moment to reconsider."
  Reconsidered in WP-08; GDScript has no generics, so a shared base could only cache `Resource` and
  hand it back untyped, making all four accessors a cast at the call site — and static typing is
  non-negotiable #2, not a preference. What is genuinely shared already is: `QuestDb` calls
  `ItemDb.resource_paths()` rather than copying the `.remap` handling. The refactor that pays is a
  base plus a thin typed façade each, and it is **T3.1 on the board** rather than a shrug.
- **A CONTENT CHECK PRINTS WHAT IT CANNOT VALIDATE.** `check_content` prints every flag a quest and
  its steps name and validates none of them. A flag can be written from a scene, a conversation, a
  path action or another quest, and the writer that matters most is a runtime one —
  `PersistentState` builds `obj/<area>/<object>/<field>` at load — so a checker that failed on any
  flag with no findable writer would be wrong most times it fired. A partial check that looks
  complete is the failure mode this project exists to prevent, so the flags go in the build log
  where a reviewer reads them.
- **EQUIPMENT IS A FLAG, NOT A STORE.** `Equipment` is a component beside `Inventory` — same
  `of(who)` reasoning, so an NPC or a stash can have one — and it owns NO DICTIONARY. A slot is
  `equip/<wearer_id>/<item id>` in `Flags`, which is `PersistentState`'s `obj/<area>/<object>/<field>`
  and `Standing`'s `standing/<who>` applied a third time. Three things fall out and together they
  are the whole argument against a `Dictionary[EquipSlot, StringName]` plus a save section: it is
  already saved (no register, no version, no migration, and a new game clears it because
  `start_new_game()` clears flags); a `Gate`, a `QuestStep`, a `DialogueChoice` and a `ClimbPoint`
  gate on it **with no code and no new field**, which is WP-08's seam used by a second system; and
  `flag_changed` already announces it. The cost is stated: the key contains an item id, so renaming
  an item's `.tres` brings it back stowed.
- **THE ITEM STAYS IN THE BAG WHILE IT IS HELD.** Moving it out would make equipment a second place
  items live — `Inventory.count_of()` would begin lying and `Gate.requires_item` would refuse a key
  that is in the player's hand. So equipping is purely a flag, and the price is that losing the item
  has to stow it: `Equipment._revalidate`, on `inventory_changed` rather than on `item_lost`, because
  that is the one signal every path emits including a restored save. It is the invariant the suite
  fails first when broken.
- **ONE ITEM PER SLOT, AND THE NEWCOMER WINS.** Holding a second LIGHT stows the first rather than
  being refused, because a refusal would make swapping a lantern a two-step chore the player cannot
  see a reason for. `can_equip()` is the seam a strength rule or a two-handed rule goes into, the
  analogue of `Inventory.can_accept()`.
- **`EquipSlot` HAS NO WEAPON AND NO ARMOUR VALUE**, the same absence `ItemCategory` has, and for
  the same retraction. A slot answers "what does holding this let you do", never "how hard do you
  hit". It is append-only, because an `ItemDefinition` stores it as an ordinal.
- **A REFUSAL MAY CARRY AN AUTHORED LINE, and a reason is a CATEGORY rather than a sentence.**
  `interaction_refused` carries a `message_key` beside `args` — travelling on the signal rather than
  asked of the target, exactly as `args` does — and `Interactable.refusal_key(who, reason)` is the
  override, with "" meaning "compute `refusal.<reason>` from the enum". The alternative was a new
  `RefusalReason` per authored line, which is a category per sentence and the growth the closed sets
  exist to prevent. `Gate.locked_key` and `PathAction.refusal_key` had been declared, validated by
  `check_content` and read by NOTHING since WP-01 and WP-07 — see the defects section.
- **A UI REDRAWS ON THE WORLD'S SIGNAL, NEVER ONLY ON ITS OWN INPUT.** `InventoryScreen` refreshed
  on `inventory_changed` alone, so a row press redrew and an equip from anywhere else did not — and
  the first WP-09 capture photographed a held lantern drawn as merely carried. A press is never the
  only writer: staging equips from the command line, and `_revalidate` stows on its own. That is
  why `equipment_changed` exists at all, and it is a general rule rather than one screen's bug.
- **DISCOVERY IS A FLAG, AND THE NAMESPACE CONVENTION IS NOW A PATTERN.** `map/<area id>` in
  `Flags`, with no store, no save section, no migration and no register — the FOURTH use of
  namespace-over-`Flags` after `PersistentState`'s `obj/<area>/<object>/<field>`, `Standing`'s
  `standing/<who>` and `Equipment`'s `equip/<wearer>/<item>`. Three independent systems on one
  convention is evidence it generalises rather than a coincidence, and the next thing that needs
  saved per-thing state should reach for it before reaching for a save section. Two things fall
  out and they are the whole design: anything that writes the key reveals a place (a
  `DialogueChoice` effect, a `TriggerVolume`, a `Lever`, a quest consequence — none of which was
  touched), and a `Gate` with `requires_flag = &"map/<id>"` is a road that opens once you know
  where it goes. The cost is stated: renaming an area's folder makes an old save forget it was
  found, the same price `Equipment` pays for an item id.
- **A MAP DOT'S POSITION IS AUTHORED DATA, IN NORMALISED 0..1 SPACE.** `AreaDef.map_position`, and
  `MapScreen` has never heard of any area. A map that knew where the courtyard goes would be
  engine code naming demo content, which `check_boundary` fails the build over — proved by
  planting it. Normalised rather than pixels so one authored number is right at every window size
  and every UI scale.
- **AN AREA ID HAS NO REGISTRY PREFIX**, unlike `item/` and `quest/`. Those prefixes make a save
  file self-describing about a thing that lives only in a save file; an area id is already a
  public identifier, because it is a folder name. `data/areas/orchard.tres` declares
  `id = &"orchard"`, which is what `Director` travels to, so there is no translation table
  between `AreaDb` and `Director` — and a translation table is a second place the truth lives.
- **FAST TRAVEL ASKS; IT DOES NOT TRAVEL.** `WorldMap.travel_to` emits
  `Events.area_change_requested` and stops, exactly as `AreaDoor` does. Four refusals, each
  logged: not on the map, not found, already there, already moving. Nothing but `Director` calls
  `change_area()`, which is what keeps two things firing at once from leaving two areas in the
  tree — and a fast-travel path that ran its own transition would have been the second one.
- **AN AREA WITH NO `AreaDef` IS NOT AN ERROR**, it is a cupboard a game chose not to draw. It is
  said at INFO level once per arrival rather than warned, because the boot rung counts warnings
  and a template with no map at all is a legal state — but it is said, because "the .tres is
  authored and the dot never appeared" must not be silent. Same shape as an empty content root.
- **STAGING THAT PUTS SOMETHING ON SCREEN WAITS FOR THE WORLD TO STAY STILL, NOT MERELY TO ARRIVE.**
  `dev_stage._settle_stable(20)` demands twenty CONSECUTIVE settled frames and resets on any
  transition, which is gotcha 21's persistence shape applied to staging. `--goto` and
  `--open-menu` both leave `_wait_for_area` on the same frame, so a fixed extra delay only moves
  the race; a counter that a starting transition resets cannot be satisfied early.
- **AN ATTRIBUTE'S NAME LIVES ON ITS CONSUMER, NEVER ON THE CONTAINER.** `attr/<who>/<name>` is the
  fifth namespace over `Flags`, and `Attributes` has NO registry, no `AttributeDef` and no enum of
  names — any StringName is an attribute the moment something writes it, which is ADR-0006's
  no-code-per-thing test met without a sixth directory scan. What stops that becoming the failure
  this project keeps catching is a rule about where a name is written down:
  `PlayerController.PACE` sits beside the line that reads it, so **an attribute nobody reads has
  nowhere to be declared** and `attributes.gd` cannot grow a table of good intentions. The cost is
  stated: naming an attribute is free, READING one is always a line of engine code, and
  `AUTHORING.md` says so to an author's face. The value is a STEP, not the number, because a flag
  holding `4.7` would be a walk speed authored into a save file and the tuned `walk_speed` would
  stop being the truth.
- **A SURFACE IS METADATA ON GEOMETRY, INHERITED FROM THE NEAREST TAGGED ANCESTOR.**
  `metadata/surface` on a body or anything above it. A component would be a node per floor tile; a
  group would share one flat namespace with `navmesh_source`, where a typo becomes a second surface
  silently; an ENUM would be a list of surface names in `src/`, which `check_boundary` fails the
  build over. Inheritance is what makes it cheap to author, and the demo's third surface comes from
  it. A step's timbre is DERIVED from the name for the same boundary reason a table is refused: a
  game that authors `sand` hears it without editing `src/`.
- **A FOOTSTEP IS THE ONE CLAIM THE LADDER CANNOT SEE AT ALL, AND THE FILE IS SPLIT ALONG THAT
  LINE.** Not visual, so no capture reads it; not synchronous, so no assertion reaches it; and
  headless the audio driver is `Dummy`, where every `play()` leaks (gotcha 20). So the pure parts
  — the stride accumulator, the surface query and the two timbre functions — are asserted, and the
  raycast, the frame loop and the `play()` are a windowed run with the log quoted. The same split
  `SurfaceWetness` made for drying, and it is said out loud rather than implied.
- **AN ITEM COUNT IS A FLAG THAT IS PUBLISHED DOWNWARD, NOT A BAG THAT IS READ UPWARD.**
  `bag/<carrier_id>/<item id>` in `Flags`, written only by `Inventory._publish`, and it is the
  general answer whenever a lower layer holds something an upper one must observe. `QuestTracker`
  is `systems` and `Inventory` is `gameplay`, so a tracker reading a bag points the wrong way —
  the same violation WP-08 refused over `reward_item`. Publishing inverts it, and the capability is
  identical: `QuestStep` gained NO field, `QuestTracker` gained no knowledge, and `item_count_test`
  FAILS if either file's code names `Inventory`, `ItemDb` or `BagKeys` — nothing else in the suite
  could, because the behaviour would be identical with the layer rule gone. Settled by T3.3 from
  the FIRST of WP-09's two costed designs. Do not "simplify" it by handing the tracker a bag.
- **A DERIVED FLAG IS READABLE, ANNOUNCED, AND NOT SAVED.** `Flags.declare_derived(prefix)`, and
  `_collect_save` skips those keys. That is what makes the count projection legal rather than a
  second copy of the truth: `flags.gd`'s own header forbids storing anything recomputable, and a
  count mirrored from the bag is recomputable by definition. The consequence is a duty rather than
  a freedom — the PUBLISHER must republish whenever the store is wiped under it, which is why
  `Inventory` subscribes to `game_started` (clear) and `game_loaded` (republish, after every
  section, so the answer cannot depend on save-participant order). Anything else that wants to be
  readable-but-derived pays the same price and should say so in its header.
- **A COUNTED CONDITION IS `AT_LEAST` OR `EQUALS`, AND `AT_MOST` DRAWS NO TALLY.** `AT_MOST` is a
  ceiling, so "2 / 3" under *keep it below three* tells the player to gather more of the one thing
  they must not; a `condition_value` of 0 is not a count either, because `AT_LEAST 0` passes with an
  empty bag. `FlagQuery.progress()` answers `(have, need)` with `need == 0` meaning "not a count",
  and `check_content` fails the build on both mistakes rather than letting a journal draw `0 / 0`.
- **THE BAG KEY SHAPE LIVES IN `src/core/state/bag_keys.gd`, AND NOT ON `Inventory`.** Three places
  need it and none may rebuild it: the bag WRITES it, `check_content` PARSES it to validate the item
  id, and the suite asserts on it. The reason it cannot sit beside `Equipment.PREFIX` is a compile
  error, not taste — `check_content` runs under `--script`, where autoload identifiers do not
  resolve, so naming `Inventory.PREFIX` would not compile. Keep that file free of autoloads.
- **ONE FLAG NAMESPACE IS VALIDATED BY `check_content`; THE REST ARE STILL ONLY PRINTED.** WP-08's
  rule stands — a flag can be written from anywhere, so failing on one with no findable writer would
  be wrong most times it fired. `bag/<carrier>/<item id>` is the exception because it has exactly
  ONE writer and half the key is an item id the tool can look up. The CARRIER is deliberately not
  validated: it is an `@export` in a scene the tool does not open, and a game may put a bag on an
  NPC or a stash.
- **A NEW GAME IS A NEW BAG.** `Director.start_new_game()` clears the flags; `Inventory` now clears
  its counts on `game_started` for the same reason. It did not before T3.3, so the previous run's
  items carried into a fresh game — unreachable in practice and invisible to every gate, and found
  only because the count projection cannot tolerate the two disagreeing.
- Six ADRs in `docs/decisions/` cover the layered `src/`, warnings-as-errors, the input map,
  and save-via-callables.

## Verify before claiming anything is done

Since T1.4 these run in CI too — `.github/workflows/ladder.yml`, on every push, pull request and
manual `gh workflow run ladder.yml --ref <branch>`. CI is not a substitute for running them: the
windowed capture is the one rung a GPU-less runner cannot do, and push events on this repo have
lagged by as much as 25 minutes.

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --check-only --script <file>   # type gate
"$G" --headless --import                       # scenes and resources
"$G" --headless --quit-after 120               # must end "0 warnings, 0 errors"
"$G" --headless res://tests/test_runner.tscn --quit-after 400   # 1,468 assertions, exit 1 on fail
"$G" --headless --script tools/check_budgets.gd            # must exit 0
"$G" --headless --script tools/check_content.gd            # must exit 0
"$G" --headless --script tools/check_boundary.gd           # must exit 0 — src/ and tests/ name no demo content
"$G" --resolution 960x540 --quit-after 90 -- --new-game --shot=<path> --shot-frame=70 --time=18:40 --freeze-time
```

## Thirty-eight gotchas that each cost an hour

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


25. **GITHUB RUNS EVERY `run:` BLOCK AS `bash -e {0}`, so `set -uo pipefail` inside a step does
    NOT turn errexit off.** T1.4's first red run reported nothing but `Process completed with exit
    code 1`: the step died on the failing `godot` line, before the line that prints WHICH
    assertion failed. The uploaded artefact had the answer and the step did not, which is a gate
    that fails without saying why — half a gate. Any rung that must outlive its own command's
    failure captures the status with `|| status=$?`, which is exempt from errexit, and judges it
    afterwards. Related, and it wasted an hour on its own: **verifying a shell fragment
    interactively with `( ... )` inside an `&&` chain also silently disables `set -e`** — the same
    fragment reported exit 0 on a deliberately failing suite inline and exit 1 as a script file.
    Test a workflow fragment as a FILE, never inline.

26. **`gh`'s run listing lags, and believing it produces a confident wrong diagnosis.**
    `actions/runs` reported `total_count: 0` for four minutes after a push whose run had already
    been created AND completed. On that evidence CI looked disabled, which cost a needless
    visibility change to rule out a private-repo minutes limit — the runs that had already passed
    were pushed while the repo was private. Push-event delivery on this repo ran up to **25
    minutes** behind at times. Check `run_started_at` against the push time before concluding
    anything is broken, and prefer `gh workflow run` for a prompt answer: `workflow_dispatch` is a
    trigger on the ladder precisely because a gate with one way in has a single point of failure.
    A manual run gets its own `concurrency` group keyed on its run id, because a dispatch was
    once cancelled by the very push it was verifying and a cancelled run reports neither pass nor
    fail.

27. **AN EXPORT DROPS AN INSTANCE OVERRIDE THAT HAS NO `[editable]` MARKER, and running from
    source cannot see it.** A hand-authored `.tscn` that sets a property on a node INSIDE an
    instanced scene needs `[editable path="<the instance>"]` at the foot of the file. Without it
    the text loader applies the override happily; the exporter converts `.tscn` to binary `.scn`
    and the conversion silently discards it, so the prefab reverts to its defaults in the shipped
    build ONLY. The demo's NPC lost its `object_id`, its prompt and its conversation exactly this
    way, and every rung, both CI jobs and 930 assertions were green throughout. Stale `index=`
    values look like the culprit and are not — correcting them changed nothing.
    `tools/check_content.gd` gates it now. Related, from the same package:
    **`export_filter="all_resources"` is the only setting that ships directory-scanned content**
    (`"scenes"` ships zero of it), **`include_filter="*.tres"` is the plausible wrong fix** because
    the include filter is for NON-resource files, and **a debug export is required to verify
    content at all**, because the readout is behind `OS.is_debug_build()`. An export template must
    be installed first, and it comes only in a 1.28 GB `.tpz`.


28. **A SPRITE DRAWN FROM THE WRONG CELL STILL LOOKS LIKE A CHARACTER.** This is gotcha 2 in its
    sharpest form: a day/night system that lights nothing is at least obviously wrong on screen,
    but a person drawn from the wrong row is still a person — upright, lit, facing *some*
    direction — so a capture of it cannot be JUDGED, it has to be READ. T2.1's second placeholder
    sheet therefore labels every cell: `column + 1` bright pips down the left edge, `frame + 1`
    along the foot, and a different body tint per animation block. That is what turned
    `frame=19/24` from a number to be taken on trust into a checkable prediction — four left pips,
    two foot pips, orange body, `(1*3 + 1) * 4 + 3 = 19`. Any future visual seam whose failure mode
    is "plausible but wrong" needs the same treatment; a screenshot of something that merely looks
    fine is not evidence.

29. **A `Theme` HAS NO VARIABLES, so a colour put in a type variation is a colour duplicated.**
    Godot's `Theme` stores each item per type, and there is no reference between them — so the
    natural-looking design, where `TitleText` carries both its `font_size` and its `font_color`,
    means the accent colour is written into as many variations as use it and "one Theme edit
    restyles every screen" is false the moment there are two. The split T2.1 settled on: variations
    carry ONLY sizes, and the colours and insets live once each under `UiPalette` / `UiMetrics`
    which the screens read by name. Related, and it is what makes this work at all: the project
    theme set as `gui/theme/custom` resolves from ANY Control in the tree, so a screen never has to
    be handed it — but a theme item that exists in the file and does not resolve from a node is not
    wired, which is the same failure shape as an unwired `@export`, and it is worth one assertion.

30. **`[importer_defaults]` IS UNDOCUMENTED AND ABSENT FROM `--doctool`.** Godot's per-importer
    project defaults are an editor-managed `project.godot` section with no `ProjectSettings` entry,
    so the rule this project runs on — check every name against the API dump before using it —
    cannot be satisfied for it, and hand-authoring an undocumented format is exactly the change
    that looks applied and does nothing. T2.1 stopped rather than guess. One latent hazard for
    whoever picks it up: every committed `.import` carries `detect_3d/compress_to=1`, and these
    sheets ARE used in 3D via `Sprite3D`, so a re-import can switch them to VRAM compression and
    put block artefacts through pixel art.

31. **NO ORDINARY RUN EVER ENTERS AN AREA, so most of the ladder is blind to area content.**
    `--headless --quit-after 120` boots to the MAIN MENU and reports `0 warnings, 0 errors`
    without loading anything — it cannot see a wrong `area_id`, an empty navmesh bake, an NPC with
    no schedule or an unlit interior. Neither can a bare `--shot`: the PNG is the title screen,
    which is what the first capture in T2.2 turned out to be. **`--new-game` is what starts a
    game**, `--goto=<area>` travels to a different one, and the area load is threaded so the
    shutter needs `--shot-frame=70` with `--quit-after 90` rather than the old bare 55. This is
    gotcha 22's family, one level up: not a rung that cannot see an error, but a rung reporting
    clean about work it never did. Related and cheap to trip over: `--stand-by=` takes a NODE
    NAME, not an `object_id`, and a propless new area at 18:40 renders near-black, which looks
    exactly like a lighting bug — capture a new area at midday first.

32. **STAGING THAT RUNS BEFORE `--new-game` HAS ITS STATE THROWN AWAY.** `--new-game` CLEARS EVERY
    FLAG, so `--flag=met/x:true` applied during argument parsing is gone by the time the area
    lands — and the run still reports `0 warnings, 0 errors`, because nothing failed. The first
    WP-08 capture was a journal with no quest in it for exactly that reason, and the only trace is
    the ORDER of the log lines: `--flag` before `Quest tracker ready`, and no `started` line after
    it. `--flag` now waits for the area the way `--open-menu` already did. This is gotcha 31 one
    step further in: not a rung blind to an error, and not a rung reporting clean about work it
    never did, but staging that ran before the thing it was staging for. Any future `--` flag that
    poses state a new game resets needs the same wait, and `dev_stage.gd`'s header says so.


33. **`Array[StringName].sort()` DOES NOT SORT ALPHABETICALLY.** It orders by the StringName's
    internal handle, so the result is stable within a run and arbitrary between them. It compiles,
    it looks like a sort, and `Equipment.equipped_ids()` returned two ids in the wrong order with a
    single failing assertion as the only trace. `Inventory.ids()` had already hit this and sorts
    through `String` with a `sort_custom`, which is the only reason this cost a minute rather than
    an hour — a comment saying WHY a line is not the obvious one is worth more than the line.
    Anything sorting `StringName`s goes through `String`.

34. **A UI THAT REDRAWS ONLY ON ITS OWN INPUT IS SILENTLY WRONG THE MOMENT SOMETHING ELSE WRITES.**
    `InventoryScreen` refreshed on `inventory_changed`, so pressing a row to equip redrew correctly
    and equipping from anywhere else did not — and the first WP-09 capture came back showing a held
    lantern drawn as merely carried while the log said `player equipped`. Nothing failed, because
    the screen was still right about the bag. A press is never the only writer: staging equips from
    the command line, `_revalidate` stows on its own, and a save restores. Subscribe to the fact,
    not to the gesture. This is gotcha 2's family in the UI layer, and only a capture sees it.

35. **TWO STAGING FLAGS THAT BOTH WAIT FOR "THE AREA" LEAVE THAT WAIT ON THE SAME FRAME, AND
    RACE.** `--goto` and `--open-menu` each begin with `_wait_for_area()`, so they resume
    together: if the menu opened first, the travel `--goto` was about to request unwound it —
    `ScreenKeys` unwinds the stack on every `area_change_requested` — and the capture came back
    showing nothing, with `0 warnings, 0 errors` and every rung green. This is gotcha 32's family
    one step further out: not staging that ran before the thing it staged for, but two pieces of
    staging that were both correct and were ordered by chance. A LONGER FIXED WAIT ONLY MOVES THE
    RACE. The fix is gotcha 21's shape — `dev_stage._settle_stable(20)` requires twenty
    CONSECUTIVE settled frames and resets its count the moment a transition begins, so it cannot
    be satisfied early no matter which flag resumed first. Any future staging flag that puts
    something on screen uses it, and `dev_stage.gd`'s header says so.

36. **`String.hash()` MIXES ITS LOW BITS WEAKLY, so `hash() % N` CLUSTERS SHORT SIMILAR NAMES.**
    Measured: `"grass"` hashes to 260508453 and `"stone"` to 274826446 — wildly different numbers
    whose last three digits are 453 and 446 — and `"wood"` and `"sand"` differ by 159027 in a
    number of 2.09 billion. WP-09b derives a footstep's timbre from the surface's name, so those
    two surfaces produced brightnesses 0.006 apart and **sounded identical**, with every rung
    green, a `playing=true` in the log and an inequality assertion passing. Adding a second derived
    axis did not help — the salted hashes collided the same way. The fix is an avalanche before the
    modulus (one multiply, two shifts), which moves the pair to 796 and 572. Two lessons, and the
    second is the general one: anything deriving a VALUE from a Godot string hash must mix it
    first, and **a regression assertion about a perceptible difference must demand a MARGIN**,
    because mere inequality is exactly what the broken version passed. Gotcha 2 with a speaker on
    it: a step that plays is not a step that follows.


37. **A BASE-CLASS `static var` IS ONE STORAGE SHARED BY EVERY SUBCLASS.** Probed under 4.7.2 with
    two throwaway subclasses bumping a counter declared on their base: `A.shared=3 B.shared=3
    Base.shared=3`. This is the opposite of the per-class statics most languages give you, and it
    is what made the obvious shape of T3.1 — `ItemDb extends ContentDb`, with `_by_id`, `_loaded`
    and `content_dir` on the base — silently catastrophic: five registries would have shared ONE
    cache and ONE content root, so `Fixtures.activate()` would have pointed all five at a single
    folder and four catalogues would have come back empty. Every accessor would still have been
    typed and the class diagram would still have looked right. The shared part of five static
    classes must therefore be a FUNCTION taking the caller's state, never inherited state. Three
    related facts from the same probe, each of which the design depends on: a `class_name` passed
    as a `Script` works with `is_instance_of()`; `Script.get_global_name()` returns the class name;
    and a `Dictionary[StringName, X]` handed to an untyped `Dictionary` parameter keeps its value
    type and is filled BY REFERENCE — which is the whole mechanism keeping every registry accessor
    typed with one shared scan. Related and cheaper to trip over: **`ResourceLoader` caches by
    path**, so re-saving a different resource over a path already loaded in this run hands the next
    scan the FIRST one. A new file name, not a second write.

38. **A MISSPELLED PROPERTY NAME IN A HAND-AUTHORED `.tres` IS SILENTLY DISCARDED.** Measured under
    4.7.2: `conditio_flag = &"bag/player/item/rose_petal"` in a quest step loaded with **no engine
    error, no warning and no `Invalid` line anywhere** — the resource simply came back with that
    field at its default. This project hand-authors every `.tres`, so it is exactly the slip the
    editor would have made impossible, and it is `[editable]`'s family (gotcha 27): a property the
    loader drops looks identical to a property nobody set. The only thing that saw it was
    `problems()` on the resource itself, and only because a non-ALWAYS test with no flag is a
    declared problem — a misspelt `condition_value` would have become 0 in silence, which is why
    T3.3's content gate refuses a count below one. **Every field a `.tres` sets that MATTERS must be
    reachable by `problems()` or by a checker**, or authoring it is a suggestion.

## How work is sliced

**One package, one chat** — see [`docs/WORK_PACKAGES.md`](WORK_PACKAGES.md), which is the
board of every package from here to skeleton-complete — WP-01 to WP-15 plus the T-phases. Each
names the exact files that chat should read, so a session loads a few hundred lines instead of three thousand. The layer rule
(`core -> content -> systems -> gameplay -> ui`, downward only) is what makes that possible: a
package never has to read upward.


**Next package: T3.2 — the five art-contract seams T2.1 left open.** T3.3 has closed, which was the
last row that changed what a consuming game can EXPRESS, so what remains in Phase T3 is one row:

- **T3.2** holds the five T2.1 leftovers — shared materials, the environment post-stack and
  camera framing as `@export`s, the texture import defaults, the Git LFS lines — so they stop
  being mentioned in five places. **Note gotcha 30 before starting it:** `[importer_defaults]` is
  undocumented and absent from `--doctool`, and T2.1 stopped rather than guess at it, so the
  honest outcome for that one seam may be a written-down refusal rather than a change.
  There is also a latent hazard in the same area: every committed `.import` carries
  `detect_3d/compress_to=1`, and these sheets ARE used in 3D, so a re-import can put VRAM
  compression through pixel art.

**objective markers on the map** is now a listener rather than new state — `quest_advanced` has
an emitter and `MapScreen` already redraws on facts.

*(This line names ONE package or one honest choice between a few. Earlier revisions accumulated a
stale line per package and two were left stranded here; if you ever find two, the lower one is
history — delete it.)*

The original WP-08 through WP-15 continue after the T1 and T2 phases, several of them re-framed.

## Plan — where this is going

**Phase 1 is complete and Phase 2 is well under way.** The demo loop works end to end: walk a lit
courtyard through a day/night cycle, be prompted, read a sign, throw a lever, take an item,
empty a chest, be refused by a gate that wants a key, open it once you carry the key, cross a
volume that fires once, rest on a bench and watch the light change, climb a trellis to a terrace
and back down, press I at any point to see what you are carrying in a window that stops the
world — then walk north through a door into a lantern-lit hall that has never heard of the sun,
and come back, and ask the garden-keeper who they are and what lies behind the north gate, in a
box that leaves the world running behind it — and that conversation now hands you an errand, which
the lever you already threw and the dais you already crossed advance, and three rose petals out of
the wicker chest settle — the journal counting them `2 / 3` on the way, readable on `J` at any
point — and pick a lantern up, hold it from the satchel with Enter, and pass under an arch
that turned you away a moment earlier with a line its author wrote — and press `M` to see the two
places you know drawn on one map, the hall a grey `???` until you have walked to it and a gold dot
you can press to travel back to once you have — and every one of those walks now sounds different
depending on whether you are crossing grass, the wooden dais or stone. Every one of those changes
survives a save and a
reload, including from the far side of an area that is no longer loaded. All of it is covered
by 1,468 headless assertions.

**Next, in this order.** The order matters and is not arbitrary:

1. **The rest of the system catalogue**, WP-14 and WP-15 re-framed — see the board. WP-11 closed
   the last row that had no proof at all, and WP-10 is OPTIONAL.
2. **T3.2**, the five art-contract seams T2.1 left open — the last row in Phase T3.
   *(T3.1 is DONE — one scan behind all five catalogues, with every accessor still typed. T3.3 is
   DONE — an item count is a flag published downward, so a step can require N of an item id and
   the quest system still does not know what an inventory is.)*

*(Path actions, NPC schedules, navigation baking, weather visuals, quests, equipment, the world
map, the shared content scan and counted quest steps are all DONE — WP-06, WP-07, WP-08, WP-09, WP-09b, WP-11,
WP-13, T3.1 and T3.3.)*

**Still open, and expensive later:**
- **The export path is PROVEN as of T2.0** — an exported `.exe` reports the same catalogue counts
  and resolved paths the editor does. What remains unproven is a RELEASE export's content, because
  the readout is behind `OS.is_debug_build()`, and every platform other than Windows.
- **No hard-coded-string audit.** Computed keys (`verb.*`, `refusal.*`) are covered by an enum
  loop in the test suite, but literal player-facing text in code is still caught only by review.

## Read next

`CLAUDE.md` (rules, and the doc router table) · `docs/TEMPLATE.md` (why this is not a game) ·
**`docs/AUTHORING.md`** (add an area, an NPC, a conversation, an item, an object, a quest,
equipment, a place on the world map) ·
**`docs/ART_CONTRACT.md`** (what art must satisfy) · **`docs/TESTING.md`** (adding assertions) ·
`docs/ARCHITECTURE.md` (§ The extension surface — what may be subclassed) ·
`docs/NEW_GAME.md` · `docs/SYSTEMS_INVENTORY.md` · `docs/ROADMAP.md` · `docs/DEVLOG.md` ·
`src/core/events/events.gd` (the connection map)
