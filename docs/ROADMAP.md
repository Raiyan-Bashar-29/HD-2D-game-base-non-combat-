# Roadmap

> **Read [`TEMPLATE.md`](TEMPLATE.md) first.** This project is a reusable base for many games,
> not one game. Phases 0 to 2 below happened and are accurate. Phases 3 and 4 were retired on
> 2026-08-26 because they planned a *consuming game's* work, and are replaced by the T-phases.

Phases, and the exit criteria that decide when each one is actually finished. An exit
criterion must be checkable by running the engine, not by reading the code and feeling good
about it.

Art generation is out of scope throughout. Every phase must work on placeholder art, and
"replace the placeholders" is a separate track that can start at any time without blocking
anything here.

---

## Phase 0 — Foundation · **COMPLETE**

*Goal: an empty folder becomes a project that boots, logs, and can be verified.*

Delivered:
- 80-directory layered structure, engine config, version control
- Ten autoloads: logging, events, input, settings, save, flags, clock, weather, audio, director
- Warnings-as-errors, making GDScript statically checked
- Placeholder art generator
- The verification ladder, all five rungs proven

Exit criteria, all met:
- [x] `--headless --import` completes with no errors
- [x] `--headless --quit-after 30` boots with **0 warnings, 0 errors**, exit code 0
- [x] Every script passes the parse and type gate
- [x] A save participant can register, and the save envelope round-trips — NOTE: this was
      marked met on 2026-08-23 having only been observed as a log line. The round trip was
      first actually executed on 2026-08-24 by the test suite, and passes.
- [x] A frame can be captured to PNG and inspected

## Phase 1 — One area, one character · **COMPLETE**

*Goal: a person can be walked around a lit, living space and touch things in it.*

Done:
- HD-2D camera rig with tilt-shift depth of field
- Billboarded, lit, shadow-casting 8-way character sprite
- Camera-relative movement with walk, run and sneak
- Day/night lighting driven by the world clock, verified at dawn, midday, dusk and night
- Weather state affecting sun and fog, verified under a forced storm
- The courtyard: ground, pillars, walls, a dais, two lanterns, spawn markers

Remaining:
- Hard-coded-string audit (the budget and content checkers are DONE and passing)

Also done, ahead of Phase 2 because every screen needs it first:
- Screen stack, pause semantics and input contexts (WP-02) - a screen declares whether it
  pauses; UiRoot does the pausing; input readers hold NAMED tokens so two of them cannot
  release each other
- The HUD clock readout and the inventory screen (WP-03) - the stack's first real
  consumers, plus the one action-to-screen binding and keyboard/gamepad focus in a screen

Exit criteria:
- [ ] Walk the courtyard, and the character faces the direction of travel correctly in all
      eight directions
- [x] Approach three overlapping objects and select each one deliberately — ranking plus
      Tab cycling, done 2026-08-24
- [x] Pick up an item; it appears in the inventory and no longer exists in the world —
      done 2026-08-25, covered by the test suite
- [x] Refuse at a locked gate, throw the lever, open it, reload, and it is still open —
      done 2026-08-24, covered by the test suite
- [x] Open a chest, take its contents, reload, and it is still open and still empty —
      done 2026-08-25, covered by the test suite
- [x] Rest on the bench and watch the light change — done 2026-08-26. Two windowed captures
      from the same 06:30 start, one with the same skip the bench performs, show warm dawn
      becoming cool night with the lantern pools lit
- [ ] Save, quit, relaunch, continue — position, time, weather and inventory all restored
- [x] Test suite passes headless and exits non-zero on failure — 606 assertions
- [x] A screen opens over the world, gameplay input stops, the fade still runs over the
      top of it, and Escape restores control — done 2026-08-26, windowed captures plus a
      real-input probe in the live tree
- [x] Press I and the inventory opens with real rows, grouped by category with localized
      names and counts; the world freezes; arrows and the d-pad move focus between rows;
      Escape closes it and control returns — done 2026-08-26, windowed capture at dusk and
      midday plus a real-input probe that pressed I, Escape and I twice in the live tree
- [x] The HUD shows the clock and follows it — done 2026-08-26, windowed capture and an
      assertion driving the real Clock
- [x] Two overlapping input locks release correctly: lock A, lock B, release A, the player is
      still locked — done 2026-08-26, covered by the test suite
- [ ] A 30-second play session produces **zero** warnings or errors in the log
- [x] The budget checker reports no file over its limit — a mandatory close-out gate for every
      package since WP-01; 73 files, 5,638 code lines, 0 violations at WP-06

> **Phases map onto work packages.** `docs/WORK_PACKAGES.md` is the executable version of this
> document: fifteen packages, one chat each, in dependency order. When the two disagree, the
> board is what is actually being worked and this file needs updating.

## Phase 2 — Two areas and a reason to move · **IN PROGRESS**

*Goal: prove the world is a world, not a room.*

- [x] A second area, with a door between them — the Lantern Hall, an interior (WP-04)
- [x] Loading that hides behind the fade, with the shader warm-up hitch handled (WP-04)
- [x] Navigation baking, and one NPC that walks a route by the clock (WP-06)
- [x] Dialogue runner, dialogue UI, and an authorable conversation format (WP-05)
- [x] The pause menu itself, and the other four menus with it (WP-12, taken early because
      Phase 3's controller-navigation criterion needed screens to navigate)
- Localization wired for real: every string is already an ID
- [x] Weather visuals: rain, snow and wind particles, wet surfaces, ambience layers (WP-13)

Exit criteria:
- [x] Captures of clear, rain and storm that are visibly different, and wet surfaces that
      appear and dry out — done 2026-08-26, seven windowed captures at 13:00 with the clock
      and the weather both frozen: clear, rain, storm, snow, a soak-to-dry triptych at
      wetness 1.0 / 0.5 / 0.0, and a storm seen from inside the Lantern Hall with not one
      drop indoors
- [x] Cross between areas twenty times with no leak in node count or memory — done 2026-08-26,
      `--round-trips=20`: node count exactly flat at 120 across all twenty, memory -12 KiB
- [x] Trigger two transitions in the same frame and be refused cleanly, with a log line —
      done 2026-08-26, exercised forty times in the same run, two per trip
- [x] An NPC is at the market at noon and at home at night, across a save and reload — done
      2026-08-26. `--npc-day` walks the clock through a whole day: gate_post at 06:00 and
      09:00, the dais at 12:00 and 15:00, the bench from 20:00 through 02:00. Whereabouts
      persist through `PersistentState`, asserted in the suite. Two captures examined
- [x] Hold a conversation that reads and sets a flag, and branches on it — done 2026-08-26,
      covered by the test suite, plus a windowed capture and a real-input probe that pressed
      the button, advanced a line and took a branch with the world still running
- [ ] Switch language at runtime and see every visible string change

## Phases 3 and 4 — RETIRED, out of scope

They used to read *"thirty minutes that represent the finished game"* and *"regions, quest lines,
the full plot"*. Under the reframing in [`TEMPLATE.md`](TEMPLATE.md) those are not deferred work,
they are **a consuming game's phases**. A criterion like *"a new player finishes the slice with no
guidance and no soft-lock"* is one no template can meet, and leaving it here would keep pointing
effort at polishing the demo.

What follows replaces them.

---

## Phase T1 — Make it a base, not a demo · **COMPLETE**

*Goal: the demo can be deleted and the template still stands up.*

| Step | State |
|---|---|
| **T1.1 Integration** — every package onto `main` in one linear chain | **DONE** 2026-08-26, PR #10. WP-12 and WP-13 were built in parallel and merged in; the `UiRoot`/`ScreenKeys` duplicate close-on-travel was resolved in favour of `ScreenKeys`. |
| **T1.2 The boundary** — the rule, a gate that enforces it, and the leaks fixed | **DONE** 2026-08-26, commit `06ce363`. `tools/check_boundary.gd` derives the demo ids from `scenes/areas/` and `data/` and fails on any of them in `src/` code. All four known leaks closed. |
| **T1.3 Test fixtures + framework hardening** | **DONE** 2026-08-26, commit `a8377a0`. `tests/framework/fixtures.gd` and `fixture_content.gd` build the content a case needs; the three content registries gained a redirectable `content_dir`. Four silent-pass modes now fail: a crash, an early return, a case that asserts nothing, and a suite file nobody listed. `check_boundary` now scans `tests/` too. |
| **T1.4 CI** — automate the ladder | **DONE** 2026-08-26. `.github/workflows/ladder.yml` runs six of the seven rungs on every push, pull request and manual dispatch, in two jobs: the full checkout and a stripped template. The engine is downloaded, its SHA512 verified against a pinned literal and its build string asserted before any rung runs. Proved red then green. |

Exit criteria:
- [x] `main` contains the template — done 2026-08-26
- [x] A gate fails on a planted `&"courtyard"` in a `src/` file, and passes otherwise — done
      2026-08-26, and it is `tools/check_boundary.gd`, not `check_content.gd`: the combined file
      came out at 252 of the 250 allowed code lines and the budget checker refused it
- [x] No file under `src/` names demo content — done 2026-08-26. One exemption,
      `src/systems/debug/`, justified in the tool header and conditional on those files staying
      behind `OS.is_debug_build()`, which the same tool now checks
- [x] The debug surface cannot be driven in a release build — done 2026-08-26
- [x] `docs/NEW_GAME.md` exists, and its claims were run against a stripped copy of the repo
- [x] A deliberately crashing test case exits **1** — done 2026-08-26, T1.3, and it took TWO
      mechanisms because the obvious one is not enough. A GDScript runtime error aborts only the
      innermost frame (probed), so the declared plan catches a crash that swallows an assertion
      but a planted crash in a leaf helper still reported `2/2` and exit 0. `ErrorWatch`, an
      `OS.add_logger` Logger counting `ERROR_TYPE_SCRIPT`, catches that one: `zz_probe_test raised
      1 engine script error(s)`, exit 1. A failing assertion, an early return and a missing plan
      were each planted and each exited 1 as well
- [x] `data/` and `scenes/areas/` moved aside, and the suite still passes — done 2026-08-26,
      T1.3: `861 passed, 0 failed, 12 skipped`, exit 0, with every skip named and counted. Full
      checkout: `911 passed, 0 failed, 0 skipped`. Restored, and `git status` showed no change to
      any demo file
- [x] A pushed branch with a broken assertion goes red in CI — done 2026-08-26, T1.4. One
      assertion in `core_test.gd` changed to expect 6 where the answer is 5; run
      [32989608134](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32989608134)
      failed at `Rung 4 - test suite` in BOTH jobs, printing `FAILED: dict_read int — expected 6,
      got 5` and `910 passed, 1 failed`; rungs 5-7 were skipped. Restored, and run
      [32989771404](https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-/actions/runs/32989771404)
      went green: `911 passed, 0 failed, 0 skipped` full, `861 passed, 0 failed, 12 skipped`
      stripped

## Phase T2 — Make it swappable

*Goal: a second, visually different game starts from this without editing `src/`.*

- **T2.0 The export proof — DONE, 2026-08-26.** Sequenced FIRST in Phase T2 by RISK, not by theme
  — it belongs to T3 by subject. A Windows preset, and the first run of an exported build there
  has ever been. **The assumption held:** `export_filter="all_resources"` ships resources that no
  scene references, and the exported `.exe` reports the same 3 items, 1 conversation and 1
  schedule the editor does. ADR-0006's honest limit is closed and needed no revision. The proof
  was not wasted, though: running the export found a SECOND defect that every rung, both CI jobs
  and 930 assertions were blind to — a missing `[editable]` marker dropped an instance's property
  overrides in the binary conversion only, so the demo's NPC shipped with no id, no prompt and no
  conversation. Fixed, and now a `check_content` gate. See the board.
- **T2.1 The art contract — DONE, 2026-08-27.** The first four items of the list below, which are
  the two exit criteria and their supports; the last five were left, in the order they are
  written, because the package hit its file budget and half-doing five seams is worse than
  finishing two. A `SpriteSheetLayout` resource replacing `FACING_COUNT`/`FRAME_COUNT`, with the
  sector width DERIVED from the facing count instead of a separate literal `TAU / 8.0`, and
  animation blocks with idle/walk row offsets so idle-vs-walk is no longer structurally
  impossible; a project `Theme` at `assets/theme/ui_theme.tres` so the UI look stops living as
  constants inside five screen files. **Left for later:** shared materials; the environment
  post-stack as `@export`s rather than code constants; camera exports set per area; the texture
  import defaults (an undocumented editor-managed `[importer_defaults]` section, so it cannot be
  checked against the API dump the way this project requires); the Git LFS lines, which the
  `.gitattributes` comment is right to keep commented until real art exists — LFS pointers for a
  2 KB placeholder are pure overhead and would put the CI checkout on a dependency it does not
  have. See the board.
- **T2.2 Consumer documentation — DONE, 2026-08-27.** `AUTHORING.md`, `ART_CONTRACT.md`,
  `TESTING.md`, the extension surface as a section of `ARCHITECTURE.md`, and both routers
  updated so the new documents are reachable. (`NEW_GAME.md` was already done in T1.2.) The last
  criterion below was **performed rather than asserted**: a new area, a new NPC and a new
  conversation were authored from the documents alone, run, captured and looked at, six doc
  defects were found and fixed, and the content was then deleted — it was a test of the docs,
  not new demo content. `tests/unit/docs_test.gd` now fails on a documented `res://` path or
  worked-example field that no longer exists. See the board.

Exit criteria:
- [x] An exported build reports **non-zero** catalogue counts for items, conversations and
      schedules, matching the editor — T2.0, **2026-08-26**. Ran the exported `.exe` outside the
      editor: `items: 3, dialogue: 1, schedules: 1`, resolved paths identical to a source run.
      Moved here from Phase T3, where it was listed while `SYSTEMS_INVENTORY.md` simultaneously
      marked export presets LATER; that contradiction was settled 2026-08-26 in favour of blocking
- [x] Swap in a sprite sheet with a different cell and frame count, changing **no code** — T2.1,
      **2026-08-27**. `character_alt.png`, 4 facings x 3 frames x 2 animation blocks on a 24x40
      cell against the default 8 x 4 on 32x48. Two `ExtResource` paths in `player.tscn` changed
      and nothing else. Windowed capture LOOKED AT: the probe logged `frame=19/24`, and the
      picture showed the walk block's tint, four column pips and two frame pips — block 1,
      frame 1, column 3, which is exactly index 19
- [x] One `Theme` change restyles every screen at once — T2.1, **2026-08-27**. Six lines of
      `assets/theme/ui_theme.tres` and no other file: the main menu and the inventory screen both
      went from dark-on-translucent-black to dark-on-parchment with a deep-red accent and a wider
      inset, and the HUD clock followed. Captures before and after, both looked at
- [x] Someone who has not read `src/` can author an area, an NPC and a conversation from the docs
      — T2.2, **2026-08-27**. Performed, not claimed: an area, an NPC with a schedule and a
      four-node conversation were written from `AUTHORING.md` alone, with no reference to `src/`
      and nothing copied from an existing area. All seven ladder rungs green with the new content
      in (`1101 passed`), `check_content` clean including the `[editable]` marker, and the capture
      shows the NPC in the new area saying its first-meeting line. **The evidence is the six
      places the docs were wrong**, all fixed and listed in `DEVLOG.md` — the largest being that
      the documented capture command never leaves the main menu, so an author following it
      photographs the title screen and concludes their area is broken. A walkthrough that worked
      first time would have meant the author was still reading from memory

## Phase T3 — Finish the system catalogue

The remaining packages, re-framed — see the board. **The export proof moved OUT of this phase and
into T2.0**, at the front of Phase T2: it was always described here as "the one genuinely blocking
item", and a blocking item scheduled last is a contradiction. Sequenced by risk, not by theme.

- **WP-08 Quests — DONE, 2026-08-27.** The phase's first package, and the widest remaining hole:
  quests were the one system with no proof at all. A quest is now authored data in `data/quests/`,
  found by the fourth directory-scan registry, and **every step names a FLAG CONDITION rather than
  a callback** — so a conversation that writes a flag starts a quest, a lever advances it and a
  trigger volume finishes it, with none of the three knowing the quest system exists. `QuestTracker`
  derives progress from `Flags` and latches only the two things that cannot be derived (that a quest
  started, and that it completed). A `JournalScreen` on `J`, one placeholder quest, and 49 new
  assertions. See the board.

- **WP-09 Character depth — PARTIAL, and deliberately: EQUIPMENT DONE, 2026-08-27.** The row asked
  for three systems in one package — an attribute container, surface-aware footsteps and equipment
  that changes traversal — which is over the board's own 8-file limit, so it was split and the half
  with a consumer was built. An `ItemDefinition` gains one field, `equip_slot`, and `Equipment` is a
  component beside `Inventory` that **owns no dictionary**: a slot is the flag
  `equip/<wearer>/<item>`, so a `Gate`, a `QuestStep` and a `DialogueChoice` all gate on what is in
  hand with **no code and no new field in any of them**. Enter on a satchel row holds or stows.
  The other two thirds are **WP-09b** on the board, with the reason each was deferred.

- **WP-11 World map and fast travel — DONE, 2026-08-29.** The phase's third package, and the last
  system in the catalogue with no proof at all. An `AreaDef` .tres per area in `data/areas/`,
  found by the fifth directory-scan registry, carries the map position, the arrival spawn and
  `known_from_start` — and **discovery is the flag `map/<area id>` with no store behind it**, the
  fourth use of the namespace-over-`Flags` shape after `PersistentState`, `Standing` and
  `Equipment`. So discovery is already saved, already cleared by a new game, already announced on
  `flag_changed`, and writable by a conversation effect, a lever or a trigger volume with **no
  code in any of them**. `WorldMap` under `GameRoot` turns arrival into discovery and emits the
  same `area_change_requested` an `AreaDoor` emits; `MapScreen` on `M` draws one dot per def at
  its authored normalised position and names no area. Three windowed captures LOOKED AT and READ,
  and 65 new assertions. See the board.

- **WP-09b Character depth — DONE, 2026-08-29.** The phase's fourth package, and the two thirds of
  WP-09 that were split out for having no consumer. Both were built to have one. An attribute is
  the flag `attr/<who>/<name>` — the FIFTH namespace-over-`Flags` — and it ships with exactly one
  reader, `PlayerController.current_speed()`, with the attribute's NAME declared as a const on that
  consumer so an attribute nobody reads has nowhere to be written down. A surface is
  `metadata/surface` on area geometry, inherited from the nearest tagged ancestor, and a step's
  sound is DERIVED FROM THE SURFACE'S NAME rather than looked up in a table, so a game that authors
  `sand` hears it without editing `src/`. 56 new assertions cover the three pure parts; the
  raycast, the frame loop and the `play()` are a windowed probe with the log quoted. See the board.

Exit criteria:
- [ ] Every system has one proof, and no system has a second area's worth of content
      — quests: **done**, WP-08, 2026-08-27. One quest, two steps, two windowed captures LOOKED AT:
      the journal with the objective open, and the same quest under "Settled" with its toast up
      — equipment: **done**, WP-09, 2026-08-27. One equippable item, one gate requiring it, three
      windowed captures LOOKED AT and READ rather than glanced at: the satchel with
      `Brass Lantern x1 [in hand]` beside an unmarked `Rose Petal x2`, the arch refusing with its
      own authored line, and the same arch with the blocker gone one flag later
      — attributes and surface-aware footsteps: **done**, WP-09b, 2026-08-29. An attribute that
      changes something and persists, proved windowed at 2.861 m against 4.687 m over the same 60
      frames with `pace` 0 and +4; the surface under the player reported correctly on THREE
      materials, two tagged directly and one inherited from the terrain root, and the step sound
      following it — `brightness=0.733 decay=2.13`, `0.841/4.68`, `0.550/3.02`, `playing=true` on
      a WASAPI device. Not visual and not synchronous, so the claim is a quoted log rather than a
      capture, and the file headers say which half is which
      — world map and fast travel: **done**, WP-11, 2026-08-29. Two areas on one map, three windowed
      captures LOOKED AT and READ: a map with the second area drawn as an unknown grey `???`, the
      same map one flag later with it drawn as a gold selectable `Lantern Hall`, and the same map
      again after actually travelling there -- the two states swapped, with the courtyard still on
      the map from the far side of an area no longer loaded

## Phase T4 — Template v1.0

Version and tag it. Write the upgrade note for games already forked from it — nothing currently
describes how a game receives a later fix to the base.

---

## Sequencing rules

1. **Breadth of systems, one shallow proof each.** This *replaces* "depth before breadth", which
   is retracted — see [`TEMPLATE.md`](TEMPLATE.md). It was the right rule for one game and the
   wrong one for a formula library.
2. **No content without a system.** If an area needs a feature that does not exist, build the
   feature or cut the area. Do not special-case it. *(Unchanged, still correct.)*
3. **No file under `src/` may name demo content.** The boundary that had no rule until T1.2.
4. **A system is proved by a fixture, demonstrated by the demo.** An assertion that names
   `item/rose_key` is testing the demo, not the item system.
5. **Nothing is done until the engine says so.** Every completion claim cites a command that was
   run and its result. *(Unchanged. This is the project's spine.)*
6. **Every session appends to `DEVLOG.md`.** What changed, why, how it connects, what was verified.
7. **Art stays deferred, permanently.** The template ships a *contract* art must satisfy, never
   art. Each game brings its own.
