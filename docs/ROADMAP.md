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

## Phase 1 — One area, one character · **IN PROGRESS**

*Goal: a person can be walked around a lit, living space and touch things in it.*

Done:
- HD-2D camera rig with tilt-shift depth of field
- Billboarded, lit, shadow-casting 8-way character sprite
- Camera-relative movement with walk, run and sneak
- Day/night lighting driven by the world clock, verified at dawn, midday, dusk and night
- Weather state affecting sun and fog, verified under a forced storm
- The courtyard: ground, pillars, walls, a dais, two lanterns, spawn markers

Remaining:
- Item definitions, inventory, and pickups
- Containers (needs the item system first)
- A minimal HUD
- Content validator and hard-coded-string audit (the line-budget checker is DONE and passing)

Exit criteria:
- [ ] Walk the courtyard, and the character faces the direction of travel correctly in all
      eight directions
- [x] Approach three overlapping objects and select each one deliberately — ranking plus
      Tab cycling, done 2026-08-24
- [ ] Pick up an item; it appears in the inventory and no longer exists in the world
- [x] Refuse at a locked gate, throw the lever, open it, reload, and it is still open —
      done 2026-08-24, covered by the test suite
- [ ] Open a chest, take its contents, reload, and it is still open and still empty
- [ ] Sleep on the dais and watch the light change
- [ ] Save, quit, relaunch, continue — position, time, weather and inventory all restored
- [x] Test suite passes headless and exits non-zero on failure — 55 assertions, done 2026-08-24
- [ ] A 30-second play session produces **zero** warnings or errors in the log
- [ ] The budget checker reports no file over its limit

## Phase 2 — Two areas and a reason to move

*Goal: prove the world is a world, not a room.*

- A second area, with a door and an edge transition between them
- Loading that hides behind the fade, with the shader warm-up hitch handled
- Navigation baking, and one NPC that walks a route by the clock
- Dialogue runner, dialogue UI, and an authorable conversation format
- Notifications and a pause menu
- Localization wired for real: every string is already an ID
- Weather visuals: rain, wet surfaces, ambience layers

Exit criteria:
- [ ] Cross between areas twenty times with no leak in node count or memory
- [ ] Trigger two transitions in the same frame and be refused cleanly, with a log line
- [ ] An NPC is at the market at noon and at home at night, across a save and reload
- [ ] Hold a conversation that reads and sets a flag, and branches on it
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
