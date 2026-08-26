# Work Packages

**One package, one chat.** A chat context window is the binding constraint on this project, so
work is sliced into packages that each fit in one. Every package names the exact files to read,
so a new session loads a few hundred lines instead of three thousand.

Read `CLAUDE.md` and `docs/CONTEXT.md` first — always, about a minute — then find your package
below and **read its manifest and nothing else.**

## The rules

**Size.** No package exceeds roughly **8 files or 500 new code lines**. Over that, split it and
add a row. Same reasoning as the file budgets: a package that grows past one chat becomes a
package that gets half-finished.

**Closing a package.** Not done until all of this is true:

1. Ladder green — `--import` with **zero `SCRIPT ERROR` / `Parse Error` lines** (gotcha 22: the
   boot rung's `0 warnings, 0 errors` does not see them), boot `0 warnings, 0 errors`, tests
   pass, `check_budgets` exits 0, `check_content` exits 0, `check_boundary` exits 0.
2. New behaviour covered by assertions in `tests/unit/`, and a deliberately broken assertion
   still exits 1.
3. `SYSTEMS_INVENTORY.md` statuses and `ROADMAP.md` criteria updated.
4. `DEVLOG.md` appended — did / why / connects / verified / unblocks / gaps.
5. `CONTEXT.md` updated — counts, new settled decisions, new gotchas, next package.
6. This file marks the package `DONE` with its commit.
7. Committed and pushed.
8. **The chip for the next package is created**, so the handoff is automatic. If no chip ever
   arrives, nothing is lost: this file's row for the next package IS the fallback handoff, and
   `docs/CONTEXT.md` opens with the branch map saying which tip to build from. Use the
   spawn-task mechanism with a self-contained prompt: it must name the start-here docs, the
   goal, the files to write, the exit criteria, and what is deferred - everything a session
   with no memory of this one needs. WP-01 chip is the worked example; copy its shape.

**Anything with a visual consequence needs a windowed capture and an actual look at the PNG.**
Headless shades nothing. This project has already shipped two bugs that every other gate passed.

## Board

| # | Package | Status |
|---|---|---|
| 01 | Triggers and traversal | **DONE** — see below |
| 02 | UI foundation | **DONE** — see below |
| 03 | HUD and inventory screen | **DONE** — see below |
| 04 | Second area, transitions, loading | **DONE** — see below |
| 05 | Dialogue | **DONE** — see below |
| 06 | NPCs and navigation | **DONE** — see below |
| 07 | Path actions | **DONE** — see below |
| 08 | Quests | **TODO — next** |
| 09 | Character depth | TODO |
| 10 | Crafting and gathering | **OPTIONAL** — a genre choice, not a requirement of every game (TEMPLATE.md). Does not block v1.0 |
| 11 | World map and fast travel | TODO |
| 12 | Menus | **DONE** — taken out of order; it needed only WP-02 |
| 13 | Presentation | **DONE** — taken out of order; see below |
| 14 | Dev tools and hardening | TODO |
| 15 | Release engineering | **SPLIT** — the export proof is template work and is now **T2.0**; credits and the accessibility pass belong to a consuming game |

### The template phases, added 2026-08-26

Read [`TEMPLATE.md`](TEMPLATE.md) first. These are NOT numbered WP-nn because they cut across the
original board rather than continuing it.

| # | Package | Status |
|---|---|---|
| T1.1 | Integration — every package onto `main` | **DONE** — PR #10 |
| T1.2 | Engine/demo boundary: the rule, a gate, and the leaks fixed | **DONE** — see T1.2 below |
| T1.3 | Test fixtures + framework hardening | **DONE** — see T1.3 below |
| T1.4 | CI — automate the ladder | **DONE** — see T1.4 below |
| T2.0 | **The export proof** | **DONE** — the assumption HELD; see T2.0 below |
| T2.1 | Art contract seams | **TODO — next** |
| T2.2 | Consumer documentation | TODO |

**Why T2.0 jumps the queue, and it is deliberately out of thematic order.** It belongs to Phase
T3 by subject and is sequenced FIRST by risk. The three content registries find items,
conversations and schedules by DIRECTORY SCAN (ADR-0006). No export preset exists, so nobody has
ever run an exported build. If a Godot export omits unreferenced resources, every catalogue ships
EMPTY — and every ladder rung, both CI jobs, `check_content` and 911 assertions all stay green,
because they run from `res://` in the editor where the files are plainly there. That is the
"409 passing checks and never rendered a frame" failure this project was founded to prevent,
reproduced at the last possible moment.

The asymmetry is what decides the order: the proof is cheap (one preset, one export, one count),
and if it FAILS the fix is architectural — a revision to ADR-0006 touching how all content is
found. Every package built in the meantime would be built on an assumption known to be false.
T2.1 by contrast fails locally, inside `CharacterVisual` and a `Theme`. Cheap test, architectural
blast radius, so it goes first.

**Re-framed rows on the original board.** WP-09's exit criterion "the lantern gates an area" is a
content claim; restate it as *equipment can gate traversal, a lantern is the example*. WP-10 is a
genre choice, and the board row now says OPTIONAL. WP-14's "a smoke test that drives **the whole demo**"
hard-wires the demo into a permanent gate; it should drive *a* game, from fixtures.

When every package is `DONE`, the skeleton is complete: every system has a working minimal
implementation plus one piece of placeholder content proving it. Everything after that is
content, and none of it should need new architecture. That is the bet this project is making.

---

## WP-01 · Triggers and traversal — **DONE**

**Goal.** Complete the interactable catalogue so the Phase 1 loop is genuinely whole: volumes
that fire on entry, a place to rest and skip time, and authored vertical movement.

**Read:** `src/gameplay/interactables/interactable.gd`, `gate.gd` (closest existing pattern),
`src/gameplay/objects/persistent_state.gd`, `src/core/util/layers.gd`,
`src/systems/world_clock/clock.gd`, `src/gameplay/character/player_controller.gd`,
`src/core/events/events.gd`, `tests/unit/pickups_test.gd` (the test idiom),
`scenes/areas/courtyard/courtyard.tscn`, `scenes/objects/gate.tscn`.

**Write**
- `src/gameplay/interactables/trigger_volume.gd` — `Area3D` on `Layers.TRIGGER`, once-or-repeat,
  persisted by `object_id`, sets a flag and emits. **Must not know what its action does.** The
  `Triggers/` node, the collision layer and the inventory row all exist already and nothing
  populates them.
- `src/gameplay/interactables/rest_point.gd` — `SIT` verb, skips to a target hour.
- `Clock.skip_to_hour(hour)` — routed through `set_time`, **not** `advance_minutes`, or an
  eight-hour sleep emits 480 `minute_passed` signals.
- `src/gameplay/interactables/climb_point.gd` + a climb state in `PlayerController`. This is the
  authored vertical movement that "no jumping" implies.
- Prefabs in `scenes/objects/`, placed in the courtyard, plus CSV rows.
- Cases in `tests/unit/`.

**Exit criteria**
- A trigger fires once on entry, does not re-fire, and stays fired across a reload.
- Resting advances the clock, and captures before and after show the lighting actually changed.
- A climb point moves the player vertically and cannot be entered mid-air.
- Ladder green; `check_content` still exits 0.

**Unblocks:** the clock time-skip that NPC schedules (WP-06) need.
**Deferred here:** physics props, water volumes, harvestables (WP-10).

**Closed 2026-08-26**, commit `81b28b0`. All four exit criteria met. 215 assertions
(was 165), boot `0 warnings, 0 errors`, both checkers exit 0. Two bugs the engine caught and
static checks could not: a climb that oscillated on its corner because the waypoint did not
latch, and a trigger near the area origin firing at spawn because the player exists there for
a frame before `Director` places them. Both are written up in `DEVLOG.md` and `CONTEXT.md`.
One scope addition beyond the manifest, deliberate and small: `RefusalReason.NOT_GROUNDED`,
because a climb refused mid-air with no message is indistinguishable from a broken button.

---

## WP-02 · UI foundation — **DONE**

**Goal.** A screen stack, pause semantics and input contexts — so no screen is ever built on an
ad-hoc pause and a boolean.

**Why before any screen.** Nothing currently has a home for modal UI. `InteractionSensor` reads
input every physics frame with no notion of an open screen, and the only hand-over mechanism is
`PlayerController.set_input_locked()`, driven solely by dialogue signals. Build a screen first
and you get one boolean per screen, forever.

**Read:** `src/ui/` (all three files), `scenes/boot/game_root.tscn`, `src/core/boot/game_root.gd`,
`src/systems/interaction/interaction_sensor.gd`, `src/gameplay/character/player_controller.gd`,
`src/systems/input/actions.gd`, `src/core/events/events.gd`.

**Write:** `src/ui/root/ui_root.gd` — a screen stack, one `is_gameplay_input_allowed()` truth,
and a `ui_mode_changed` signal on the bus. Replace the single input-lock boolean with a counted
or token lock (`lock(&"dialogue")`), so two systems locking cannot unlock each other. Pause via
deliberate `process_mode` per node — music and the fade keep running, gameplay stops.

**Exit criteria:** a stub screen opens, gameplay input stops, music keeps playing, the fade still
works, and closing it restores control. Two overlapping locks release correctly.

**Unblocks:** every screen in the game.

**Done 2026-08-26**, commit `444dbd2`.
`InputLock` (`src/core/util/input_lock.gd`), `UiRoot` (`src/ui/root/ui_root.gd`), `UiScreen`
and `StubScreen` (`src/ui/screens/`), `GameEnums.UiMode`, `Events.ui_mode_changed`.
`PlayerController.set_input_locked(bool)` is DELETED; its callers hold named tokens, and
`InteractionSensor` grew its own lock and now knows an open screen exists at all. Suite 215 ->
294, everything green, plus three windowed captures and a real-input probe in the live tree.
Two things the manifest did not anticipate, both small and both justified in `DEVLOG.md`:
`Audio`, `Director`, `NotificationToast` and `DevCapture` each opted out of pause in their own
`_ready()` (autoloads are pausable by default, so music would have cut out), and `ScreenFade`
moved to be the last child of `UILayer`, because a curtain that does not cover the screens is
not a curtain.

---

## WP-03 · HUD and inventory screen — **DONE**

**Goal.** The first real consumers of the stack. The inventory has data and no window.

**Read:** `src/ui/root/ui_root.gd` and `src/ui/screens/ui_screen.gd` (both from WP-02),
`src/ui/screens/stub_screen.gd` (the worked example), `src/ui/hud/`, `src/ui/prompt/`,
`src/gameplay/character/inventory.gd`, `src/content/items/item_definition.gd`, `item_db.gd`,
`src/systems/world_clock/clock.gd`, `localization/strings.csv`.

**Write:** a HUD (clock readout; prompt and toasts already exist) and an inventory screen bound
to `Events.inventory_changed`. The UI stays dumb — it reads `Inventory.ids()` and renders; it
holds no rules. Every string is a CSV key.

**Exit criteria:** open with `I`, items listed with localized names and counts grouped by
category, gameplay frozen while open, basic gamepad navigation. Capture and look at it.
The screen is a `UiScreen` pushed onto `UiRoot` — it must NOT touch `get_tree().paused`, must
NOT lock the player, and must NOT add a signal for any of that. If it needs to, the stack is
wrong and that is a WP-02 bug, not a reason to work around it. Delete `StubScreen` once this
and one other real screen exist.

**Done 2026-08-26**, commit `1563915`.
`src/ui/hud/hud_clock.gd`, `src/ui/screens/inventory_screen.gd`, `src/ui/root/screen_keys.gd`,
`tests/unit/screens_test.gd`, 22 CSV rows. `StubScreen` is DELETED along with its two
`ui.stub.*` rows and the `--open-screen` flag, which became `--give=<list>` plus
`--open-inventory` so a capture shows real rows. `ui_test.gd` now drives real screens. Suite
294 -> 355, everything green, two windowed captures examined and a real-input probe that
pressed I, ui_down, ui_up, Escape and I twice in the live tree.
One thing the manifest did not anticipate, justified in `DEVLOG.md`: a screen must declare
`pauses_world` in `_init`, not `_build`, or `_ready` discards a caller's override — which had
been making the overlay assertion in `ui_test.gd` pass vacuously since WP-02.

---

## WP-04 · Second area, transitions, loading — **DONE**

**Goal.** Prove `Director` for real. It is written, guarded, logged — and has **never swapped two
areas**, because only one exists.

**Read:** `src/systems/scene_director/director.gd`, `src/gameplay/world/area_root.gd`,
`src/gameplay/world/environment_driver.gd`, `scenes/areas/courtyard/courtyard.tscn`,
`src/ui/hud/screen_fade.gd`, `src/gameplay/interactables/gate.gd`.

**Write:** a second area, a door that travels, a loading indicator behind the fade, shader
warm-up. Interior variant with `follow_clock = false`.

**Exit criteria:** twenty round trips with no growth in node count or memory; two transitions in
one frame refused with a log line; world state on both sides survives a save and reload;
captures of both areas.

**Done 2026-08-26**, commit `3ed321f`.
`scenes/areas/lantern_hall/`, `src/gameplay/interactables/area_door.gd`,
`src/ui/hud/loading_indicator.gd`, `tests/unit/transitions_test.gd`,
`Events.area_load_progress`, `Director.WARM_UP_FRAMES`, an Interior group on
`EnvironmentDriver`, and `--round-trips`, `--cross-area-save` and `--goto` in `dev_capture.gd`.
Suite 370 -> 414. Twenty round trips held node count exactly flat at 120 and memory to -12 KiB;
the guard refused forty same-frame second requests in the same run; a save taken IN THE HALL
reloaded into the hall with its coffer still empty, after the values were deliberately wiped
first.
Three defects the manifest could not have anticipated, all invisible with one area and all
justified in `DEVLOG.md`: `DictRead.get_name` dispatched to the native `Resource.get_name`, so
loading a save had never restored the area; `InteractionSensor` held a freed `_current` because
a freed object compares EQUAL to null, leaving a prompt for an unloaded area on screen; and
`follow_clock = false` still sampled the clock once, so the first interior was pitch black at
02:30 and fine at noon from the same scene file.

---

## WP-05 · Dialogue — **DONE**

**Goal.** The largest unproven system. A runner, an authorable diffable format, and a UI.

**Read:** `src/core/state/flags.gd`, `src/core/events/events.gd` (the dialogue signals are
already declared), `src/ui/root/ui_root.gd`, `src/content/items/item_definition.gd` (the content
Resource pattern to copy), `src/gameplay/character/player_controller.gd` (it already yields to
dialogue signals), `docs/decisions/ADR-0006-item-discovery-by-directory-scan.md` (registry
pattern to reuse for conversations).

**Write:** a conversation format under `data/dialogue/`, a runner, a dialogue box with portraits
and choices and text speed. Conditions read `Flags`; effects set them. Placeholder story only.

**Exit criteria:** a conversation that reads a flag, branches on it, sets another, and survives
a save mid-conversation or explicitly refuses to be saved mid-conversation.


**Done 2026-08-26**, commit `addf337`.
`src/content/dialogue/` (four data classes plus the registry), `dialogue_runner.gd`,
`dialogue_screen.gd`, `speaker.gd`, `data/dialogue/gardener.tres`, `tests/unit/dialogue_test.gd`,
`Events.dialogue_requested`, `GameEnums.FlagTest` and `FlagWrite`. Suite 414 -> 460.
The exit criterion is met by the SECOND half, deliberately: a conversation is not saved. A saved
node id would make every node id in every .tres a permanent public identifier, so the section
exists, is always empty, and logs what it discarded; a mid-conversation save reloads with the
conversation over and control returned.
The first draft of `speaker.gd` reached for `UiRoot` and `DialogueScreen` directly, which is a
layer violation — gameplay must not name a screen. It emits `Events.dialogue_requested` instead
and `ScreenKeys` listens, matching `AreaDoor` exactly.
One defect from WP-01 found on the way: `object.lever.gate.on` had an unquoted comma, so the
lever's toast had been cut at `Somewhere north` for three packages. `check_content.gd` now fails
any CSV row that parses to more than two columns.

---

## WP-06 · NPCs and navigation — **DONE**

**Goal.** Navmesh baking, an NPC brain, and schedules driven by the world clock.

**Read:** `src/gameplay/character/character_visual.gd` (reused unchanged for NPCs),
`src/gameplay/world/area_root.gd`, `src/systems/world_clock/clock.gd`,
`src/gameplay/interactables/interactable.gd` (an NPC is an interaction target).

**Write:** `NavigationRegion3D` baking in the area template, `NavigationAgent3D` pathing, a brain
with idle/wander/travel, and schedules keyed to `hour_passed`. Level-of-detail for offscreen
NPCs is deferred.

**Exit criteria:** an NPC is at the market at noon and home at night, across a save and reload,
and thirty NPCs do not measurably cost frame time.


**Done 2026-08-26**, commit `c42c844`.
`src/content/npc/` (three classes), `src/gameplay/character/npc_brain.gd`,
`scenes/characters/npc.tscn`, `data/schedules/keeper.tres`, `Navigation/` and `Waypoints/` added
to both areas and to the `AreaRoot` contract, `GameEnums.NpcActivity`, `tests/unit/npc_test.gd`.
`dev_capture.gd` was SPLIT — it had reached 310 of its 250 allowed lines — into itself plus
`src/systems/debug/dev_probes.gd`, which now owns every scripted scenario. Suite 460 -> 555.
The schedule criterion is measured by `--npc-day`, which steps the clock through a whole day:
gate_post at 06:00 and 09:00, the dais at 12:00 and 15:00, the bench from 20:00 through 02:00 —
the last of those being the midnight wrap working. `--npc-storm=30` reports
`16.598 ms/frame with 1 NPC, 16.675 with 31`.
Three defects found while building it and eight more from an independent adversarial review of
WP-01 to WP-05, including a HARD SOFT-LOCK in dialogue that could only be escaped by killing the
process. All eleven are listed in `CONTEXT.md` and justified in `DEVLOG.md`.

---

## WP-07 · Path actions — **DONE**

**Goal.** The signature mechanic: per-NPC non-combat verbs in the spirit of Octopath's
Scrutinise, Inquire, Purchase and Guide.

**Read:** WP-06 output, `src/gameplay/interactables/interactable.gd`,
`src/gameplay/character/inventory.gd`, `src/core/state/flags.gd`, `src/core/util/game_enums.gd`.

**Write:** available actions per NPC as content data, success conditions, consequences, and a
reputation or standing store. Reuses the refusal-with-a-reason pattern the interaction system
already has.

**Exit criteria:** one NPC with two actions, one of which can fail and change standing, all
persisted.


**Done 2026-08-26**, commit `e5f90bc`.
`src/content/npc/path_action.gd`, `src/gameplay/interactables/path_action_point.gd`,
`src/gameplay/character/standing.gd`, `scenes/objects/path_action.tscn`, two authored actions in
`data/actions/`, five new `InteractVerb`s and `RefusalReason.LOW_STANDING`,
`tests/unit/path_actions_test.gd`. Suite 555 -> 606.
NO FOURTH REGISTRY: a path action is only ever reached through the NPC that offers it, exactly
as a chest reaches its `ItemDefinition`s, so nothing looks one up by id and the note in
`schedule_db.gd` about three being a pattern does not fire.
The criterion is met by barter's three bands: refused below standing 1, committed and FAILING at
1, committed and succeeding at 2 — captured once per band, and in the success shot the prompt
has already fallen back to the other action because `once` applies to success only.
`dev_probes.gd` was SPLIT again, into itself plus `dev_stage.gd`; the budget checker has now
found three seams in the debug surface, at 310, 320 and 250 lines.
One defect fixed in WP-06's code: the unreachable guard believed a single frame's answer, and a
`NavigationAgent3D` recomputing after a wander re-target legitimately answers "unreachable"
before it has finished thinking. It now requires thirty consecutive frames.

---

## WP-08 · Quests

**Read:** `src/core/state/flags.gd`, `src/core/save/save_system.gd`, WP-05 output.
**Write:** a quest state machine with steps, a journal, plot/chapter gating, map markers.
**Exit criteria:** a quest started from dialogue, advanced by a trigger, completed by an item
handover, surviving a reload at every step.

---

## WP-09 · Character depth

**Read:** `src/gameplay/character/` (all), `src/gameplay/interactables/gate.gd`,
`src/systems/audio/audio_director.gd`.
**Write:** an attribute container where adding an attribute is data not code; surface-aware
footsteps; equipment that changes traversal — a lantern that makes dark places enterable.
**Exit criteria:** the lantern gates an area, footsteps change with the surface underfoot.

---

## WP-10 · Crafting and gathering

**Read:** `src/content/items/`, `src/gameplay/interactables/pickup.gd`,
`src/gameplay/character/inventory.gd`, `src/systems/world_clock/clock.gd`.
**Write:** harvestables with a regrowth timer keyed to the clock, and recipes as content data.
**Exit criteria:** gather, wait, it regrows; craft, and the recipe consumes and produces
correctly; all persisted.

---

## WP-11 · World map and fast travel

**Read:** `src/systems/scene_director/director.gd`, `src/gameplay/world/area_root.gd`, WP-02/03.
**Write:** an `AreaDef` content resource, a region map with discovery, travel points.
**Exit criteria:** discover an area, travel to it, discovery persists.

---

## WP-12 · Menus — **DONE**

**Read:** `src/ui/root/ui_root.gd`, `src/core/state/settings.gd`, `src/core/save/save_system.gd`,
`src/systems/input/actions.gd`, `src/core/boot/game_root.gd`.
**Write:** main menu (new / continue / quit), settings screen covering every row in
`Settings.DEFAULTS`, save-and-load screen with slot headers, key rebinding, controller navigation.
**Exit criteria:** the whole game reachable and playable on a gamepad, rebinding persists, and
`GameRoot` no longer boots straight into an area.

**Closed 2026-08-26**, commit `094d4dc`. All three exit criteria met. A `MenuScreen` base plus
five menus, `KeyBindings` for the override file, `Director.start_new_game()`,
`SaveSystem.latest_slot()`, two bus signals, and a `GameRoot` that emits `main_menu_requested`
instead of loading `courtyard`. 717 assertions (was 460), boot `0 warnings, 0 errors`, both
checkers exit 0, four windowed captures looked at.

Controller navigation needed no gamepad code: a `VBoxContainer` of `Button`s answers `ui_up`,
`ui_down` and `ui_accept` already, so no screen owns a cursor. Proved with a real-input probe,
quoted verbatim in `DEVLOG.md`.

**Three bugs the engine caught and no static gate could:** a menu backed out of had no focused
row so a gamepad did nothing at all (`UiScreen._opened` had never meant what its docstring said);
two translucent screens stacked printed through each other; and
`InputEventJoypadButton.as_text()` is sixty characters wide and ran off the side of a menu.

**Honestly over budget:** 11 files and roughly 700 new code lines, against the board's "about 8
files or 500". Landed whole rather than split, because the five menus share one base and one CSV
block and a half-landed menu set is a game with no way back to the main menu.

**Deferred:** thirteen settings still have no runtime consumer (WP-13/WP-15), runtime language
switching, a duplicate-binding warning, and per-device button glyphs.

---

## WP-13 · Presentation — **DONE**

**Taken out of board order**, from WP-05's tip. WP-06 through WP-12 are still open, and this
package touched nothing they own: five new files, plus `Audio.beds`, two capture flags, one
node in each area scene, and nine CSV rows.

**Read:** `src/systems/weather/weather.gd`, `src/gameplay/world/environment_driver.gd`,
`src/systems/audio/audio_director.gd`.

**Wrote**
- `src/systems/weather/wetness_model.gd` — `WetnessModel`. Pure `RefCounted`: 0..1, rises over
  eight seconds of rain and falls over twenty-six. Pure because drying is the only part of
  the weather visuals with memory, and gotcha 10 means no assertion can wait for a frame.
- `src/gameplay/world/precipitation.gd` — `Precipitation`. One `GPUParticles3D` per kind that
  generates its own mesh, materials and snowflake texture. **Told a weight; never polls
  Weather.**
- `src/gameplay/world/weather_visuals.gd` — `WeatherVisuals`. One node per area. Owns the
  `MIX` table, follows the player, cross-fades on `Weather.blend()`, steps the wetness, sets
  the ambience levels, and toasts the change. **Decides nothing.**
- `src/gameplay/world/surface_wetness.gd` — `SurfaceWetness`. Darkens and clearcoats an area's
  materials, on private duplicates so wetness cannot outlive the area.
- `src/systems/audio/ambience_bed.gd` — `AmbienceBed`, as `Audio.beds`. Named layers on
  procedurally generated filtered noise, because there is no audio in the project.
- `dev_capture.gd`: `--wet=<0..1>` and `--dry-for=<seconds>`.
- `tests/unit/presentation_test.gd` — 47 assertions. 460 -> 507.

**Interior lighting was already done** in WP-04 and was deliberately not rebuilt.

**Exit criteria — met.** Import clean; boot `0 warnings, 0 errors`; 507 assertions pass and a
deliberately broken one exits 1; `check_budgets` and `check_content` both exit 0. Seven
windowed captures at 13:00 with time and weather frozen, each one opened and looked at: clear,
rain and storm are unmistakably three different images, and a soak-to-dry triptych at wetness
1.0 / 0.5 / 0.0 under an unchanged clear sky shows the ground darkening and coming back.

**Commit:** `8ebc7f8` on `claude/wp-13-presentation`. See `docs/DEVLOG.md`, entry
`2026-08-26 — WP-13`.

---

## WP-14 · Dev tools and hardening

**Read:** `tools/`, `src/systems/debug/dev_capture.gd`, `tests/`.
**Write:** an in-game debug console (teleport, set flag, set time, give item), a performance
overlay, a smoke test that drives the whole demo through public APIs, and the hard-coded-string
audit. The audit claims only the literals it can actually see — computed keys are covered by the
enum loop in `tests/unit/items_test.gd`.
**Exit criteria:** the string audit exits 1 on a planted literal; the smoke test drives the demo
end to end and asserts `Log.tally() == Vector2i(0, 0)`.

---

## WP-15 · Release engineering

**Read:** `docs/decisions/ADR-0006-item-discovery-by-directory-scan.md` **first**, `project.godot`,
`tools/check_content.gd`.

**Write:** an export preset, shader warm-up, an accessibility pass, credits.

**This package must settle ADR-0006's open question.** Items are found by scanning a directory,
which is verified in the editor and headless only. The preset **must export all resources in the
project** — a "selected scenes and dependencies" preset would strip the item `.tres` files
entirely, because nothing references most of them. If an exported build comes back with an empty
catalogue, the remedy is a generated manifest and `ItemDb.resource_paths()` is the only function
that changes.

**Exit criteria:** an exported build runs on a machine without Godot installed, with a non-empty
item catalogue, and a thirty-minute soak produces zero errors.

---

## T1.2 · Engine/demo boundary — **DONE**

**Goal.** Turn `TEMPLATE.md`'s prose rule — *no file under `src/` may name demo content* — into a
mechanical gate, and fix the four leaks it already had.

**Read:** `CLAUDE.md`, `docs/TEMPLATE.md`, `docs/CONTEXT.md`, this row.

**Wrote**
- `tools/check_boundary.gd` — the gate. Demo names **derived** from the folders under
  `scenes/areas/` and the `id` of every `.tres` under `data/`, plus each id's last segment.
  Fails on any of them in a CODE line under `src/`. Also fails if a debug script defining
  `_parse_arguments()` loses its `OS.is_debug_build()` guard, because that guard is the
  precondition the one exemption rests on.
- `src/core/util/game_config.gd` — `GameConfig`. Reads the new `[game]` section of
  `project.godot`. The only file under `src/` that knows a game-specific answer.
- `director.gd` lost `const FIRST_AREA := &"courtyard"`; `log.gd` lost the literal `Gulistan`
  from the banner and the log file name; the three debug nodes got their release guard.
- `docs/NEW_GAME.md` — the strip-and-start checklist, performed against a stripped copy.

**Two decisions to not re-litigate.** Comments are exempt from the gate and code is not — a `##`
line teaching `id = &"item/rose_key"` changes no behaviour and forbidding it would make the
documentation useless. And `src/systems/debug/` is the single exempt directory, justified in the
tool's header, conditional on the release guard, with its demo names counted and printed rather
than silently skipped. **A second exempt directory means the rule is gone.**

**It became its own tool, not part of `check_content.gd`.** The combined file came out at 252 of
the 250 allowed code lines and the budget checker refused it. That is the fourth split the
checker has forced and the fourth that was already in the reasoning: `check_content.gd` validates
that the *demo* is well formed, this validates that the *engine* does not know the demo exists.

**Closed 2026-08-26**, commit `06ce363`. All five exit criteria met. 921 assertions (was 910), boot
`0 warnings, 0 errors`, all three checkers exit 0. The gate proved by planting `&"courtyard"` in
`src/core/util/layers.gd` — `FAIL — 1 boundary violation(s)`, exit 1 — and removing it. Two bugs
found that no gate had caught: `dev_capture.gd` had failed to *parse* since the WP-13 merge while
every rung stayed green (gotcha 22), and a stripped template failed its own content gate on step
one of `NEW_GAME.md` because an empty content folder was treated as a problem. Both written up in
`DEVLOG.md`.

**Left for T1.3, and CLOSED by it:** the suite was still welded to the demo, so `data/` could not
actually be deleted. Everything else on the ladder survived it, which T1.2 ran and quoted.

---

## T1.3 · Test fixtures + framework hardening — **DONE**

**Goal.** Unweld the suite from the demo, so `data/` and `scenes/areas/` can be deleted and rung 4
of the ladder survives; and make the suite able to fail, which it demonstrably was not.

**Read:** `CLAUDE.md`, `docs/TEMPLATE.md`, `docs/CONTEXT.md`, `tests/framework/`, `tests/test_runner.gd`.

**Wrote**
- `tests/framework/fixture_content.gd` — the content a case needs, built in code and deliberately
  abstract. Items, a conversation graph, a timetable, a path action.
- `tests/framework/fixtures.gd` — where it lives. **The decision is split along one line:** in
  memory when a system is HANDED content, written to `user://test_fixtures/` and scanned by the
  registry when a system LOOKS IT UP BY ID. The three registries find content by directory scan
  (ADR-0006), so the alternative was a test-only backdoor in engine code.
- `tests/framework/error_watch.gd` — an `OS.add_logger` `Logger` counting `ERROR_TYPE_SCRIPT`.
- `TestCase.plan()` / `skip()`, and a runner that enforces both plus a manifest scan.
- `ItemDb`/`DialogueDb`/`ScheduleDb`: `content_dir`, and `reload()` renamed to `rescan()`.
- `tools/check_boundary.gd` now scans `tests/framework/` and `tests/unit/` too.

**Three decisions to not re-litigate.** Fixtures on disk rather than injected, because the
registries scan directories and a backdoor in engine code that exists only for the suite is worse
than a temp folder — and the round trip through `ResourceSaver` proves the authoring format as a
side effect. The plan is a maintained number, TAP-style, because a GDScript crash aborts only its
own frame and nothing else can see a swallowed assertion. And `ErrorWatch` counts only
`ERROR_TYPE_SCRIPT`, because deliberate negative-path tests raise `push_error` and a gate that
fires on those gets switched off within a day.

**Closed 2026-08-26**, commit `a8377a0`. Both exit criteria met, plus the two Phase T1 criteria
that were waiting on it. 911 assertions (was 921 — the drop is aggregation: named per-item and
per-waypoint assertions became set-level ones that also cover content added later). Stripped run:
`861 passed, 0 failed, 12 skipped`, exit 0, every skip named and counted. All four silent-pass
modes planted and each exited 1, quoted in `DEVLOG.md`. One bug found that no gate had caught and
none could: **`ItemDb.reload()` had never called our function** — `Script.reload()` won the name,
the fourth native-name collision in this project — so every `reload()` in the three registries and
in `check_content.gd` was a script reload that happened to have the same effect.

**Left for T1.4, and CLOSED by it:** none of this ran automatically. The ladder was seven
commands a human types.

---

## T1.4 · CI — automate the ladder — **DONE**

**Goal.** A pushed branch with a broken assertion goes red. That was the last unmet Phase T1
criterion, and Phase T1 is now complete.

**Read:** `CLAUDE.md`, `docs/TEMPLATE.md`, `docs/CONTEXT.md` (gotchas 22 and 24 shape the
workflow), `tests/test_runner.gd`, `tests/framework/`, and the headers of the three `tools/check_*`
gates for their exit-code contracts.

**Wrote**
- `.github/workflows/ladder.yml` — two jobs. **Ladder (full checkout)**: rung 2 import with
  `SCRIPT ERROR` / `Parse Error` grepped at zero tolerance, rung 3 boot asserting the last
  `Session ended` line, rung 4 the suite, then `check_budgets`, `check_content`, `check_boundary`,
  each its own step. **Ladder (stripped template)**: `rm -rf data scenes/areas` then the same
  rungs minus the boot, and it asserts the run reports named skips so a stripped run can never
  look identical to a full one.
- `.github/actions/setup-godot/action.yml` — downloads `Godot_v4.7.2-stable_linux.x86_64.zip`,
  verifies it against a SHA512 pinned as a literal, and asserts `godot --version` is exactly
  `4.7.2.stable.official.ed1daf0bf` before any rung depends on it. Standard build, never mono.
  One file, because a version pinned in two jobs is a version that drifts.

**Four decisions to not re-litigate**, each argued in the workflow's own comments. **`.godot/` is
not cached and the engine archive is** — a restored cache can resolve a `class_name` this commit
deleted, and "CI is green and a fresh clone is broken" is the exact failure this package exists to
prevent; the engine zip is immutable and keyed by version, so cache the fixed thing and never the
derived one. **Rung 1 is absent** because autoload identifiers do not resolve under `--check-only`
and a machine cannot tell that expected error from a real one. **The boot rung asserts one line,
not the whole log**, because quitting mid-load prints spurious `Parse Error` lines after a clean
report and a whole-log grep would be a flake generator; the frame count is 300, not 120, since a
headless frame is nearly free and racing a threaded load is not. **The windowed capture is stated
as impossible, not dropped** — a GPU-less runner shades nothing, so any capture it produced would
be exactly the evidence gotcha 2 calls worthless.

**Closed 2026-08-26**, commit `272053f`. The one exit criterion met, and Phase T1 with it. Proved
red: one assertion in `core_test.gd` changed to expect 6 where the answer is 5, and run
[32989608134](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32989608134)
failed at `Rung 4 - test suite` in BOTH jobs, printing `FAILED: dict_read int — expected 6, got
5`. Restored, and run
[32989771404](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32989771404)
went green: `911 passed, 0 failed, 0 skipped` full, `861 passed, 0 failed, 12 skipped` stripped —
reproducing T1.3's hand-run numbers exactly. Nothing in `src/` changed and the one line touched in
`tests/` was reverted, so the stated tripwire for this package never fired. Two new gotchas, 25
and 26: GitHub runs every `run:` block as `bash -e {0}` so a step's own `set -uo pipefail` does not
turn errexit off — the first red run said only `exit code 1` — and `gh`'s run listing lags enough
to support a confident wrong diagnosis.

**Left for T2.1:** no branch protection, so the gate reports and nothing stops a red branch
merging — that is a repository setting, not a file. No status badge, deliberately: on a private
repo it renders as "unknown".

---

## T2.0 · The export proof — **DONE**

**Goal.** Prove that an exported build finds its content. Everything about this project's content
pipeline rested on an assumption nobody had ever tested: that a Godot export ships resources that
no scene references.

**THE ANSWER: IT DOES. The assumption held, and ADR-0006 needed no revision.** A Windows *debug*
export was built and run from its own `.exe`, outside the editor, in a directory containing nothing
but the executable and its `.pck` — no `project.godot`, no loose `data/`. Both sides, quoted:

```
editor    origin: template=false editor=true debug=true exe=Godot_v4.7.2-stable_win64.exe
exported  origin: template=true  editor=false debug=true exe=game.exe

both      items: 3 found in res://data/items -> [rose_key.tres, rose_petal.tres, stone_chip.tres]
both      dialogue: 1 found in res://data/dialogue -> [gardener.tres]
both      schedules: 1 found in res://data/schedules -> [keeper.tres]
```

Counts, roots and resolved paths identical, and `Session ended … 0 warnings, 0 errors` in both. The
exported build also *used* the content, not merely counted it: `--give=item/rose_key,item/rose_petal:3`
logged `+1 item/rose_key` and `+3 item/rose_petal`, which means the definitions loaded through the
pack's `.remap` indirection.

**Four measured facts, and three of them were assumptions until now.**

1. **`export_filter` is the entire risk, and `"all_resources"` is the only right answer.**
   Measured both ways: with it, all seven `data/**` resources are stored in the pack; with
   `export_filter="scenes"`, **zero** are.
2. **`ResourceLoader.list_directory()` works through the pack.** The pack stores
   `data/items/rose_key.tres.remap`; the scan returns the `.tres` path and the load follows the
   remap. ADR-0006 chose it *because* it is the resource-aware one and recorded that as unproven.
   It is now proven, and `_normalise`'s `.remap` handling is observed rather than defensive.
3. **`include_filter="*.tres"` would have been the plausible wrong fix.** The include filter is for
   NON-resource files. It is empty, and setting it instead of `export_filter` changes nothing while
   looking like a remedy.
4. **A narrowed filter fails LOUDLY here, not silently.** With `export_filter="scenes"` and the
   boot scene selected, the build strips the `class_name` scripts that are nobody's dependency —
   `GameConfig`, `GameEnums`, `DictRead`, `KeyBindings` — and dies at boot on parse errors. So the
   feared *silent empty catalogue* cannot be produced by narrowing the filter alone. It CAN be
   produced by an exclude filter, which is silent: `exclude_filter="data/*"` exported and booted
   cleanly to the main menu with `items: 0, dialogue: 0, schedules: 0`. That run is also how the
   new readout was proved to FAIL — three warnings, `1 warnings` → `3 warnings, 0 errors`.

**A SECOND DEFECT, EXPORT-ONLY, AND THE REAL PRIZE OF RUNNING THIS EARLY.** The exported build
booted with three lines the editor never printed:

```
[ERROR] [world   ] Keeper has a PersistentState with no object_id — its state cannot persist
[WARN ] [interact] Talk has no label_key, so its prompt will be blank
[ERROR] [dialogue] Talk names no conversation and will refuse every attempt
```

`courtyard.tscn` overrode `object_id`, `label_key` and `conversation_id` on two nodes **inside** its
instanced `npc.tscn` without the `[editable path="Actors/Keeper"]` marker. From source the text
loader applies those overrides; an export converts `.tscn` to binary `.scn` and the conversion
**drops** overrides on a non-editable instance. So the NPC shipped with no identity, no prompt and
no conversation, and its schedule never ran — while every rung, both CI jobs, `check_content` and
930 assertions stayed green. This project hand-authors its `.tscn` files, so the marker the editor
would have written is exactly what a hand-authored scene forgets. Stale `index=` values were ruled
out first by correcting them and re-exporting: no change.

**Wrote**
- `export_presets.cfg` — one Windows Desktop preset, committed (`git check-ignore -v` exits 1; only
  `override.cfg` is ignored). Its header carries the measurement, not a preference.
- `src/systems/debug/catalogue_report.gd` — reports every catalogue's count, root and resolved
  paths at boot, behind `OS.is_debug_build()`, in the one directory `check_boundary` exempts. It
  reports the PATHS and not only the counts because a partial ship is worse than an empty one.
  Wired into `scenes/boot/game_root.tscn` as a fifth root node.
- `tools/check_content.gd` — `_check_editable_instances()`, the gate for the second defect. 189 →
  237 of 250 code lines. Deliberately stricter than the failure needs: an *added* node inside an
  instance was observed to survive the conversion and is still required to be declared editable,
  because "which kind is this" is a distinction the exporter makes and an author should not have to.
- `tests/unit/export_test.gd` — 19 assertions. It **cannot test an exported build** and says so in
  its header and in an assertion (`is_exported() == false`), so it can never quietly start looking
  like the proof. What it does do is pin `export_filter="all_resources"` as a tested invariant,
  prove the reporter agrees with the registries, and prove every resolved path loads.
- `scenes/areas/courtyard/courtyard.tscn` — the missing `[editable]` marker.
- `docs/NEW_GAME.md` § 7 Export, and ADR-0006's honest limit closed.

**Verified.** Ladder green: import 0 `SCRIPT ERROR`/`Parse Error`; boot `0 warnings, 0 errors`;
suite **930 passed, 0 failed, 0 skipped** (911 + 19), exit 0; `check_budgets`, `check_content`,
`check_boundary` all exit 0. Stripped template: **880 passed, 0 failed, 12 skipped**, exit 0, with
`check_content` and `check_boundary` still green. Both new gates proved RED before green
(gotcha 23): deleting the `[editable]` line made `check_content` print four named violations and
`FAIL — 4 content violation(s)`; flipping `REQUIRED_FILTER` to `"scenes"` made rung 4 print
`FAIL the preset ships every resource, not only dependencies — expected scenes, got all_resources`
and exit 1. Both reverted.

**Setup note for the next person:** the export templates were not installed. Only
`Godot_v4.7.2-stable_export_templates.tpz` (1.28 GB) provides them; the four Windows x86_64 files
were extracted into `%APPDATA%/Godot/export_templates/4.7.2.stable/`. `--export-pack` needs no
template and is enough to see *which files* ship; only a real template proves they are *found*.

**Left for later, deliberately:** export presets for platforms other than Windows (each needs its
own template, and a consuming game's decision). No CI export rung — a GPU-less runner has no
platform template, and this is the same honesty as T1.4's stance on the windowed capture.

**Closed 2026-08-26.** New gotcha 27.

