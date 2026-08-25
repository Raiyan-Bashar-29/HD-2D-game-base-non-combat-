# Working on Project Gulistan

Read this before touching anything. It is short because the detail lives in `docs/`.

**Start with [`docs/CONTEXT.md`](docs/CONTEXT.md)** — one minute, and it tells you what exists,
what is broken right now, and what not to re-litigate. This file is the rules; that one is the
situation.

## What this is

An HD-2D semi-open-world **exploration and narrative** game. Godot 4.7.2, GDScript.

**There is no combat.** No battles, no enemies, no damage, no encounters. This was an explicit
retraction by the owner, not an oversight. If a task seems to need combat, it does not — redirect
the effort into traversal, interaction, world state or environment simulation.

**Art is deferred.** Do not generate or request art. Every system must work on the procedural
placeholders in `assets/placeholder/`, indefinitely. `tools/gen_placeholders.gd` regenerates them.

## The engine

Always the **console** executable; the plain one detaches and prints nothing.

```
/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
```

It is the **standard build, not .NET** — C# is not available. Regenerate the offline API
reference with `--headless --doctool <dir>` and check property names there rather than from
memory; 4.7 is newer than most training data. Module classes (`GridMap`, `CSGBox3D`,
`FastNoiseLite`) live in `modules/*/doc_classes`, not `doc/classes`.

## Non-negotiables

1. **Nothing is done until the engine has run it.** Every completion claim cites a command and
   its result. This project exists because the previous one had 409 passing static checks and
   had never rendered a frame.
2. **Static typing is mandatory** — warnings are errors, so untyped code will not parse. Read
   untyped data through `DictRead`, never `int(value)` on a `Variant`.
3. **No player-facing string literals.** Localization keys from the first line.
4. **Respect the `MUST NOT` line** in every file header. When a change needs it broken, add a
   system instead of widening the boundary.
5. **Run `tools/check_budgets.gd` before finishing.** It must exit 0.
6. **Append to `docs/DEVLOG.md`** every session: did, why, connects, verified, unblocks, gaps.
7. **Indentation is tabs.** Author with spaces, then `unexpand -t 4 --first-only`.

## Verification, in order

**On a fresh clone, run `--headless --import` FIRST.** `class_name` globals live in the
gitignored `.godot/` cache; without it every script referencing `GameEnums` or `DictRead`
fails to parse and the autoloads never load.

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --check-only --script <file>   # type gate; filter "Identifier not found: <Autoload>"
"$G" --headless --import                       # scenes and resources
"$G" --headless --quit-after 30                # must end "0 warnings, 0 errors"
"$G" --headless res://tests/test_runner.tscn --quit-after 150   # 165 assertions, exit 1 on fail
"$G" --headless --script tools/check_budgets.gd
"$G" --headless --script tools/check_content.gd    # ids, duplicate object_ids, CSV keys
"$G" --resolution 960x540 --quit-after 55 -- --shot=<path> --time=18:40 --freeze-time
```

**Gotchas that will cost you an hour each:**
- Autoload identifiers (`Log`, `Events`, …) do **not** resolve under `--check-only`. That
  error is expected; rungs 2 and 3 are the real compile check.
- `--headless` uses a dummy rasteriser and shades **nothing**. Visual claims require the
  windowed capture. A day/night system once ran, logged correct times, reported no errors, and
  lit nothing at all — because an `@export` reference was unwired.
- Anything `.new()`d and not freed spews `RID allocations were leaked at exit`.

## Where things go

`src/` is layered and dependencies point **downward only**:
`core` → `content` → `systems` → `gameplay` → `ui`. `core` knows nothing about the game, and
`content` is data shapes only, so anything may read it.

Ten autoloads, each owning one concern: `Log`, `Events`, `Actions`, `Settings`, `SaveSystem`,
`Flags`, `Clock`, `Weather`, `Audio`, `Director`. **Adding one requires an ADR.** There is no
`GameManager` and never will be.

`src/core/events/events.gd` declares every cross-system signal and is the connection map —
read it first to understand how anything is wired.

## One package per chat

A chat context window is the binding constraint on this project, so work is sliced into
packages that each fit in one. **[`docs/WORK_PACKAGES.md`](docs/WORK_PACKAGES.md) is the board.**

**Opening a chat:** read this file and `docs/CONTEXT.md`, then find your package and read **its
file manifest and nothing else**. Do not read the whole `src/` tree, the audit reports, or other
packages files.

**Closing a chat:** the package is not done until the full ladder is green, new behaviour has
assertions, `SYSTEMS_INVENTORY.md` / `ROADMAP.md` / `DEVLOG.md` / `CONTEXT.md` are updated, the
board marks it done, and it is committed and pushed. The checklist is in the board.

No package exceeds about 8 files or 500 new code lines. Over that, split it and add a row -
same reasoning as the file budgets: a package that outgrows one chat gets half-finished.

## Read next

`docs/WORK_PACKAGES.md` (the board) · `docs/CONTEXT.md` (state) · `docs/ARCHITECTURE.md` · `docs/SYSTEMS_INVENTORY.md` ·
`docs/ROADMAP.md` · `docs/DEVLOG.md` · `docs/CONVENTIONS.md` · `docs/decisions/`
