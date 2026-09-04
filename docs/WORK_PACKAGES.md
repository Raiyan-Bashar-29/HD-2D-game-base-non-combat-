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
| 08 | Quests | **DONE** — `a00ddda`, PR #16. The first package of Phase T3; see below |
| 09 | Character depth — equipment | **DONE (split)** — `1b3d799`, PR #17. The equipment third; see below. The row asked for three systems, which is over the size limit |
| 09b | Character depth — attributes and surfaces | **DONE** — `da126d9`, PR #19. The fourth package of Phase T3; see below |
| 10 | Crafting and gathering | **OPTIONAL** — a genre choice, not a requirement of every game (TEMPLATE.md). Does not block v1.0 |
| 11 | World map and fast travel | **DONE** — `cf3f3a1`, PR #18. The third package of Phase T3, and the last system with no proof at all; see below |
| 12 | Menus | **DONE** — taken out of order; it needed only WP-02 |
| 13 | Presentation | **DONE** — taken out of order; see below |
| 14 | Dev tools and hardening — **the hardening half** | **DONE (split)** — `975ff4b`, PR #23. The eighth package of Phase T3; see below. The row named four things, which is over the size limit, so its own title was the seam. Its smoke-test wording was RE-FRAMED in the same commit, because "drives the whole demo" would have welded the demo into a permanent gate |
| 14b | Dev tools — debug console and performance overlay | **DONE** — `22e0046`, PR #24. The NINTH package of Phase T3 and the row that CLOSES the phase; see below. The four commands became ONE implementation both the command line and the console call, which is also what made room in `dev_stage.gd` — it was at exactly 250/250 |
| 15 | Release engineering | **CLOSED, 2026-09-02, by the owner** — the export proof was template work and shipped as **T2.0**; credits and the accessibility pass belong to a consuming game and will not be built here. Closed the way WP-10 is OPTIONAL: recorded, not deleted. See below |

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
| T2.1 | Art contract seams | **DONE** — see T2.1 below |
| T2.2 | Consumer documentation | **DONE** — `36b5abd`, PR #15. Phase T2 closes; see T2.2 below |
| T3.1 | **A generic content registry** — one scan, with a thin typed façade per catalogue | **DONE** — `767fbe3`, PR #20. The fifth package of Phase T3; see below. The refactor PAID, and not in the shape WP-08 costed: the duplication was in the SCAN, not the cache, so the base went on the RESOURCE |
| T3.2 | The five art-contract seams T2.1 left | **DONE** — the seventh package of Phase T3 and the last of its T-numbered rows, though the phase itself stays open on WP-14; see below. Four seams built and one refused in writing, and the point of the row is as much that they stop being mentioned in five documents as that four of them exist |
| T4.1 | **Template v1.0 — the version, and the upgrade note** | **DONE** — `799d957`, PR #25. The first package of Phase T4. The version is `[template] base/version`, NOT `application/config/version`, and the reason is the whole package in one line: a fork resets its own version on day one, so that field stops recording which base the game came from. `docs/UPGRADING.md` was PERFORMED against a real stripped fork and found a template defect nobody would have reasoned their way to; see below |
| T4.2 | **A second worked example, authored from `AUTHORING.md` alone** | **DONE** — the second package of Phase T4, and T2.2's mechanism applied to CONTENT. Five defects, two of them in the TEMPLATE rather than the prose: `check_boundary` matched SUBSTRINGS, so an item called `pear` collided with the word `appeared` and failed a gate its author could not fix; and `--stand-by` always resolved in the DEPARTURE area, so no object in an authored area could be photographed. Both gotcha 44's shape — found only by authoring content this repository does not have; see below |
| T4.3 | **`NEW_GAME.md` performed as a fork, and the release tag** | **DONE** — the last package of Phase T4, which it CLOSES. Landed the 26-PR stack on `main` as one 71-commit chain and tagged `v1.0.0` with the owner's authorisation, then performed `NEW_GAME.md` from a fresh clone. Two defects, one in the TEMPLATE: `core_test.gd` asserted an empty `first_area` was illegal when four other statements call it legal, so a fork had a red rung 4 before authoring its first area; and the prune list never learned about `quest.`, so a fork shipped this template's demo quest strings with every gate green. Bumped to `1.0.1`; see below |
| T4.4 | **`TESTING.md` performed, the last document never walked** | **DONE** — five for five: every document performed has found a defect reading would not, and this is the third of the five where the defect was in the TEMPLATE. The test runner SKIPPED A LISTED CASE THAT DID NOT PARSE, in silence, for the life of the suite — `load()` returns a non-null uninstantiable `GDScript`, `script.new()` then raises a runtime error, and that aborts only `_run_case`, so the loop moved on and the suite reported `1608 passed, 0 failed` and exit 0 with a whole case never run. `error_watch.gd` had counted the error the whole time and nothing asked it. Also: the document's ONE worked example did not compile, and three documents gave three different gotcha counts. Bumped to `1.0.2`; see below |
| T3.3 | **A quest step that can read an ITEM COUNT** | **DONE** — `292dd44`, PR #21. The sixth package of Phase T3; see below. WP-09 costed two designs and closed neither; this took the FIRST one with the cost that made it look expensive removed — the count is a DERIVED flag, so it is readable without being saved twice |

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

**Re-framed rows on the original board.** WP-09 was SPLIT rather than restated, and its section
says why: three systems in one row is over the size limit. Its criterion "the lantern gates an
area" was also a content claim, and what was built and proved is *equipment can gate traversal*,
of which a lantern is the example. WP-10 is a
genre choice, and the board row now says OPTIONAL. **WP-14's "a smoke test that drives the whole
demo" was re-framed by WP-14 itself, in the commit that took the row** — that wording would have
hard-wired the courtyard, the keeper and the rose key into a permanent gate, which is the boundary
`check_boundary` exists to defend arriving through the back door of a test, and the welding T1.3
spent a whole package undoing. `tests/unit/smoke_test.gd` drives *a* game, from
`tests/framework/fixtures.gd`, and skips its one game-shaped block loudly in a stripped checkout.
WP-14 was also SPLIT along its own title, for the size reason WP-09 was split: it named four
things, and the two that are gates shipped while the two that are UI became **WP-14b**.

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

## WP-08 · Quests — **DONE**

**Goal.** Phase T3's first package, and the widest remaining hole: quests were the one system in
the catalogue with **no proof at all**. The flag store, a conversation that writes a flag, an NPC
to talk to and a screen stack all existed, and nothing tied them into an objective the player can
be told about and can see completed.

**The one decision everything else follows from: A STEP NAMES A FLAG CONDITION, NEVER A CALLBACK.**
The same closed set of six comparisons `FlagTest` already gave a dialogue condition. That is what
makes a quest authored data rather than a code change, and it is what makes the rest of the game
able to feed a quest without knowing quests exist — a conversation writing `met/gardener` starts
one, a lever writing `area/courtyard/gate_unlocked` advances it, a trigger volume writing
`area/courtyard/dais_entered` finishes it, and **none of those three files was touched.** The
placeholder quest is built entirely out of flags the demo was already writing.

**Wrote**
- `src/content/quest/quest.gd`, `quest_step.gd` — typed `Resource`s, id equals file name with a
  `quest/` prefix, `problems()` returning `PackedStringArray`, no autoload touched so the
  `--script` build gate can load them.
- `src/content/quest/quest_db.gd` — the fourth registry. `content_dir` a `static var`, `rescan()`
  and not `reload()` (gotcha 17), an empty folder not an error.
- `src/systems/quest/quest_tracker.gd` — watches `Events.flag_changed`, re-derives every quest,
  emits `Events.quest_started` / `quest_advanced` / `quest_completed` (all three declared in
  Phase 0 and unlistened-to until now) and asks for a toast. A node under `GameRoot`, found by
  group the way `UiRoot` is; no ADR, because no autoload.
- `src/ui/screens/journal_screen.gd` — a `UiScreen` declaring its flags in `_init`, bound to `J`
  through `ScreenKeys.toggle_journal` and to `--open-menu=journal` through `menu_for`, which is
  the binding `screen_keys.gd`'s own header predicted would land there.
- `src/core/state/flag_query.gd` — **extracted, not copied.** `DialogueRunner._passes` was the
  only evaluator of `FlagTest`; a quest step asks the identical question, so the `match` moved to
  one file both call. A test fails if a second copy grows back in either.
- `data/quests/keepers_errand.tres` — ONE quest, two steps, plus 15 CSV rows.
- `tests/unit/quests_test.gd` — 49 outcomes, plan computed so authoring a second quest edits no
  number. 1081 → **1149** (49 here, 2 in `export_test.gd` for the fourth catalogue line, and 17 that
  `docs_test.gd` computed from the new worked quest example in `AUTHORING.md`).
- `tools/content_scenes.gd` — the tool split, below.
- Fourth redirect in `tests/framework/fixtures.gd` and a fixture quest in `fixture_content.gd`;
  `GameEnums.QuestState`; the fourth row in `CatalogueReport`; `--flag=` in `dev_stage.gd`;
  `docs/AUTHORING.md` § Add a quest.

**DERIVED, EXCEPT FOR TWO LATCHES, and the asymmetry is the design.** `flags.gd` says: if it can
be derived, derive it — and almost all of this is. Two things cannot be. That a quest **started**:
its start condition is a flag, and resetting that flag must not un-give a quest the player has
carried for three hours. That a quest **completed**: a step may test `AT_LEAST 3` on a counter, and
something decrementing it later must not reopen a finished quest. Those two, and only those two,
are what the save section holds — as **two lists of ids**, never an enum ordinal. The **current
objective is not latched**: it is a live question, so clearing the flag behind objective two brings
objective two back. Both halves are asserted, because a latch nothing tests is indistinguishable
from a cache.

**A COMPLETED QUEST GRANTS NOTHING, and that is a layer rule rather than a shortcut.** A
`reward_item` field would need `Inventory` and a player — both `gameplay` — inside a `systems`
tracker, and `src/` points downward only. It emits `quest_completed` and stops, which is the
reasoning that already keeps `Weather` from drawing rain and a `TriggerVolume` from naming its
consequence. Anything that wants to hand over an item listens; anything that wants to gate a
conversation tests the flag the last step tested, with no code at all.

**THE FOURTH REGISTRY CAME DUE ON A NOTE `schedule_db.gd` LEFT.** Its header said "three is a
pattern, four is a problem — if a fourth registry appears, that is the moment to reconsider." It
was reconsidered rather than ignored, and the verdict is to keep the copy: GDScript has no
generics, so a shared base could only cache `Resource` and hand it back untyped, making all four
accessors a cast at the call site — and static typing is non-negotiable #2, not a preference. What
is genuinely shared already is: `QuestDb` calls `ItemDb.resource_paths()` rather than copying the
`.remap` handling. The refactor that would pay is a base holding the cache plus a thin typed façade
each; that touches four registries and the four areas of the suite covering them, so it is **T3.1
on the board** rather than a paragraph here.

**`check_content.gd` was SPLIT, and the seam was already in the reasoning.** It stood at 237 of 250
and the quest checks did not fit. `tools/content_scenes.gd` now holds the scene *text* scans —
duplicate `object_id`, `_key` literals, the `[editable]` marker — which need no class registered
and keep working on a scene broken for an unrelated reason; what stayed asks the *registries* what
they loaded. Still ONE command and ONE CI rung, because it is a `RefCounted` the entry point
instantiates rather than a second `SceneTree` tool. 237 → 178 + 102. Fifth time the budget checker
has exposed a split that was already there.

**The quest checks print the flags rather than validating them,** and the line is drawn there
deliberately. A flag can be written from a scene, a conversation, a path action or another quest,
and the writer that matters most is a runtime one — `PersistentState` builds
`obj/<area>/<object>/<field>` at load. A checker that failed on any flag with no findable writer
would be wrong most times it fired, and a partial check that looks complete is the failure mode
this project exists to prevent. So they go in the build log where a reviewer reads them:

```
  quests: 1
     quest/keepers_errand   2 steps, starts on met/gardener is_true
        unlock              done when area/courtyard/gate_unlocked is_true
        dais                done when area/courtyard/dais_entered is_true
```

**PROVED RED, THEN GREEN — both gates, both the real failure shape (gotcha 23).** The exact output
is in `DEVLOG.md`. (1) A step's `summary_key` misspelled by one letter in the authored quest:
`check_content` exits 1 naming the quest, the step and the key; reverted, exit 0. (2) A second copy
of the comparison table planted back in `dialogue_runner.gd`: the suite exits 1 on *"and it no
longer carries its own copy of the comparison table"*, `1148 passed, 1 failed`; reverted,
`1149 passed, 0 failed`, exit 0.

**One defect, found by the capture and not by any gate.** `--flag=` was applied during argument
parsing, and `--new-game` **clears every flag** — so the first WP-08 capture photographed a journal
with no quest in it and every rung stayed green. `--flag` now waits for the area the way
`--open-menu` does. This is gotcha 31's family: not a rung blind to an error, but staging that ran
before the thing it was staging for.

**The input path was proved by a temporary probe and the probe was removed** (gotcha 15 —
`TestCase.run()` is synchronous and no assertion can press a key). Run windowed, quoted verbatim in
`DEVLOG.md`: `depth=0 top=NONE` → press `J` → `depth=1 top=journal` → press again → `depth=0
top=NONE`. `git diff src/systems/debug/` is empty.

**Two windowed captures, LOOKED AT, both at midday with `--new-game --shot-frame=70`.** The journal
over a live courtyard showing *Underway · The Keeper's Errand · — Unlock the north gate* with the
*New errand* toast up; and the same screen after all three flags with *Settled · The Keeper's
Errand · — Nothing left to do* and *The Keeper's Errand is settled*. **The `Button` styleboxes were
left unpopulated**: the journal did not force the decision — its rows are legible against the
shipped dark palette — and T2.2's reasoning for leaving them holds, so the gap stays stated rather
than guessed at.

**Deferred, with reasons, not silently.** A quest step **cannot read an item count**: `Inventory`
keeps counts, not flags, so "bring me three petals" is not authorable, and the original exit
criterion "completed by an item handover" is **not met** for that reason. The seam is a `Pickup` or
`ItemContainer` that writes a flag, which is a template change — recorded in
`ARCHITECTURE.md`'s limitations and in `AUTHORING.md` where an author would hit it, so nobody works
around it under `src/`. Also deferred: branching and failable quests, timed quests, rewards beyond
a flag, sorting and filtering in the journal, and map markers (WP-11).

**Ladder, all green.** `--headless --import` exit 0 with **zero** `SCRIPT ERROR` / `Parse Error`
lines; boot `0 warnings, 0 errors`; suite **1149 passed, 0 failed, 0 skipped**, exit 0;
`check_budgets`, `check_content`, `check_boundary` all exit 0 — and `check_boundary` now derives
`quest/keepers_errand` and `keepers_errand` as demo names and finds neither anywhere in `src/` or
`tests/`.

**CI green, run 33091433887, job logs read rather than the tick.** Full checkout **1149 passed, 0
failed, 0 skipped** with `quests: 1` in `check_content`; stripped template **1094 passed, 0 failed,
16 skipped** with `quests: 0` — the empty quest folder is not an error, which is the T1.2 finding
holding for the fourth registry. All three checkers PASS in both jobs. The push run (33091433975)
and the pull-request run (33091486449) are both green too.

**Commit:** `a00ddda` on `claude/wp-08-quests`, PR #16 — stacked onto `claude/t2-2-consumer-docs`
(#15) rather than `main`, matching the rest of the chain.

---

## WP-09 · Character depth — equipment — **DONE**

**Read:** `src/gameplay/character/` (all), `src/gameplay/interactables/gate.gd`,
`src/systems/audio/audio_director.gd`.
**Write:** an attribute container where adding an attribute is data not code; surface-aware
footsteps; equipment that changes traversal — a lantern that makes dark places enterable.
**Exit criteria:** the lantern gates an area, footsteps change with the surface underfoot.

**THE ROW WAS THREE PACKAGES AND IT WAS SPLIT, which is the board's own rule rather than a
shortcut.** "No package exceeds roughly 8 files or 500 new code lines. Over that, split it and add
a row." An attribute container, a surface system with audio, and equipment are three systems with
three sets of content, three test files and three captures. The equipment third was built because
it is the one with a CONSUMER: traversal already has a class that gates on a flag, so equipment had
somewhere to be proved the day it existed. `09b` carries the other two, each with its reason.

**EQUIPMENT OWNS NO DICTIONARY, and everything else follows from that.** A slot is a flag:

```
equip/<wearer_id>/<item id>          equip/player/item/brass_lantern
```

which is `PersistentState`'s `obj/<area>/<object>/<field>` and `Standing`'s `standing/<who>`
applied to a third case. Three consequences, and together they are the whole argument against a
`Dictionary[EquipSlot, StringName]` plus a save section:

1. **It is already saved.** No `SaveSystem.register`, no save version, no migration, and a new
   game clears it for free because `start_new_game()` clears flags.
2. **A gate can require it with no code.** A `requires_flag` pointing at one of those keys gates
   traversal on a held lantern, and `Gate` was NOT TOUCHED. Neither was `QuestStep`, nor
   `DialogueChoice`, nor `ClimbPoint` — so "carry a light to the dark place" is authorable as a
   quest step today. Same seam WP-08 built quests on, used a second time by a second system, which
   is the first evidence that the seam generalises rather than fitting one case.
3. **It is announced already.** `flag_changed` fires, so `QuestTracker` re-derives and a dialogue
   condition re-evaluates, and nothing had to learn that equipment exists.

The cost is stated rather than hidden: the key contains an item id, so an item id becomes a public
identifier the way an `object_id` is. Renaming an item's `.tres` brings it back stowed — the item
itself survives, because `Inventory` deliberately keeps counts whose definition vanished.

**THE ITEM STAYS IN THE BAG WHILE IT IS HELD**, and this is the load-bearing invariant. Moving it
out would make equipment a second place items live: `count_of()` would begin lying, and
`Gate.requires_item` would refuse a key that is in the player's hand. So equipping is purely a
flag, and the price is that losing the item has to stow it — `_revalidate`, bound to
`inventory_changed` rather than to `item_lost`, because that is the one signal every path emits
including a restored save. That invariant is what the planted violation below breaks.

**TWO @exports THAT HAD BEEN DECLARED, VALIDATED AND READ BY NOTHING.** Found while looking for
where an equip-gated gate says "you need a light": `Gate.locked_key` (since WP-01) and
`PathAction.refusal_key` (since WP-07) were both set by authored content, both checked by
`check_content`, and both dead — the prompt computed `refusal.<reason>` from the enum and never
asked. `PathAction.refusal_key`'s own comment claimed it was "shown for the LOW_STANDING refusal".
This is gotcha 2's shape exactly: a message that is merely WRONG looks the same as a message that
is right, so nothing failed. `interaction_refused` now carries a `message_key` — beside `args`, for
the same reason `args` travels there — and `Interactable.refusal_key(who, reason)` is the override.
An empty string means "compute it from the reason", which is what every object that has not
authored a line returns.

**Two defects the CAPTURE found and no gate could.** (1) The satchel screen redrew only on
`inventory_changed`, so equipping from anywhere other than a row press left a held item drawn as
merely carried — the first capture came back reading `Brass Lantern x1` with no marker while the
log said it was equipped. It now listens to `equipment_changed` too. (2) `--open-inventory` did
not wait for the area, so with `--new-game` it drew over the title screen. Third flag to need that
wait after `--open-menu` and `--flag`, and gotcha 32's family again.

**One engine surprise worth the gotcha list.** `Array[StringName].sort()` DOES NOT SORT
ALPHABETICALLY — it orders by the StringName's internal handle. Two fixture ids came back reversed
and the only trace was one failing assertion. `Inventory.ids()` already sorted through `String` for
this reason, which is what made it findable in a minute; `equipped_ids()` now does the same.

**Files.** `src/gameplay/character/equipment.gd` (82 code lines) · `GameEnums.EquipSlot` ·
`ItemDefinition.equip_slot` and `is_equippable()` · `Events.equipment_changed`, plus `message_key`
on `interaction_refused` · `Interactable.refusal_key` with overrides in `gate.gd` and
`path_action_point.gd` · `interact_prompt.gd` preferring the authored line ·
`inventory_screen.gd` (rows equip, and redraw on equipment) · `--equip=` in `dev_stage.gd` and the
`--open-inventory` wait · `scenes/characters/player.tscn` gains an `Equipment` node ·
`data/items/brass_lantern.tres` plus a pickup and an equip-gated `Gate` in the courtyard and 6 CSV
rows · `tests/unit/equipment_test.gd` (70 outcomes) · three equippable fixture items and an
`equip_slot` parameter on `FixtureContent.item()` · `docs/AUTHORING.md` § Make an item equippable.
1149 → **1224** (70 here, and 5 that `docs_test.gd` computed from the new worked example).

**`items_test.gd`'s hard-coded `3` became `FixtureContent.items().size()`**, on the same reasoning
as a computed plan: adding a fixture must not mean editing a number somewhere else.

**PROVED RED, THEN GREEN — both, with the real failure shape (gotcha 23).** (1) The gate's
`locked_key` misspelled by one letter in the authored scene: `check_content` exits 1 with
`courtyard.tscn:369 localization key 'object.gate.arch.lockd' is not in the CSV`; reverted, exit 0.
(2) The load-bearing invariant broken the way it would really break — `equip()` made to remove the
item from the bag: the suite exits 1, `1201 passed, 18 failed`, first failure
*"it is still carried — expected true, got false"*; reverted, `1219 passed, 0 failed`, exit 0.

**The input path was proved by a temporary probe and the probe was removed** (gotcha 15). Run
windowed: `PROBE focus='@Button@26' held=[]` → press → `held=[&"item/brass_lantern"]` → press again
→ `held=[]`. `git diff src/systems/debug/` carries only `--equip` and the `--open-inventory` wait.

**Three windowed captures at midday, LOOKED AT and READ rather than glanced at** (gotcha 28 — a
screen that merely looks fine is not evidence). The satchel showing
`Brass Lantern  x1   [in hand]` under *Tools* beside an unmarked `Rose Petal  x2` under *Materials*
— the discriminating pair, since a marker glued onto every row would look identical on one item.
The arch refusing with *"It is pitch dark beyond the arch, and you have no light in hand."* while
the lantern sits in the bag. And the same arch, same camera, same hour, one `--equip` different:
the blocker slab GONE and *"Lantern raised, the dark under the arch gives way."* up.
**The `Button` styleboxes were left unpopulated again** — the satchel's rows are legible against
the shipped dark palette, so it did not force the decision either.

**Deferred, with reasons, not silently.**
- **A quest step still cannot read an ITEM COUNT**, and equipment did not make it cheaper. Being
  HELD is a fact about one item, which is what a flag is; holding THREE OF something is a count,
  and both ways to expose it are real design decisions rather than an afternoon: an `Inventory`
  that mirrored `count/<item>` into `Flags` would write every carried item into the flag section
  as well as its own, and a `QuestStep` that read the bag directly would put `gameplay/Inventory`
  inside a `systems` tracker against the layer rule. It is **T3.3** on the board now rather than a
  line in three documents.
- **Attributes and footsteps** are `09b`, and the reason is stated there rather than here.
- No equipment SCREEN — the satchel is where equipping happens, and a second window listing five
  slots with one thing in them would be a UI for content that does not exist.
- No stat effect from equipment: nothing reads a stat yet, which is `09b`'s problem.
- Combat is still not a thing. `EquipSlot` has no weapon and no armour value and will not get one.

**Ladder, all green.** `--headless --import` with **zero** `SCRIPT ERROR` / `Parse Error` lines;
boot `0 warnings, 0 errors`; suite **1224 passed, 0 failed, 0 skipped**, exit 0; `check_budgets`,
`check_content` and `check_boundary` all exit 0 — and `check_boundary` derives
`item/brass_lantern` and `brass_lantern` as demo names and finds neither in `src/` or `tests/`.

**CI green, run 33095187525, job logs read rather than the tick.** Full checkout **1224 passed, 0
failed, 0 skipped** with `quests: 1` in `check_content`; stripped template **1169 passed, 0 failed,
16 skipped** with `quests: 0` — the equipment case runs in BOTH, because it is fixtures all the way
down and skips nothing. All three checkers PASS in both jobs. The push run (33095176524) and the
pull-request run (33095253385) are green too.

**Commit:** `1b3d799` on `claude/wp-09-character`, PR #17 — stacked onto `claude/wp-08-quests`
(#16) rather than `main`, matching the rest of the chain.

---

## WP-09b · Character depth — attributes and surfaces — **DONE**

The two thirds of the original WP-09 row that were split out. Both are real; neither had a consumer
the way equipment did, and that is the whole reason they went second.

**Read:** `src/gameplay/character/player_controller.gd`, `src/gameplay/character/standing.gd` (the
namespace-over-Flags shape), `src/gameplay/character/equipment.gd` (the same shape, applied),
`src/systems/audio/audio_director.gd`, `src/gameplay/world/surface_wetness.gd` (something already
walks every material in an area), `src/core/util/layers.gd`.
**Write:** an attribute container where adding an attribute is DATA, not code, and a decision
FIRST about what reads one; surface tagging on area geometry, and footsteps that change with it.
**Exit criteria:** an attribute changes something observable and persists; the surface under the
player is reported correctly on at least two materials, and the step sound follows it.

**IT WAS TAKEN OVER T3.1 AND T3.3, AND THE REASON IS `TEMPLATE.md`'s REPLACEMENT RULE.** T3.1 is a
refactor of five copies of one scan — genuinely worth doing, and it changes nothing a consuming
game can observe. T3.3 is depth in a system that already has a proof. This row was the last one
in the catalogue holding TWO systems with no implementation at all, so it is the only one of the
three that is breadth rather than polish. T3.1 remains the strongest of the two that are left, and
its arithmetic is unchanged: still five copies, still five places to fix one scan bug.

**THE FIRST QUESTION WAS "WHAT READS ONE", AND IT WAS ANSWERED BEFORE ANYTHING WAS WRITTEN.** The
row said so and it was the right instruction: 17 of the 23 settings have no consumer, and WP-09
found `Gate.locked_key` and `PathAction.refusal_key` declared, validated by a content gate and read
by nothing for six packages. So `Attributes` ships with EXACTLY ONE consumer,
`PlayerController.current_speed()`, and two structural decisions exist to stop that number growing
silently:

1. **There is no registry, no `AttributeDef` and no enum of names.** Any StringName is an attribute
   the moment something writes it, so declaring the fiftieth costs no code — ADR-0006's test met
   with no sixth directory scan, which `area_db.gd`'s header explicitly warns against.
2. **An attribute's NAME is a const on its consumer, never on the container.**
   `PlayerController.PACE` sits beside the line that reads it. So an attribute nobody reads has
   *nowhere to be written down*, and `attributes.gd` cannot accumulate a table of good intentions.
   That is the whole of the design: a rule about where a name lives, not a mechanism.

**A FIFTH NAMESPACE OVER `Flags`, AND IT WAS REACHED FOR FIRST, AS WP-11 SAID TO.** `attr/<who>/<name>`
after `obj/<area>/<object>/<field>`, `standing/<who>`, `equip/<wearer>/<item>` and `map/<area>`.
Same three consequences, asserted rather than assumed: already saved with no register, version or
migration; already cleared by a new game; already announced on `flag_changed`, so a quest step can
test an attribute today. Same stated cost, too: the key contains a character id, so renaming a
carrier resets its attributes on an old save.

**A VALUE IS A STEP, NOT THE NUMBER.** Clamped to ±4, worth 0.125 of the base each, so the tuned
`walk_speed = 3.2` in `player_controller.gd` stays the truth and a save file never contains a
walk speed. `Standing`'s clamp for `Standing`'s reason — the ceiling is the design.

**A SURFACE IS ONE METADATA KEY, INHERITED FROM THE NEAREST TAGGED ANCESTOR.** `metadata/surface`
on a body, or on anything above it. The alternatives were a component per floor tile (a node per
tile), a group (one flat namespace shared with `navmesh_source`, where a typo becomes a second
surface silently) and an enum (**a list of surface names in `src/`, which `check_boundary` fails
the build over**). Inheritance is what makes it cheap: the courtyard tags `Terrain` once and
overrides the two floors that differ, and the third surface the probe reported was the inherited
one.

**A STEP'S SOUND IS DERIVED FROM THE SURFACE'S NAME.** Not looked up in a table, because a table
mapping a name to a timbre is the same boundary violation as the enum, and it would mean a game
that authors `sand` gets silence until someone edits `src/`. Two axes, brightness and decay,
derived from two salted hashes of the name. Art is deferred and audio is art, so the burst is
generated exactly the way `AmbienceBed` generates its rain, and `stream_for()` is the one function
a game with real recordings replaces.

**THE PROBE FOUND A DEFECT THAT NOTHING ELSE COULD HAVE, AND IT IS GOTCHA 2 WITH A SPEAKER ON IT.**
The first windowed run reported `playing=true` on all three surfaces with every rung green — and
grass came out at brightness 0.452 against stone's 0.446, which is *the same sound*. The cause is
that **`String.hash()` mixes its low bits weakly**: `"grass"` hashes to 260508453 and `"stone"` to
274826446, wildly different numbers whose last three digits are 453 and 446, so `hash() % 1000`
clusters short names of similar length. A step that plays is not a step that *follows*. Fixed with
an avalanche in `_spread` — one multiply and two shifts — which moves the same pair to 796 and 572,
and the regression assertion demands a MARGIN rather than mere inequality, because inequality is
exactly what the broken version passed. New gotcha 36.

**WHAT IS ASSERTED AND WHAT IS QUOTED, SAID OUT LOUD RATHER THAN IMPLIED.** A footstep is the one
claim this ladder cannot see at all: not visual, so no capture reads it; not synchronous, so no
assertion reaches it; and headless the audio driver is `Dummy`, where every `play()` leaks
(gotcha 20). So the file is split the way `SurfaceWetness` split for drying. Assertable and
asserted: `travel()` (the stride accumulator, remainder CARRIED), `GroundSurface.of_node()` (the
walk up the tree) and `brightness_for()` / `decay_for()` (pure functions of a name). Quoted from a
windowed run: the raycast, the frame loop and the `play()`.

**THE ATTRIBUTE NEEDED NO NEW STAGING FLAG**, which is the namespace paying for itself a fifth
time. `--flag=attr/player/pace:4` already works, already waits for the area (gotcha 32's fix), and
already goes through `_settle_stable` (gotcha 35). `dev_stage.gd` stayed at 247 of its 250 lines
and did not have to split.

**Files.** `src/gameplay/character/attributes.gd` (21 code lines) ·
`src/gameplay/world/ground_surface.gd` (26) · `src/gameplay/character/footsteps.gd` (115) ·
`PlayerController.character_id`, `PlayerController.PACE` and `current_speed()` made public ·
a `Footsteps` node in `player.tscn` · three `metadata/surface` tags in `courtyard.tscn` and one in
`lantern_hall.tscn` · `tests/unit/character_depth_test.gd` (56 outcomes) ·
`docs/AUTHORING.md` § Tag the ground you walk on. No new signal, no new autoload, no new registry,
no new CSV row — there is no player-facing text in either system.
1298 → **1355**.

**PROVED RED, THEN GREEN — three times, each with the real failure shape (gotcha 23).**
(1) `const HOME_GROUND := &"courtyard"` in `footsteps.gd`: `check_boundary` exits 1 with
`res://src/gameplay/character/footsteps.gd:54 names demo content 'courtyard' (from
res://data/areas/courtyard.tres)`; reverted, exit 0.
(2) The consumer broken the way it would really break — `current_speed()` made to return the gait
speed and ignore the attribute, which is precisely the declared-and-unread failure this package
exists to avoid: the suite exits 1 with `1352 passed, 3 failed`, naming *"a raised pace is
measurably faster — expected true, got false"*; reverted, `1355 passed, 0 failed`, exit 0.
(3) The inheritance walk stopped after one node — the break that would silently lose the demo's
third surface: exits 1 with *"an untagged body inherits from the root — expected fixture_hard,
got "*; reverted, exit 0.

**The probe was temporary and was removed** (gotcha 15). Run windowed, `git diff
src/systems/debug/` empty afterwards:
```
PROBE audible=true driver=WASAPI
PROBE at (4.0, 0.2, 4.0)    grounded=true surface='grass' brightness=0.733 decay=2.13 playing=true steps=1
PROBE at (0.0, 0.6, -2.0)   grounded=true surface='wood'  brightness=0.841 decay=4.68 playing=true steps=2
PROBE at (-8.5, 3.4, -2.5)  grounded=true surface='stone' brightness=0.550 decay=3.02 playing=true steps=3
PROBE pace=0 speed=3.200 moved=2.861 m in 60 frames, steps=4
PROBE pace=4 speed=4.800 moved=4.687 m in 60 frames, steps=7
```
The first three are the surface criterion: grass and wood from their own tags, stone INHERITED from
`Terrain`. The last two are the attribute criterion, driven by real `MOVE_UP` input over the same
60 physics frames — 2.861 m against 4.687 m, and 4 steps against 7, because a faster walk covers a
stride sooner.

**One windowed capture, LOOKED AT** — the courtyard at 12:00 after the metadata edits, confirming
the three tagged materials are the three the player actually walks on and that nothing about the
scene moved: grass underfoot, the wood dais with the keeper beside it, stone pillars and the back
wall. `build/shots/wp09b_courtyard.png`.

**WHAT WAS NOT BUILT, AND SAID RATHER THAN DROPPED.** No footstep PARTICLES — the inventory row
asked for "step audio and particles", and `Footsteps.current_surface()` is the hook a puff would
listen to, which is why it is a query and not a signal (nothing needs a signal yet). No second
attribute, and no consumer for one: that is the rule, not an omission. No character sheet screen,
no attribute that gates an interaction, and no surface that costs anything to cross — a slow
surface is a `PlayerController` change and belongs with whoever wants one.

**Commit:** `da126d9` on `claude/wp-09b-attributes`, PR #19 — stacked onto `claude/wp-11-worldmap`
(#18) rather than `main`, matching the rest of the chain.

---

## WP-10 · Crafting and gathering

**Read:** `src/content/items/`, `src/gameplay/interactables/pickup.gd`,
`src/gameplay/character/inventory.gd`, `src/systems/world_clock/clock.gd`.
**Write:** harvestables with a regrowth timer keyed to the clock, and recipes as content data.
**Exit criteria:** gather, wait, it regrows; craft, and the recipe consumes and produces
correctly; all persisted.

---

## WP-11 · World map and fast travel — **DONE**

**Read:** `src/systems/scene_director/director.gd`, `src/gameplay/world/area_root.gd`, WP-02/03.
**Write:** an `AreaDef` content resource, a region map with discovery, travel points.
**Exit criteria:** discover an area, travel to it, discovery persists.

**IT WAS TAKEN OVER T3.1, T3.3 AND WP-09b DELIBERATELY**, and the reason is the one that put
WP-08 first: this was the last system in the catalogue with NO PROOF AT ALL, and `TEMPLATE.md`'s
replacement rule is breadth of systems with one shallow proof each. The three alternatives are
all real and all narrower — a refactor, a gap in an existing system, and half of a split row —
and each of them improves something that already works. This built the last thing that did not.

**DISCOVERY IS A FLAG, AND IT OWNS NO STORE.** A known area is:

```
map/<area id>                        map/lantern_hall
```

which is `PersistentState`'s `obj/<area>/<object>/<field>`, `Standing`'s `standing/<who>` and
`Equipment`'s `equip/<wearer>/<item>` applied to a FOURTH case. **WP-09's section said to copy
this shape and it copied cleanly**, which is now three independent systems on one namespace
convention rather than two and a coincidence. The same three consequences, and they are the whole
argument against a discovery store with a save section:

1. **It is already saved.** No `SaveSystem.register`, no version, no migration, and a new game
   clears it for free. That is what makes "discovery persists across a save and a reload,
   including from the far side of an area that is no longer loaded" true with no code at all: the
   flag never lived in the area.
2. **Anything can reveal a place with no code.** `--flag=map/lantern_hall:true` is the second
   capture, and a `DialogueChoice` effect, a `TriggerVolume` or a `Lever` writes exactly the same
   key. Nothing was touched to make that work. The key runs the other way too: a `Gate` with
   `requires_flag = &"map/<id>"` is a road that opens once you know where it goes.
3. **It is announced already.** `flag_changed` fires, so a quest step testing "have you found the
   orchard" works today.

The cost is stated: the key contains an area id, so renaming an area's folder makes an old save
forget it was found. Same price `Equipment` pays for an item id, and smaller than the
alternative, which writes the same id into a save section of its own anyway.

**THE MAP SCREEN NAMES NO AREA AND NO POSITION, WHICH IS WHAT THE BOUNDARY GATE WOULD HAVE
CAUGHT.** Every dot is drawn at the `map_position` its own `.tres` declares, in normalised 0..1
space so the same authored number is right at every window size. Proved by planting
`const HOME := &"courtyard"` in `map_screen.gd`: `check_boundary` exits 1 naming the file, the
line and `res://data/areas/courtyard.tres` as the source — the gate derives area ids from the new
registry as well as from `scenes/areas/`.

**TRAVEL ASKS AND DOES NOTHING ELSE.** `WorldMap.travel_to` emits `Events.area_change_requested`
and stops, exactly as `AreaDoor` does, so `Director` still owns every transition and its guard.
Four refusals, each logged rather than silent: not on the map, not found, already there, already
moving. The headline assertion is the one `transitions_test` makes about a door — one request,
naming the area and the AUTHORED arrival spawn, with the player unmoved and nothing loaded.

**A FIFTH REGISTRY, AND IT IS EVIDENCE FOR T3.1 RATHER THAN AGAINST IT.** `AreaDb` is the fifth
copy of the same thirty lines of scan-and-validate. WP-08 reconsidered and kept the fourth copy
with reasons that have not changed — GDScript has no generics, so a shared base could only cache
`Resource` and hand it back untyped. What changed is the arithmetic: five copies is five places
to fix a scan bug, and `area_db.gd`'s header says so and points at the board row.

**THE ID HAS NO PREFIX**, unlike `item/` and `quest/`. Those prefixes make a save file
self-describing about things that live only in a save file; an area id is already a public
identifier, because it is a folder name. A `map/orchard` id would have put a translation table
between `AreaDb` and `Director`, and a translation table is a second place the truth lives.

**WHAT A "TRAVEL POINT" TURNED OUT TO BE.** The row asked for one. The arrival point is authored —
`AreaDef.arrival_spawn`, and the suite fails if it names a marker no area has. A DEPARTURE point,
a kiosk you must stand at to fast travel, is a game's policy rather than the template's: it is a
restriction on a mechanism, it needs content the demo does not have, and it would be one
interactable emitting a request the map screen already emits. Not built, and said rather than
quietly dropped.

**TWO GAPS FOUND IN OTHER PEOPLE'S WORK, both one line.** `journal_screen.gd` was never added to
`art_contract_test.gd`'s `STYLED_SCREENS`, whose own comment says "a sixth screen belongs on this
list" — so the regression gate that stops a colour being written down again could not see the
journal at all. Both it and the map are on the list now. And `docs/NEW_GAME.md` never listed
`data/quests/`; it now lists that and `data/areas/`.

**ONE NEW PALETTE ENTRY, AND IT IS THE FIRST SINCE T2.1 WROTE THE FILE.** An undiscovered marker
has to be VISIBLE and clearly lesser, and `dim` is a translucent black that would have drawn
nothing against the plate. `UiPalette/colors/muted`, one line in `ui_theme.tres`, and the screen
reads it by name — the seam working exactly as T2.1 said it would. **The `Button` styleboxes were
left unpopulated for the fourth time**: the map's markers are Buttons over an opaque plate and are
legible against the shipped dark palette, so this screen did not force the decision either.

**A STAGING RACE, FOUND BY THE THIRD CAPTURE AND FIXED WITH GOTCHA 21's SHAPE.** `--goto` and
`--open-menu` both begin by waiting for the first area, so they come out of that wait on the same
frame: if the menu opens first, the travel `--goto` is about to request unwinds it, and the
capture is of nothing with every rung green. A fixed number of extra frames only moves the race.
`dev_stage._settle_stable(20)` requires twenty CONSECUTIVE settled frames and resets its count
the moment a transition starts, which cannot be won early. Fourth staging flag to need a wait,
and the first to need a persistent one.

**Files.** `src/content/world/area_def.gd` (16 code lines) · `src/content/world/area_db.gd` (61) ·
`src/systems/world_map/world_map.gd` (67) · `src/ui/screens/map_screen.gd` (153) ·
`Events.area_discovered` · `ScreenKeys.toggle_map` and `MapScreen` in `menu_for` ·
`AreaDb` in `CatalogueReport` and in `Fixtures` · `_check_areas` in `check_content` ·
`_settle_stable` in `dev_stage.gd` · `UiPalette/colors/muted` · a `WorldMap` node in
`game_root.tscn` · `data/areas/courtyard.tres` and `data/areas/lantern_hall.tres` plus 6 CSV rows ·
`tests/unit/world_map_test.gd` (59 outcomes) · two fixture `AreaDef`s ·
`docs/AUTHORING.md` § Put an area on the world map.
1224 → **1298** (59 here, 2 in `export_test` for the fifth catalogue line, 4 in
`art_contract_test` for the two screens added to `STYLED_SCREENS`, and 9 that `docs_test.gd`
COMPUTED from the new worked example in `AUTHORING.md`).

**PROVED RED, THEN GREEN — three times, each with the real failure shape (gotcha 23).**
(1) An `AreaDef`'s `name_key` misspelled by one letter: `check_content` exits 1 with
`lantern_hall name_key 'area.lantern_hall.nam' is not in the CSV`; reverted, exit 0.
(2) The load-bearing invariant broken the way it would really break — `discover()` made to keep a
`Dictionary` instead of writing the flag: the suite exits 1 with `1288 passed, 10 failed`, first
failure *"and the whole of that is one flag — expected true, got false"*, plus the ErrorWatch
catching an out-of-bounds read in a block that never got its signal and the plan reporting
`planned 59 outcomes and produced 57`. All three mechanisms fired on one break; reverted,
`1298 passed, 0 failed`, exit 0.
(3) `const HOME := &"courtyard"` in `map_screen.gd`: `check_boundary` exits 1 with
`res://src/ui/screens/map_screen.gd:33 names demo content 'courtyard' (from
res://data/areas/courtyard.tres)`; reverted, exit 0.

**The input path was proved by a temporary probe and the probe was removed** (gotcha 15). Run
windowed: `PROBE after M: top=map depth=1` → `PROBE focus='@Button@27' text='Lantern Hall'` →
`PROBE after M again: top=NOTHING depth=0` → M, then Enter →
`[map] Travelling to 'lantern_hall' (spawn 'from_courtyard')` →
`PROBE after Enter: area=lantern_hall depth=0`. The stack unwound itself on the travel, which is
why `MapScreen` does not close itself. `git diff src/systems/debug/dev_capture.gd` is empty.

**Three windowed captures at midday, LOOKED AT and READ rather than glanced at** (gotcha 28 — a
map with the wrong area marked still looks like a map). All three at 960x540, `--new-game`,
`--shot-frame=100`, `--time=12:00 --freeze-time`.

1. `--open-menu=map`: a large WHITE dot low on the plate reading *"Rose Courtyard · you are
   here"*, and a small GREY dot above it reading *"???"*. The DISCRIMINATING pair — an
   undiscovered place drawn differently from a discovered one in the same shot, which a map whose
   dots all looked alike could not show.
2. `--flag=map/lantern_hall:true --open-menu=map`: same camera, same hour, ONE FLAG different.
   The grey `???` is now a GOLD dot reading *"Lantern Hall"* with the focus ring on it, and the
   courtyard marker has not moved or changed. That is the seam photographed: a flag written from
   outside put a place on the map.
3. `--goto=lantern_hall --open-menu=map`: the two states have SWAPPED. Lantern Hall is the white
   *"you are here"* marker, Rose Courtyard is the gold selectable one — **from the far side of an
   area that is no longer loaded**, over the hall's warm interior rather than the courtyard's
   daylight, which is how the shot also proves the travel really happened.

**Ladder, all green.** `--headless --import` with **zero** `SCRIPT ERROR` / `Parse Error` lines;
boot `0 warnings, 0 errors` with `areas: 2 found in res://data/areas` and `World map ready over 2
mapped area(s)`; suite **1298 passed, 0 failed, 0 skipped**, exit 0; `check_budgets`,
`check_content` and `check_boundary` all exit 0. A stripped template, built by hand the way the CI
job builds it, ran **1230 passed, 0 failed, 19 skipped**, exit 0, with all three checkers passing
and `mapped areas: 0` — the map case skips exactly one assertion there and says which.

**Deferred, with reasons, not silently.**
- **A departure-side travel point**, for the reason above: it is a restriction on a mechanism,
  and it is a game's policy rather than the template's.
- **Objective markers on the map.** `Events.quest_advanced` has an emitter as of WP-08 and
  `MapScreen` already redraws on facts, so this is a listener and one more marker state — but it
  is a second system's proof on this package's screen, and the board has a row for it.
- Fog of war, zoom and pan, custom map art, travel costs, travel time, mounts. Art is deferred
  indefinitely, so a map drawn from a `ColorRect` per place is the map this template ships.
- **A second region or a third area.** `TEMPLATE.md` is explicit: two areas is what the demo has
  and two areas is enough. A third would be the retracted rule winning an argument.
- Combat is still not a thing.

**CI green, run 33262997072, job logs read rather than the tick.** Full checkout **1298 passed, 0
failed, 0 skipped** with `quests: 1` and `mapped areas: 2` in `check_content`; stripped template
**1230 passed, 0 failed, 19 skipped** with `quests: 0` and `mapped areas: 0`. Every rung green in
both jobs, and both numbers match the local runs exactly.

**Commit:** `cf3f3a1` on `claude/wp-11-worldmap`, PR #18 — stacked onto
`claude/wp-09-character` (#17) rather than `main`, matching the rest of the chain.

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

## WP-14 · Dev tools and hardening — **DONE (the hardening half)**

**Read:** `tools/`, `src/systems/debug/dev_capture.gd`, `tests/`.

**The row as written, and what changed about it.** It asked for four things: an in-game debug
console, a performance overlay, "a smoke test that drives **the whole demo** through public APIs",
and the hard-coded-string audit. Two of those were re-framed or split before any code was written,
both in this commit, and neither quietly.

### The re-framing: a smoke test drives A GAME, not THE DEMO.

"Drives the whole demo" would have put `courtyard`, `keeper` and `rose_key` into a permanent gate
on the ladder. That is precisely the coupling `tools/check_boundary.gd` exists to prevent, arriving
through the back door of a test — and the gate would in fact have caught it, because
`check_boundary` has scanned `tests/unit/` since T1.3. T1.3 spent an entire package unwelding the
suite from the demo, and a smoke test written to the row's letter would have grown that welding
straight back, with "end to end" as the excuse. `TEMPLATE.md` and `TESTING.md` both already say a
test builds its own content.

So `tests/unit/smoke_test.gd` composes its session from `tests/framework/fixtures.gd` and names no
content at all. Its ONE game-shaped block asserts that `GameConfig.first_area()` resolves to a real
scene — never what that area is called — and `skip`s, counted, in a checkout with no game in it.

**And "end to end" cannot mean what it sounds like, for a reason the row could not have known.**
`TestCase.run()` is synchronous (TESTING.md rule 2), so no assertion can await a frame, a threaded
load or a keypress — a smoke test here cannot travel between areas or press a button. What it can
be, and is, is the CHAIN: a run begins and empties the bag, a flag written starts a quest, items
gathered publish their counts, a counted objective notices, something is picked up and put in hand,
time is skipped, and the whole session is saved, wiped and restored with the quest still settled.
Every one of those seams has its own case already; **this asserts that they compose**, which is the
one thing a per-system case cannot see.

### The split: the row named four things, which is over the size limit.

Same reasoning that split WP-09, and the row's own title was the seam. **Hardening** — the two
gates and the shutdown fix — shipped here. **Dev tools** — the console and the overlay, both UI
surfaces needing a screen, an action binding, localization keys and a windowed capture each — are
the new **WP-14b** row. Building all four would have been four half-finished things, which is the
outcome the 8-file limit exists to prevent.

### `Director` now drains its own loader thread, and the payoff was not the predicted one.

The defect was real and reproduced at five frame counts (`--new-game --quit-after 8/12/16/20/25`):
quitting while a threaded load was in flight tore the loader thread down inside the text parser,
which then printed **`Parse Error` for files that parse perfectly** — `courtyard.tscn`,
`wood.tres`, `gate.tscn` — plus leaked RIDs and 10-19 leaked ObjectDB instances, *after* the run
had already logged `0 warnings, 0 errors`. **Gotcha 22 with the polarity reversed:** not an error a
rung cannot see, but a FALSE error poisoning the `Parse Error` grep that rung 2 uses as this
project's compile check.

**Its real cost was a permanently weakened gate, and that is the finding.** CI's rung 3 read only
the LAST LINE of its boot log, carrying a comment that said a whole-log grep "would be a flake
generator" — so the single most load-bearing check on the ladder was switched off on that rung, on
purpose, correctly, for as long as the defect lived. A live defect had bought itself a hole in the
gate that would have caught its relatives. That generalises, and is now gotcha 41.

The fix is `Director._exit_tree()`. **There is no cancel** — checked against `--doctool`, which
gives `load_threaded_request`, `load_threaded_get_status` and `load_threaded_get` and nothing that
abandons a request — so the only clean end is to WAIT, and `load_threaded_get()` blocking is
undocumented in the dump and therefore **measured**: 118-197ms for the demo's larger area, paid
once, on the way out. `NOTIFICATION_EXIT_TREE` was measured too, rather than assumed: with a load
in flight it arrives *before* the session's own closing log line, `NOTIFICATION_PREDELETE` arrives
after it, and `NOTIFICATION_WM_CLOSE_REQUEST` never arrives at all, because headless has no window.
After the fix: **zero parse errors, zero RID leaks, zero ObjectDB leaks at all five frame counts.**
CI's rung 3 now greps its whole log — a STRONGER rung, not a faster one, and the distinction
matters because editing a workflow to make a rung pass is forbidden and this is the opposite.

**The row predicted the fix would let the boot timeout drop, and it does — but not for the row's
reason, which was stale rather than merely incomplete.** Gotcha 13 said 120 frames were needed
because the boot raced a threaded load. Gotcha 31 says a plain boot stops at the MAIN MENU and
never enters an area, so it was never racing anything; gotcha 13 was written before WP-12 added the
menu and had been wrong ever since. **Measured, and this is the control:** `--quit-after 30` and
`--quit-after 120` produce byte-identical logs — 29 lines each, same content, both
`0 warnings, 0 errors`, and both were already clean *before* the fix. So the local boot rung is
now 30, justified by the measurement rather than by the fix; CI keeps 300, because a shared runner
is slower, a headless frame costs milliseconds, and a rung that quits before the boot finishes
would report clean about work it never did. Gotcha 13 is rewritten to say all of this.

### The string audit, and why it is NOT the tool `check_content.gd` refused.

`check_content.gd`'s header already turned down a general hard-coded-string audit, in writing, and
that refusal is correct: *"telling a player-facing literal from a log message or a flag key needs
semantics a text scan does not have, and a partial tool that looks complete is how 409 passing
checks happened."* Nothing in a line of text says whether `"world"` is a log category, a flag
namespace or a sentence for a player.

So `tools/check_strings.gd` never inspects a literal and guesses. Both its checks are anchored at a
**sink** or a **declaration**, where the semantics are structural:

1. **The sink rule.** The right-hand side of a `.text` / `.tooltip_text` / `.placeholder_text` /
   `.title` assignment either passes through `tr()` or contains no string literal at all. Whatever
   reaches `.text` is on screen *by construction*, whatever it contains — so no opinion about any
   individual string is needed. `label.text = text_value` passes on holding no literal;
   `button.text = tr(A if held else B).format({"item": x})` passes on the `tr()`, which is what
   makes the `.format()` dictionary key harmless rather than something the scan must parse. All
   four property names verified against `--doctool` for 4.7.2, and matched with a trailing `" = "`
   so `text_direction` and `text_overrun_behavior` — enums, not text — are not swept in.
2. **The key rule, and this is the half with teeth.** Every `*_KEY` const under `src/` names a real
   row in `strings.csv`. **71 of them, and nothing had ever checked one:** `check_content` validates
   the keys authored in `.tres` content, and `items_test.gd`'s enum loop covers the two COMPUTED
   families (`verb.*`, `refusal.*`). A const key sat in neither. `*_PREFIX` deliberately does not
   qualify — a prefix is completed at runtime — and a key holding `%` is a pattern the scan cannot
   follow, so it is COUNTED AND PRINTED rather than silently skipped, on `check_boundary`'s
   precedent. There is exactly one: `weather.%s`.

**The second rule closes a hole that was measurably live.** With `notify.item_takne` planted — one
transposition in the toast every pickup and every chest shows — `check_content` **PASSED**,
`check_boundary` **PASSED**, and all **1,517 assertions PASSED**. tr() returning its own argument
is not an error, so the player would simply have read `notify.item_takne` on screen forever. That
is this project's founding failure mode, still live at 1,517 assertions, found by building the gate
that looks for it.

### Both gates proved red with the real violation, and one plant caught the TEST.

Gotcha 23, and it earned its keep twice.

- **Sink rule.** `label.text = "No items"` planted in `inventory_screen.gd:228`:
  `!! res://src/ui/screens/inventory_screen.gd:228 assigns a literal to .text with no tr(): "No items"`,
  `FAIL — 1 string violation(s)`, exit **1**. Removed → `PASS`, exit 0.
- **Key rule.** `notify.item_taken` → `notify.item_takne` in `pickup.gd:24`:
  `!! res://src/gameplay/interactables/pickup.gd:24 TAKEN_KEY = 'notify.item_takne' has no row in res://localization/strings.csv`,
  exit **1**. Removed → `PASS`, exit 0. This is the plant that was also run against the rest of the
  ladder, with the result quoted above.
- **The smoke test**, planted by deleting `Inventory`'s `game_started` subscription — the real way
  a new game would stop emptying the bag: four of its assertions went red and cascaded down the
  chain exactly as a smoke test should, `1539 passed, 1 failed`, exit 1. Restored →
  `1540 passed, 0 failed`.

**And the third plant found a defect in the new test rather than in the code.** The smoke test's
save/load block carried a comment claiming it asserted the save-participant ORDER — T3.3's
invariant, that a derived count must be republished on `game_loaded` because `Flags._apply_save`
wipes the store from underneath it. Deleting that subscription, which is exactly how the invariant
would really be lost, left the assertion **GREEN**: the test's own wipe happens to let
`_apply_save` publish for itself, so the ordering never came into play. The assertion was true and
the comment above it was not, and **no failure could ever have shown the difference.** The comment
now states the weaker claim, which is the true one, and points at `item_count_test.gd`, which did
go red on that plant. This is T3.2's framing gate (gotcha 40) in a second costume and is now gotcha
42: plant the real violation even when the assertion looks obvious — *especially* then, because the
thing being tested is the test.

### One budget was RAISED rather than a file split, and that is a first.

`director.gd` has a per-file override of 180 — a self-imposed tightening, 70 below the 250 default,
because "an autoload that owns one concern does not need 250 lines". It was at 176, and the drain
took it to 187. `check_budgets.gd` offers two remedies, "split the file, or justify a new budget",
and the split was the wrong one: the drain has to sit with the code that owns the loader thread,
and `Director`'s entire header is an argument for *one owner, one guarded path*. Carving up the
project's single transition path to save seven lines would trade real safety for a number. Raised
to **190**, with the reasoning in `docs/ARCHITECTURE.md` § Line budgets and at the override itself.
**What keeps this from being a slippery slope: 190 is not above the default.** Going over 250 still
means split.

The restructure that came with it is worth keeping on its own merits: `_load_area_scene` now sets
and clears `_in_flight` in ONE place and delegates the polling loop to `_await_load`, so the
invariant `_exit_tree()` depends on reads off a single function instead of four exit paths.

### Files: 12, and new code is 191 lines added against 6 removed.

`tools/check_strings.gd` (110 code lines, new) · `tests/unit/smoke_test.gd` (74 code lines, new) ·
`src/systems/scene_director/director.gd` (`_in_flight`, `_await_load`, `_exit_tree`) ·
`tools/check_budgets.gd` (the raised override and its reason) · `tests/test_runner.gd` (the CASES
entry) · `.github/workflows/ladder.yml` (rung 8 in both jobs, and rung 3's whole-log grep) ·
`CLAUDE.md` · `docs/CONTEXT.md` · `docs/ARCHITECTURE.md` · `docs/WORK_PACKAGES.md` ·
`docs/ROADMAP.md` · `docs/SYSTEMS_INVENTORY.md`. 1,517 → **1,543**.

**The suite total moved by more than the 23 assertions this package wrote**, and that is expected
rather than absorbed: `docs_test.gd` COMPUTES its plan from the documents, asserting that every
`res://` path they name exists, so adding `tools/check_strings.gd` and `tests/unit/smoke_test.gd`
to the ladder blocks in five documents adds assertions of its own. 23 from `smoke_test.gd` + 3 from
`docs_test.gd` = 26.

### Ladder, all green.

`--headless --import` with **zero** `SCRIPT ERROR` / `Parse Error` lines; boot at the new
`--quit-after 30` ending `0 warnings, 0 errors`; suite **1543 passed, 0 failed, 0 skipped**, exit
0; `check_budgets` **130 files, 11,338 code lines, 0 warnings, 0 violations**; `check_content`
PASS; `check_boundary` PASS; `check_strings` PASS over 93 engine scripts, 216 CSV rows, 71 key
declarations checked and 1 pattern reported.

**Stripped template, run locally** — `--headless --path <copy>` over a tree with `.git`, `.godot`,
`data/` and `scenes/areas/` removed: **1469 passed, 0 failed, 25 skipped** (was 1445/0/23), all
four checkers exit 0, import clean.

**THE ONE NEW SKIP IS NAMED AND COUNTED:** `smoke_test: a game in this checkout can be started
(no content — this is a stripped template) — 2 assertion(s) not run`. That is the whole of the
+2, and it is the right block to be the only one: it is the single place this package asserts
something about *a game* rather than about the engine. The outcome arithmetic reconciles exactly —
1494 outcomes against 1468 before, so +26 = 23 from `smoke_test.gd` (21 run, 2 skipped) + 3 from
`docs_test.gd`'s computed plan.

**`check_strings` reports byte-identical numbers stripped and full** — 216 CSV rows, 93 engine
scripts, 19 sinks, 71 key declarations, 1 pattern. That is the result to want rather than a
coincidence: both rules are about `src/` and `localization/`, neither of which the strip touches,
so any drift in those numbers would mean an engine string had come to depend on a game being
present. CI asserts the same thing by running rung 8 in both jobs.

**No windowed capture, and the reason is that nothing here is visual.** A shutdown drain, a text
scanner and a synchronous test have no pixels; claiming a capture proved any of them would be
theatre. The visual rung is unchanged and still owned by the packages that have something to show.
**No temporary probe either, and `git diff src/systems/debug/` is empty** — this package touches no
input path and no audio path, and the shutdown claim is proved by the engine's own output at five
frame counts rather than by a probe.

### Deferred, with reasons.

- **The debug console and the performance overlay** — WP-14b, above.
- **The sink rule cannot see four things**, and its header lists them rather than implying
  completeness: a literal reaching a sink through a variable assigned earlier; a sink outside
  `src/*.gd`, so a `.tscn` authoring `text = "Play"` is not scanned; a literal handed to
  `draw_string()` or `set_tooltip_text()`; and whether the key `tr()` received was the RIGHT key —
  a wrong key that exists renders the wrong sentence, which is gotcha 2's shape and not a
  text-scan problem.
- **The suite still cannot enter an area**, so the smoke test is a composed session and not a
  played one. Multi-frame scenarios remain *runs* in `dev_probes.gd`, per TESTING.md.
- **No CI export rung** and **no branch protection**, both unchanged from T2.0 and T1.4.
- Combat is still not a thing.

**CI green, run 33541171263, JOB LOGS read rather than the tick** (gotcha 26). Full checkout
**1543 passed, 0 failed, 0 skipped**; stripped template **1469 passed, 0 failed, 25 skipped** —
both identical to the local numbers. **Rung 8 ran in both jobs and reported identical figures** (93
engine scripts, 71 key declarations), which is the point of running it on a stripped tree. **Rung
3's new whole-log grep printed `Parse Error lines in boot.log: 0`** — the line that could not have
existed before this package. All seven rungs present in the full job and all six in the stripped
one. The run took 36 seconds, and per gotcha 26 that is a cached engine rather than evidence of a
skip: the rung logs show 1,543 assertions actually executed.

**Commit:** `975ff4b` on `claude/wp-14-hardening`, PR #23 — stacked onto
`claude/t3-2-art-seams` (#22) rather than `main`, matching the rest of the chain.

---

## WP-14b · Dev tools — debug console and performance overlay — **DONE**

**The half WP-14 split off** rather than half-finish four things, and the LAST row of Phase T3.
Neither of these is a gate; both are developer convenience, and both are UI.

**Read:** `src/systems/debug/dev_stage.gd`, `src/ui/root/ui_root.gd`, `src/ui/screens/`,
`src/systems/input/actions.gd`, `src/ui/hud/`, `localization/strings.csv`.

**Built:** a debug console (`goto`, `flag`, `time`, `give`) on F1, and a performance overlay on
F3. The three things WP-14 had already decided were taken as decided and are not re-argued below.

### The question the row asked first: CAN the console live under `src/ui/`? Yes, and it SHOULD.

The row's own test is whether any part of it wants a hard-coded area or item id. No part does — a
command takes its argument from whoever typed it, so `goto courtyard` is INPUT and not a literal.

What settled it was the stronger form of that argument rather than the permission.
`src/systems/debug/` is EXEMPT from `tools/check_boundary.gd`, and the exemption is justified only
because those files exist to drive the demo. Putting the console there would have bought it an
exemption it does not need and switched off the gate that should be watching it. Under
`src/ui/screens/` the console is policed exactly like the journal and the map, and it passes —
`check_boundary` scanned 127 engine scripts including this one and reported PASS.

**So the split is: the SURFACE is `src/ui/`, the VERBS are `src/systems/debug/`.** Everything that
would ever want to name content lives on the far side of `DevCommands`, which is in the exempt
directory where the rest of the harness already is.

### One parser, and the file it came out of was at exactly 250/250.

The row said the four commands already exist and to reuse them. They did — `--goto=`, `--flag=`
and `--give=` in `dev_stage.gd`, `--time=` in `dev_capture.gd` — and "reuse" was taken in its
strongest available sense rather than as a suggestion to copy the parsing shape.
`src/systems/debug/dev_commands.gd` now holds the four bodies, both argument parsers CALL them,
and the console calls them too. **What you type in the console is exactly what you pass on the
command line, argument for argument** — `time 18:40` is `--time=18:40`.

Each verb RETURNS its report instead of logging one, because a staging flag wants that line in the
log and a console wants it on the screen; returning the sentence lets both have it.

**And the reuse paid for itself immediately, which was not the reason for doing it.**
`dev_stage.gd` was at **exactly 250 of its 250 allowed code lines** before this package — measured
by stashing the branch and re-running the checker — so the sixth staging flag this row needed
(`--console=`) could not have been added at all. Extracting the verbs took it to **247** *while*
adding the flag. WP-14 raised a budget rather than split a file and wrote down that doing so was a
last resort; this is the other outcome, and the checker found the seam again.

### The console is a screen, the overlay is not, and that is one decision made twice.

Both follow from the same question — should the world be stopped? The console wants it stopped:
typing `time 18:40` while the clock runs photographs a moving target. So it declares
`pauses_world` and `UiRoot`'s pause table does the rest; there is no second pause mechanism, which
is what ADR-0004 exists to prevent. The overlay wants the opposite, because a frame time is
worthless unless frames are still happening — so it is a `CanvasLayer` at layer 101 beside the
HUD, never enters the stack, holds no pause, takes no focus and answers no cancel.

**Both proved windowed.** F1: `depth 0` → `PROBE F1 opened: true, depth 1, world paused true` →
`PROBE F1 again closed it: depth 0, world paused false`.

### Chrome is text, output is data — the line `check_strings.gd` forced this package to draw.

A console is full of text and the localization gate has opinions about text, so the split had to
be stated rather than discovered. The console's TITLE and its input hint are localization keys
like every other screen's (`ui.debug.console.title`, `ui.debug.console.hint`); the transcript is
echoes of a typed command and the values that came back, which no `strings.csv` could hold. The
overlay is all data and has no chrome, so it has no key at all.

The gate was satisfied the way it intends rather than routed around, with one honest exception
stated in the code: joining the transcript straight into `.text` FAILS the sink rule, correctly,
because a separator literal on the right of a `.text =` is indistinguishable to a text scan from a
sentence meant for a player. The join goes into a local first, and the comment says why.

**And the two new keys are really gated.** With `ui.debug.console.title` transposed to
`ui.debug.consloe.title`, `check_strings` printed
`!! res://src/ui/screens/debug_console_screen.gd:31 TITLE_KEY = 'ui.debug.consloe.title' has no row`
and exited **1**, while `check_content` exited 0, `check_boundary` exited 0 and all **1,573
assertions passed**. WP-14's finding, reproduced on this package's own keys.

### THE ASSERTION THAT WOULD HAVE PASSED OVER A DELETED GUARD — gotcha 42, caught by planting.

The release gate has to be asserted, and `OS.is_debug_build()` is true in every context the suite
can run in, so the assertable form is a text scan for the guard. The first version scanned each
file for the bare call. **It was wrong twice over, and planting is what found it:**

1. `screen_keys.gd` EXPLAINS its gate in a comment, so a whole-file scan would have read its own
   documentation back and passed with the binding deleted. The scan now skips comment lines, the
   way `check_boundary.gd` and `check_strings.gd` both do.
2. `perf_overlay.gd` carried `if not OS.is_debug_build():` **twice** — in `_ready` and in `_input`
   — so deleting the real one in `_ready` would have left the assertion green on the other. The
   fix was in the CODE rather than in the test: `_input` and `toggle()` now gate on
   `_label == null`, which is the same question and a stricter one, because a release build never
   builds the label. One place decides, and the anchor is unique.

Each of the three gate sites is now named by a fragment that appears nowhere else in its file, and
each was proved red with the real violation and the explaining comment left in place:

- the guard deleted from `toggle_console` →
  `FAILED: screen_keys.gd gates on 'if not OS.is_debug_build():' — expected true, got false`,
  `1572 passed, 1 failed`, exit 1. Restored → `1573 passed, 0 failed`.
- `and OS.is_debug_build()` deleted from `menu_for` → the matching failure, exit 1.
- the guard deleted from `PerfOverlay._ready` → the matching failure, exit 1.

Four more plants, on the behaviour rather than on the gate: the transcript trim removed →
`the transcript is bounded — expected 12, got 42`; the empty-line guard removed →
`so the transcript did not grow — expected 2, got 4`; `flag`'s malformed-argument refusal removed
→ two failures, including `and wrote nothing — expected false, got true`; and the CSV key typo
above.

### ABSENT FROM A RELEASE EXPORT — measured, with a control.

Not assumed, and not left to the text scan. Both tools log one line when they arm, and two real
exports were built and run:

| | `Debug console armed on debug_console` | `Performance overlay armed on debug_perf` |
|---|---|---|
| **debug export** (`--export-debug`) | present | present |
| **release export** (`--export-release`) | **absent** | **absent** |

Both runs otherwise identical and both ending `0 warnings, 0 errors`. The debug build is the
control: without it, two absent lines would prove only that nothing was logged. This is the shape
gotcha 39 established — a measurement outranks an assumption, and a control is what makes it one.

### Windowed captures, LOOKED AT and READ (gotcha 28).

Three, and two of them carry a checkable prediction rather than merely looking fine.

1. **The console with a real transcript.** Run at `--time=12:00 --freeze-time`, then
   `--console="time 18:40;flag map/somewhere:true;give item/rose_petal:2"`. The panel shows six
   lines — the echo and the answer for each command — over a courtyard still visible through the
   dim, so the world is stopped rather than gone. **The prediction:** the run asked for noon, and
   the HUD clock in the capture reads `Day 1 | 18:40 | Dusk` with the scene lit for dusk. The
   console really moved the clock, and the lighting and the readout agree.
2. **`goto` really travels.** `--console="goto lantern_hall"` from the courtyard. The capture is
   the interior — different geometry, the interior's own 36° / 9.5 m framing from T3.2 — with the
   toast `Lantern Hall is added to your map`, and no console, because travel unwinds the stack
   through `ScreenKeys`. The log reads `Entered 'courtyard'` … `goto requested 'lantern_hall'` …
   `Entered 'lantern_hall'`.
3. **The overlay over live gameplay.** `16.67 ms/frame  60 fps  17.72 ms process  98 draw calls
   169 nodes  0 orphans`, top-left in gold, with the NPC visibly at a different post than in the
   console capture — which is the point of it not being a screen.

**The first attempt at capture 3 came back with no overlay in it, and it was not a defect.** The
shutter frame landed before F3. Diagnosed by probing rather than guessed at: the label reported
`rect=[P: (32.0, 24.0), S: (1888.0, 40.0)] vis=true colour=(0.86, 0.74, 0.52, 1.0)` with the right
text, so nothing was wrong with the drawing and the timing was the whole story.

### The input probe, quoted and then removed (gotcha 15).

A console is an input path end to end and `TestCase.run()` cannot press a key. A temporary probe
in `src/systems/debug/dev_probes.gd` pressed F1, F3 and a real ENTER through the `LineEdit`:

```
PROBE stack depth before F1: 0
PROBE F1 opened: true, depth 1, world paused true
PROBE LineEdit found: true, has focus true
PROBE enter ran it: clock 04:15, transcript 2 line(s), box now ''
PROBE F1 again closed it: depth 0, world paused false
PROBE overlay before F3: visible false
PROBE F3 -> visible true | 35.71 ms/frame  28 fps  188.11 ms process  97 draw calls  169 nodes  0 orphans
PROBE 90 frames later          | 16.70 ms/frame  54 fps  17.56 ms process  96 draw calls  169 nodes  0 orphans
PROBE F3 again -> visible false
```

**The frame time visibly changes**, which is the row's own criterion: the load spike reads 35.71
ms at 28 fps, and ninety frames later the same overlay reads 16.70 ms at 54 fps. The probe also
settled a 4.3-era question the dump does not answer — `LineEdit` distinguishes having focus from
being in EDIT mode, and `has focus true` with the enter actually taking is what proves
`grab_focus()` plus `edit()` is the right pair. **`git diff src/systems/debug/dev_probes.gd` is
empty.**

### Files: 12, and new code is 321 lines.

`src/systems/debug/dev_commands.gd` (63 code lines, new) ·
`src/ui/screens/debug_console_screen.gd` (80, new) · `src/ui/hud/perf_overlay.gd` (68, new) ·
`tests/unit/dev_tools_test.gd` (98, new) · `src/systems/debug/dev_stage.gd` (the three verbs
delegate, and `--console=`) · `src/systems/debug/dev_capture.gd` (`--time=` delegates) ·
`src/ui/root/screen_keys.gd` (`toggle_console`, the `menu_for` entry, the armed line) ·
`src/systems/input/actions.gd` (`DEBUG_PERF` on F3) · `scenes/boot/game_root.tscn` (the
`PerfOverlay` layer) · `localization/strings.csv` (two rows) · `tests/test_runner.gd` (the CASES
entry) · plus the documents. **130 → 134 files, 11,338 → 11,659 code lines.**

**1,543 → 1,574 assertions**, and the arithmetic is stated rather than absorbed: **+30** is the
whole of `dev_tools_test.gd`, and **+1** is `docs_test.gd`, which COMPUTES its plan from the
documents and gained one `res://` path to resolve when these sections named
`src/systems/debug/dev_commands.gd`. Every plant below was run before the documents were written
and therefore quotes 1573 rather than 1574; the totals differ by that one computed assertion and
nothing else.

### Ladder, all green.

`--headless --import` with **zero** `SCRIPT ERROR` / `Parse Error` lines; boot at `--quit-after
30` ending `0 warnings, 0 errors`; suite **1574 passed, 0 failed, 0 skipped**, exit 0;
`check_budgets` **134 files, 11,659 code lines, 0 warnings, 0 violations**; `check_content` PASS;
`check_boundary` PASS over 127 engine scripts; `check_strings` PASS over 96 engine scripts, 218
CSV rows, 24 sinks, 73 key declarations and 1 pattern.

**Stripped template, run locally** — `--headless --path <copy>` over a tree with `.git`, `.godot`,
`data/` and `scenes/areas/` removed: **1500 passed, 0 failed, 25 skipped** (was 1469/0/25), all
four checkers exit 0, import clean.

**THERE IS NO NEW SKIP, and that is the result to want rather than a gap.** The +31 is the whole
of `dev_tools_test.gd` plus `docs_test.gd`'s one computed assertion, and every one of the 30 runs
in a stripped template — because a console and an overlay are ENGINE, and nothing about either
needs a game to be present. `check_strings`
again reports byte-identical numbers stripped and full (218 rows, 96 scripts, 24 sinks, 73 keys, 1
pattern), which is what it should: both its rules are about `src/` and `localization/`, neither of
which the strip touches.

### Deferred, with reasons, not silently.

- **Command history, autocomplete and a watch list of live flags** — deferred by the row, and the
  transcript is deliberately un-scrollable for the same reason: a console that needs scrolling
  wants history, and half of it is worse than none.
- **No command mutates content on disk**, per the row.
- **The overlay has no graph**, only a number. A sparkline is a second thing to get wrong, and the
  averaged number already answers the question the row asked.
- **`DEBUG_FREECAM` on F2 is still declared and still unbound.** It predates this package, it is
  not a dev-tools row's job to invent a free camera, and saying so is cheaper than a reader
  wondering whether F2 was missed.
- **The `Button` styleboxes**, for the sixth package running. The console draws no `Button` at
  all, so this row had no occasion to take them; the reason has not changed and neither has the
  seam.
- Combat is still not a thing.

**CI green, run 33546328207, JOB LOGS read rather than the tick** (gotcha 26). Full checkout
**1574 passed, 0 failed, 0 skipped**; stripped template **1500 passed, 0 failed, 25 skipped** —
both identical to the local numbers. `check_budgets` reported **134 files, 11,659 code lines, 0
warnings, 0 violations** in BOTH jobs, and rung 8 reported identical figures in both (218 CSV
rows, 96 engine scripts, 73 key declarations), which is the point of running it on a stripped
tree. Rung 3's whole-log grep printed `Parse Error lines in boot.log: 0`. All seven rungs present
in the full job and all six in the stripped one. The run took 38 seconds, and per gotcha 26 that
is a cached engine rather than evidence of a skip: the rung logs show 1,574 assertions actually
executed.

**Commit:** `22e0046` on `claude/wp-14b-dev-tools`, PR #24 — stacked onto
`claude/wp-14-hardening` (#23) rather than `main`, matching the rest of the chain.


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

### Everything above is DONE, in T2.0 — and the remnant should be CLOSED, not built.

The export preset, the ADR-0006 question and the shader warm-up all shipped in T2.0, which was
sequenced to the front of Phase T2 by risk. What is left of this row is **credits and an
accessibility pass**, and WP-14 flagged both as belonging to a *consuming game* rather than to the
template:

- **Credits** name a team, and a template does not have one. A game built on this base credits its
  own people; a `credits.tres` shipped by the template would be either empty or wrong, and the
  mechanism it would need — a screen that reads a resource and scrolls it — is `MenuScreen` plus a
  `.tres`, which Tier 1 of the extension surface already covers with no new code.
- **An accessibility pass** over placeholder art and a UI whose every colour and size a game is
  expected to replace is a pass over something designed to be thrown away. The seams that make
  accessibility *possible* are the ones that matter and they already exist and are proved: the
  project `Theme` holds every font size and colour in one file (T2.1), input is rebindable through
  `actions.gd` with a rebind screen (WP-12), and there is no timed input anywhere in the template
  because there is no combat. A real pass belongs to whoever ships real art.

**The recommendation is therefore to close this row with that reasoning**, the way WP-10 was marked
OPTIONAL, rather than build two things for a game that does not exist. Recorded here rather than
acted on, because retiring a row is the owner's call and not a package's.

**WP-14b SURFACED THIS RATHER THAN DECIDING IT, 2026-09-02, and with Phase T3 now closed it is the
only thing standing between the board and Phase T4.** WP-14b found nothing that changes the
reasoning above and one small thing that reinforces it: the console and the overlay are the last
two engine surfaces a consuming game does NOT restyle, because a player never sees either — which
sharpens the point that a pass over the surfaces a game *does* restyle belongs to whoever ships the
real art. **This needs a yes or a no from the owner**, and the two live options are:

- **CLOSE the row** with the reasoning above recorded, and go straight to Phase T4. This is the
  recommendation.
- **KEEP it** and build credits plus an accessibility pass, which is roughly one package and
  produces two artefacts a consuming game replaces.

WP-10 (crafting) is already OPTIONAL and does not block v1.0 either way.

---

### THE ANSWER, 2026-09-02: CLOSED.

The owner took the recommendation. **Credits and the accessibility pass will not be built on this
base.** The row is closed the way WP-10 is marked OPTIONAL — recorded with its reasoning rather
than deleted, so a later session finds the argument instead of re-deriving it.

Nothing about the reasoning changed on the way to the decision, and the two artefacts a consuming
game would replace are still a `credits.tres` and a restyle of a `Theme` a game is expected to
replace. **What the template owes accessibility is the seams, and it has them and they are
proved:** the project `Theme` at `assets/theme/ui_theme.tres` (T2.1), rebindable input through
`src/systems/input/actions.gd` plus the rebind screen (WP-12), and no timed input anywhere,
because there is no combat.

**With this closed, Phase T4 begins.** T4.1 is below.

---

## T4.1 · Template v1.0 — the version, and the upgrade note — **DONE** — `799d957`, PR #25

**Read:** `docs/TEMPLATE.md`, `project.godot`, `src/core/util/game_config.gd`,
`docs/NEW_GAME.md`.

The first package of Phase T4, and the roadmap named two deliverables. The second is the one that
mattered: *nothing described how a game already forked from this base receives a later fix*, which
is the one question a reusable base has to answer.

### The version does NOT live in `application/config/version`, and that is the package in one line.

That field was the obvious candidate and it is the wrong one, for a reason `NEW_GAME.md` § 4 was
already carrying: **it tells a fork to reset it to `0.0.1` on day one.** So after exactly one fork
that field means *the game's* version, and nothing anywhere records which base the game came from
— and "which base am I on" is the first question an upgrade note has to answer.

So the template states its own version in its own section:

```
[template]
base/version="1.0.0"
```

read through `src/core/util/template_version.gd`. **A fork leaves that line alone, and a merge
that changes it is the base announcing a release inside the fork's own diff** — which is what the
performed merge in `UPGRADING.md` § 7 actually shows happening.

It is a project setting rather than a `const` under `src/` for the same reason `[game]
world/first_area` is: reading a `const` means opening engine code, and the premise of the whole
boundary is that a consuming game does not read `src/`.

### It is readable at runtime because it is in every boot banner, which is not decoration.

The banner now reads `<game> <game version> | base <base version> | Godot ... | debug=...`. A bug
report from a forked game is unanswerable without it: the game's own version says nothing about
which template fix it already has. `Log` previously allowed itself exactly one dependency,
`GameConfig`; `TemplateVersion` is the same kind of thing — a pure reader of `project.godot` that
depends on nothing — so the edge is not widened in kind.

### `TemplateVersion` is a separate file from `GameConfig`, and the split is not tidiness.

`GameConfig`'s header says it owns *"the values a game author writes once"*. The base's version is
the one value a game author must NEVER write. Putting it there would have made that sentence
false; a second small file keeps both true.

### The upgrade note was PERFORMED, and it found a defect nobody would have reasoned to.

`NEW_GAME.md`'s precedent (T2.2) is that a consumer document's claims are run, not written from
intent. So: a stripped fork was made from a clone of the base, following `NEW_GAME.md` step by
step; two template releases were landed on the base; both were merged in; and the fork's whole
ladder was run afterwards. Everything quoted in `UPGRADING.md` § 7 is real output. **The two
release numbers, 1.1.0 and 1.1.1, are synthetic scaffolding and the document says so** — a
version-to-version walk needs two versions, and the real template has released one.

Four things came out of it that no amount of design would have produced:

1. **`project.godot` auto-merged**, including a base edit three lines from a field the fork had
   renamed. The note says so AND says not to count on it, because git decided that, not the
   template.
2. **`localization/strings.csv` conflicts every time**, because both sides append at the end of
   the file. The resolution is always "keep both sides" — it is a key-value file, not competing
   edits to one value.
3. **A merge pushes the template's DEMO CONTENT back into the fork.** An item belonging to the
   template's demo arrived as a new file with no conflict and therefore no warning, because
   `data/` is a directory both sides own files in and git has no opinion about whose. This is in
   no other document.
4. **The fork's rung 4 went RED, and it was a real template defect.** `smoke_test.gd` gated its
   first-area block on `Fixtures.has_demo_content()` — "any content at all", which flips true on
   the first `.tres` of any kind. A game that authored one item before its first area therefore
   armed an assertion about AREAS and failed rung 4, *in exactly the window `NEW_GAME.md` walks an
   author through, while `NEW_GAME.md` claimed the ladder stays green.* The fix is one line and it
   is the general rule: **a block must gate on the same question it asserts.**
   `Fixtures.area_ids()` is that question and it already existed. Nothing is weakened — a game
   WITH areas still fails on an unset first area and on one naming a scene that is not there,
   which was planted and proved.

`NEW_GAME.md` was corrected in the same commit: its stale `880 passed, 0 failed, 12 skipped`
became the measured `1527 passed, 0 failed, 25 skipped`, it now says `[template] base/version` is
the one `project.godot` field a fork must not touch, and it states the authoring-order trap.

### What the template CANNOT promise, written down rather than implied.

Five things, in `UPGRADING.md` § 4: it cannot promise a clean merge (git decides, from a diff the
template cannot see), that your content still loads across a MAJOR, that a save survives, or
anything at all about a fork that edited `src/` — and there will be no automatic upgrade script.
The fourth is the sharpest: **the boundary rule is what makes the merge safe**, so a fork that
broke it has no upgrade path and no version number can give it one.

### The changelog is a GATE, not a courtesy.

`docs/CHANGELOG.md`'s newest `## <semver>` heading must equal `[template] base/version`, asserted
by `tests/unit/version_test.gd`. Bumping one without the other is the exact rot the discipline
exists to prevent, and it was planted: bumping the heading alone fails rung 4.

### Five plants, each proved red with the real violation (gotcha 23), and one is gotcha 43's.

1. The banner loses its base-version fragment — `expected 1, got 0`.
2. **The same fragment written TWICE** — `expected 1, got 2`. This is gotcha 43 taken as a rule
   rather than as a story: the scan asserts the fragment appears EXACTLY ONCE, so a decorative
   second copy cannot hide a deleted real one.
3. The changelog bumped and the setting not — `expected 1.0.0, got 1.0.1`.
4. A two-part version in `project.godot` — three failures, including `current()` falling back to
   `0.0.0` rather than returning something unparseable.
5. `first_area` pointed at an area that does not exist, WITH areas present — the block that was
   loosened still fails, which is what proves the loosening was not a weakening.

### No visual and no input surface, said rather than skipped.

Nothing this package touches draws a pixel or reads a key, so there is no windowed capture and no
debug probe. The boot banner is the one new runtime output and it is a log line, proved on rung 2
and quoted below. `git diff src/systems/debug/` is clean because nothing went in there.

### Files: eleven, and new code is 118 lines.

New: `src/core/util/template_version.gd` (43 code lines), `tests/unit/version_test.gd` (74),
`docs/UPGRADING.md`, `docs/CHANGELOG.md`. Edited: `project.godot`, `src/core/log/log.gd` (+1),
`tests/unit/smoke_test.gd` (one line changed), `tests/test_runner.gd` (+1), `docs/NEW_GAME.md`,
`docs/TEMPLATE.md`, `CLAUDE.md`. Under the 500-line limit with room to spare.

### Ladder, all green.

```
--headless --import                     zero SCRIPT ERROR / Parse Error lines
--headless --quit-after 30              Session ended after 0.7s — 0 warnings, 0 errors
                                        Project Gulistan 0.0.1 | base 1.0.0 | Godot 4.7.2-stable
res://tests/test_runner.tscn            === 1601 passed, 0 failed, 0 skipped ===   (was 1574)
check_budgets/content/boundary/strings  exit=0, all four
stripped template                       === 1527 passed, 0 failed, 25 skipped ===  NO new skip
the performed fork, after two merges    === 1538 passed, 0 failed, 14 skipped ===, four checkers exit=0

CI, run 33595460507, JOB LOGS read rather than the tick (gotcha 26):
Ladder (full checkout)      === 1601 passed, 0 failed, 0 skipped ===, every rung PASS
Ladder (stripped template)  === 1527 passed, 0 failed, 25 skipped ===, every rung PASS
and CI's own boot lines read `Project Gulistan 0.0.1 | base 1.0.0 | Godot 4.7.2-stable`.
```

### Deferred, with reasons, not silently.

- **A git tag on the real repository.** The version the template states about itself is the
  deliverable the roadmap asked for, and it is assertable; a tag is a release action, and releases
  are the owner's. `v1.0.0` exists only in the throwaway proof repositories.
- **A compatibility TABLE in `TemplateVersion`.** A table is a list of exceptions to the promise,
  and the promise is the product. `same_major_as()` and `compare_to()` are the whole surface.
- **A tool that performs the merge.** `UPGRADING.md` § 4 states there will be no automatic
  upgrade, and shipping one would contradict the document in the same package that wrote it.
- **Credits and the accessibility pass** — WP-15, closed above.


## T4.2 · A second worked example, authored from `AUTHORING.md` alone — **DONE**

**Goal.** T2.2's mechanism — *perform the document and count the defects* — applied to CONTENT
rather than to docs. T2.2 performed the area, NPC and conversation sections and found six defects;
everything `AUTHORING.md` has gained since (the world map, surfaces and attributes, equipment and
the gate that reads it, quests, counted steps, the `obj/` writers) had been WRITTEN but never
walked. Gotcha 44 is the argument for doing it: the states a consuming game passes through are
exactly the states this repository never sits in.

**Method, and the one rule that makes it worth anything.** A new area — an orchard with a warden,
a schedule, a four-node conversation, two items, a sign, a basket, a pickup, an equip-gated arch,
a world-map def and a two-step quest whose first step counts items — was authored **from the
document alone, with `src/` never opened while writing**. Every time the document did not say
enough, that was recorded rather than patched from knowledge. The content was then DELETED, the
way T2.2's was: this is a test of the documents, and `TEMPLATE.md` says the demo does not get
deepened.

**Five defects, and two of them were in the TEMPLATE rather than in the prose.**

1. **§ Add an area ends at a RED rung 4, and § Put an area on the world map calls that state
   legitimate.** Following the area section exactly — scene, CSV row, then its own three closing
   commands — gives `1621 passed, 4 failed`, `FAILED: every authored area is on the map`. The area
   section never mentions `data/areas/<id>.tres`; the map section said an area without one "is
   simply not on the map — legitimate for a cupboard". The suite requires one per authored area, so
   that sentence was false, and it was false in the section a reader goes to when the assertion
   fires. Both corrected, and the real cost measured with a control: an area adds **20** assertions
   to `transitions_test.gd`, as documented, **plus 5** to `world_map_test.gd`, which was not.
2. **`check_boundary` matched SUBSTRINGS, so an item called `pear` failed a gate its author could
   not fix.** `tests/unit/menus_test.gd` says *"and Load has appeared under it"*, and **`appeared`
   contains `pear`**. Gotcha 44's shape exactly — green in the full demo, green in the stripped
   template, red only in a consuming game's hands, because the collision needs an id this
   repository does not have. **And the document made it worse**: its gate table said a
   `check_boundary` failure "is a bug in the *engine*, not in your content", sending the author to
   file a bug rather than rename. FIXED: ids are matched as whole words. The two remaining hits
   were real whole-word ones — an engine test using `"apple"` and `"pear"` as throwaway dictionary
   keys — and **that fix belonged in the test**, which now draws them from the reserved `fixture_`
   namespace, immune by construction because an id after an underscore is not a whole word.
3. **`--stand-by` always resolved in the DEPARTURE area, so no object in an authored area could be
   photographed at all.** `--goto=orchard --stand-by=BrambleWay` failed with *found no node called
   'BrambleWay'*. Not a race — a deterministic loss: `_wait_for_area()` returns on the same frame
   `--goto` asks to travel. Gotcha 35, whose rule `dev_stage.gd`'s own header already states for
   `--open-menu` — this call site was simply missed, which is gotcha 41's family. FIXED with
   `_settle_stable(SETTLE_FRAMES)`, and the document now carries a `--goto` + `--stand-by` recipe
   with frames that work (260/290/340 rather than 1/70/90).
4. **The quest section named no `obj/` field, and a step that can never finish passes every
   gate.** Its writers table pointed at ADR-0005 for `obj/<area>/<object>/<field>`. Writing
   `obj/orchard/bramble_way/opened` from that: `check_content` PASSED, the journal drew the
   objective, the run reported `0 warnings, 0 errors` — and the field is `open`. **This is the one
   flag family no gate can check**, because the field lives in engine code and the object is placed
   in a scene. All seven are now a table in the document (`open`, `thrown`, `emptied`, `taken`,
   `read`, `fired`, `done`), each shorter than the word you would guess, with the trap stated.
5. **§ Tag the ground you walk on cannot be verified at all**, against the document's opening
   promise that every section "ends with a command that tells you whether you got it right". No
   gate reads `metadata/surface`, nothing logs it on load, and no debug flag walks anybody — the
   surface resolves only when a character WALKS. Stated honestly rather than papered over.

**Six sections performed CORRECTLY and are now proved rather than asserted**, which is the other
half of the result: the world map (the def, the normalised `map_position` measured at 0.61/0.24 of
the plate, discovery-by-arrival), the conversation and its fall-through entry, the NPC and its
schedule, the `[editable]` marker rule, the counted quest step (`Gather three pears. 2 / 3`), and
an authored `locked_key` reaching the player.

**Gates proved red with the real violation, then green (gotcha 23).** The new `--stand-by`
assertion was proved by deleting the settle call: `FAIL func _stand_by settles rather than only
waiting for an area`, exit 1 — **and the other two `_settle_stable` calls were still in the file**,
so a whole-file scan would have stayed green. That is gotcha 43's rule met by narrowing the TEXT
rather than the fragment. The boundary matcher got a plant AND a control, because a fix that makes
a gate accept more has to show it still refuses: `rose_key` planted whole → `FAIL — 5 boundary
violation(s)`; `rose_keys` planted → `PASS`; the same `rose_keys` plant against the OLD substring
matcher → `FAIL — 4 boundary violation(s)`, flagging `rose_keys` as `rose_key` and `appeared` as
`pear`. Both plants use PERMANENT demo ids, so they are repeatable after the walkthrough content
was deleted.

**Files: 5, and the new code is 6 assertions plus two fixes.** `tools/check_boundary.gd`,
`src/systems/debug/dev_stage.gd`, `tests/unit/core_test.gd`, `tests/unit/dev_tools_test.gd`,
`docs/AUTHORING.md`.

**Ladder, all green.** Import exit 0 with **zero** `SCRIPT ERROR` / `Parse Error`; boot
`0 warnings, 0 errors`; suite **1607 passed, 0 failed, 0 skipped** (1601 + 6); `check_content`,
`check_boundary`, `check_budgets`, `check_strings` all exit 0. Stripped template **1533 passed, 0
failed, 25 skipped** — 1527 + 6, **no new skip**. Five windowed captures LOOKED AT and READ.

**CI green, run `33599084960`, job logs read rather than the tick (gotcha 26).** Full checkout
`=== 1607 passed, 0 failed, 0 skipped ===`; stripped template `=== 1533 passed, 0 failed, 25
skipped ===`, the 25 skips unchanged from T4.1. All four checkers PASS in both jobs. The push run
(`33599052173`) and the dispatch (`33599094672`) agree.

**Commit:** `4f5f753` on `claude/beautiful-proskuriakova-2df954`, PR #26 — stacked onto
`claude/wp-t4-version-upgrade` (#25) rather than `main`, matching the rest of the chain.

**What was deliberately NOT done.** A `check_content` rule for `obj/` flags: it would have to know
each prefab class's field constant, which means a list in a tool naming engine internals that
`check_boundary` cannot help it keep honest — the field table plus "read it out of a run" is the
cheaper truth, and defect 4 is now documented rather than gated. And the world-map assertion was
NOT weakened to match the prose: requiring a def per area is a real invariant, and the document was
the thing written from intent.

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

**CI green**, run
[32995130430](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32995130430),
both jobs: `930 passed, 0 failed, 0 skipped` full checkout, `880 passed, 0 failed, 12 skipped`
stripped, reproducing the hand-run numbers exactly. Dispatched manually rather than waited for,
per gotcha 26.

**Closed 2026-08-26**, commit `835fb79`. New gotcha 27.


---

## T2.1 · Art contract seams — **DONE**

**Goal.** Make the art contract authorable data instead of code constants, and prove it by
swapping something. Phase T2's goal is *"a second, visually different game starts from this
without editing `src/`"*, and two things made that false.

**The two seams, and what was actually wrong with each.**

1. **`CharacterVisual` hard-coded the sheet.** `FACING_COUNT = 8` and `FRAME_COUNT = 4` were
   constants, and the eight-way sector maths was a **separate literal `TAU / 8.0`** that had to
   agree with the first by hand. Two places holding one number, waiting for the first game whose
   sheet has four facings. There was also no animation-row offset, so idle-versus-walk was not
   merely unimplemented, it was structurally impossible — the sheet had exactly one cycle and
   nowhere to put a second.
2. **The UI look lived as constants inside five screen files.** `menu_screen.gd`,
   `dialogue_screen.gd`, `inventory_screen.gd`, `hud_clock.gd`, `loading_indicator.gd`. The
   accent colour was written out three times in slightly different values (`0.86, 0.74, 0.52`
   twice, `0.90, 0.78, 0.55` once); `40` appeared twice, `24` three times, `18` twice. So a
   restyle was five edits that would drift, and a consuming game had nowhere to put its own look
   but a fork of the screens.

**A FACING IS NOT A COLUMN, and getting that wrong would have re-created the bug.** The obvious
implementation maps `GameEnums.Facing` down onto `layout.facings` — `int(facing) * facings / 8` —
and that puts the number 8 back in the code, in a second place, exactly where it was. So the two
are quantised *separately from the same angle*: `_facing` from `GameEnums.Facing.size()`, because
eight is how many directions the **game** reasons about, and `_column` from `layout.facings`,
because that is how many the **art** distinguishes. Neither reads a literal. When `facings == 8`
they agree by construction, which is why nothing about the existing sheet changed.

**Wrote**
- `src/content/art/sprite_sheet_layout.gd` — 34 code lines. `facings`, `frames`, `animations`,
  `cell_size`, `idle_row`, `walk_row`, plus `sheet_rows()`, `sheet_size()`, `sector_radians()`,
  `column_for_angle()`, `animation_for()`, `frame_index()` and `problems()`. In `src/content/`
  because it is a data shape, so anything may read it, and it touches no autoload — the same
  constraint `item_definition.gd` carries, and for the same reason: `tools/` loads content classes
  under `--script`, where autoload identifiers do not resolve.
- `assets/placeholder/character_layout.tres` — the old constants, moved out of code unchanged:
  8 facings, 4 frames, 1 block, 32x48.
- `assets/placeholder/character_alt_layout.tres` + `character_alt.png` — the swap subject, and it
  disagrees with the default on **every** number: 4 facings, 3 frames in **2** blocks, 24x40.
- `assets/theme/ui_theme.tres`, wired as `gui/theme/custom` in `project.godot`. Nine type
  variations carrying font sizes, a `UiPalette` of four colours, a `UiMetrics` of six insets.
- `tools/gen_placeholders.gd` — `_build_alt_sheet()`, and see below for why every cell is labelled.
- `tests/unit/art_contract_test.gd` — 83 assertions. 930 → **1013**.

**THE PALETTE IS NOT COPIED INTO THE VARIATIONS, and that is the whole design.** A `Theme`
resource has no variables, so a colour repeated into nine variations is nine places to change and
"one Theme edit restyles every screen" would simply be false. So the variations carry **only**
`font_size` — the one thing that genuinely differs by role — and the screens read the four colours
and six insets by name from `UiPalette` / `UiMetrics`. It costs each screen a `get_theme_color`
call and buys the criterion outright.

**Three values were deliberately UNIFIED rather than carried across.** The dialogue box's dim was
`0.03, 0.02, 0.05, 0.72` against the inventory's `0.04, 0.03, 0.06, 0.78`; its speaker tint was
`0.90, 0.78, 0.55` against the others' `0.86, 0.74, 0.52`; its hint was 16pt against the others'
18. Those differences were duplication, not design — nobody chose them — and keeping them would
have meant three palette entries that exist only to preserve a typo. Two column separations moved
by 2px and 4px for the same reason. This is a visual change, and it is the only one in the
package; the captures show it as an improvement in consistency.

**EVERY CELL OF THE ALT SHEET IS SELF-LABELLING, because gotcha 2 has a sharper form here than
usual.** A day/night system that lights nothing is at least obviously wrong on screen. **A
character drawn from the wrong cell still looks like a character** — it is a person, upright, lit,
facing *some* direction. So a capture cannot be *judged*, it has to be *read*. Each cell of
`character_alt.png` therefore carries `column + 1` bright pips down its left edge and `frame + 1`
along its foot, and the two animation blocks wear different tints. Four left pips and two foot
pips on an orange body is block 1, frame 1, column 3 — index `(1*3 + 1) * 4 + 3 = 19` — and no
amount of plausible-looking pixel art can fake that number.

**Verified. Both criteria are VISUAL claims and both were demonstrated by a capture that was
looked at, not by an assertion.**

*Criterion 1 — swap in a sheet with a different cell and frame count, changing no code.* Two
`ExtResource` paths in `scenes/characters/player.tscn` repointed at the alt pair; nothing else
touched, and the file was reverted afterwards. Standing still, the probe logged
`sprite visible=true frame=0/24 size_px=(96.0, 240.0)` and the zoomed capture showed the green
idle-block body, one left pip, one foot pip and eyes — column 0, frame 0, idle. Walking, the probe
logged `frame=19/24` and the capture showed the orange walk-block body, **four** left pips, **two**
foot pips, no eyes and offset legs — block 1, frame 1, column 3, which is index 19 exactly. The
default sheet reports `frame=0/32 size_px=(256.0, 192.0)`, so `hframes`/`vframes` follow the
layout and not a constant. The NPC beside the player kept the 8x4 sheet throughout, which is the
incidental proof that a layout is per-node rather than global.

*Criterion 2 — one `Theme` change restyles every screen at once.* Six lines of
`assets/theme/ui_theme.tres` and no other file: `text` white → near-black, `accent` gold → deep
red, `dim` and `solid` near-black → parchment, `margin` 64 → 120, `TitleText` 40 → 56. Captures
before and after of the main menu and of the inventory screen over a frozen world. Both screens
restyled completely, and the HUD clock followed without being mentioned. Reverted.

*Ladder, all green.* `--headless --import` exit 0 with **zero** `SCRIPT ERROR` / `Parse Error`
lines; boot `0 warnings, 0 errors`; suite **1013 passed, 0 failed, 0 skipped**, exit 0;
`check_budgets`, `check_content`, `check_boundary` all exit 0; windowed capture at 18:40 looked at
and unchanged from before the refactor.

*Both new gates proved RED before green (gotcha 23).* Adding
`add_theme_font_size_override(&"font_size", 22)` back to `hud_clock.gd` — the exact regression the
gate exists to catch — printed `FAILED: hud_clock.gd writes down no font size — expected 0, got 1`
and exited 1. Changing `frames = 3` to `4` in the alt layout printed `FAILED: the alt layout is 3
frames in 2 blocks — expected [3, 2], got [4, 2]` and `FAILED: the two layouts disagree on the
frame count`, and exited 1. Both reverted, both green again.

**A temporary probe, added and removed as gotcha 15 prescribes.** `CharacterVisual.describe()`
existed with no caller, so no run had ever printed which cell was being drawn. A
`_temporary_t21_probe()` in `dev_capture.gd` logged it at the shutter, and a `_temporary_t21_walk()`
pressed `move_left` twelve frames before the shot — an assertion cannot press a key and
`TestCase.run()` never reaches a frame. Both are quoted above and both are gone;
`git diff src/systems/debug/dev_capture.gd` is empty.

**What the assertions deliberately do NOT claim.** `art_contract_test.gd` says so in its header
and means it: it cannot say what a sprite looks like. What it does cover is the part that is a
pure function of the facing count — the sector maths, the frame indexing, the layout's own
validation — plus a **compatibility assertion** that an 8x4 layout produces the same index the old
`_frame * FACING_COUNT + facing` produced, which is what says this refactor moved the numbers
without moving the picture. It also pins the theme resolving *through the project setting on a
live Control*, because a theme item that exists in a file and does not resolve from a node is not
wired — the same failure shape as an unwired `@export`.

**A regression gate, not just a refactor.** The look reached five files one reasonable line at a
time, and nothing but a check stops it going back. `_no_screen_holds_a_size_or_a_colour_of_its_own`
fails if any of the five names a `Color(` or calls `add_theme_font_size_override` in a code line,
and fails if `character_visual.gd` regains a `TAU / 8` or a `FACING_COUNT`. Comments are exempt,
on `check_boundary`'s reasoning: a `##` line naming what the theme replaced teaches by example and
changes nothing.

**Left for later, because the package hit its file budget and half-doing five seams is worse than
finishing two:** shared materials, the environment post-stack and camera framing as `@export`s,
the texture import defaults, and the Git LFS lines. **All five were closed by T3.2** — four built,
LFS refused in writing — and the current state of every one of them is stated once, in
`docs/ART_CONTRACT.md`. Nothing in this paragraph describes the project as it is now.

**One gap the restyle capture exposed, and it belongs to the theme rather than to a screen.** The
theme governs sizes, colours and insets; it does **not** yet set the `Button` styleboxes, so
`MenuRow` and `ChoiceRow` still draw Godot's default dark panel. Against the parchment palette
that left every row dark-on-light — legible, but plainly not restyled with the rest. The seam
exists and is the right one (`MenuRow/styles/normal` and friends in the same file, no code); it is
simply unpopulated. A consuming game with a light palette will hit this immediately, which makes
it T2.2's business to say so, or a one-line theme addition whenever a real look is chosen.

---

## T2.2 · Consumer documentation — **DONE**

**Goal.** Phase T2's last exit criterion, and the only one in the project that cannot be checked
by running a command: *someone who has not read `src/` can author an area, an NPC and a
conversation from the docs.* Everything the template can do was documented in **file headers**,
which are excellent and are the wrong place for a consumer — they are found by already knowing
which file to open. There was no document that starts at "I want to add an area" and ends at a
working area.

**Wrote**
- `docs/AUTHORING.md` — the main deliverable. Task-first: add an area, an interactable object, an
  item, a conversation, an NPC. Each task names the files, the required fields, and the gate that
  catches getting it wrong. Includes the ten required children of an area root, a complete
  minimal area written out in full, the `[editable path=...]` trap, and the debug flags that
  actually drive the game.
- `docs/ART_CONTRACT.md` — the consumer-facing form of the two headers T2.1 wrote to be read by a
  consuming game. The sheet grid, the declared cell size, the theme's three-way split, and the
  `Button` stylebox gap stated plainly.
- `docs/TESTING.md` — the five non-obvious rules of this suite, each of which has cost this
  project an hour: the suite is a scene, `run()` is synchronous, every case declares a plan, the
  plan is not enough on its own, and an unlisted case never runs.
- `docs/ARCHITECTURE.md` § **The extension surface** — three tiers: authored data, the points that
  are open to subclass or replace, and the internals. **Put in `ARCHITECTURE.md` and not in
  `AUTHORING.md` deliberately:** `AUTHORING.md` is about content files that need no code at all,
  and the moment it also described subclassing, the "you never edit `src/`" line at its head would
  have been contradicted by its own contents.
- `tests/unit/docs_test.gd` — 68 outcomes, computed rather than declared. 1013 → **1081**.
- Both routers: a doc-router table in `CLAUDE.md` replacing a flat list, and `CONTEXT.md`'s
  "Read next". A document nobody is routed to is a document nobody reads.

**THE CRITERION WAS PERFORMED, NOT ASSERTED, and the deliverable of that exercise is the list of
things that were wrong.** A new area, a new NPC with a schedule and a new four-node conversation
were authored from `AUTHORING.md` alone — nothing copied from an existing area, no `src/`
consulted while writing them. The full ladder ran green with the new content in
(`1101 passed`), `check_content` passed including the `[editable]` gate, and a windowed capture at
midday shows the new NPC in the new area delivering its first-meeting line over a dialogue box.
Then **the content was deleted** — it was a test of the documents, not new demo content, and
`TEMPLATE.md` is explicit that the demo does not get deepened.

**Six defects the walkthrough found, in the order they hurt:**

1. **The documented capture command never leaves the main menu.** A `--shot` on its own
   photographs the title screen; the area is never entered. An author following the document
   would see their brand-new area render as somebody else's menu. `--new-game` is required, and
   nothing anywhere documented the debug harness flags at all — now a table of eight in
   `AUTHORING.md`.
2. **The gate table claimed the boot rung catches "an unresolvable first area".** It does not.
   `--headless --quit-after 120` stops at the main menu and reports `0 warnings, 0 errors`
   without loading any area, so it cannot see a wrong `area_id`, an empty navmesh bake or a
   broken NPC. Gotcha 22's family: a rung reporting clean about work it never did.
3. **`--stand-by=` takes a NODE NAME, not an `object_id`** — and the id is what the same document
   had just told the author to set. It fails with `found no node called ...`.
4. **The NPC placement example omitted its own `[ext_resource]` line** for the NPC prefab, so the
   block could not be used as written. Every worked example is now self-contained.
5. **The navmesh example implied a healthy bake is a big number.** A flat floor bakes **2**
   polygons, which looks like the empty-bake failure and is not. Now: any non-zero count.
6. **The suggested capture hour makes a new area look broken.** A minimal area has no props and
   no lanterns, and at 18:40 it renders very nearly black. Now: capture at midday first.

Two things the walkthrough confirmed rather than corrected, both worth recording because they are
the parts most likely to be got wrong from a document: an override block on a node inside an
instance needs **no `index=`** — the name resolves it, and the stale indices in the demo's
courtyard really are the red herring T2.0 said they were — and one `[editable path=...]` at the
foot of the file is sufficient for both overridden children of one instance.

**`docs_test.gd`, and why prose got a gate at all.** Most of this package is prose and prose is
not assertable. But two things in a consumer document are facts about the repository and both rot
in silence: a `res://` path that no longer resolves, and a field name in a worked example that was
renamed. Both are found by a reader, once, following the document into a dead end and concluding
the template is broken. So the case scans every `.md` in `docs/` plus `CLAUDE.md`, asserts every
`res://` path resolves, and — by reading each fenced block's own script `ext_resource` lines —
asserts that every property named in a worked `.tres`/`.tscn` example exists on the class that
block says the resource is scripted by. The class mapping comes out of the documents, so there is
no second list here to go stale in turn.

**Paths under the content roots are skipped when absent, not failed**, because `docs/` teaches by
example and a stripped template has deleted exactly those files.

**`DEVLOG.md` is exempt, and finding that out was the case's first red.** Its very first run failed
on a path the DEVLOG names under `tests/unit/`: a temporary probe created to prove the runner
fails on a crash, quoted by name, and then correctly deleted. That is a true entry about a path
that should not exist. A log of what was done necessarily names removed files, so the history is
scanned for nothing; everything a reader is meant to *follow* still is. It is also why the two
planted violations below are quoted verbatim in `DEVLOG.md` and only described here.

**Proved red, then green (gotcha 23).** Two planted violations, both the real failure shape rather
than a convenient one: renaming `walk_row` to a name the class does not have, in `ART_CONTRACT.md`'s
worked layout, and repointing one script path in `AUTHORING.md` at a file that does not exist.
Together they produced **6 failures** and exit 1 — one for the dead path, one for the renamed
field, and four for the properties that could no longer be resolved against a missing class. Both
reverted: `1081 passed, 0 failed, 0 skipped`, exit 0. The output is in `DEVLOG.md`.

**Two documents were corrected in passing, because a consumer reads them.** `ARCHITECTURE.md`'s
area diagram listed **eight** children and was missing `Navigation/` and `Waypoints/` — as did
`SYSTEMS_INVENTORY.md`'s row, which said "the eight required children are now asserted" while
`transitions_test.gd` has asserted **ten** since it was written. And two of `ARCHITECTURE.md`'s
"known limitations" had been false since T2.0 and WP-13 — the export path is proven and weather
does render — so they are replaced by the two that were true then: the `Button` styleboxes, and the missing
material and camera exports. The second was closed by T3.2 and its bullet is gone.

**The `Button` stylebox gap was left unfixed, deliberately.** It is one addition to
`ui_theme.tres` with no code, and it was tempting. But a stylebox has to be *designed*, and the
only palette available to design against is the placeholder one — so the result would be a
decision shipped as a default, in a package whose whole job is to describe the template honestly
rather than to change it. It is now stated in three places a consumer actually reaches:
`ART_CONTRACT.md`, `ARCHITECTURE.md`'s limitations, and `CONTEXT.md`. The main-menu capture taken
during the walkthrough shows it plainly.

**Ladder, all green.** `--headless --import` exit 0 with **zero** `SCRIPT ERROR` / `Parse Error`
lines; boot `0 warnings, 0 errors`; suite **1081 passed, 0 failed, 0 skipped**, exit 0;
`check_budgets`, `check_content`, `check_boundary` all exit 0; windowed capture at 18:40 taken and
looked at, and the courtyard is unchanged.

**Why the next package is WP-08 and not a new T-phase row.** Phase T2 closes here: all four exit
criteria are ticked. Phase T3 is *"finish the system catalogue"*, and its packages are the
original WP-08 to WP-15, re-framed — so T3 is the phase and WP-08 is its first package, not an
alternative to it. The board's ordering predates the template reframing and survives it: quests
are a system with **no** proof at all, and the replacement rule is breadth of systems, one shallow
proof each. The five T2.1 leftovers are engine work whose two exit criteria are already met; they belong in a
T3 row of their own rather than reopening T2. That row became **T3.2**, and closed them.

**CI green, run 33086307621, job logs read rather than the tick.** Full checkout
`1081 passed, 0 failed, 0 skipped`; stripped template `1027 passed, 0 failed, 16 skipped`, the
four new skips being exactly the doc-named paths under the content roots that a stripped checkout
has deleted. All three checkers PASS in both jobs.

**Commit:** `36b5abd` on `claude/t2-2-consumer-docs`, PR #15.

---

## T3.1 · A generic content registry — **DONE**

**Read:** the five registries — `src/content/items/item_db.gd`, `dialogue/dialogue_db.gd`,
`npc/schedule_db.gd`, `quest/quest_db.gd`, `world/area_db.gd` — plus `docs/AUTHORING.md` as the
acceptance test and `tests/framework/fixtures.gd` as the seam most likely to break.
**Write:** one scan, and a thin typed façade per catalogue.
**Exit criteria:** the five catalogues behave identically from the outside — same typed
accessors, same ids, same per-file error reporting, same `content_dir` redirection — with the
scan living in one place; **or** the row closed with a measured argument for the five copies.

**THE ROW WAS COSTED TWICE BEFORE THIS CHAT, AND BOTH COSTINGS WERE RIGHT ABOUT THE WRONG
THING.** WP-08 reconsidered at the fourth copy and kept it: GDScript has no generics, so a base
holding the CACHE could only store `Resource` and hand it back untyped, making every accessor a
cast at the call site — against non-negotiable #2. WP-11 made it the fifth and changed only the
arithmetic. Neither verdict is overturned. **What neither weighed is that the duplication was
never in the cache.** It was in the scan, and a scan needs exactly two things from a resource:
its `id`, and its `problems()`. So the base went on the **resource** (`ContentEntry`) and the
shared part is a **function** (`ContentScan.into()`) that fills the *caller's own typed
dictionary*. `ItemDb._by_id` is still `Dictionary[StringName, ItemDefinition]`,
`ItemDb.definition()` still returns `ItemDefinition`, and there is no cast at any call site in
the project. WP-08's constraint was satisfied rather than traded away.

**THE MEASUREMENT, WRITTEN DOWN AS THE ROW ASKED, in code lines as `check_budgets` counts them.**

| | before | after |
|---|---|---|
| `item_db.gd` | 70 | 36 |
| `dialogue_db.gd` | 53 | 36 |
| `schedule_db.gd` | 53 | 36 |
| `quest_db.gd` | 53 | 36 |
| `area_db.gd` | 61 | 43 |
| **five registries** | **290** | **187** |
| `content_scan.gd` | — | 39 |
| `content_entry.gd` | — | 5 |
| **total** | **290** | **231** |

Net −59 lines, and that is the *least* interesting number. What was genuinely identical across
the five was `_register()` at 17 lines apiece — the load, the type check, the id-equals-filename
check, the duplicate check and the `problems()` append — plus a five-line `_ensure_loaded()`.
Roughly a hundred lines of copy became one twenty-line function, so **a bug in the id check, the
duplicate check, the type check or the `.remap` handling is now one fix instead of five.** What
did NOT move is the part that carries a type: each façade keeps its own `content_dir`, its own
typed `_by_id`, and its own accessor. Five wrappers of the same length was the outcome to avoid
and it did not happen — `has()`, `all()`, `count()`, `problems()` and `rescan()` were never the
duplication, they are three lines each and they name their own type.

**A STATIC BASE CLASS WOULD HAVE BEEN A DISASTER, AND IT TOOK A PROBE TO KNOW IT — NEW GOTCHA
37.** The obvious shape is `ItemDb extends ContentDb`, with `_by_id`, `_loaded` and `content_dir`
as `static var`s on the base. Measured under 4.7.2 with two throwaway subclasses bumping a base
counter: `A.shared=3 B.shared=3 Base.shared=3`. **A base-class `static var` is ONE storage shared
by every subclass.** Five registries inheriting it would have shared one cache and one
`content_dir`, so `Fixtures.activate()` would have pointed all five at one folder and four
catalogues would have come back empty — with every accessor still typed and the shape still
looking right. That is why the shared part had to be a function.

**`ItemDb.resource_paths()` BECAME `ContentScan.resource_paths()`, and no alias was left.** The
function was always the shared scan; four registries, `check_content.gd`, `catalogue_report.gd`
and three test cases called it through the item registry, and `path_actions_test.gd` scanned
**path actions** through it. Three registry headers spent a paragraph apologising for the call.
Nine call sites, one identifier each, and three headers got shorter. A delegating alias was
considered and refused: the point of the package is one implementation with one name.

**WHAT THE `ContentEntry` BASE IS ACTUALLY FOR, because "a base class for tidiness" would be the
wrong reason.** `project.godot` sets `unsafe_property_access` and `unsafe_method_access` to
**error**, so a shared scan reading `resource.id` or calling `resource.problems()` through a
`Resource` does not compile. `ContentEntry` is what makes the shared scan legal. It holds exactly
the two members the scan uses and its `MUST NOT` says so: a field belongs there only when the
SCAN uses it.

**THE ACCEPTANCE TEST WAS `AUTHORING.md`, AND NOT ONE WORD OF IT CHANGED.** It names `ItemDb`
once, describes the scan, the folders and the id-equals-filename rule, and every sentence is
still true. Neither did `data/`: the demo's `.tres` files were untouched and load unchanged with
`id` now declared on the base.

**47 NEW ASSERTIONS, AND THEY ARE ABOUT THE FAILURE MODE A SHARED SCAN HAS.**
`tests/unit/content_scan_test.gd` drives `ContentScan.into()` directly for every branch it has —
empty root, absent root, sound file, id mismatch naming both values, a resource of the wrong
type, a `.tres`/`.res` duplicate, an empty prefix, and a resource whose own `problems()` must
reach the caller — and then plants the *same* violation in all five fixture roots at once and
names each registry: **a shared scan is exactly the change that can leave four catalogues
reporting a bad file and the fifth silent.** It also asserts that one bad file costs the
catalogue exactly that file, because a scan that gave up on the first problem would satisfy every
other assertion in the file.

**THE ONE THING THE TEST GOT WRONG FIRST, and it is worth the line.** Re-saving a *different*
`AreaDef` over a path already loaded in the same run handed the scan back the FIRST resource:
`ResourceLoader` caches by path. One failing assertion — `expected 1, got 0` — was the only
trace, and the fix is a second id rather than a second write. Anything in the suite that expects
a re-authored file to be re-read needs a new path.

**Verified.** `--headless --import` with zero `SCRIPT ERROR` / `Parse Error`; boot
`0 warnings, 0 errors`; **`1402 passed, 0 failed, 0 skipped`** (was 1355 — +47, none lost);
`check_budgets` 125 files / 10,506 code lines / 0 warnings / 0 violations; `check_content` PASS;
`check_boundary` PASS over 119 engine scripts. **Stripped template run locally** — `data/` and
`scenes/areas/` moved aside — `1334 passed, 0 failed, 19 skipped` (was 1287/19), both checkers
exit 0, which is the rung that proves an empty content root is still not an error.

**The gates were proved failing, not assumed (gotcha 23).** Two real violations planted in
`data/items/`: `planted_mismatch.tres` carrying `id = &"item/mismatched"`, and
`planted_broken.tres` containing one line of prose. `check_content` exit **1**, naming both —
`planted_broken.tres is not an ItemDefinition`, and
`planted_mismatch.tres declares id 'item/mismatched' but its file name requires
'item/planted_mismatch'`. Both removed; exit **0**. The verbatim output, with the full paths, is
in `DEVLOG.md`, which is the one document exempt from the `res://`-path gate.
The suite's own exit-1 was proved by the
accidental `ResourceLoader` cache failure above — `1401 passed, 1 failed`, exit 1.

**A windowed capture, although there should have been nothing to see, and there was not.**
`--new-game --shot-frame=70 --quit-after 90 --time=12:00`: the courtyard at midday with the
player, the keeper, the sign, the pickup, the HUD clock and the `Read Weathered Notice` prompt —
indistinguishable from WP-09b's. The boot readout still names every catalogue and its resolved
paths: `items: 4`, `dialogue: 1`, `schedules: 1`, `quests: 1`, `areas: 2`. **If a screen had
changed, the refactor had leaked.** No temporary probe was needed: this package touches no input
and no audio path. `src/systems/debug/catalogue_report.gd` carries one deliberate line — the
`resource_paths` rename — and nothing else.

**Files: 20, and the board's "about 8" is worth explaining rather than quietly exceeding.** Two
new engine files, five registries rewritten, five resource classes changed by one `extends` line
each, one new test case, and eleven single-identifier renames the compiler would have caught. New
code is **negative**. A refactor's file count is a poor proxy for how much of a chat it costs, and
the rule's own reasoning — a package that outgrows one chat gets half-finished — was never in
danger here.

**Why this was taken over T3.2 and T3.3.** T3.2 is five deferred art seams and T3.3 adds a
capability. This row was the only one on the board that was pure debt with a known interest rate,
and it was the one that got *worse* every package — a sixth catalogue would have been a sixth
copy. **T3.3 is next**: "bring me three petals" is still not authorable, which is a limit on what
a consuming game can express, and `TEMPLATE.md`'s replacement rule puts breadth of expression
ahead of art seams.

**Not built, and said rather than dropped:** a sixth catalogue, a hot-reload or file-watcher on
the content roots, a content editor, async or threaded scanning, a cache that outlives a session,
and any change to what a `.tres` may contain. `ContentScan` also does not recurse into
subdirectories — neither did any of the five copies, and a nested content root is a request
nobody has made.

**Commit:** `767fbe3` on `claude/t3-1-registry`, PR #20 — stacked onto
`claude/wp-09b-attributes`, matching the rest of the chain.

---

## T3.3 · A quest step that can read an ITEM COUNT — **DONE**

**Read:** `src/content/quest/quest_step.gd`, `src/systems/quest/quest_tracker.gd`,
`src/core/state/flag_query.gd`, `src/gameplay/character/inventory.gd`, plus `AUTHORING.md`'s quest
and item sections read as a consumer would.
**Write:** a step that can require N of an item id, without the quest system learning what an
inventory is.
**Exit criteria:** the journal shows the progress, the step completes at the threshold, and it
uncompletes or does not — per a decision stated out loud and asserted.

### The row was scoped once and it named two designs. This is the FIRST one, with the cost that made it look expensive removed.

WP-09 declined to close this and costed both candidates rather than shrugging:

> an `Inventory` that mirrored `count/<item>` into `Flags` would write every carried item into the
> flag section as well as its own, and a `QuestStep` that read the bag directly would put
> `gameplay/Inventory` inside a `systems` tracker against the layer rule.

**The second one is not a design, it is the layer rule being broken**, and WP-08 had already
refused exactly that once — the `reward_item` field. So the choice was the first one or nothing,
and the whole question was whether its stated cost is real.

**It is not, and one line of `flags.gd` is why.** The cost was "the same number is now in the save
file twice, written by two participants in two formats" — which is a genuinely bad trade, and it is
also the thing `flags.gd`'s own header forbids: *"WHAT DOES NOT BELONG HERE: anything recomputable.
If it can be derived, derive it."* A count mirrored into `Flags` is recomputable BY DEFINITION,
because the bag it came from is the truth and is already saved. So the mirror is declared DERIVED:

```gdscript
Flags.declare_derived(BagKeys.PREFIX)          # Inventory._ready
```

and `Flags._collect_save` skips those keys. The published count is readable, announced on
`flag_changed`, visible to `FlagQuery` — and absent from the save file. **`Inventory.SAVE_VERSION`
did not move, `Flags`'s format did not change, and there is no migration**, which is the answer to
the package's "a new field on a saved resource may need a version bump": nothing new is saved.

### The one decision everything else follows from: THE DEPENDENCY POINTS DOWN, so the quest system was not touched at all.

```
bag/<carrier_id>/<item id>          bag/player/item/rose_petal -> 3
```

`Inventory` (`gameplay`) writes to `Flags` (`core`). `QuestTracker` (`systems`) reads `Flags`
through the `FlagQuery` it already used. **Neither has heard of the other**, and the inversion is
the entire package: a tracker reading a bag points UP, a bag publishing a flag points DOWN, and
they deliver the same capability.

What that bought, and none of it is a coincidence — it is WP-08's seam used for the **third** time
after `Equipment`:

- **`QuestStep` gained no field.** Not `required_item`, not `required_count`. A counted step is
  `condition_flag = &"bag/player/item/rose_petal"`, `condition_test = 4`, `condition_value = 3` —
  the closed set of six comparisons, unchanged since WP-08.
- **`QuestTracker` gained no knowledge.** Its one new function, `step_progress`, is a pass-through
  to `FlagQuery`; it names no `Inventory`, no `ItemDb` and no `BagKeys`.
- **Nothing that writes a count had to change.** A `Pickup`, an `ItemContainer`, `--give=` and a
  restored save all go through `Inventory.add`, so all four advance a counted step already.
- **Sixth namespace-over-`Flags`**, after `PersistentState`, `Standing`, `Equipment`, `WorldMap` and
  `Attributes` — and the first whose value is a NUMBER rather than a truth.

**And a test fails if that stops being true.** `item_count_test.gd`'s last block text-scans
`quest_tracker.gd` and `quest_step.gd` for `Inventory`, `ItemDb.` and `BagKeys`, and
`journal_screen.gd` for `Flags.`. Nothing else in the suite could fail if the tracker started
reading a bag directly — **the behaviour would be identical and the layer rule would be gone** —
which is the same reasoning `art_contract_test.gd` uses to keep a sheet dimension out of
`character_visual.gd`. It also asserts that exactly ONE file under `src/` builds a bag key.

**The first version of that block was WRONG in an instructive way.** A raw text scan failed on both
files, because both HEADERS explain at length why an `Inventory` is not reachable from them — so
the gate fired on the paragraph documenting the rule it enforces. `check_boundary` had already drawn
this line: **comments are exempt, code is not.** The block now strips comment lines first.

### `BagKeys` is its own file, and the reason is a compile error rather than tidiness.

Three places need the key shape and none may rebuild it: `Inventory` WRITES it,
`tools/check_content.gd` PARSES it back to validate the item id, and the suite asserts on it.
`Equipment.PREFIX` lives on `Equipment` and that could not work here: `check_content` runs under
`--headless --script`, where autoload identifiers do not resolve, so naming `Inventory.PREFIX`
would not COMPILE — the mechanism that file's own header calls a real enforcement of the layer
rule. `src/core/state/bag_keys.gd` touches no autoload, and its MUST NOT says it must not start.

The parser earns its place on one line: **an item id contains a slash**, so the carrier is the
FIRST segment after the prefix and the item id is everything left. Splitting on the last slash
answers `rose_petal`, which `ItemDb` would then fail to find — a validator failing on valid content
is worse than no validator. That round trip is an assertion.

### THE UNCOMPLETE QUESTION, STATED OUT LOUD: a step reopens, a quest does not — and no new decision was needed.

This is the exit criterion that asked for a decision, and the honest answer is that WP-08 had
already made it and `quest_tracker.gd`'s header names **this exact case**:

> A step may test AT_LEAST 3 on a counter; if something later decrements it, a finished quest would
> reopen. Completion is a fact about history, not about the world right now.

So: **spend a petal on an ACTIVE quest and the objective comes back**, because a step is a live
question. **Spend one after the quest settled and nothing happens**, because completion is latched
and saved. Both halves are asserted against the thing that finally decrements — a bag — rather than
against a flag written by hand, which is all the suite could do before. The package's contribution
here is not a decision; it is the first real test of one.

Two adjacent behaviours, also asserted: a count **already satisfied** when the quest starts passes
its step at once (a step is never "reached"), and a FOURTH petal does not un-finish a step needing
three, because the test is `AT_LEAST` and not `EQUALS`.

### The journal draws the tally, and it still reads no flag.

`— Gather three rose petals.   2 / 3`, from `ui.journal.progress`. An objective line is a FORMAT,
so the format is a localization key and not a `"%s / %s"` in a screen file.

`journal_screen.gd`'s MUST NOT line forbids it from reading a flag, and drawing "2 / 3" needs the
current value of one. Non-negotiable #4 says: when a change needs a MUST NOT broken, add a system
instead of widening the boundary. So `FlagQuery.progress()` answers `(have, need)` — where the
comparison table already lives — and `QuestTracker.step_progress()` passes it through, so the
screen still talks to nothing but the tracker.

**`need == 0` means "not a count", and two of the six tests deliberately return it.** `AT_MOST` is
a CEILING: drawing `2 / 3` under *keep it below three* would tell the player to gather more of the
one thing they must not. And a `condition_value` of 0 is not a count either — `AT_LEAST 0` passes
with an empty bag, so it is an unconditional step wearing an errand's clothes.

### The new content gate, and why validating THIS flag namespace is not a contradiction.

`check_content` prints every quest flag and validates none of them, on a rule WP-08 wrote down: a
flag can be written from a scene, a conversation, a path action or at runtime, so failing on one
with no findable writer would be wrong most times it fired. **`bag/<carrier>/<item id>` is different
in the one way that matters: it has exactly ONE writer, and half the key is an item id this tool can
look up.** So three mistakes that are otherwise completely silent now fail the build:

- an item id **no `.tres` declares** — the count reads zero forever and the objective never clears;
- a **count of zero**, which is always satisfied;
- a bag key under a test that is **not a count** — worse than the others, because `get_bool` on an
  int warns and answers false, so the step can never pass at all.

The carrier is deliberately NOT validated, and the omission is stated rather than papered over: a
`carrier_id` is an `@export` on a node in a scene this tool does not open, and a game may put a bag
on an NPC or a stash. Same line `_all_waypoint_names` draws.

`_condition_text` also now prints the VALUE for the tests that use one. The first version did not,
and `bag/player/item/rose_petal at_least` in the build log says nothing about the errand a reviewer
is checking.

### ALL THREE BRANCHES PROVED RED, THEN GREEN, WITH THE REAL FAILURE SHAPE (gotcha 23).

Planted in `data/quests/keepers_errand.tres`, one at a time, each reverted:

1. **A plural slip on the item id** — `item/rose_petals`. `check_content` exit **1**:
   `quest/keepers_errand/petals counts 'item/rose_petals', which no item .tres declares`.
2. **`condition_value = 0`.** Exit **1**:
   `quest/keepers_errand/petals asks for 0 of 'item/rose_petal'; a count below one is always satisfied`.
3. **`condition_test = 1`** (IS_TRUE on a count). Exit **1**:
   `quest/keepers_errand/petals tests an item count with is_true, which is not a count`.

Reverted after each: exit **0**, with `petals done when bag/player/item/rose_petal at_least 3` in
the build log.

**And the suite's own exit 1, on the invariant rather than on a broken assertion.** The load-bearing
invariant is that every path which moves a count republishes, so `_publish()` was deleted from
`remove()` — the way it would really be lost. Exit **1**, `1460 passed, 9 failed`, first failure
*"spending two republishes one — expected 1, got 3"*, and `error_watch.gd` additionally caught the
downstream crash: a quest wrongly completed, so `current_step` answered null. Restored:
`1468 passed, 0 failed`, exit 0.

### One latent defect found, because the design could not tolerate it.

**A new game did not empty the bag.** `Director.start_new_game()` clears the flags, resets the
playtime and emits `game_started`; nothing was listening on behalf of `Inventory`, so the previous
run's items carried into a fresh game. Unreachable in practice — the boot goes to the main menu with
an empty bag — and invisible to every gate, because nothing asserted it.

It surfaced only because this design *cannot* tolerate it: the flags are cleared and `_counts` is
not, so the mirror and the truth disagree the moment a new game starts. `Inventory` now clears on
`game_started` and republishes on `game_loaded` — the second because `Flags._apply_save` wipes the
store and the derived keys are deliberately not in the file it restores from, so **the answer must
not depend on save-participant order**, and `game_loaded` fires once after every section is applied.
Both are asserted.

**And that made `--give=` need the area wait**, which is gotcha 32 for the FOURTH time after
`--open-menu`, `--flag` and `--open-inventory`: items staged during argument parsing are now thrown
away by the new game a frame later. Given the wait, `--give` and `--equip` would then leave
`_wait_for_area` on the same frame and be ordered by chance — gotcha 35 — so `--equip` waits one
frame more. That is an ordering rather than a race, and it was **verified both ways round on the
command line**: `--equip` reports `true` whether it is typed before or after `--give`.

### Two windowed captures, LOOKED AT and READ rather than glanced at (gotcha 28).

Both `--new-game --open-menu=journal --shot-frame=110 --quit-after 130 --time=12:00 --freeze-time`,
so the two differ by exactly one petal:

- **`--give=item/rose_petal:2`** — `Journal / Underway / The Keeper's Errand /
  — Gather three rose petals.   2 / 3`, with the *New errand* toast up, the HUD reading
  `Day 1 | 12:00 | Midday`, and the courtyard visible and stopped behind the dim panel. The tally
  is a **checkable prediction** and not a screenshot that merely looks fine: two given, three
  required.
- **`--give=item/rose_petal:3`** — the same screen, same camera, same hour: `Settled /
  The Keeper's Errand / — Nothing left to do.` The log line between them is
  `quest/keepers_errand: completed`.

The staging log is the other half of the reading, because it shows the objective walking forward
through steps the demo already had: `--give item/rose_petal x2: true`, then `started`, then
`advanced [unlock]`, `advanced [dais]`, `advanced [petals]`.

**No temporary probe was needed and none was left** (gotcha 15). This package touches no input path
and no audio path — `J` was proved by WP-08's probe and `ScreenKeys` was not touched.
`git diff src/systems/debug/` carries only the `--give` wait, the `--equip` frame gap and their
header lines.

### The demo gained ONE step and one petal, and no new object.

A third step on `keepers_errand`, last so the two existing objectives and both WP-08 captures still
mean what they meant, and the courtyard chest holds three petals instead of two so the errand can
actually be finished. **One piece of placeholder content per system**: no second quest, no second
item, no new pickup.

### Files: 14, and new code is 312 lines added against 22 removed.

`src/core/state/bag_keys.gd` (28 code lines, new) · `flags.gd` (+`declare_derived`, `is_derived`,
and `_collect_save` skipping them) · `flag_query.gd` (+`progress`) · `inventory.gd`
(+`carrier_id`, `_publish`, the two subscriptions) · `quest_tracker.gd` (+`step_progress`) ·
`journal_screen.gd` (the tally line) · `dev_stage.gd` (the `--give` wait, the `--equip` frame gap) ·
`tools/check_content.gd` (`_check_item_count`, `_condition_text` with its value, `_test_name`) ·
`data/quests/keepers_errand.tres` and `courtyard.tscn` and 3 CSV rows ·
`tests/unit/item_count_test.gd` (66 outcomes, new) · `fixture_content.gd` (a second fixture quest
and a counted `quest_step`) · `fixtures.gd` · `content_scan_test.gd` (its hard-coded `1` became
`FixtureContent.quests().size()`, on the same reasoning as a computed plan) ·
`docs/AUTHORING.md` § Count items in a quest step.
1402 → **1468**.

### Ladder, all green.

`--headless --import` with **zero** `SCRIPT ERROR` / `Parse Error` lines; boot
`0 warnings, 0 errors`; suite **1468 passed, 0 failed, 0 skipped**, exit 0; `check_budgets`
**127 files, 10,869 code lines, 0 warnings, 0 violations**; `check_content` PASS; `check_boundary`
PASS over 121 engine scripts, deriving 16 demo names and finding none of them in `src/` or `tests/`.

**Stripped template, run locally** — `1400 passed, 0 failed, **19** skipped` (was 1334/19), both
checkers exit 0, `quests: 0` and `demo names derived: 0`. **The skip count did not move**: all 66
new assertions are fixtures all the way down and every one runs in a checkout with no game in it.

### Deferred, with reasons, not silently.

- **A step that TAKES the items.** A completed quest still emits `quest_completed` and stops —
  WP-08's layer reason holds exactly as it did, and a consuming game that wants the petals handed
  over listens to the signal or puts an `ItemContainer` in front of the keeper.
- **No sixth catalogue.** T3.1 made one cheap and WP-09b declined one deliberately; a count needs no
  resource, no registry and no save section, which is `Attributes`' argument used a second time.
- **`AT_MOST` draws no tally**, on purpose — see above. And `EQUALS` counts, though nothing authored
  uses it.
- **No count in the inventory screen's rows beyond `xN`**, no "quest item" marker, and no objective
  marker on the map — `quest_advanced` has an emitter, so a marker is a listener plus one more
  `MapScreen` state, and that is WP-11's deferred row rather than this one.
- **The carrier is not validated by any gate**, stated above.
- **Branching quests, a failure state, timed quests, item instances and a journal detail pane** are
  all still deferred, unchanged.
- Combat is still not a thing, and a count of arrows would not change that.

**CI green, run 33529911105, job logs read rather than the tick** (gotcha 26). Full checkout
**1468 passed, 0 failed, 0 skipped** with `item definitions: 4` and `quests: 1`; stripped template
**1400 passed, 0 failed, 19 skipped** with `item definitions: 0` and `quests: 0`. All three checkers
PASS in both jobs. **19 skips in both the previous run and this one** — no new skip to name, because
the counted step is proved on a fixture quest and a fixture item that a stripped checkout still
writes to `user://`. The push run (33529829466) and the pull-request run (33529893285) are green
too.

**Commit:** `292dd44` on `claude/t3-3-item-count`, PR #21 — stacked onto `claude/t3-1-registry`
(#20) rather than `main`, matching the rest of the chain.

---

## T3.2 · The five art-contract seams T2.1 left — **DONE**

**This is the last T-numbered row of Phase T3, and the phase is NOT closed by it.** WP-14 is still
TODO and WP-15 has a remnant; the phase's exit criterion is about systems having a proof, not
about T-rows being finished. The chip this package raises is for WP-14.

**Read:** `docs/ART_CONTRACT.md` as the consumer it is written for, `docs/CONTEXT.md` gotcha 30,
and the two area scenes, `src/gameplay/world/environment_driver.gd`,
`src/gameplay/camera/hd2d_camera_rig.gd`, `project.godot`, `.gitattributes`.
**Write:** whatever each of the five needs — including nothing, said out loud.
**Exit criteria:** for each of the five, either the seam EXISTS and a change to one file
demonstrably changes what is rendered, or it is REFUSED in writing with the reason, where an
artist reads it. Either way each is mentioned in exactly **one** place afterwards.

### The row's real deliverable was the fifth criterion, not the first four.

These five were named in `CONTEXT.md`, `ROADMAP.md`, `WORK_PACKAGES.md`, `ARCHITECTURE.md` and
`ART_CONTRACT.md` — five documents, four of them too many, each saying a slightly different thing
about work nobody was doing. A backlog item mentioned in five places is not tracked five times; it
is tracked zero times and described five times, and the descriptions drift. So half the acceptance test
here is documentary, and it is worth stating PRECISELY, because the loose version of it is not
what was achieved. **What is now in exactly one place is the CURRENT STATE of each seam — the
thing a reader would act on — and that place is `ART_CONTRACT.md`.** The four stale claims are
gone: `ARCHITECTURE.md`'s "no shared material library" bullet is deleted, `CONTEXT.md`'s "Not
built" line no longer lists them, `ROADMAP.md`'s T2.1 entry says "closed by T3.2" instead of
reciting the five, and `.gitattributes` points at `ART_CONTRACT.md` instead of restating the LFS
reason.

Each seam is still NAMED in several documents, and that is correct rather than a failure to
finish: a package section in this file, a settled decision in `CONTEXT.md`, a row in
`SYSTEMS_INVENTORY.md` and a gotcha are the project's standard record shape for finished work, and
none of them is a description of pending work that can drift out of date. **The difference that
mattered was never the number of mentions; it was five documents each independently describing
something nobody was doing.** Nothing was deleted from the record either: T2.1's own section still
says what T2.1 left, because that is still true, and now says where to read what happened to it.

**Four built, one refused.** The refusal is written where an artist reads it, with the reason and
with the steps to turn it on, which is a different artefact from silence.

### 1. Shared materials — BUILT, and the defect was already in the tree.

`assets/materials/wood.tres`, pointed at by both areas with an `ExtResource`. The two demo areas
had each grown a **byte-identical** `StandardMaterial3D` called `m_wood` — same texture, same
`texture_filter = 0`, same `uv1_scale = Vector3(2, 2, 1)` — and neither file could see the other.

**A library of ONE, and that is the whole argument.** The other five materials across the two
areas are deliberately still inline, because they are not duplicates: one area tiles stone at
`(3, 3)` and the other floors it at `(8, 8)` and walls it at `(6, 2)`. **A tiling rate is a
property of the surface it is stretched over, not of the substance**, so hoisting those would give
a shared file with a per-area override on every user — the duplication with an extra indirection,
and a palette instead of a seam. A material is shared when two areas genuinely want the same
thing, and exactly one of six did.

Nothing under `src/` knows the folder exists. A shared material is a scene-authoring convention,
not a system: no registry, no id, no directory scan, no sixth catalogue.

**What already made this safe, and it was not planned for this:** `SurfaceWetness` duplicates
every material before darkening it (WP-13's settled decision). Without that, rain in the courtyard
would leave the hall's plinth wet on the far side of an area change — the exact failure a shared
sub-resource invites, closed a package before it could happen.

### 2. The environment post stack — BUILT, twenty exports at the values T2.1 shipped.

`_build_post_stack()` held twenty literals. All twenty are now `@export`s on `EnvironmentDriver`,
in two groups, **at exactly the values they had**, so no area that leaves them alone renders
differently — the point of the seam is that a game can reach them, not that anything moved.

**Per AREA, not per project, and not a resource.** The driver already lives in the area scene and
its `Interior` group already varies that way; a game wanting one look everywhere authors its areas
from one copy. A `.tres` "environment look" resource was considered and dropped: it is the shape
`SpriteSheetLayout` has, but a layout is *shared between nodes in one scene* while a post stack is
*one per area* — so it would have added a resource class, a folder and a wiring step to reach
exactly the same set of numbers.

**What stayed in code, and why that is not half a job.** The tonemapper, the fog mode, the glow
blend mode, `AMBIENT_SOURCE_COLOR` and `BG_SKY` are the STRUCTURE the rest of the file assumes,
not numbers an area tunes — `_apply_now` writes `ambient_light_color` every frame, which only
means anything if the source is a colour. The four expensive effects (`ssao`, `sdfgi`, `ssil`,
`ssr`) ARE exports despite being `false` everywhere, because "revisit only if the look demands it"
is a decision for the game and **a value a consuming game cannot reach is not a seam, it is an
opinion.** The day/night KEYFRAMES table is untouched and no seam is claimed for it: that is a
curve, not a look setting.

### 3. Per-area camera framing — the seam ALREADY EXISTED, and the row was wrong about it.

`HD2DCameraRig` has carried `distance`, `fov`, `pitch_degrees`, `height_offset`, `follow_lag`,
`frame_bias` and the whole depth-of-field group as `@export`s since it was written, and its header
has said "duplicate it and change the numbers" the whole time. What was missing was **an area
using them** — both demo areas took every default, so the claim had never been run.

So this one cost an authored value and a capture rather than an implementation: the interior now
frames at `distance = 9.5, fov = 36.0, height_offset = 0.95` against the outdoor `14.0 / 27.0 /
1.15`, because a room reads better close. One run logs both — `Rig ready: fov 27.0, distance 14.0`
then `Rig ready: fov 36.0, distance 9.5` — which is the seam being two different things in one
session rather than a setting that parsed.

**Reporting a seam as missing when it exists is its own kind of stale**, and it is why the
five-mentions problem was worth a package: the claim was copied between documents four times
without anyone opening the file.

### 4. The texture import defaults — BUILT, and gotcha 30 is now WRONG.

T2.1 stopped here on a sound rule: `[importer_defaults]` is undocumented, absent from `--doctool`,
and this project checks every name against the API dump before typing it. **The rule was right and
the conclusion was not**, because there is a stronger form of evidence available and it is
non-negotiable #1: *run the engine.*

The measurement, in four steps. A throwaway texture was copied into a scratch folder under `res://`
and imported with stock defaults (`detect_3d/compress_to=1`, `mipmaps/generate=false`); the section was
written into `project.godot`; the generated `.import` was DELETED; and `--headless --import`
regenerated it. It came back carrying `detect_3d/compress_to=0` and `mipmaps/generate=true`. A
second probe confirmed `ProjectSettings.get_setting("importer_defaults/texture")` returns it as a
Dictionary at runtime — `type=27 value={ "detect_3d/compress_to": 0, "mipmaps/generate": true }` —
which is what makes it assertable. Both are quoted in `DEVLOG.md`, and the probe directory is gone.

**Exactly one value is set in the end**, `detect_3d/compress_to = 0`, because exactly one was
wrong: it is the editor's "this texture was used in 3D, switch it to VRAM compression" rewrite, and
every character sheet in an HD-2D game IS used in 3D through `Sprite3D`. `mipmaps/generate` was
only the control value — it moved `false → true` to prove the section applied, and was removed.
The three other values `ART_CONTRACT.md` recommended turn out to be Godot's own defaults already,
measured on the untouched probe, so setting them would have been ceremony. **A default nobody
needs is a default nobody maintains.**

All eight committed `.import` files moved `1 → 0` too, so the hazard is closed for what is here as
well as for what a game imports next — and the sheets were re-imported and photographed, because
a compression change is precisely the edit that looks applied and silently ruins pixel art.

### 5. Git LFS — REFUSED, in writing, with the reason and the turn-on steps.

Two of the three reasons were already recorded: pointers for a 2 KB procedural placeholder are
pure overhead, and enabling them puts the CI checkout on a dependency it does not declare
(`actions/checkout` needs `lfs: true`, and without it every PNG arrives as a text pointer and the
import fails). The third is the one that decides it and had not been said: **this template cannot
verify the change it would be making.** Proving LFS works needs an LFS-enabled remote and a CI run
against real binaries, and neither exists while art is deferred. A configuration nobody can test
is exactly the change that looks applied and does nothing.

So it is refused rather than omitted, and the difference is that `ART_CONTRACT.md` now names the
three steps to turn it on. `.gitattributes` keeps the commented line and **stops restating the
reason** — its comment is a pointer, because that file was the fifth mention this package existed
to remove.

### The assertions, and the one that found a defect in itself.

`tests/unit/area_look_test.gd`, **47 new assertions**, 1,468 → 1,515 — and then to **1,517**,
because `docs_test.gd` COMPUTES its plan from the documents and this package added two `res://`
paths to them. Said rather than absorbed: the gate proofs below were run at 1,515, before the
documentation was written. The shape is the one
`art_contract_test.gd` established: fail if a hard-coded value grows back.

- `_the_driver_assigns_no_number_to_the_environment` — zero code lines matching
  `^_environment\.[a-z_0-9]+ = -?[0-9]`. A CALL is not a literal, deliberately: `maxf(0.1, …)`
  clamps a computed value and is not a look decision, so only the first token after `=` is judged.
- `_the_rig_assigns_no_number_to_its_camera` — the same over `camera.` and `_attributes.`.
- Twenty plus thirteen assertions pairing each export's live value with `@export` appearing on its
  declaration line, so a rename, a deletion and a moved default all fail by name.
- `_no_two_areas_declare_the_same_material_inline` — sub-resource bodies compared with
  `ExtResource` ids resolved to paths, because the same material carries different ids in
  different scenes, which is why two copies of it were invisible in the first place.
- `_the_texture_import_defaults_close_the_3d_compression_hazard` — the project setting AND every
  committed `.import`, naming the offenders in the failure message.

**A gate that never fails has never been tested, and one of these was not a gate.**
`_an_area_really_uses_the_framing_seam` passed with the override deleted, because it scanned every
line of an area scene and `WeatherVisuals` also exports a **`height_offset`** — two classes, one
property name, gotcha 17's family. Found by planting the real violation, which is the entire
argument for planting it. It now walks `[node]` blocks and reads only those whose `script`
resolves to the rig, buffering each block and judging it at the end rather than from the moment
the `script` line goes by, since a property authored above `script` is legal `.tscn`.

### Six gates proved RED with the real violation, then green (gotcha 23).

| Planted | Output | Exit |
|---|---|---|
| both areas' `m_wood` re-inlined | `FAILED: no two areas declare the same material inline (1 duplicated) — expected 0, got 1`, plus the 2 skips a shared material with no users correctly produces | 1 |
| `_environment.glow_intensity = 0.9` | `FAILED: the driver writes down no environment number — expected 0, got 1` | 1 |
| `camera.fov = 27.0` | `FAILED: the rig writes down no camera or depth-of-field number — expected 0, got 1` | 1 |
| `"detect_3d/compress_to": 1` and one `.import` back to `=1` | `FAILED: the default disables the 3D re-import to VRAM compression` and `FAILED: every committed texture .import disables 3D detection: ["res://assets/placeholder/character_placeholder.png.import"]` | 1 |
| the hall's three framing lines deleted | first draft: **passed** — the defect above. After the fix: `FAILED: at least one camera rig in an area authors its own framing — expected true, got false` | 1 |
| the `glow_intensity` default moved to `0.8` | `FAILED: glow_intensity is an @export at the value T2.1 shipped — expected [0.9, true], got [0.8, true]` | 1 |

All reverted, all green again: `1515 passed, 0 failed, 0 skipped` — 1,517 once the documents were
written, for the reason above.

### Six windowed captures, LOOKED AT and READ. This package is entirely visual.

All at `--new-game … --time=12:00 --freeze-time`, midday rather than dusk (gotcha 31: a propless
area at 18:40 renders near-black and looks exactly like a lighting bug), and the interior needs
`--goto` with `--shot-frame=95 --quit-after 110` because no ordinary run enters an area at all.

Captures 1 and 2 are the baselines. **Seam 1:** one line added to `assets/materials/wood.tres` —
`albedo_color = Color(0.85, 0.15, 0.55, 1)` — and captures 3 and 4 show the courtyard's dais AND
the hall's plinth both magenta, from **one file neither area contains**. Reverted. **Seam 2:** one
line added to `courtyard.tscn`'s driver node, `volumetric_fog_density = 0.06`, and capture 5 is
the same frame hazed to the horizon with the sky wall gone milky — everything else identical.
Reverted. **Seam 3:** capture 6 against capture 2, the same interior at the same hour with the
player sprite drawn at roughly 130 px against 78 and the floor grid visibly larger. Kept, as the
one piece of placeholder content proving the seam.

**The `.import` change was photographed rather than assumed.** All six captures were taken AFTER
the eight `.import` files moved to `detect_3d/compress_to=0` and the project re-imported: the
character sprites are crisp, hard-edged and free of block artefacts, and `compress/mode=0` still
reads `0` in all eight files. This is the check the exit criteria singled out, because a
compression change is the one edit that passes every rung and ruins the picture.

### Files: 13, and the only new code is a test.

`assets/materials/wood.tres` (new), `courtyard.tscn`, `lantern_hall.tscn`,
`environment_driver.gd` (+22 code lines, 183 → 205 of 250), eight `.import` files, `project.godot`,
`.gitattributes`, `tests/unit/area_look_test.gd` (new, 227 of 250), `tests/test_runner.gd`, and the
documents. `hd2d_camera_rig.gd` was **not touched** — the seam was already there.

### Ladder, all green.

`--headless --import` with **zero** `SCRIPT ERROR` / `Parse Error` lines; boot
`0 warnings, 0 errors`; suite **1517 passed, 0 failed, 0 skipped**, exit 0; `check_budgets`
**128 files, 11,119 code lines, 0 warnings, 0 violations**; `check_content` PASS; `check_boundary`
PASS over 122 engine scripts, deriving 16 demo names and finding none of them.

**Stripped template, run locally** — `1445 passed, 0 failed, **23** skipped` (was `1400 / 19`),
both checkers exit 0, `demo names derived: 0`. **The skip count MOVED and the four new ones are
named**, because a skip nobody names is a stripped run pretending to be a full one. All four are
`area_look_test`'s three content-dependent blocks — a shared material with no areas to use it
(2 outcomes), the inline-duplicate gate with fewer than two areas to compare, and no area to author
framing — and every one is correctly a claim about CONTENT rather than about the engine. The
arithmetic closes exactly: of the case's 47 outcomes, 4 skip and 43 run, and the remaining +2 on
the passed count is `docs_test` picking up the two new `res://` paths the documents name, both
under `assets/`, which a stripped checkout keeps.

### Deferred, with reasons, not silently.

- **The day/night keyframe table** is still a `const`. It is a curve rather than a look setting,
  and no document has ever listed it as a seam. Say so before building it, not after.
- **The `Button` styleboxes** are left for the FOURTH time, and deliberately. A stylebox has to be
  *designed*, and the only palette to design against is the placeholder one, so populating them
  would ship a decision as a default — the reasoning T2.2 gave, unchanged. This package had the
  file open and still did not take it, which is the point at which "left again" should be read as
  settled rather than pending.
- **No shared material beyond one.** ONE piece of placeholder content per system; a palette of
  five would be content, and four of the five would be wrong (see seam 1).
- **No environment-look resource**, no sixth catalogue, no registry for materials.
- **Git LFS**, refused above.
- Art is still deferred, permanently. This package built the seams art drops into and no art.

**CI green, run 33535503432, job logs read rather than the tick** (gotcha 26). Full checkout
**1517 passed, 0 failed, 0 skipped** with `item definitions: 4` and `quests: 1`; stripped template
**1445 passed, 0 failed, 23 skipped** with `item definitions: 0` and `demo names derived: 0`. All
three checkers PASS in both jobs, both at `128 files, 11119 code lines, 0 warnings, 0 violations`.
The four new skips are the ones named above. The push run (33535489902) and the pull-request run
(33535564427) are green too.

**Commit:** `d20fbc1` on `claude/t3-2-art-seams`, PR #22 — stacked onto `claude/t3-3-item-count`
(#21) rather than `main`, matching the rest of the chain.

---

## T4.3 · `NEW_GAME.md` performed, and the release tag taken — **DONE**

**The last package of Phase T4, and the phase's third exit criterion.** Two jobs: land the stack
and take the tag the owner had deferred, then perform the one document a fork reads first.

**THE TAG WAS STILL BLOCKED FOR THE SAME REASON, AND THE FIX WAS ONE MERGE.** Phase T4's third
criterion had been refused on 2026-09-02 — *not yet, merge the stack first* — because
`origin/main` was at `d0bf153`. It still was: all 26 PRs open, zero merged, so the reason had not
expired. What made it tractable is that the stack was one LINEAR chain. `git merge-base
--is-ancestor` confirmed all 25 ancestor branches were contained in T4.2's tip, 71 commits ahead
of `main`, so retargeting PR #26 from `claude/wp-t4-version-upgrade` to `main` and merging it
landed the entire stack at once as `648bac1`. Only then did `v1.0.0` name a tree that actually
declares `base/version="1.0.0"`. Put back to the owner with that answer in hand, and authorised.

Six PRs (#1, #2, #3, #10, #12, #13) auto-closed as merged because they targeted `main`. The other
19 could not: GitHub refuses to retarget a PR whose base already contains its commits — *"There
are no new commits between base branch 'main' and head branch"* — so they were closed with a
comment pointing at #26. **They read Closed, not Merged.** Every commit is on `main` and reachable
from `v1.0.0`; this is a GitHub limitation, not a gap in the record, and it is written here
because the board would otherwise look like 19 abandoned packages.

**THEN THE FOURTH DOCUMENT WAS PERFORMED, AND IT FOUND A TEMPLATE DEFECT.** A fresh `git clone`
from GitHub into a short path, then sections 1 to 4 followed literally with `src/` never opened
while performing — the same discipline as T2.2, T4.1 and T4.2. Four for four now: every document
walked has found something reading did not.

**DEFECT 1 — `core_test.gd` failed a fork that had not authored its first area yet.** It asserted
`equal("a template with a game in it names one", configured != "", true)` — unconditionally,
though the name is conditional. Four things in the repository already said an empty
`[game] world/first_area` is legal: that case name, the comment eight lines below it in the same
function, `NEW_GAME.md` section 4, and the file's own header MUST NOT line, since whether a game
is configured is a claim about the PROJECT and not about `GameConfig`. Gotcha 46's shape, one
function further down.

It was green in the full template and green in the stripped one — neither ever empties that field
— and red only in a real fork: `1537 passed, 1 failed, 20 skipped`, exit 1. The control names what
it was really asserting: `first_area="tideglass_field"`, an area that does not exist, made it pass
`1538 passed, 0 failed`. It demanded a non-empty STRING. **Removed rather than made conditional**,
because `smoke_test.gd` already makes the claim properly — gated on `Fixtures.area_ids()` and
stronger, since it also requires the named area to resolve. `plan(50)` became `plan(49)`.

**DEFECT 2 — section 3's prune list never learned about quests.** Written at T1.2, before WP-08
existed, it listed `area. talk. action. object. item.` and was never extended. A fork that followed
the document kept five rows of demo content in its own `localization/strings.csv`:
`quest.keepers_errand.*`, *"The Keeper's Errand"*, *"three rose petals"*. All four checkers exited
0 and the whole suite was green, because **no gate reads `localization/` for demo content at all**
(gotcha 48). Verified that every `quest.*` key is demo and that the engine's quest strings live
under `notify.quest.*`, which the prune keeps. The prefix is now listed, and the section carries a
third trap saying no gate checks this file, with a grep to run afterwards.

**FOUR PROSE DEFECTS, RE-MEASURED RATHER THAN INHERITED.** The `awk` comment claimed "keeps 147 of
189 rows"; the file is 219 rows and the corrected `awk` keeps 168. Section 6's quoted checker
output was T1.2's and had drifted — no `quests: 0` line at all, and `src scripts scanned: 74` where
the tool now prints `engine scripts scanned: 129, over src/ and ["res://tests/framework",
"res://tests/unit"]`. The intro said "rename four fields" where section 4 lists five. And section 6
asserted the unset-first-area error **with no command to produce it**: `--headless --new-game`
prints nothing and ends `0 warnings, 0 errors`, because game flags need a `--` separator and
`--quit-after` counts FRAMES — two independent ways to get a green run that verified nothing
(gotcha 47).

**Ladder, all green.** Import exit 0 with **zero** `SCRIPT ERROR` / `Parse Error`; boot
`0 warnings, 0 errors`; suite **1608 passed, 0 failed, 0 skipped**, exit 0; `check_content`,
`check_boundary`, `check_budgets`, `check_strings` all exit 0. Stripped template **1534 passed, 0
failed, 25 skipped**, all four checkers exit 0 — **no new skip**.

**The total moved by +1 and it was predicted.** Minus the one assertion removed, plus two:
`docs_test` computes its plan from the docs, and section 6's corrected checker output names
`res://tests/framework` and `res://tests/unit` for the first time.

**Planted, and the fix that accepts MORE has a control (gotcha 23).** The defect was found in a
real fork rather than manufactured, so the control is the half that matters: copying an area back
into the fork with `first_area` still empty turned it red again — `FAILED: the configured first
area is set` and `FAILED: and its scene really exists`, exit 1, both from `smoke_test.gd`. A game
WITH areas and an unset first area is still caught. For the CSV, the old `awk` leaves 5 demo rows
and the corrected one leaves 0, with the new trap-3 grep returning nothing.

**Both numbers the document quotes were measured on the final tree**, not carried over: a fork
that followed sections 1 to 4 with `first_area` empty reports `1539 passed, 0 failed, 20 skipped`
across fifteen named cases, and the harsher stripped variant CI runs reports `1534 passed, 0
failed, 25 skipped`. The banner line quoted in section 6 was copied out of the fork's own run.

**Version bumped to 1.0.1; the tag for THAT was not taken.** T4.1's precedent decides it — stating
a version is engineering and assertable, cutting a release is the owner's. Leaving `main` saying
`1.0.0` after changing it would have made one version name two trees, which is the rot
`version_test.gd` exists to prevent. `docs/CHANGELOG.md` gains a `## 1.0.1` PATCH entry whose *a
consuming game does* line is actionable: a fork made at 1.0.0 that followed `NEW_GAME.md` should
grep its CSV for `quest.` and delete what it finds.

**What was deliberately NOT done.** No gate over `localization/`. It would need to know which key
prefixes are engine and which are content — the same list that just rotted, moved one directory
away and given the authority to fail a build. The document's own grep is the cheaper truth and is
aimed at the person actually holding the fork. This is the same objection that refused a
`check_content` rule for `obj/` flags at T4.2, and it is recorded for the same reason.

**CI green, run `33785871834`, job logs read rather than the tick (gotcha 26).** Full checkout
`=== 1608 passed, 0 failed, 0 skipped ===`; stripped template `=== 1534 passed, 0 failed, 25
skipped ===`, the 25 skips unchanged from T4.2. All four checkers PASS in both jobs.

**Commit:** `4ec29fb` on `claude/t4-3-new-game-perform`, PR #27, targeting `main` directly.


## T4.4 · `TESTING.md` performed, the last document never walked — **DONE**

**The fifth document performed, and the fifth to find a defect.** T2.2 walked the first half of
`AUTHORING.md`, T4.1 `UPGRADING.md`, T4.2 the rest of `AUTHORING.md`, T4.3 `NEW_GAME.md`. Five for
five, and **three of the five found a defect in the TEMPLATE rather than in the prose.** The
mechanism was the same one and it is not negotiable: do what the document says a consumer does,
from the document alone, and treat every wall as a finding rather than as a reason to go and read
the code. For `TESTING.md` the consumer is somebody adding assertions to a suite they did not
write, so the walk began by copying the document's own worked example verbatim into a new case
and registering it in `CASES`.

### The defect: a listed case that does not parse reported a clean pass, and exit 0

The very first run found it, and it found it by accident, which is the point. The copied example
did not compile — see below — and the suite's answer to a case that does not compile was:

```
SCRIPT ERROR: Parse Error: Identifier "inventory" not declared in the current scope.
   at: GDScript::reload (tests/unit/inventory_order_test.gd:14)
ERROR: Failed to load script "tests/unit/inventory_order_test.gd" with error "Parse error".
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
=== 1608 passed, 0 failed, 0 skipped ===
```

*(The throwaway case's `res://` prefix is stripped in that quote on purpose. It was deleted at
the end of the package, and `docs_test.gd` asserts that every `res://` path named in `docs/`
resolves — so quoting the engine's own line verbatim fails rung 4. `DEVLOG.md` is exempt from
that scan for exactly this reason; the board is not. The gate caught it here, which is a fair
demonstration that it works.)*


**Exit 0.** `0 failed`, `0 skipped`, and a whole case never run — a last line byte-identical to
one from a checkout in which the file does not exist.

The chain is three facts this project already knew, meeting in a place nobody looked.
`load()` on a script with a parse error returns a `GDScript` that is **not `null`** and cannot be
instantiated; `_run_case` tested only for `null`, so it walked into `script.new()`; and the
failure of that call is a GDScript runtime error, which **gotcha 24 established aborts only the
innermost frame.** So `_run_case` itself aborted, the `does not extend TestCase` failure two lines
below was never reached, and the `for` loop in `_ready` carried on. The sharpest part is that
`tests/framework/error_watch.gd` — T1.3's second mechanism, built precisely because the plan was
measured and found insufficient — **had counted the error the whole time.** `_no_script_errors` is
read per case from *inside* `_run_case`, after `run()` returns, so an error raised on the way IN
is tallied by the watch and read by nobody. Three correct mechanisms, all silent: the plan never
ran, the manifest was satisfied because the file WAS listed, and the watch was never asked.

**Two guards, because the second is the general one.** `can_instantiate()` before instantiating,
which names the file; and a run-level check that any engine script error no named case accounted
for fails the run, because the next hole in that wall will not be a parse error.

**Proved by planting, and the plant was caught twice — once deliberately and once by accident.**
Deliberately: a parse error appended to `version_test.gd`, a case with nothing else wrong with it.

```
res://tests/unit/version_test.gd is listed but does not parse, so it never ran
FAILED: 2 engine script error(s) were raised outside any case: ["Parse Error: Identifier
  nothing_declared_anywhere not declared in the current scope. at
  res://tests/unit/version_test.gd:123 in GDScript::reload()", ...]
=== 1591 passed, 2 failed, 0 skipped ===
```

Exit 1, both guards firing independently, the file and the line named, and the parse errors
quoted. Removed, and the control is exit 0 at `=== 1624 passed, 0 failed, 0 skipped ===`. By
accident, and it is better evidence than the plant: while this package was writing
`doc_counts_test.gd`, a stray escape produced `Invalid escape in string` at line 29 — and the new
guard reported the file and line unprompted, on a real mistake, where the old runner would have
carried on green.

### The document's one worked example did not compile, and it was wrong twice over

`equal("an empty inventory holds nothing", inventory.count(), 0)` — the only assertion example in
the document. Copied verbatim it produces two parse errors. **Nothing declares `inventory`**:
`TestCase` provides `plan`, `equal`, `skip`, `build` and `attach` and no content whatsoever, which
the document nowhere states. And **`Inventory` has no `count()`** — it has `distinct_count()`,
`total_count()` and `count_of(id)`. So a consumer's first act on this document is a compile
failure, followed, until this package, by a *green suite* that hid it. The replacement was written
and then RUN as a real case before being put in the document, which is non-negotiable #1 aimed at
prose.

### Three documents, three different answers to a countable question

`CLAUDE.md` said 44 in two places, `CONTEXT.md` said 48 and `TESTING.md` said
43, over a list of 48 entries. Each was true when written; none was updated.
This is gotcha 48's shape — a number in prose with no gate — but **without gotcha 48's excuse**:
the localization gate was refused in writing because it would need a list of which key prefixes
are engine, which is the same rot moved sideways. A count needs no list. `doc_counts_test.gd`
counts the entries, checks they run 1..N without a gap or a repeat, spells the number, and
requires every document that states it to state that one.

It is **its own case file rather than three more checks inside `docs_test.gd`**, because that
file's MUST NOT line forbids asserting anything about what the documents SAY, and non-negotiable
#4 says a change that needs a MUST NOT broken adds a system instead of widening the boundary.

**Planted twice.** A fiftieth gotcha added with no count updated fails all four claim sites at
once — `expected fifty, got forty-nine` — which is the rot that actually happened. `CLAUDE.md`
alone drifted back to 44 fails exactly one, naming the file. Both exit 1; both restored.
The gate also had a hole of its own on the first pass, and it was gotcha 43's shape: the section
heading is the PRIMARY statement of the count and was being swallowed by the section it opens, so
the gate would have passed while the list's own title was wrong. It is kept as a claim now.

### The assertion that was kept, and why

The throwaway case was deleted; **`bag_mirror_test.gd` was kept**, because it covers something
genuinely missing. `Inventory.add` carries a comment saying `_publish()` runs *before* either
signal, "so nothing woken by one reads a flag that still says the old number". `remove` has the
identical ordering and no comment, and **nothing asserted it on either path** — so a listener that
reacted to `item_gained` by reading `bag/<carrier>/<item>` would have read the previous count, with
an off-by-one in whatever it drew as the only trace. Ten assertions, and the last is the
interesting one: spending the LAST of a stack ERASES the row rather than zeroing it, so "current"
there means absent, and an emission tally is what makes a missing row distinguishable from a
handler that never ran.

Planted on both sides. `_publish()` moved after `Events.item_lost.emit` gives
`FAIL the flag already read the REMAINDER inside item_lost — expected 3, got 5` — the listener
reading the old number, exactly the defect the comment warns about. After
`Events.item_gained.emit` gives `expected 5, got -1`. **Nothing else in the suite failed on either
plant**, which is the proof the invariant was uncovered rather than covered twice.

One assertion of the ten caught the author rather than the code, and it is worth recording: the
first version expected `0` from the erased row and got `-1`, because `_publish` erases rather than
zeroes. The code was right and the assertion was wrong — which is what the second and third
outcomes of `plan()` are for, and the plan itself caught a miscount in the same file
(`planned 9 outcomes and produced 10`).

### What was deliberately NOT done

No windowed capture, and no temporary probe under `src/systems/debug/`. This package changes no
rendering, no input path and no engine file at all — `git diff src/` is empty, the inventory
plants having been fully restored — so a capture would be a screenshot of something it did not
touch, which is ceremony that later reads as evidence. `git diff src/systems/debug/` is clean.

No third mechanism in the runner. The plan, the watch and the manifest are enough once the watch
is actually asked, and the run-level backstop is that asking. Adding a fourth would be a second
thing to get wrong in the file whose job is judging whether things went wrong.

### Verification

Full ladder green, run locally. Rung 2 greps to zero `SCRIPT ERROR` / `Parse Error`; rung 3 ends
`0 warnings, 0 errors`; rung 4 is `=== 1625 passed, 0 failed, 0 skipped ===`, up 17 from 1,608 —
ten from `bag_mirror_test.gd`, six from `doc_counts_test.gd`, and one more because `docs_test.gd`
COMPUTES its plan from the documents and this section names an additional `res://` path. All
four checkers exit 0.

**Stripped template, measured rather than inherited:** `=== 1551 passed, 0 failed, 25 skipped ===`,
up 17 by the same arithmetic, and **the 25 skips are unchanged** — neither new case adds one,
since fixtures work in a stripped checkout and the documents are still there. All four checkers
exit 0 against `--path` as well.

**Version bumped to 1.0.2; the tag for it was NOT taken.** T4.1's precedent, reaffirmed by T4.3.
The `## 1.0.2` CHANGELOG entry's *a consuming game does* line is honest about the one visible
consequence: a game whose suite contains a case that does not compile will see rung 4 fail where
it previously passed, and that is the bug being fixed rather than a new restriction — the case was
never running.

**CI green, run `33840155182`, job logs read rather than the tick (gotcha 26).** Both jobs report
`success`. Full checkout `=== 1625 passed, 0 failed, 0 skipped ===`; stripped template
`=== 1551 passed, 0 failed, 25 skipped ===` — byte-identical to the local measurements, and the
25 skips unchanged from T4.3. All four checkers pass in both jobs. The only `error:` strings
anywhere in the log are the workflow's own `::error::` echo lines for the failure path it did not
take, plus the expected "couldn't open directory" notices for the content roots in the tree
where that content is deliberately deleted.

**Commit:** `29ba248` on `claude/t4-4-testing-perform`, PR #29, targeting `main`.

## The board is closed — 2026-09-04

**There is no next row, and that is a decision rather than a gap.** T4.4 landed the last
consumer document to be performed, every phase is complete, and the two remaining candidates —
WP-10 crafting, and nothing — were put to the owner, who chose nothing. `CONTEXT.md`'s settled
decisions carry the full reasoning, and the version stays `1.0.2` and untagged.

**WP-10 remains OPTIONAL and unbuilt**, kept on the board as a record rather than a queue entry,
the way WP-15's remnant is. A real defect is still a package. So is a seam that a game actually
built on this base discovers is missing. A package invented so that there is one is how the
previous project got a 3,983-line file, twenty reasonable lines at a time.
