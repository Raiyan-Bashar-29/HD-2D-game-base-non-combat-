# Roadmap

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
- [x] Test suite passes headless and exits non-zero on failure — 555 assertions
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
- The pause menu itself (the pause mechanism under it landed early, in WP-02)
- Localization wired for real: every string is already an ID
- Weather visuals: rain, wet surfaces, ambience layers

Exit criteria:
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

## Phase 3 — The vertical slice

*Goal: thirty minutes that represent the finished game.*

- Main menu, save/load screen, settings screen, full controller navigation
- A quest with steps, a journal, and map markers
- Path actions: non-combat NPC verbs in the spirit of Octopath's Scrutinise and Inquire
- Equipment that changes traversal — a lantern that opens the dark places
- Cutscene support with scripted camera
- Real art begins replacing placeholders, area by area
- Performance pass, and a Windows export

Exit criteria:
- [ ] A new player finishes the slice with no guidance and no soft-lock
- [ ] 60 fps at 1080p on the target machine, measured not assumed
- [ ] Exported build runs on a machine without Godot installed
- [ ] A 30-minute soak produces zero errors
- [ ] Every player-facing string is a localization key, proven by the string audit

## Phase 4 — Production

Content scaled on proven systems: regions, quest lines, the full plot, audio, accessibility
pass, and release engineering. Deliberately unplanned in detail — planning it now would be
the same mistake as the previous project's eleven regions.

---

## Sequencing rules

1. **Depth before breadth.** No second region until the first one is genuinely good. This is
   the single lesson from eleven shallow regions.
2. **No content without a system.** If an area needs a feature that does not exist, build the
   feature or cut the area. Do not special-case it.
3. **Nothing is done until the engine says so.** Every completion claim cites a command that
   was run and its result.
4. **Every session appends to `DEVLOG.md`.** What changed, why, how it connects, what was
   verified.
5. **Art stays deferred** until Phase 3. Systems must run on placeholders indefinitely.
