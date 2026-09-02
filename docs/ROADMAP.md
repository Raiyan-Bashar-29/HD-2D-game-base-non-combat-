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

Remaining: nothing — the last item, the hard-coded-string audit, shipped as `tools/check_strings.gd`
in WP-14 (2026-09-01).

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
  constants inside five screen files. It left five items, which were **closed by T3.2 in Phase
  T3** — four built, one refused in writing. See the board.
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

## Phase T3 — Finish the system catalogue · **COMPLETE, 2026-09-02**

Nine packages: WP-08, WP-09, WP-11, WP-09b, T3.1, T3.3, T3.2, WP-14 and WP-14b, the last of which
closed the phase's one exit criterion. WP-10 (crafting) is OPTIONAL and blocks nothing; WP-15's
remnant is a decision awaiting the owner rather than work in this phase.

The packages, re-framed — see the board. **The export proof moved OUT of this phase and
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

- **T3.1 A generic content registry — DONE, 2026-08-30.** The phase's fifth package, and the one
  row that was a pure refactor: five catalogues carried five copies of the same scan-and-validate.
  WP-08 costed the refactor at the fourth copy and kept the copy for a sound reason — a base
  holding the CACHE could only hand back untyped `Resource`s — and WP-11 changed only the
  arithmetic. **Both were right about the wrong half.** The duplication was in the SCAN, which
  needs exactly two things from a resource: its `id` and its `problems()`. So the base went on the
  **resource** (`ContentEntry`) and the shared part is a **function**, `ContentScan.into()`, that
  fills the caller's own typed dictionary — every registry keeps its `content_dir`, its typed
  cache and its typed accessor, and **there is no cast at any call site in the project.** Five
  registries: 290 code lines to 187, plus 44 shared, so 290 against 231; the scan-and-validate
  body exists once instead of five times. `ItemDb.resource_paths()` became
  `ContentScan.resource_paths()` with no alias, since four registries and three test cases were
  calling the item registry to scan things that are not items. 47 new assertions, all of which run
  in a stripped template, and **not one word of `AUTHORING.md` had to change** — which was the
  acceptance test. New gotcha 37: a base-class `static var` is ONE storage shared by every
  subclass, measured, which is why a shared base CLASS would have given all five catalogues one
  cache. See the board.

- **T3.3 A quest step that can read an ITEM COUNT — DONE, 2026-08-31.** The phase's sixth package,
  and the one row on the board that was breadth of EXPRESSION: "bring me three petals" was not
  authorable, which is a limit on what a consuming game can say. WP-09 had costed both candidate
  designs and closed neither, and the one taken is its first with the cost that made it look
  expensive removed. `Inventory` PUBLISHES each count as `bag/<carrier_id>/<item id>` in `Flags` —
  the SIXTH namespace-over-`Flags` — so **the dependency points DOWN from `gameplay` to `core`
  instead of up from `systems` to `gameplay`**, and the quest system was not touched: no field on
  `QuestStep`, no line in `QuestTracker` that knows what an inventory is, and a test now FAILS if
  either learns. The mirror is a PROJECTION and not a second truth: `Flags.declare_derived` keeps
  it out of the save file, so nothing is saved twice, `Inventory.SAVE_VERSION` did not move and
  there is no migration. Two things fell out that were already decided and only needed asserting:
  a count already satisfied passes the step at once, and a count going back down reopens an
  ACTIVE objective while a COMPLETED quest stays complete — the case `quest_tracker.gd`'s own
  header names. 66 new assertions, three new `check_content` branches each proved red then green,
  and two windowed captures LOOKED AT and READ. See the board.

- **T3.2 The five art-contract seams T2.1 left — DONE, 2026-09-01.** The phase's seventh package,
  and the LAST of its T-numbered rows — but Phase T3 was not closed by it and this file should not
  be read as saying so: WP-14 was still TODO, WP-15 has a remnant, and the exit criterion below is
  about systems having a proof rather than about T-rows being finished. *(The phase closed two
  packages later, with WP-14b on 2026-09-02.)* T2.1 shipped the sprite-sheet contract and the project `Theme` and
  left five items, which then spent six packages being described in **five documents** — a backlog
  item mentioned five times is tracked zero times and described five times, and the descriptions
  drift. Four are now built and one is refused in writing, and every one of them is stated in
  exactly one place, `ART_CONTRACT.md`. **Shared materials:** `assets/materials/wood.tres`, one
  file both areas point at, and the defect was already there — the two demo areas each carried a
  byte-identical `m_wood`. A library of ONE, because the other five materials are *not* duplicates
  (a tiling rate belongs to the surface, not the substance) and a shared file with a per-area
  override on every user is duplication with an extra indirection. **The environment post stack:**
  twenty literals in `_build_post_stack()` became twenty `@export`s at exactly the values T2.1
  shipped; what stays in code is the STRUCTURE the rest of the driver assumes, and the four
  expensive effects are exports despite being `false` because a value a game cannot reach is not a
  seam, it is an opinion. **Per-area camera framing:** the seam already existed and the row was
  wrong about it — `HD2DCameraRig` has carried its framing as `@export`s since it was written, and
  what was missing was an area USING them, so the interior now frames at 36° / 9.5 m against the
  outdoor 27° / 14 m and one run logs both. **The texture import defaults:** gotcha 30 said this
  could not be done, because `[importer_defaults]` is undocumented and absent from `--doctool`.
  The rule was right and the conclusion was not — it was settled by MEASUREMENT instead, which is
  non-negotiable #1: a throwaway texture, the section added, its `.import` deleted, and
  `--headless --import` regenerated it carrying the values. One value is set,
  `detect_3d/compress_to = 0`, which closes the latent hazard that a re-import would put VRAM
  block artefacts through pixel art. **Git LFS is refused**, with the reason that decides it
  written down for the first time: the template cannot verify the change it would be making.
  47 new assertions, six gates each proved red with the real violation then green — one of which
  exposed a defect in the test itself — and six windowed captures LOOKED AT and READ. See the
  board.

- **WP-14 Dev tools and hardening — DONE as the HARDENING half, 2026-09-01.** The phase's eighth
  package, and the first row to be both RE-FRAMED and SPLIT in the commit that took it. The row
  asked for "a smoke test that drives **the whole demo**", which would have welded the courtyard,
  the keeper and the rose key into a permanent ladder gate — the coupling `check_boundary` exists to
  prevent, arriving through the back door of a test, and the welding T1.3 spent a package undoing.
  `smoke_test.gd` drives *a* game from `tests/framework/fixtures.gd`, names no content, and skips
  its one game-shaped block, counted, in a stripped checkout; and because `TestCase.run()` is
  synchronous it is the CHAIN rather than a playthrough — a run begins, a flag starts a quest, items
  publish their counts, an objective notices, something goes in hand, time skips, and the session is
  saved, wiped and restored. The row also named four things, over the size limit, so its own title
  was the seam: the two gates shipped and the two UI surfaces became **WP-14b**. **`Director` now
  drains its loader thread on shutdown**, and the interesting part is what the defect had been
  costing: quitting mid-load printed `Parse Error` for files that parse perfectly, so CI's boot rung
  had been written to read only its last line, with a comment saying a whole-log grep "would be a
  flake generator" — a live defect had bought itself a hole in the project's own compile check. No
  `load_threaded_cancel` exists in 4.7, so the fix waits, measured at 118-197ms, and **rung 3 now
  greps the whole log**. Gotcha 13's stated reason for the boot timeout turned out to be stale
  rather than merely incomplete (gotcha 31: a plain boot enters no area), and 30 frames was measured
  to produce a byte-identical log to 120. **A fourth checker, `check_strings.gd`**, is the
  hard-coded-string audit — deliberately not the literal-classifier `check_content.gd` refused in
  writing, but a **sink** rule and a **declaration** rule, because whatever reaches `.text` is
  player-facing by construction. Its second half closed a hole that was measurably live: with one
  transposed character planted in a toast key, `check_content`, `check_boundary` and all **1,517
  assertions passed**. 26 new assertions, three gates proved red with the real violation then green
  — **and one of those plants exposed a defect in the new test rather than in the code** (gotcha 42),
  a comment claiming an assertion covered save-participant order when the assertion stayed green
  with the invariant deleted. See the board.

Exit criteria:
- [x] Every system has one proof, and no system has a second area's worth of content
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
      — an item count in a quest step: **done**, T3.3, 2026-08-31. One counted step on the
      existing placeholder quest, two windowed captures LOOKED AT and READ rather than glanced at
      (gotcha 28): the journal reading `Underway - The Keeper's Errand - Gather three rose
      petals.  2 / 3` after `--give=item/rose_petal:2`, and the same screen at the same hour with
      one petal more reading `Settled - Nothing left to do.` The tally is a checkable prediction
      rather than a screenshot that merely looks fine
      — the look of an area as data: **done**, T3.2, 2026-09-01. Three seams, each demonstrated by
      a before/after pair from the same camera and hour in which ONE edit to ONE file is the only
      difference, all six LOOKED AT and READ (gotcha 28): one shared material tinted in
      `assets/materials/wood.tres` turns the dais in one area and the plinth in the other magenta
      together; `volumetric_fog_density = 0.06` on one area's driver node hazes that area alone;
      and the interior's own `fov = 36.0, distance = 9.5` draws the player at roughly 130 px
      against 78 at the same hour, with one run logging both rigs
      — dev tools: **done**, WP-14b, 2026-09-02. A debug console on F1 and a performance overlay
      on F3, three windowed captures LOOKED AT and READ. The console capture is a checkable
      prediction rather than a screenshot that looks fine: the run was launched at
      `--time=12:00 --freeze-time`, the console was handed `time 18:40`, and the HUD reads
      `Day 1 | 18:40 | Dusk` over a dusk-lit courtyard — readout and lighting agreeing. The
      overlay's own criterion is a frame time that visibly moves, measured across a load spike at
      35.71 ms / 28 fps and then 16.70 ms / 54 fps

**THIS CRITERION IS NOW TICKED**, and it was held open through T3.2 and WP-14 on purpose: it is
about every system having one proof, and the last two systems with none were the two dev tools.

- **WP-14b Dev tools — DONE, 2026-09-02.** The phase's NINTH package, the half WP-14 split off,
  and the row that CLOSES Phase T3. The console lives under `src/ui/` — settled rather than
  assumed, and settled on the stronger argument: it names no content, so putting it in the exempt
  debug directory would have bought it an exemption it does not need and switched off the gate
  that should be watching it. The four verbs became ONE implementation in
  `src/systems/debug/dev_commands.gd` that both argument parsers and the console call, so what you
  type in the console is exactly what you pass on the command line — and that extraction is also
  what made room for a sixth staging flag in `dev_stage.gd`, which was sitting at **exactly 250 of
  its 250 allowed code lines**. The console is a `UiScreen` declaring `pauses_world` and the
  overlay is a `CanvasLayer` that never enters the stack, which is one decision made twice from
  the same question. **Absence from a release export is MEASURED with a control** rather than
  assumed: a debug export logs both armed lines and a release export logs neither. 30 new
  assertions, seven plants each proved red with the real violation — **and the first version of
  the gate assertion was wrong twice over** (it read its own explaining comment, and the overlay
  carried the anchor fragment twice), which is gotcha 42 arriving on schedule and being caught
  only because the violation was planted. See the board.

## Phase T4 — Template v1.0 · **IN PROGRESS**

**Phase T3 closed with WP-14b, 2026-09-02.** WP-15's remnant — credits and an accessibility pass —
was **CLOSED by the owner** on the same day rather than built: both belong to a consuming game,
and the seams that make accessibility possible already exist and are proved. WP-10 (crafting) is
OPTIONAL and blocks nothing. The board carries the full reasoning.

- **T4.1 The version and the upgrade note — DONE, 2026-09-02** — `799d957`, PR #25. The phase's first package, and
  both of the things this phase was named for.

  **The version is `[template] base/version`, not `application/config/version`**, and that choice
  is the package: `NEW_GAME.md` § 4 tells a fork to reset its own version to `0.0.1` on day one,
  so after one fork that field no longer records which base the game came from. It is read through
  `src/core/util/template_version.gd` and printed in every boot banner as `base <version>`, which
  is what makes a bug report from a forked game answerable.

  **`docs/UPGRADING.md` was PERFORMED against a real stripped fork**, to `NEW_GAME.md`'s standard
  rather than written from intent: a fork made, two template releases landed on the base, both
  merged in, and the fork's whole ladder run afterwards. It found four things design would not
  have — that `project.godot` auto-merges, that `localization/strings.csv` conflicts every time in
  the same trivially-resolvable way, that **a merge pushes the template's own demo content back
  into a fork with no conflict and therefore no warning**, and a genuine template defect: a test
  block gated on "any content" while asserting about "any area", so a game that authored an item
  before its first area had a red rung 4 in exactly the window `NEW_GAME.md` walks it through.
  Fixed, planted and proved. `docs/CHANGELOG.md` is the version-to-version discipline and its
  newest heading is asserted equal to the setting.

  **What the template CANNOT promise is written down** — no clean merge, no content compatibility
  across a MAJOR, no save survival, nothing at all for a fork that edited `src/`, and no automatic
  upgrade, ever. See the board.
- **T4.2 A second worked example, authored from `AUTHORING.md` alone — DONE, 2026-09-02.** T2.2's
  mechanism applied to CONTENT: an orchard, a warden, a schedule, a conversation, two items, an
  equip-gated arch, a map def and a counted quest, all authored from the document alone with
  `src/` never opened — then deleted, because it was a test of the documents. **Five defects, and
  two were in the template rather than the prose:** `check_boundary` matched SUBSTRINGS, so an
  item called `pear` failed on the word `appeared` and the gate table told the author to blame
  the engine; and `--stand-by` always resolved in the DEPARTURE area, so no object in an authored
  area could be photographed at all. Both are gotcha 44's shape — invisible to both of this
  repository's states. Six more sections were performed and now hold proofs rather than claims.

**Exit criteria for the phase:**

- [x] The template states its own version, readably at runtime and assertably. — T4.1
- [x] A game already forked from this base has a documented, PERFORMED way to receive a later fix.
      — T4.1
- [ ] A release tag on the repository. Deliberately not taken by T4.1: a tag is a release action
      and releases are the owner's.

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
