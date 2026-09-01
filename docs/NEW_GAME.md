# Starting a new game on this template

The strip-and-start checklist. Read [`TEMPLATE.md`](TEMPLATE.md) first — it says *why* the
boundary exists; this says *what to delete* and *what to rename*.

**The one-line version:** delete `data/**` and `scenes/areas/**`, prune the demo half of
`localization/strings.csv`, rename four fields in `project.godot`, and never edit `src/`.

**The test that you did it right** is at the bottom, and it is mechanical: the ladder still goes
green on an empty game, and `tools/check_boundary.gd` still exits 0.

---

## 1. Delete

| Delete | Why it is demo |
|---|---|
| `data/items/*.tres` | the rose key, the petal, the stone chip |
| `data/dialogue/*.tres` | the gardener conversation |
| `data/schedules/*.tres` | the keeper's timetable |
| `data/actions/*.tres` | barter and scrutinise |
| `data/quests/*.tres` | the keeper's errand |
| `data/areas/*.tres` | where the two demo areas sit on the world map |
| `scenes/areas/courtyard/`, `scenes/areas/lantern_hall/` | the two demo areas, and everything placed in them |

**Keep the folders themselves.** `data/items/`, `data/dialogue/`, `data/schedules/`,
`data/actions/`, `data/quests/`, `data/areas/` and `scenes/areas/` are the **content roots the
registries scan**. `ItemDb`, `DialogueDb`, `ScheduleDb`, `QuestDb` and `AreaDb` find content by
directory scan (ADR-0006) — no registration list,
no code per item — so an empty folder is the correct empty state and a missing one is not.

```bash
rm -f data/items/*.tres data/dialogue/*.tres data/schedules/*.tres data/actions/*.tres
rm -f data/quests/*.tres data/areas/*.tres
rm -rf scenes/areas/courtyard scenes/areas/lantern_hall
```

## 2. Keep, and never edit to start a game

| Keep | What it is |
|---|---|
| `src/**` | **The engine. All of it.** Editing it to start a game is the failure this template exists to prevent. |
| `scenes/objects/`, `scenes/characters/`, `scenes/boot/` | reusable prefabs — a sign, a gate, a chest, a lever, a door, the player, an NPC, the boot tree |
| `tools/**`, `tests/framework/**` | the ladder |
| `assets/placeholder/**` | procedural art. Regenerate with `tools/gen_placeholders.gd`. |
| `localization/strings.csv` | **partly** — see below |
| `tests/unit/**` | the ladder — since T1.3 it builds its own content and passes without yours |

## 3. Prune the localization CSV

`localization/strings.csv` is the one mixed file. **Delete every row whose key starts with:**

```
area.        talk.        action.        object.
item.        — EXCEPT every item.category.* row, which is engine
```

Everything else is engine and stays: `ui.*`, `verb.*`, `refusal.*`, `notify.*`, `weather.*`,
`time.*`, `keys.*`, `item.category.*`.

```bash
awk '!/^(area|talk|action|object)\./ && (!/^item\./ || /^item\.category\./)' \
  localization/strings.csv > /tmp/pruned.csv   # keeps 147 of 189 rows; review, then move it back
```

**Two traps in this file:**

1. **A value containing a comma MUST be quoted**, or the CSV parser silently truncates it at the
   comma and `tr()` still returns a plausible-looking string. This shipped a half-sentence for
   three packages. `tools/check_content.gd` fails any row that parses to more than two columns.
2. **`ui.menu.title` holds the game's NAME**, not a UI label. It is an engine key with a
   game-specific value — change the value, keep the key.

Regenerate `strings.en.translation` by running `--headless --import` after editing.

## 4. Rename

Every place the template says which game this is. There are five, and there are no others —
`tools/check_boundary.gd` is what guarantees the sixth does not exist inside `src/`.

| File | Field | Note |
|---|---|---|
| `project.godot` | `application/config/name` | the boot banner and the log file name are derived from this, through `GameConfig` |
| `project.godot` | `application/config/description` | |
| `project.godot` | `application/config/version` | reset to `0.0.1` |
| `project.godot` | `application/config/icon` | and replace `icon.svg` |
| `project.godot` | **`[game] world/first_area`** | **the one that matters.** The area a new game begins in. `world/first_spawn` defaults to `default`. |
| `README.md`, `CLAUDE.md` | title lines | project-facing prose, not code |

**Do not** grep-and-replace the game name across `docs/`. The DEVLOG is a history of this
template's construction and should stay readable as one.

### What `[game] first_area` is, and why it is a project setting

Nothing under `src/` may name an area, so `Director` cannot hold
`const FIRST_AREA := &"courtyard"` — it did until T1.2, and that is the leak this whole boundary
was written for. It is read through `GameConfig.first_area()`
([`src/core/util/game_config.gd`](../src/core/util/game_config.gd)).

An empty setting is a legal state — a template with no game in it yet. `Director.start_new_game()`
then logs `No first area — set game/world/first_area in project.godot` and changes nothing, rather
than clearing the flags and going quiet.

## 5. The one thing that will not be clean, stated honestly

**The test suite comes with you, and it tells you what it stopped covering.** As of T1.3 the
cases build the content they need from `tests/framework/fixtures.gd`, so deleting `data/` and
`scenes/areas/` leaves rung 4 intact: `880 passed, 0 failed, 12 skipped`, exit 0. Those twelve are
the assertions that genuinely ask something about authored content — that the catalogue matches the
disk, that every item name has a CSV row, that every waypoint a schedule names exists in some
area. They come back one at a time as you author your own content, and until then the run PRINTS
each one rather than quietly passing.

**`src/systems/debug/` names demo content on purpose.** `dev_probes.gd` and `dev_stage.gd` are the
development harness — `--give=item/rose_key` stages a photograph, `--goto=` drives a real
transition — and a probe that travelled to an abstract area would verify nothing. They are the one
directory `tools/check_boundary.gd` exempts, they are behind `OS.is_debug_build()` so they cannot
be driven in a shipped build, and the exempted names are **counted and printed** by the gate so a
new game can see how much rewriting the harness needs. Rewrite their scenario arguments for your
own content; do not delete the files, because the capture and measurement machinery around them is
engine.

## 6. Verify

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --import                                   # FIRST, always — class_name cache
"$G" --headless --quit-after 30                            # must end "0 warnings, 0 errors"
"$G" --headless --script tools/check_content.gd            # must exit 0
"$G" --headless --script tools/check_boundary.gd           # must exit 0
"$G" --headless --script tools/check_budgets.gd            # must exit 0
"$G" --headless --script tools/check_strings.gd            # must exit 0
"$G" --headless res://tests/test_runner.tscn --quit-after 400
```

**On a stripped template with no content yet, the first four must still pass.** This was RUN, not
assumed — the whole strip above was performed against the demo and reverted, and T1.2 in
`DEVLOG.md` quotes the output:

```
  item definitions: 0 · conversations: 0 · schedules: 0 · path actions: 0 · scenes scanned: 14
  PASS
  demo names derived: 0 — []
  src scripts scanned: 74 (res://src/systems/debug/ is exempt)
  PASS
```

Zero items is not an error; an item that is present and does not load is, and `ItemDb` reports
that per file. (It WAS an error until T1.2, and the first command in this document made the gate
fail.) `check_boundary.gd` derives zero demo names and passes trivially, which is exactly right:
the rule it enforces is about `src/`, and `src/` did not change.

The boot run is clean and lands on the main menu. Starting a game before you have set
`[game] world/first_area` logs, and changes nothing:

```
[ERROR] [world    ] No first area — set game/world/first_area in project.godot
```

That is the template telling you the one thing it still needs.

The test suite passes, with skips reported. Section 5 says what the skips are.

## 7. Export

**`export_filter="all_resources"` in `export_presets.cfg`. If you change one thing in this
document, do not change that one.** `ItemDb`, `DialogueDb` and `ScheduleDb` find content by
SCANNING a directory (ADR-0006), so nothing in any scene references most of `data/**`. Those
resources are nobody's dependency, and Godot's exporter walks dependencies. Narrow that filter and
your items, conversations and NPC schedules do not ship — while every editor run, both CI jobs,
`check_content` and all 930 assertions stay perfectly green, because there the files are plainly on
disk. `tests/unit/export_test.gd` now asserts the field, so a change fails rung 4 rather than a
release.

The preset is committed (only `override.cfg` is gitignored), so a new game inherits a working one.
Rename `export_path` and the `application/*` fields; leave `export_filter` alone.

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --export-debug "Windows Desktop" "$(pwd -W)/build/windows/game.exe"
cd build/windows && ./game.console.exe --headless --quit-after 30
```

**Use `--export-debug`, and read the `[content]` lines.** `src/systems/debug/catalogue_report.gd`
reports every catalogue's count and resolved paths at boot, and WARNS on an empty one in an
exported build. It is behind `OS.is_debug_build()`, so a release export prints nothing — which is
correct for players and useless for verifying, hence the debug export. Compare against the same
lines from a source run; equal is the only acceptable answer. A PARTIAL ship is worse than an empty
one, because three of four items is a plausible number.

**An export template must be installed first** — Godot will refuse otherwise. That is expected
setup, not a problem to route around. `--export-pack` does not need one and is enough to check
*which files* ship; only a real template can prove they are *found* at runtime.

**Two things that go wrong here, both silent from source:**

1. **A hand-authored `.tscn` that overrides a node inside an instanced scene needs
   `[editable path="<the instance>"]`.** Without it the text loader applies the override and the
   exporter's binary conversion DROPS it, so your prefab reverts to its defaults in the shipped
   build only. This bit the demo: the keeper lost its `object_id`, its prompt and its
   conversation in an export and nowhere else. `tools/check_content.gd` now fails on it.
2. **A narrowed `export_filter` does not just cost you content.** It also strips the `class_name`
   scripts that are nobody's dependency — `GameConfig`, `GameEnums`, `DictRead` — and the build
   dies at boot on parse errors. Loud, and worth knowing so the symptom is not misread.

## Read next

[`TEMPLATE.md`](TEMPLATE.md) · [`ARCHITECTURE.md`](ARCHITECTURE.md) ·
[`SYSTEMS_INVENTORY.md`](SYSTEMS_INVENTORY.md) · [`decisions/`](decisions/)
