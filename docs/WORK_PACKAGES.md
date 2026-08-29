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
| 09b | Character depth — attributes and surfaces | **DONE** — `PENDING`, PR #19. The fourth package of Phase T3; see below |
| 10 | Crafting and gathering | **OPTIONAL** — a genre choice, not a requirement of every game (TEMPLATE.md). Does not block v1.0 |
| 11 | World map and fast travel | **DONE** — `cf3f3a1`, PR #18. The third package of Phase T3, and the last system with no proof at all; see below |
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
| T2.1 | Art contract seams | **DONE** — see T2.1 below |
| T2.2 | Consumer documentation | **DONE** — `36b5abd`, PR #15. Phase T2 closes; see T2.2 below |
| T3.1 | **A generic content registry** — a base holding the scan and cache, with a thin typed façade per registry | TODO — WP-08 made it the FOURTH copy of the same thirty lines and reconsidered the note in `schedule_db.gd`; WP-11 made it the FIFTH and did not re-argue it. The verdict is in the WP-08 section and the changed arithmetic is in `area_db.gd`'s header |
| T3.2 | The five art-contract seams T2.1 left | TODO — shared materials, the environment post-stack and camera framing as `@export`s, the texture import defaults, the Git LFS lines |
| T3.3 | **A quest step that can read an ITEM COUNT** | TODO — "bring me three petals" is still not authorable. Scoped by WP-09, which proved the flag seam is enough for "hold ONE of this" and not for a count; the two candidate designs and what each costs are in the WP-09 section |

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

**Commit:** `PENDING` on `claude/wp-09b-attributes`, PR #19 — stacked onto `claude/wp-11-worldmap`
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

**Left for later, in the roadmap's own order, because the package hit its file budget and
half-doing five seams is worse than finishing two.** Shared materials. The environment post-stack
as `@export`s rather than code constants. Per-area camera exports. The texture import defaults —
and this one has a reason beyond budget: `[importer_defaults]` is an undocumented
editor-managed section, absent from `--doctool`, so it cannot be checked against the API dump the
way this project requires, and the per-file values already committed are correct for pixel art.
The Git LFS lines stay commented, and the `.gitattributes` comment is right: LFS pointers for a
2 KB placeholder are pure overhead, and enabling them would put the CI checkout on a dependency
it does not currently have.

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
does render — so they are replaced by the two that are true: the `Button` styleboxes, and the
missing material and camera exports.

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
proof each. The five T2.1 leftovers (shared materials, the environment post-stack and camera
framing as `@export`s, the texture import defaults, the LFS lines) are engine work whose two exit
criteria are already met; they belong in a T3 row of their own rather than reopening T2.

**CI green, run 33086307621, job logs read rather than the tick.** Full checkout
`1081 passed, 0 failed, 0 skipped`; stripped template `1027 passed, 0 failed, 16 skipped`, the
four new skips being exactly the doc-named paths under the content roots that a stripped checkout
has deleted. All three checkers PASS in both jobs.

**Commit:** `36b5abd` on `claude/t2-2-consumer-docs`, PR #15.
