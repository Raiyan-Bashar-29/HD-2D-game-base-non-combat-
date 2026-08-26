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

- **T2.1 The art contract.** A `SpriteSheetLayout` resource replacing `FACING_COUNT`/`FRAME_COUNT`;
  the sector maths derived from it rather than from a separate literal `TAU / 8.0`; an
  `animation_row` offset so idle-vs-walk is not structurally impossible; a project `Theme` so the
  UI look stops living as constants inside five screen files; shared materials; the environment
  post-stack as `@export`s rather than code constants; camera exports set per area; the texture
  import defaults flipped before real art lands; the Git LFS lines enabled.
- **T2.2 Consumer documentation.** `NEW_GAME.md`, `AUTHORING.md`, `ART_CONTRACT.md`, `TESTING.md`,
  and a stated extension surface versus internals.

Exit criteria:
- [ ] Swap in a sprite sheet with a different cell and frame count, changing **no code**
- [ ] One `Theme` change restyles every screen at once
- [ ] Someone who has not read `src/` can author an area, an NPC and a conversation from the docs

## Phase T3 — Finish the system catalogue

The remaining packages, re-framed — see the board — plus **the export proof**, which is the one
genuinely blocking item from WP-15: three registries find content by directory scan, no export
preset exists, and if an export omits unreferenced resources then every item, conversation and
schedule ships empty while every current gate still passes.

Exit criteria:
- [ ] An exported build on a machine without Godot reports non-zero catalogue counts
- [ ] Every system has one proof, and no system has a second area's worth of content

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
