# Architecture

How Project Gulistan is put together, and why. This document is the reason the code looks the
way it does; if code and this document disagree, one of them is a bug.

## The problem this architecture exists to solve

The previous project, Veilbound Chronicles, recorded its own cause of death in
`ARCHITECTURE_DEBT_V1.md`:

- 14,557 lines of GDScript across only 26 files. `main.gd` reached **3,983 lines**,
  `world.gd` 3,598, `battle.gd` 2,372.
- 409 of 409 static checks passing, while "real parser/import run", "rendered collision
  validation" and "multi-resolution HD-2D presentation" all sat unresolved on the debt
  list. **The build had never been run in a real editor or a real frame.**
- ~200 hard-coded player-facing strings with no localization IDs.
- Eleven regions of content breadth with no single proven vertical slice.

Nothing here is about elegance for its own sake. Every rule below exists to make one of
those four outcomes structurally difficult.

---

## Layers

Dependencies point downward only. A layer may use anything below it and must never know
anything above it.

```
  ui/          screens, HUD, prompts             may read everything below it
  gameplay/    things that exist in the world     player, camera, areas, interactables
  systems/     game-agnostic services            director, clock, weather, audio, input
  content/     typed resource definitions        data shapes only, depends on nothing
  core/        no game knowledge at all          log, events, save, flags, settings, util
```

The test for a violation is simple: **could you delete the layer above and still compile?**
If `core` imports something from `gameplay`, that is a defect, not a shortcut.

**Why `content` sits below `gameplay`, not above it.** It was above until 2026-08-25. That was
wrong: `pickup.gd` in `gameplay` must reference `ItemDefinition` in `content`, which under the
old order was an **upward** dependency and failed the very test above. Content is *data*, not a
consumer - a pile of typed `Resource` shapes that depend on nothing and that anything may read.
The error was harmless only because `src/content/` was empty; it would have become real on the
day the first Resource landed. See ADR-0001.

`core` in particular must stay knowledge-free. `Log` does not read `Flags`. `SaveSystem` does
not know what a "clock" is. That is what lets both be trusted from anywhere.

## Autoload policy

Ten autoloads, in initialisation order. Each owns exactly one concern and each is small.

| Autoload | Owns | Must not |
|---|---|---|
| `Log` | Severity, categories, the log file, rotation | Read any game state |
| `Events` | Every cross-system signal declaration | Hold state or logic — permanently |
| `Actions` | Input action names and default bindings | Interpret what an action means |
| `Settings` | Machine preferences on disk, window and vsync | Apply audio or gameplay settings itself |
| `SaveSystem` | Slot files, format, version, atomic writes | Know what any section contains |
| `Flags` | Plot and world state | Interpret any flag |
| `Clock` | Day, hour, minute, phase | Know what time means to anything |
| `Weather` | Kind, blend, intensity, scheduling | Spawn a particle or touch a light |
| `Audio` | Bus layout, music and ambience | Own positional world sound |
| `Director` | Which area is loaded, transitions, player reference | Know what is inside an area |

**Order matters.** `Log` and `Events` come first because everything reports through them.
`SaveSystem` precedes every system that registers as a save participant, because registration
happens in `_ready()` and autoloads initialise top to bottom.

**Rules.**
1. An autoload must stay under **200 lines**. Past that, it is doing two jobs.
2. Adding one requires a decision record in `docs/decisions/`.
3. There is no `GameManager`, and there never will be. That name is how a codebase asks for
   a god object. If something does not fit the ten above, it is not global.

## How things talk to each other

Apply this in five seconds:

| Situation | Use | Why |
|---|---|---|
| You own the thing and it is right there | Direct call | Traceable, typed, cheapest |
| A parent needs to hear from its own child | Node signal | Local and obvious |
| A fact about the world changed and you must not know who cares | `Events` bus | Decoupled by design |
| You need a value back, or to know the receiver acted | **Never the bus** | Signals are announcements, not calls |

The bus has a real cost: emit and listen sites sit far apart, so flow is harder to trace.
Three rules keep that survivable, and they are enforced by convention in `src/core/events/events.gd`:

1. Every signal is **declared there**, with typed parameters. Never emitted ad hoc.
2. Past tense for things that happened; the `_requested` suffix for asks.
3. **Exactly one system emits any given signal,** and the comment names it. Two emitters
   means the signal is modelled wrong.

`events.gd` is therefore also the connection map: reading that one file tells you how the
game is wired.

## Composition, not inheritance

A character is not a subclass. It is a body with parts:

```
Player (CharacterBody3D)          movement, gait, state          player_controller.gd
|- Collision (CollisionShape3D)
|- Visual (Node3D)                billboard, facing, animation   character_visual.gd
|  |- Sprite3D
|- InteractOrigin (Marker3D)      where interaction rays start
```

`CharacterVisual` knows nothing about input and is reused unchanged by every NPC. The
controller knows nothing about how the sprite is drawn. Either can be replaced alone.

The same applies to areas. Every area scene has the identical shape, so `Director` never needs
a per-area special case, and area fifty needs no code at all:

```
AreaRoot (Node3D)                 area_root.gd
|- Environment/                   WorldEnvironment, Sun, Moon, EnvironmentDriver
|- Terrain/                       geometry and static collision
|- Props/                         scenery, lights
|- Interactables/                 anything the player can act on
|- Actors/                        NPCs
|- Spawns/                        one Marker3D per entry point
|- Triggers/                      Area3D volumes
|- Camera/                        the area's HD2DCameraRig
```

## Data, not code

| Belongs in | What |
|---|---|
| A typed `Resource` | Item definitions, area config, weather profiles, surface tables |
| A scene | Anything with a node structure: objects, characters, areas, UI |
| Script | Behaviour only |

The test: **adding the fiftieth item must not touch a single line of code.** If it does, the
item system is wrong.

## Anti-monolith measures, concretely

Good intentions did not work last time. These are mechanical:

1. **Warnings as errors.** `project.godot` sets `untyped_declaration`, `unsafe_call_argument`,
   `unsafe_method_access`, `unsafe_property_access` and `unsafe_void_return` to **error**.
   GDScript now behaves like a statically typed language: `var x = 5` will not parse, and
   calling a method on an untyped value is a build failure. This alone eliminates the largest
   category of runtime surprise.
2. **Line budgets,** counted in CODE lines so documentation is never penalised: 250 per
   script, 150 for an autoload, 40 per function, 60 for the game root. Enforced by
   `tools/check_budgets.gd`, which exits 1 on violation. Currently 23 files, 1,890 code
   lines, 0 violations. It also bans `print()` outside the logger and the tools.
3. **A stated `MUST NOT` in every file header.** Every script says what it is forbidden to
   know. When a change requires violating it, that is the signal to add a new system instead.
4. **The verification ladder,** below. Nothing is "done" until the engine has run it.

## The verification ladder

Every rung is proven working on this machine. Nothing here is aspirational.

| Rung | Command | Catches |
|---|---|---|
| 1. Parse and type gate | `--headless --check-only --script <file>` | Type errors, unknown functions, with file and line |
| 2. Import gate | `--headless --import` | Broken scenes, resources, asset references |
| 3. Headless run | `--headless --quit-after 120` | Boot order, null references, real `_process` frames |
| 4. Tests | `--headless res://tests/test_runner.tscn --quit-after 300` | Logic, save round-trips. 555 assertions, exit 1 on failure |
| 5. Visual capture | `--quit-after 55 -- --shot=<path> --time=HH:MM` | The actual look, at any hour, on demand |

**Rung 1 gotcha:** autoload identifiers such as `Log` do not resolve under `--check-only`,
because a standalone script check does not create them. Filter
`Identifier not found: <Autoload>` out of that gate; rungs 2 and 3 are the real compile check.

**Rung 4 gotcha:** it is a SCENE, entered positionally, not a `--script` tool. Under
`--headless --script` the autoload *nodes* are created but the autoload *identifiers* fail to
compile (`Compile Error: Identifier not found: Log`), so no test touching a system can run
that way. Also: anything created with `.new()` and not freed prints a wall of
`RID allocations were leaked at exit`, which drowns real errors.

**Rung 5 is the important one.** `--headless` uses a dummy rasteriser and shades nothing, so
visual work needs a real window. `DevCapture` makes that repeatable: it forces the clock and
the weather from the command line and writes the viewport to a PNG. This is what closes the
"multi-resolution HD-2D presentation cannot be verified" item that the previous project could
never resolve.

## The HD-2D look, and where it lives

| Ingredient | Where | Note |
|---|---|---|
| Long lens diorama | `hd2d_camera_rig.gd` | 27 degrees at 14 m, pitch -32. Matters more than any post effect |
| Tilt-shift depth of field | `hd2d_camera_rig.gd` | Both near **and** far blur. Far only just looks like fog |
| Billboarded sprites | `character_visual.gd` | `BILLBOARD_FIXED_Y`, so characters stay upright |
| Sprites that sort and cast shadows | `character_visual.gd` | `ALPHA_CUT_DISCARD`. Alpha blending writes no depth, so it cannot sort or cast shadows |
| Crisp pixels | `character_visual.gd` | `TEXTURE_FILTER_NEAREST` |
| Sprites lit in real time | `character_visual.gd` | `shaded = true`, which is why a lantern lights the character at night |
| Filmic highlights | `environment_driver.gd` | AgX tonemapping |
| Bloom | `environment_driver.gd` | Threshold 0.92, screen blend |
| Depth between scenery layers | `environment_driver.gd` | Depth fog beyond 30 m plus light volumetric fog |
| Day and night | `environment_driver.gd` | An eight-key colour table, interpolated every frame |
| No TAA | `project.godot` | TAA smears billboards and makes pixel art crawl. MSAA 4x instead |

## Known limitations, stated honestly

- **Input actions are invisible in the editor.** They are built in code, so Project Settings
  shows an empty Input Map. Accepted; see `docs/decisions/ADR-0003`.
- **No hard-coded-string audit.** Computed keys (`verb.*`, `refusal.*`, `item.category.*`,
  `time.phase.*`) are each covered by an enum loop in the suite, and `tools/check_content.gd`
  fails a CSV row with an unquoted comma — but literal player-facing text in code is still
  caught only by review.
- **Audio has no assets,** so every audio path is written but unexercised. It accepts `null`
  everywhere by design, which means it is untested rather than broken.
- **`Weather` publishes state but nothing renders it yet.** No rain exists.
- **The export path is unproven.** Items, conversations and schedules are all found by scanning
  a directory, which is verified in the editor and headless only. See ADR-0006.
- **`Director` does not cancel its threaded load on shutdown**, which is why the boot rung needs
  `--quit-after 120` rather than 30. Deferred to WP-14.
