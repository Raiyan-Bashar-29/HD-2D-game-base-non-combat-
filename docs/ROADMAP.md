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

## Phase 1 — One area, one character · **COMPLETE, and honestly so since 2026-09-04**

> **This phase read COMPLETE for months while carrying three unticked exit criteria**, and
> Phase 2 read IN PROGRESS with one. Nobody had lied: each was ticked as it was proved and
> the three that were awkward to prove — an eight-direction walk-through, a save across a
> real relaunch, and a 30-second session — were left, then the phase was called done on the
> strength of everything else. That is the drift this project polices everywhere else, in
> the one file that describes whether the project is finished. **T5.1 proved all four
> rather than ticking them**, and one of the four turned out to be a genuinely missing
> FEATURE rather than an unproved one: the locale setting was wired to nothing. The lesson
> is the cheap half of gotcha 23 — a criterion nobody has run is a criterion nobody knows
> the answer to, and "complete except for the hard ones" is how 409 passing checks happened.

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
- [x] Walk the courtyard, and the character faces the direction of travel correctly in all
      eight directions — done 2026-09-04 (T5.1). `facing_test.gd` asserts the mapping from a
      direction of travel to a facing and a sheet column, in the form that holds for every
      camera angle: the eight directions stay distinct, and one sector of turn advances the
      facing by exactly one. Planted both ways — swapping the axes in `_screen_angle` gives
      `expected 1, got 7`, and deleting the standing-still guard gives `expected 0, got 2`.
      A live windowed probe then walked the real player through all eight in the courtyard,
      reporting `facing=N column=N` for N in 0..7, and a capture at frame 140 was read.
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
- [x] Save, quit, relaunch, continue — position, time, weather and inventory all restored —
      done 2026-09-04 (T5.1), and in TWO PROCESSES, which is the whole point: the existing
      `--cross-area-save` reloads in process and cannot tell a value read back from disk
      from one that was simply never cleared. Run one posed `lantern_hall / 0.00,-4.20 /
      day 3 21:45 / STORM / carrying 1` and saved it; a fresh process reported that line
      back identically after loading. The boot line before the load is the control —
      `area='' at=0.00,0.00 day=1 time=06:00 weather=0 carrying=0` — and the weather is
      deliberately STORM rather than CLEAR, because CLEAR is the boot default and would
      have been right by accident.
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
- [x] A 30-second play session produces **zero** warnings or errors in the log — done
      2026-09-04 (T5.1), and it had simply never been run: the boot rung is 30 FRAMES at the
      main menu (gotcha 31). A windowed 33.6-second session that entered the courtyard,
      baked its navmesh, opened the satchel, cycled the sensor and interacted twice ended
      `0 warnings, 0 errors` with zero `SCRIPT ERROR`, `Parse Error` or leaked-RID lines.
- [x] The budget checker reports no file over its limit — a mandatory close-out gate for every
      package since WP-01; 73 files, 5,638 code lines, 0 violations at WP-06

> **Phases map onto work packages.** `docs/WORK_PACKAGES.md` is the executable version of this
> document: fifteen packages, one chat each, in dependency order. When the two disagree, the
> board is what is actually being worked and this file needs updating.

## Phase 2 — Two areas and a reason to move · **COMPLETE, 2026-09-04**

*Goal: prove the world is a world, not a room.*

- [x] A second area, with a door between them — the Lantern Hall, an interior (WP-04)
- [x] Loading that hides behind the fade, with the shader warm-up hitch handled (WP-04)
- [x] Navigation baking, and one NPC that walks a route by the clock (WP-06)
- [x] Dialogue runner, dialogue UI, and an authorable conversation format (WP-05)
- [x] The pause menu itself, and the other four menus with it (WP-12, taken early because
      Phase 3's controller-navigation criterion needed screens to navigate)
- [x] Localization wired for real: every string is already an ID, and since T5.1 the locale
      SETTING reaches `TranslationServer` and there is a second language to switch to
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
- [x] Switch language at runtime and see every visible string change — done 2026-09-04
      (T5.1). It was unmet for a reason no amount of wiring would have fixed: the CSV had
      ONE locale column, so there was nothing to switch TO, and `settings_screen.gd`
      cycled a locale, stored it, and nothing ever read it back — `TranslationServer` was
      never told. `Settings._apply_locale` now applies it, on `_apply_display`'s stated
      reasoning rather than by analogy: nothing else owns `TranslationServer` either.
      `tools/gen_pseudolocale.gd` generates an `en_XA` column so a second language exists
      without the template pretending to ship a translation — the same argument that
      generates placeholder ART. Two captures of the satchel at 12:00, differing only in
      that setting, were READ: `Satchel / Key Items / Rose Key x1` against
      `[~~Satchel~~] / [~~Key Items~~] / [~~[~~Rose Key~~] x1~~]`, the item row
      double-wrapped because the row format AND the name both come from the table.

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

## Phase T4 — Template v1.0 · **COMPLETE**

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

- **T4.3 `NEW_GAME.md` performed, and the release tag taken — DONE, 2026-09-03.** The phase's
  last package. **The stack landed first:** all 26 PRs were still open and `origin/main` was at
  `d0bf153`, but every branch was an ancestor of T4.2's tip, so retargeting #26 to `main` merged
  the lot as one 71-commit chain and made `v1.0.0` an honest tag rather than the dishonest one
  refused the day before.

  **Then the fourth document was performed**, and like the three before it, it found what reading
  could not. A fresh clone was forked, stripped and renamed from `NEW_GAME.md` alone. **Two
  defects, one of them the template:** `core_test.gd` asserted `[game] world/first_area != ""`
  UNCONDITIONALLY, contradicting its own case name, the comment eight lines below it and
  `NEW_GAME.md` § 4 — so a fork that did exactly what the document says had a red rung 4 before
  it authored its first area, while the document promised the ladder stays green. Green in both
  of this repository's states, because neither ever empties that field. The claim moved to
  `smoke_test.gd`, which already made it correctly and more strongly; the control — areas present
  with the field still empty — was planted and is still red.

  **And § 3's prune list never learned about quests.** Written before WP-08, it omitted `quest.`,
  so a fork shipped the demo's `quest.keepers_errand.*` rows — "The Keeper's Errand", "three rose
  petals" — inside its own game, with all four checkers and the whole suite green, because **no
  gate reads `localization/` for demo content at all.** That is now stated in the document as its
  own trap, with a grep to run after pruning. Three further prose defects were re-measured rather
  than inherited, including a `--new-game` invocation that is silently green without a `--`.

- **T4.4 `TESTING.md` performed, the last document never walked — DONE, 2026-09-04.** After the
  phase's exit criteria were already met, so it adds none: the phase closed with T4.3 and this
  package neither reopens it nor is required by it. What it settles is the *last* of the five
  consumer documents, and **five for five now — every document performed has found a defect no
  amount of reading would have, and three of the five were defects in the TEMPLATE.**

  **The template defect is the sharpest of the three, because it invalidated the rung that judges
  every other one.** The suite SKIPPED A LISTED CASE THAT DID NOT PARSE, in silence, at exit 0.
  `load()` on a script with a parse error returns a `GDScript` that is not `null` and cannot be
  instantiated, so `_run_case` walked into `script.new()` — and gotcha 24 already established that
  a GDScript runtime error aborts only the innermost frame, so the failure two lines below was
  never reached and the loop moved on. Measured: `=== 1608 passed, 0 failed, 0 skipped ===` and
  exit 0, a last line byte-identical to a checkout in which the file does not exist. T1.3 built
  two mechanisms here because the first was measured and found wanting; this was the third hole in
  the same wall, and the one neither was positioned to see — `error_watch.gd` had counted the error
  the whole time and nothing ever asked it. Two guards close it, and the second closes the class.

  **The document's one worked example did not compile**, and was wrong twice over — nothing
  declares `inventory`, and `Inventory` has no `count()`. Copying it verbatim is what began the
  package, which is a fair summary of why documents get performed rather than proofread.

  **And three documents gave three different answers to a countable question:** 44,
  48 and 43, over a list of 48 gotchas. `doc_counts_test.gd` counts the
  entries and requires every document that states the number to state that one — gotcha 48's shape
  without gotcha 48's excuse, since a count needs no list of exceptions behind it.

  One assertion was KEPT rather than deleted with the throwaway: `bag_mirror_test.gd`, on the
  ordering between the count-flag publish and `item_gained` / `item_lost`, which `Inventory.add`
  documents in a comment and which nothing tested on either path.

**Exit criteria for the phase:**

- [x] The template states its own version, readably at runtime and assertably. — T4.1
- [x] A game already forked from this base has a documented, PERFORMED way to receive a later fix.
      — T4.1
- [x] A release tag on the repository. Deliberately not taken by T4.1: a tag is a release action
      and releases are the owner's. **Taken 2026-09-03**, once the whole PR stack had landed —
      `v1.0.0` on `648bac1`, the merge commit that brought WP-01 through T4.2 onto `main` in one
      linear chain of 71 commits. It was refused on 2026-09-02 for a reason that had not yet
      expired: `origin/main` was still at `d0bf153`, so a tag then would have named either a
      commit lacking the version it claimed or an unmerged branch.

---


## Phase T5 — The base as a reusable CHARACTER kit · **IN PROGRESS**

*Goal: a future game inherits working characters and changes only assets. Several idle formats and
several movement styles, so that swapping a sprite sheet makes a character feel different without
touching code.*

**Why this phase exists, and why it is not scope creep.** Phases 0 to T4 answered "does the base
have a home for every system a game needs". This one answers a narrower and more practical
question the owner put on 2026-09-04: *when we make the actual game, what do we get for free?* The
answer had better be "the characters move, animate and feel distinct from their art alone",
because that is the part a new game otherwise rebuilds blind. It is a phase rather than a package
because the first row exposed how much of it was declared and unread.

- **T5.1 The skeleton's four open exit criteria — DONE, 2026-09-04.** Not part of this phase's
  goal, but it is what revealed the gap: proving criteria rather than ticking them found the
  locale setting wired to nothing, and reading the roadmap honestly is what prompted the question
  this phase answers. See Phase 1 and Phase 2, now fully ticked.

- **T5.2 An animation block per GAIT — DONE, 2026-09-04.** `SpriteSheetLayout.animation_for` took
  a **boolean**, so a sheet could hold an idle cycle and a walk cycle and nothing else: run and
  sneak replayed the walk block faster. Meanwhile `GameEnums.MoveState` had ten values and
  `Events.player_state_changed` was declared, emitted and **listened to by nothing** — the sixth
  time this project has found something validated and unread. It now takes a `MoveState`, and
  `run_row` / `sneak_row` / `climb_row` default to `-1` meaning "replay the walk block", so every
  sheet authored before it behaves identically and a game adds a run cycle by drawing one. Proved
  by 19 assertions, a live probe reading the real `sprite.frame`, and three captures in which the
  player walks in green and runs in rust while the NPC beside them stands in blue — same sheet,
  same frame, different blocks.

- **T5.3 Delivering the gaits that were already declared — DONE, 2026-09-04.** An audit of the
  whole base went looking for more of this project's characteristic defect and found the
  **seventh instance, created by T5.2 two rows above.** `MoveState.CLIMB` never reached
  `CharacterVisual` at all: `_physics_process` returns early while a climb owns the body, and
  `climb_step` touched the visual only after resetting the state to IDLE — so across all three
  callers of `update_from_velocity` nothing could ever pass CLIMB, and `climb_row` was exported,
  defaulted, range-limited, validated by `problems()` and asserted by `art_contract_test.gd`
  while being **impossible to draw**. Invisible in the demo because the shipped sheet leaves
  `climb_row` at -1, so the fallback drew the walk block and looked right; the first person to
  see it would have been the first game that drew a climb cycle. **Both ends were asserted and
  the wire was not** — `traversal_test` proved the body reports CLIMB, `art_contract_test`
  proved the layout maps it, and nothing proved it arrived. Second defect in the same function:
  `update_from_velocity` pinned `_frame = 0` whenever horizontal speed was zero, so **no idle
  block had ever advanced a single cell** — three of the shipped sheet's four idle cells were
  undrawable, while "more than one idle" sat on the exit criteria below. Fixed: a climb counts
  as moving without turning the character, and an idle block that DIFFERS from the walk block
  advances at a new `idle_fps` (a sheet whose idle *is* its walk block still holds cell 0, which
  is the pre-T2.1 case and would otherwise walk on the spot). Proved by 18 new assertions and by
  planting the revert: the fix removed, the suite is `1688 passed, 6 failed`, exit 1, naming
  `a climb draws the climb block — expected 1, got 0`; restored, `1694 passed, 0 failed`, exit 0.
- **T5.4 The three missing enforcement gates — DONE, 2026-09-05.** Not a character row, and it is
  here because the T5.3 audit that produced it found the structural cause of seven packages'
  worth of the same defect: **no gate anywhere asked whether a declared thing has a CONSUMER.**
  Three gates close it. `tools/check_signals.gd` requires every signal in the registry to have an
  emitter, resolving indirect `Signal`-value dispatch so the three quest signals — which have
  **zero** direct `.emit` sites — are not false positives; it named `debug_command` on its first
  run. `tools/check_layers.gd` enforces `core -> content -> systems -> gameplay -> ui`, the one
  architectural rule with no gate, and **found a real violation immediately: 55 upward
  references**, of which 13 were the interaction sensor sitting in `systems/` while typed on
  `Interactable`. Moved to `src/gameplay/interaction/`; gotcha 55. `check_boundary.gd` gained the
  `localization/` half, closing gotcha 48: an orphan CSV row fails, presence is reported, and the
  stripped CI job now runs `NEW_GAME.md`'s prune `awk` before it, which checks the prune list
  itself. Each gate proved red by planting a real violation and green by removing it — exit codes
  in `DEVLOG.md`. Ladder: four checkers to six, rungs 9 and 10 in CI as their own steps. 1,728
  assertions.

- **T5.5 The twelve settings with no consumer — DONE, 2026-09-05.** Also not a character row,
  and the last of the T5.3 audit's structural findings. **Twelve of twenty-three settings were
  declared, drawn to the player, translated in both languages, and inert.** Nine got a real
  consumer, placed by who OWNS the thing that has to change: the viewport and the shadow atlas to
  `Settings` itself, bloom to `EnvironmentDriver` because the Environment is that node's, DOF to
  `HD2DCameraRig` — `set_dof_enabled()`'s first ever caller — the prompt's two to `InteractPrompt`,
  the typewriter's to `DialogueScreen`, the hold floor to `InteractionSensor`, and
  `accessibility/text_scale` to a new `UiAccessibility` under `UILayer`. **`video/shadows` is the
  placement worth reading**: shadows are cast by lights an AREA AUTHOR placed, no node owns the
  set of them, so it is applied at the shadow ATLAS and a game that adds a hundred lights gets it
  free. **Three were REMOVED** — screen shake, autosave and subtitles have no machinery in this
  template to reach, and a row drawn to the player that cannot do anything is worse than a dead
  constant. **Five of the twelve were a TEMPLATE defect and not a missing game feature**: a fork
  could not honour `accessibility/*` without editing `src/`, because the thing that changes is the
  theme every screen in `src/ui/` draws from. Plus the audit's four one-liners:
  `reset_to_defaults()` never re-applied the locale, `Actions.JUMP` is gone entirely, and
  `rebind()` gates on `Actions.REBINDABLE`. **The seventh gate was deliberately NOT built** — the
  consumer question is an ASSERTION, because `Settings.DEFAULTS` is a runtime fact and a `check_*`
  tool would have to parse `settings.gd` to get it. Writing it found gotcha 56. Eight plants, each
  exit 1; six settings photographed in pairs. 1,782 assertions, stripped 1,708. Version 2.0.0,
  untagged. CI green on `31fea16`, PR #34.

- **T5.6 A wholesale character swap, photographed — DONE, 2026-09-05.** The phase's last proof
  criterion, and the only one of the three that was a proof rather than a feature. The repository
  held a sheet with a different GRID and a sheet with GAITS and **never one with both**, so the
  phase's claim had been demonstrated in halves. `character_alt.png` went from two animation
  blocks to five (idle, walk, run, sneak, climb, 96x600) and `character_alt_layout.tres` is now
  the only layout in the project that leaves no gait at -1. The player was pointed at the pair,
  driven through all five gaits through the real input path and photographed, and **no file under
  `src/` changed for the swap** — the swap is two `ExtResource` paths in `player.tscn`. The
  CONTROL is the strongest evidence: the same probe on the DEFAULT sheet draws blocks 0, 1, 2, 1,
  1 — sneak and climb falling back to the walk block, which is the `-1` contract measured in the
  live game for the first time. Four defects, three of them this row's own, and all four
  invisible to any rung that does not open a window: gotchas 57 to 60. Two plants, each exit 1,
  and plant 2 re-created T5.3's defect exactly, which is the row's own claim made good.
  1,782 -> 1,798 assertions. Version 2.1.0, untagged.

- **T5.7 `reduce_motion` finished, and the shadow atlas — DONE, 2026-09-05.** The two things T5.6
  wrote down and deliberately skipped. `accessibility/reduce_motion` reached **three of the four**
  motions this template draws: `ScreenFade` cuts instead of dissolving and
  `HD2DCameraRig.follow_lag` goes to zero, both on `_authored_dof`'s veto shape. **The shadow half
  was a live defect rather than a portability worry** — `_apply_shadows` restored a `2048` const
  called "the engine's own default" and the default is **4096**, so every windowed boot of this
  repository ran at half the authored shadow resolution, measured `boot = 2048` against
  `boot = 4096` on a real display server. `ShadowAtlas` (new, `core`) reads the authored sizes
  before the first zeroing; `settings.gd` went 144 -> 139 of its 150. That is **gotcha 61**, whose
  transferable half is that `_apply_display()` returns early under `--headless`, so no rung below
  the windowed capture executes that code at all. **The camera motion turned out to be
  photographable, contradicting this row's own prediction**: two `--gait-shots` runs differing by
  one line of `settings.cfg` translate the whole world by 42 px, residual 0.0268 at -42 against
  0.0975 at zero. Four plants, each exit 1. 1,798 -> 1,821 assertions.
  `settings_consumers_test.gd` split at its budget, `settings_effects_test.gd` is the new half. Version 2.2.0, untagged.

**Exit criteria for the phase:**

- [x] A character's movement styles come from its sheet, not its code: idle, walk, run, sneak and
      climb each addressable, and an unnamed one falling back rather than breaking. — T5.2 for
      the addressing, **T5.3 for climb actually arriving.** This box was ticked while CLIMB
      reached nothing; it is honest now, and the lesson is that "addressable" was asserted at
      both ends of a seam whose middle had no assertion.
- [x] The same seam serves NPCs, with no NPC-specific animation code. — T5.2, `NpcBrain` passes a
      gait and knows nothing about animation blocks. Worth knowing: `NpcBrain` only ever passes
      WALK or IDLE, so RUN, SNEAK and CLIMB are exercised by the player alone.
- [ ] **More than one idle.** A second idle block chosen over time or at random, so a standing
      character is not a held pose. **Reworded by T5.3's finding rather than closed:** the reason
      a standing character was a held pose was that the idle block never advanced at all, which
      is now fixed. What remains is genuinely a SECOND block and a chooser between them, and it
      is a smaller and more optional thing than this line implied.
- [ ] **A turn in place.** Changing facing while stationary currently snaps between columns —
      except that **nothing changes facing while stationary at all.** `_aim()` is called only
      when the character is moving, and the one public API for it, `face_direction()`, has only
      test callers. So the first question is not how to animate a turn but WHO is allowed to ask
      for one: the player turning to face an interaction target, or an NPC turning to face the
      player in dialogue. That is a seam decision and T5.3 deliberately left it to the owner
      rather than picking one silently.
- [x] **A worked example of swapping a character wholesale** — a second sheet with a different
      cell size, facing count and gait set, dropped in and photographed, to the standard T2.1 set
      for the layout swap. — **T5.6, 2026-09-05.** `character_alt.png` is 4 facings, 24x40 and
      FIVE blocks against the default's 8, 32x48 and three, and the swap is two `ExtResource`
      paths in `player.tscn` with nothing under `src/` touched. Five gaits driven through the
      real input path and photographed, each pip tally agreeing with the block decoded off
      `sprite.frame`; the same probe on the default sheet draws sneak and climb from the WALK
      block, which is the `-1` fallback measured live. Captures are re-takeable with `--gait-shots=<dir>` rather than committed, which is this project's standing practice for screenshots.

**THE PHASE IS CLOSABLE, AND CLOSING IT IS THE OWNER'S.** Two boxes remain and neither is a
defect: a second idle block is a chooser on top of machinery that now works, and **a turn in
place is explicitly a seam decision the owner has not made** — WHO may ask for a turn. T5.3 and
T5.5 both declined to pick one silently and T5.6 and T5.7 decline too. If the owner answers that
question the phase has one small row left; if the owner says the two remaining boxes belong to a
consuming game rather than to the base, the phase closes today.

**AND A THIRD THING THE OWNER SAW THAT NO EXIT CRITERION ASKS FOR — FIXED, T5.8, 2026-09-05.** On
2026-09-05 the owner reported that sideways movement "just slides to the side". It did, and **the
code was not the reason**: `character_placeholder.png` drew one pose eight times, measured at 0.7%
pixel difference between the front view and the back, with facings 2 and 3 byte-identical. Both
boxes above are about a character's BLOCKS; nothing on this list ever asked whether a facing is
distinguishable, and every capture in T5.2, T5.3 and T5.6 was taken without noticing.
**T5.8 gave both sheets five poses and a mirror** — front, three-quarter, side, three-quarter
back, back — took the worst facing pair from 0.0% to 7.5% (default) and 21.9% (alt), added
`sheet_facings_test.gd` with a floor picked by measurement, and photographed the same character
walking north, east, south and west through `--facing-shots`, which nothing in this repository had
ever captured. It touched no file under `src/` except the debug capture tool. That is gotcha 62.

- **T5.8 A placeholder sheet whose facings are distinguishable — DONE, 2026-09-05.** Candidate J,
  and the only row on this board that came from the owner playing the game rather than from an
  audit. Suite 1,821 -> 1,829, one plant at exit 1, version 2.3.0. **It does not tick either box
  above** — it is about the SHEET, not the blocks — but it changes the case for one of them: a
  turn in place was not worth animating while every facing drew the same picture, and now it is.

- **T5.9 Screen shake, and the setting that scales it — DONE, 2026-09-05.** Candidate H, and the
  row T5.7 obliged: it had finished `reduce_motion` for the three motions that EXISTED and written
  down that a shake would have to be reached in the SAME row it was built, or the setting was a
  gap again. `HD2DCameraRig` gained a decaying SINE offset (102 -> 138 of its 250, so no new class
  was needed), `Events.camera_shake_requested` is the ask, `Gate.open_shake` is the template's own
  asker and **defaults to 0.0**, and `gameplay/camera_shake` is back in `DEFAULTS` as its 0..1
  scale — **the first of the three settings 2.0.0 removed to come back with the feature it was
  waiting for**, which is what removing them instead of faking them was for. `reduce_motion`
  removes it outright rather than making it smaller, on the typewriter's and the fade's reasoning.
  A sine and not noise is what made it provable: the same command at scale 1.0 / 0.5 / 0.0 moves
  the camera **0.302357 / 0.151178 / 0.000000 m** and the picture **(+14,-12) / (+8,-6) / (0,0)
  px**, with the HUD at identical pixels throughout. Suite 1,829 -> 1,848, two plants each exit 1,
  **gotcha 64**, version 2.4.0.


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
