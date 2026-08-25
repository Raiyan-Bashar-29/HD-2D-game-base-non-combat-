# Development Log

Append-only. Newest entry at the top. One entry per working session.

**Entry template**

```
## YYYY-MM-DD — Title
**Did:**       what changed, concretely
**Why:**       the reason, so a future reader does not undo it
**Connects:**  how the new pieces wire into what already existed
**Verified:**  the exact command run, and its result. No claim without one
**Unblocks:**  what is now possible that was not before
**Known gaps:** what is deliberately still missing
```

---

## 2026-08-24 — Audit: four defects fixed, and rung 4 of the ladder made real

**Did:**

Audited the Phase 0 skeleton, fixed every confirmed defect, and built the test suite.

- **Toggle-run did nothing.** `_is_running()` polled `Input.is_action_just_pressed` and is
  called twice per frame (from `_current_speed()` and `_update_state()`), so the toggle
  flipped twice and netted to zero. Polling moved into `_poll_run_toggle()`, called once at
  the top of `_physics_process`, and `_is_running()` is now a pure query.
- **A missing area left the screen permanently black.** `ScreenFade` starts opaque and only
  `Director` lifts it, so the early-return in `game_root.gd` stranded the player. It now logs
  an error naming the expected path and requests the fade-in regardless.
- **`player_yaw` was saved and never read.** Written to every save since the first commit,
  read nowhere, so facing was silently lost on load. Restored via `_yaw_override`.
- **A fresh clone did not run at all.** Proved by cloning the repo to a scratch directory:
  `class_name` globals live in `.godot/global_script_class_cache.cfg`, which is generated and
  correctly gitignored, so `events.gd` could not resolve `GameEnums`, the `Events` autoload
  failed to instantiate, and the console filled with parse errors that look like broken code.
  One `--headless --import` fixes it. Now documented in `README.md`, `CLAUDE.md` and
  `docs/CONTEXT.md`.
- **The silent fallback that hid a bug is now loud.** `EnvironmentDriver`'s sibling discovery
  reported at `Log.debug`; it is a `Log.warn` now, so an unwired scene reference cannot hide
  behind a working-looking day/night cycle again. Also added the canonical
  `node_paths=PackedStringArray(...)` header to the `EnvironmentDriver` node in
  `courtyard.tscn`, which is the documented serialization for node-typed exports.
- **Built `tests/test_runner.gd` + `.tscn`:** 55 assertions over `DictRead` coercion, `Flags`
  including no-op-set silence, `Clock` hour/day rollover and midnight-crossing arithmetic,
  `Weather` force and shelter, and a full save round-trip.
- Added `docs/CONTEXT.md`, a one-minute state snapshot for a new session, linked from the top
  of `CLAUDE.md` and the first row of the README table.

**Why:**

Two of the four Veilbound failure modes had already reappeared in miniature, in this project,
at 1/600th scale. `ROADMAP.md` marked "a save participant can register, and the save envelope
round-trips" as a met Phase 0 exit criterion when only the registration had ever been observed,
as a log line — the save path had never once executed. That is precisely the
409-passing-checks pathology. The criterion is now genuinely true, and the roadmap records
that it was wrongly claimed a day earlier rather than quietly correcting itself.

**Connects:**

Rung 4 had to become a **scene** entered positionally, not the `--script` tool the
architecture document specified. Under `--headless --script` the autoload *nodes* are created
but the autoload *identifiers* fail to compile (`Compile Error: Identifier not found: Log`),
so no test touching a system could ever have run that way. The documented command could not
have worked; it is corrected in `ARCHITECTURE.md`, `README.md`, `CLAUDE.md` and `CONTEXT.md`.

**Verified:**

- Type gate clean on all four edited scripts.
- `--headless --import` clean.
- `--headless --quit-after 60` — loads the courtyard, `0 warnings, 0 errors`.
- `--headless res://tests/test_runner.tscn --quit-after 150` — **55 passed, 0 failed**, exit 0.
  A deliberately broken assertion was confirmed to produce exit 1, so the gate genuinely fails.
- `tools/check_budgets.gd` — 24 files, 2,026 code lines, 0 violations, exit 0.

**Unblocks:**

Interaction, items and world objects can now be built against a suite that will catch a
regression in save, time or flags, rather than against a boot log.

**Known gaps:**

Still zero typed `Resource` content classes and zero `tr()` calls, so the "adding the
fiftieth item touches no code" test in `ARCHITECTURE.md` cannot yet be run even once, and the
no-hard-coded-strings rule has a document but no mechanism. No stable-object-ID scheme, which
blocks object persistence and is the next thing to decide. Trigger volumes have a folder, a
collision layer and no system. The audit that found this was itself incomplete — three of five
dimensions landed before the run hit a weekly usage limit; correctness and Godot-API review
were done by hand instead, and the surviving reports are in the scratchpad, not the repo.

---

## 2026-08-23 — Phase 0 foundation, and a lit courtyard with a character in it

**Did:**

Created the project from an empty folder.

- **Structure:** 80 directories in five code layers (`core`, `systems`, `gameplay`,
  `content`, `ui`), plus `scenes`, `data`, `assets`, `localization`, `tests`, `tools`, `docs`.
  Git initialised on `main`. `.gitignore` and `.gitattributes` written, including a note that
  `*.uid` and `*.import` files **must** be committed.
- **Engine config** (`project.godot`): Forward+, MSAA 4x, TAA deliberately off, debanding on,
  occlusion culling on, gravity 24, ten named collision layers, editor folder colours, and
  GDScript warnings-as-errors.
- **Ten autoloads:** `Log`, `Events`, `Actions`, `Settings`, `SaveSystem`, `Flags`, `Clock`,
  `Weather`, `Audio`, `Director`.
- **Utilities:** `Layers`, `GameEnums`, `DictRead`.
- **Gameplay:** `HD2DCameraRig`, `CharacterVisual`, `PlayerController`, `EnvironmentDriver`,
  `AreaRoot`, screen fade, game root.
- **Tools:** procedural placeholder art generator, and `DevCapture` for screenshots and
  command-line control of time and weather.
- **Content:** the `courtyard` area and the player scene.
- **Docs:** this log, `ARCHITECTURE.md`, `SYSTEMS_INVENTORY.md`, `ROADMAP.md`,
  `CONVENTIONS.md`, and decision records.

**Why:**

The previous project died of four things, all recorded in its own debt register: god objects
(`main.gd` at 3,983 lines), code that passed 409 static checks while never once running in a
real engine frame, 200 hard-coded strings, and eleven regions of breadth with no proven
slice. Every structural decision here targets one of those. The two strongest levers are
warnings-as-errors, which makes untyped and unsafe code fail to parse at all, and the
verification ladder, which makes "it runs" a command rather than an opinion.

**Connects:**

`Log` and `Events` sit at the bottom and depend on nothing, so everything may use them.
`Events` is the single declared home for every cross-system signal, which makes it the
connection map — reading that one file shows how the game is wired. `SaveSystem` knows
nothing about game content: systems register a pair of callables, so adding a saveable system
never edits the save code. `Clock` publishes time and refuses to interpret it;
`EnvironmentDriver` consumes it and turns it into light. `Director` owns every area
transition behind one guarded path so two doors cannot fire at once. `GameRoot` spawns the
player once and `Director` repositions them per area, so walking out and back in cannot lose
state.

**Verified:**

- `--headless --import` — clean, no errors.
- `--headless --quit-after 30` — boots, loads the courtyard, spawns the player, exits 0 with
  **0 warnings and 0 errors**.
- Parse and type gate over all 18 scripts — every one clean under warnings-as-errors.
- Deliberately broken script → exit 1 naming the file and line, so the gate genuinely fails.
- Visual capture at 06:50, 12:30, 18:40 and 22:00, plus a forced storm. Dawn shows warm low
  light and long raked shadows; night shows cold ambient with two warm lantern pools and the
  character lit by them. **The character sprite casts a real shadow**, which confirms
  `ALPHA_CUT_DISCARD` is behaving as intended.

**Two real bugs found and fixed by that visual pass**, neither of which any static check
would have caught:

1. The character was invisible. `centered = false` with a negative Y offset pushed the sprite
   1.68 m below the ground. Now centred and lifted by half a cell height, derived from the
   texture rather than hard-coded.
2. Every hour of the day rendered identically. `EnvironmentDriver`'s `sun` and `moon`
   `@export` references were never wired in the area scene, so the driver held `null` and the
   directional light stayed frozen at its default energy forever. Wired explicitly, **and**
   the driver now discovers its own siblings by name and logs a warning when it has to — so
   the same silent failure cannot recur.

The second one is the whole argument for rung 5 of the ladder. A day/night system that
compiles, runs, logs correct times, reports no errors, and lights nothing.

**Unblocks:**

The interaction, item and object systems, which are the next milestone. They have somewhere
to live (`Interactables/` in every area), a way to be found (`Layers.INTERACT_MASK`), a way to
announce themselves (four interaction signals already declared in `Events`), a way to persist
(`Flags` plus the area's `flag_key()` namespace), and a way to be seen (placeholder art plus
capture).

**Known gaps:**

No test runner yet, so rung 4 of the ladder is unused. No audio
assets, so every audio path is written but unexercised. Weather publishes state but nothing
renders rain. Only one area exists, so the transition code has never actually swapped two
areas. Input actions do not appear in the editor's Input Map panel, which is a known accepted
trade-off.
