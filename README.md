# Project Gulistan

An HD-2D semi-open-world exploration and narrative game. 3D environments with real-time
lighting, billboarded 2D sprite characters, a long-lens diorama camera, day/night and weather.

Visual reference: Octopath Traveler I / II / 0, and The Adventures of Elliot.

**There is no combat.** The game is about moving through a world, interacting with its objects
and people, watching it change with the hour and the weather, and following a plot.

- **Engine:** Godot 4.7.2 stable, standard build. GDScript only — the installed engine is not
  the .NET build, so C# is not available.
- **Status:** Phase 0 complete. Phase 1 in progress. See [ROADMAP](docs/ROADMAP.md).

---

## Read these first

| Document | What it is for |
|---|---|
| [ARCHITECTURE](docs/ARCHITECTURE.md) | Layers, autoloads, how systems talk, the HD-2D recipe |
| [SYSTEMS_INVENTORY](docs/SYSTEMS_INVENTORY.md) | Everything the game needs, with status and boundaries |
| [ROADMAP](docs/ROADMAP.md) | Phases and their exit criteria |
| [DEVLOG](docs/DEVLOG.md) | What was done, when, why, and what verified it |
| [CONVENTIONS](docs/CONVENTIONS.md) | Naming, typing, and file rules |
| [decisions/](docs/decisions/) | Why particular choices were made, so they are not re-litigated |

## Running it

The engine lives outside this repo. Use the **console** executable for anything on the command
line — the plain one detaches and prints nothing.

```bash
GODOT="/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
```

Play it:

```bash
"$GODOT" .
```

## Verifying it

Five rungs, each proven to work. Details and gotchas in
[ARCHITECTURE](docs/ARCHITECTURE.md#the-verification-ladder).

Type-check one script. Catches type errors and unknown function calls, with file and line:

```bash
"$GODOT" --headless --check-only --script src/core/save/save_system.gd
```

Import gate — broken scenes, resources and asset references:

```bash
"$GODOT" --headless --import
```

Boot for real and watch the log. Should end with `0 warnings, 0 errors`:

```bash
"$GODOT" --headless --quit-after 30
```

Look at the game at a specific hour, in specific weather, without waiting for it:

```bash
"$GODOT" --resolution 960x540 --quit-after 55 -- --shot=user://shots/dusk.png --time=18:40 --freeze-time --weather=RAIN
```

`--shot`, `--shot-frame`, `--time`, `--freeze-time` and `--weather` are all documented at the
top of `src/systems/debug/dev_capture.gd`. Press **F12** in game for a manual screenshot.

Regenerate the placeholder art:

```bash
"$GODOT" --headless --script tools/gen_placeholders.gd
```

## Layout

```
src/          all GDScript, in five layers: core -> systems -> gameplay -> content -> ui
scenes/       boot, areas, characters, objects, ui, vfx
data/         authored content instances (.tres / .json)
assets/       art and audio, including generated placeholders
localization/ translation sources
tests/        headless test runner and cases
tools/        generators, validators and checkers
docs/         the documents listed above
```

Dependencies point downward through the `src/` layers only. `core` knows nothing about the
game; everything may depend on `core`.

## Controls

WASD or arrows to move. **Shift** run, **Ctrl** sneak, **E** interact, **Tab** cycle target,
**I** inventory, **J** journal, **M** map, **Esc** pause. Full gamepad bindings included.

Actions are declared in `src/systems/input/actions.gd`, not in `project.godot`, so the
editor's Input Map panel will look empty. That is deliberate — see
[ADR-0003](docs/decisions/ADR-0003-input-map-in-code.md).

## House rules

1. Nothing is "done" until the engine has run it. Every completion claim cites a command and
   its result.
2. No player-facing string is ever written as literal text. It is a localization key from the
   first line.
3. Every script header states what the file **must not** know. When a change needs that rule
   broken, add a system instead.
4. Depth before breadth. One area, genuinely good, before a second one exists.
5. Every session appends to the [DEVLOG](docs/DEVLOG.md).
