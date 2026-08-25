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

1. Ladder green — `--import`, boot `0 warnings, 0 errors`, tests pass, `check_budgets` exits 0,
   `check_content` exits 0.
2. New behaviour covered by assertions in `tests/unit/`, and a deliberately broken assertion
   still exits 1.
3. `SYSTEMS_INVENTORY.md` statuses and `ROADMAP.md` criteria updated.
4. `DEVLOG.md` appended — did / why / connects / verified / unblocks / gaps.
5. `CONTEXT.md` updated — counts, new settled decisions, new gotchas, next package.
6. This file marks the package `DONE` with its commit.
7. Committed and pushed.
8. **The chip for the next package is created**, so the handoff is automatic. Use the
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
| 06 | NPCs and navigation | **TODO — next** |
| 07 | Path actions | TODO |
| 08 | Quests | TODO |
| 09 | Character depth | TODO |
| 10 | Crafting and gathering | TODO |
| 11 | World map and fast travel | TODO |
| 12 | Menus | TODO |
| 13 | Presentation | TODO |
| 14 | Dev tools and hardening | TODO |
| 15 | Release engineering | TODO |

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

## WP-06 · NPCs and navigation

**Goal.** Navmesh baking, an NPC brain, and schedules driven by the world clock.

**Read:** `src/gameplay/character/character_visual.gd` (reused unchanged for NPCs),
`src/gameplay/world/area_root.gd`, `src/systems/world_clock/clock.gd`,
`src/gameplay/interactables/interactable.gd` (an NPC is an interaction target).

**Write:** `NavigationRegion3D` baking in the area template, `NavigationAgent3D` pathing, a brain
with idle/wander/travel, and schedules keyed to `hour_passed`. Level-of-detail for offscreen
NPCs is deferred.

**Exit criteria:** an NPC is at the market at noon and home at night, across a save and reload,
and thirty NPCs do not measurably cost frame time.

---

## WP-07 · Path actions

**Goal.** The signature mechanic: per-NPC non-combat verbs in the spirit of Octopath's
Scrutinise, Inquire, Purchase and Guide.

**Read:** WP-06 output, `src/gameplay/interactables/interactable.gd`,
`src/gameplay/character/inventory.gd`, `src/core/state/flags.gd`, `src/core/util/game_enums.gd`.

**Write:** available actions per NPC as content data, success conditions, consequences, and a
reputation or standing store. Reuses the refusal-with-a-reason pattern the interaction system
already has.

**Exit criteria:** one NPC with two actions, one of which can fail and change standing, all
persisted.

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

## WP-12 · Menus

**Read:** `src/ui/root/ui_root.gd`, `src/core/state/settings.gd`, `src/core/save/save_system.gd`,
`src/systems/input/actions.gd`, `src/core/boot/game_root.gd`.
**Write:** main menu (new / continue / quit), settings screen covering every row in
`Settings.DEFAULTS`, save-and-load screen with slot headers, key rebinding, controller navigation.
**Exit criteria:** the whole game reachable and playable on a gamepad, rebinding persists, and
`GameRoot` no longer boots straight into an area.

---

## WP-13 · Presentation

**Read:** `src/systems/weather/weather.gd`, `src/gameplay/world/environment_driver.gd`,
`src/systems/audio/audio_director.gd`.
**Write:** rain, snow and wind particles driven by `Weather.intensity()`, wet surfaces, ambience
layers, interior lighting. `Weather` publishes state and nothing renders it today.
**Exit criteria:** captures of clear, rain and storm that are visibly different; wet surfaces
appear and dry out.

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
