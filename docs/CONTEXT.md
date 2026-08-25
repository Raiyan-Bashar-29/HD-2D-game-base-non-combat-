# Context — read this first, it takes one minute

A state snapshot for a new session. `CLAUDE.md` has the *rules*; this file has the *situation*.
Keep it short. When it drifts from reality, fix it in the same commit as the change.

**Last updated:** 2026-08-24 · last commit `9e8e10c` · branch `main` · working tree has
uncommitted audit fixes
**Remote:** https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-

## What this is

HD-2D semi-open-world **exploration and narrative** game. Godot 4.7.2, GDScript.
Visual reference: Octopath Traveler I/II/0, The Adventures of Elliot.

**No combat.** Explicitly retracted by the owner — not an oversight. **Art is deferred**;
everything runs on procedural placeholders. The goal is a *base prototype*: a skeleton with a
home for every system the finished game will need, so later work is content and data, not new
architecture.

## Where it stands

Phase 0 complete, Phase 1 in progress. 25 scripts, ~1,890 code lines, 3 scenes, 1 area.
Boots headless with **0 warnings, 0 errors**.

**Works, and verified by running it:** logging with rotation · signal registry (`events.gd`) ·
input actions · settings · save/load with atomic writes and versioning · plot flags · area
director with a re-entrancy guard and threaded loading · world clock · weather state · audio
buses · HD-2D camera rig with tilt-shift DOF · billboarded lit shadow-casting 8-way character ·
camera-relative walk/run/sneak · day/night lighting · screen fade · dev screenshot capture ·
placeholder art generator · line-budget checker · headless test suite (55 assertions).

**Not built:** interaction system · items and inventory · world objects · triggers · NPCs ·
dialogue · quests · UI beyond the fade · content validator · localization wiring ·
weather visuals · typed Resource content classes (there are currently zero).

## Known defects

**Fixed 2026-08-24, all four found by audit and each verified after the fix:**

1. Toggle-run did nothing. `_is_running()` polled `is_action_just_pressed` and is called
   twice per frame, so the toggle flipped twice and netted to zero. Polling moved to
   `_poll_run_toggle()`, called once at the top of `_physics_process`.
2. A missing area left the opaque fade up forever with no recovery. `game_root.gd` now logs
   an error and requests the fade-in regardless.
3. `player_yaw` was written to every save and never read back, so facing was silently lost.
   Restored via `_yaw_override`.
4. **A fresh clone did not run at all.** `class_name` globals live in the gitignored
   `.godot/` cache, so `events.gd` could not resolve `GameEnums`, the `Events` autoload
   failed, and the console filled with parse errors that looked like broken code. Fix is
   documentation: run `--headless --import` once after cloning. Now stated in `README.md`
   and `CLAUDE.md`.

**Not defects, but known and deliberate:**

- `Weather` keeps rolling during a visual capture unless `--freeze-time` is passed, so an
  un-frozen screenshot is not reproducible.
- The environment driver rebuilds a `Dictionary` every frame in `_sample()`. Measured as
  harmless at this scale; revisit if the frame budget tightens.
- 17 of the 23 settings have no consumer yet. They are declared so the settings screen has
  something to bind to, not because anything reads them.

## Decisions already made — do not re-litigate

- **GDScript, not C#.** The installed engine is the standard build; .NET is not available.
- **Warnings are errors.** `var x = 5` does not parse. Read untyped data via `DictRead`, never
  `int(value)` on a `Variant`.
- **Input actions live in code** (`src/systems/input/actions.gd`), so the editor's Input Map
  panel looks empty. Intentional — ADR-0003.
- **Ten autoloads, no `GameManager`.** Adding one requires an ADR.
- **No jumping.** Vertical movement will be authored: ladders, stairs, climb points.
- Four ADRs in `docs/decisions/` cover the layered `src/`, warnings-as-errors, the input map,
  and save-via-callables.

## Verify before claiming anything is done

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --check-only --script <file>   # type gate
"$G" --headless --import                       # scenes and resources
"$G" --headless --quit-after 30                # must end "0 warnings, 0 errors"
"$G" --headless res://tests/test_runner.tscn --quit-after 150   # 55 assertions, exit 1 on fail
"$G" --headless --script tools/check_budgets.gd            # must exit 0
"$G" --resolution 960x540 --quit-after 55 -- --shot=<path> --time=18:40 --freeze-time
```

## Four gotchas that each cost an hour

1. Autoload identifiers (`Log`, `Events`, …) **do not resolve** under `--check-only`. That
   error is expected. Rungs 2 and 3 are the real compile check.
2. `--headless` uses a dummy rasteriser and **shades nothing**. Visual claims need the
   windowed capture. A day/night system once ran, logged correct times, reported no errors and
   lit nothing — because one `@export` was unwired in the scene.
3. Author with 4 spaces, then `unexpand -t 4 --first-only` before saving. Tabs are the project
   style, and mixed indentation is a parse error.
4. The test suite is a SCENE entered positionally, never `--script`. Under `--script` the
   autoload identifiers fail to compile, so no test touching a system can run that way.

## Next up

Interaction sensor → items and inventory → containers, doors, readables, triggers → object
persistence. Before any of it: decide the stable-object-ID scheme below, because every one of
those systems persists state through it.

**Two unresolved design questions that get expensive later:**
- **Stable object IDs.** Nothing yet assigns persistent identity to a world object. If it ends
  up being the node path, renaming a node orphans its saved state. Decide before content exists.
- **Sprite sheet layout is hardcoded.** `CharacterVisual` has `FACING_COUNT = 8` and
  `FRAME_COUNT = 4` as constants; a different sheet needs a code edit. Should be a resource.

## Read next

`CLAUDE.md` (rules) · `docs/ARCHITECTURE.md` · `docs/SYSTEMS_INVENTORY.md` ·
`docs/ROADMAP.md` · `docs/DEVLOG.md` · `src/core/events/events.gd` (the connection map)
