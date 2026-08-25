# Systems Inventory

Everything Project Gulistan needs, with what it depends on, what it must never know about,
and where it stands today.

**Status key**

| Mark | Meaning |
|---|---|
| DONE | Built, runs, and verified by the engine |
| PART | Skeleton exists and runs; scope deliberately incomplete |
| TODO | Not started |
| LATER | Deliberately deferred, with a reason given |

The **Boundary** column is the anti-god-object column. It records what a system is forbidden
to know, and it is the single most important column in this document. Every monolith in the
previous project started as a system that was allowed to know one thing too many.

---

## 0. Foundation

| System | Purpose | Depends on | Boundary — must NOT know | Status |
|---|---|---|---|---|
| Logging | Severity- and category-tagged log to console and rotating file | nothing | any game rule; it never reads Flags | DONE |
| Event registry | One declared, typed home for every cross-system signal | nothing | holds zero state and zero logic, permanently | DONE |
| Shared enums | Vocabulary two or more systems must agree on | nothing | anything used by only one system | DONE |
| Safe data reads | Typed reads out of untyped JSON and save data | nothing | what the data means | DONE |
| Collision layers | Named layer and mask constants | nothing | who uses them | DONE |
| Settings | Player machine preferences, on disk | Log, Events | how to apply audio or gameplay settings; it announces, owners react | DONE |
| Save system | Slots, atomic writes, schema version, migration | Log, Events | what any save section contains | DONE |
| Flag store | Plot and world state, one source of truth | Log, Events, Save | what any flag means | DONE |
| Game root | Builds the persistent tree, spawns the player | Director | game logic of any kind. 60-code-line hard budget | DONE |
| Input actions | Action names and default bindings, declared in code | Log | what an action means; it names, never interprets | DONE |
| Verification harness | Parse gate, import gate, headless run, visual capture | Godot only | — | PART |

## 1. World and presentation

| System | Purpose | Depends on | Boundary — must NOT know | Status |
|---|---|---|---|---|
| Scene director | Area load, unload, transition, player placement | Log, Events, Save | what is inside an area; no per-area special cases | DONE |
| Area root | The uniform contract every area scene satisfies | Weather, Audio, Log | gameplay logic | DONE |
| HD-2D camera rig | Long-lens diorama framing, tilt-shift depth of field | Events, Director | input; what it follows beyond a Node3D | DONE |
| Character visual | Billboarded, lit, correctly-sorted sprite with 8-way facing | Events | input, movement, game rules | DONE |
| Player controller | Movement, gait, movement state, authored climb, token input lock | Actions, Settings, Events, Layers | dialogue, inventory, interaction rules, the camera | DONE |
| World clock | Day, hour, minute, time-of-day phase | Log, Events, Save | what time *means* to anything | DONE |
| Weather state | Current kind, blend, intensity, scheduling | Log, Events, Save | particles, lights, sounds | DONE |
| Environment driver | Turns clock and weather into real lighting and post | Clock, Weather | what time it is or what weather it is; it only renders consequences | DONE |
| Screen fade | The black rectangle transitions hide behind | Events | why it is fading | DONE |
| Audio director | Bus layout, music and ambience cross-fade | Settings, Events | positional world sound; a door owns its own player | PART |
| Dev capture | Screenshots, and forcing time, weather and a time skip from the CLI | Clock, Weather | nothing may depend on it | DONE |
| Weather visuals | Rain, snow, wind particles and wet surfaces | Weather | weather scheduling | TODO |
| Area streaming | Chunked load for large regions | Director | — | LATER — discrete areas first; Director already loads threaded, so this is a swap, not a rewrite |
| Navigation | Baked navmesh for NPC pathing | Area root | who is walking | TODO |
| Interior lighting | Areas that ignore the outdoor sun | Environment driver | — | PART — `follow_clock` flag exists |

## 2. Interaction, items, objects — the current milestone

| System | Purpose | Depends on | Boundary — must NOT know | Status |
|---|---|---|---|---|
| Interaction sensor | Finds and ranks candidate targets, fires the chosen one | Actions, Events, Layers | what any interactable does | DONE |
| Interactable contract | The base class every interactable satisfies | Events | who is interacting, beyond a Node3D | DONE |
| Interaction prompt UI | Shows verb and label for the current target, localized | Events | how to perform an interaction | DONE |
| Item definitions | Typed Resource, id equals filename, ADR-0006 | — | inventory or world state | DONE |
| Item registry | id to definition by directory scan; static, not an autoload | — | who carries anything | DONE |
| Item instances | Per-item mutable state: durability, contents | Item definitions | UI | LATER — deferred until something has durability; id plus count suffices |
| Inventory | Held items, stacking, a capacity seam. A component, not an autoload | Events, Save | how items are displayed | DONE |
| Inventory UI | Grid, tooltips, sorting, controller navigation | Events | inventory rules | TODO |
| Pickups | World items that enter the inventory | Interactable, Inventory | — | DONE |
| Containers | Take-all chests. Named ItemContainer: Container is a native class | Interactable, Items | — | DONE |
| Doors and gates | Locked, unlocked, flag-gated, with refusal reasons | Interactable, Flags | — | PART — flag-gated done; area transit not wired |
| Readables | Signs, books, notes | Interactable, Localization | — | DONE |
| Switches and levers | Toggle world state | Interactable, Flags | what the state causes | DONE |
| Trigger volumes | Fire on entry, once or every time, persisted by object_id | Layers, Flags, Events | what its firing causes | DONE |
| Harvestables | Gather with a regrowth timer | Interactable, Clock, Inventory | — | TODO |
| Sittables and beds | Rest, and skip time through `Clock.skip_to_hour` | Interactable, Clock | why the hour it jumps to matters | DONE |
| Climbables | Ladders and authored climb points, two markers per object | Player controller | how to move a body — it asks the mover | DONE |
| Physics props | Push, drop, stack | Layers | — | TODO |
| Water volumes | Wading and swimming | Player controller, Layers | — | LATER |
| Equipment | Tools, lantern, clothing that change traversal and interaction | Inventory, Flags | combat — there is none | TODO |
| Object persistence | Authored object_id, state via Flags. ADR-0005 | Flags, Save | object behaviour | DONE |

## 3. Characters and life

| System | Purpose | Depends on | Boundary | Status |
|---|---|---|---|---|
| Character attributes | Stamina, carry capacity, skills that gate interactions | Save | what gates what | TODO |
| Footsteps and surfaces | Surface-aware step audio and particles | Audio, Player controller | — | TODO |
| NPC brain | Idle, wander, react to the player | Navigation, Clock | dialogue content | TODO |
| NPC schedules | Routines driven by the world clock | Clock, NPC brain | — | TODO |
| NPC level of detail | Cheap offscreen behaviour so a town scales | NPC brain | — | LATER |
| Path actions | Non-combat NPC verbs, in the spirit of Octopath's Scrutinise and Inquire | Interactable, Flags, Inventory | — | TODO |
| Followers | A companion that trails the player | Navigation | — | LATER — leave a seam, build nothing |
| Animation state machine | Drives sprite animation from movement and actions | Character visual | — | PART — code-driven frames work now; revisit if authored animation is needed |

## 4. Narrative

| System | Purpose | Depends on | Boundary | Status |
|---|---|---|---|---|
| Dialogue runner | Executes a conversation graph | Events, Flags | how it is displayed | TODO |
| Dialogue UI | Box, portrait, choices, text speed | Events, Settings | conversation logic | TODO |
| Dialogue content format | Authorable, diffable conversation files | — | — | TODO |
| Barks | Short unprompted lines with cooldowns | Dialogue UI | — | LATER |
| Cutscenes | Scripted camera, movement and timing | Director, Player controller | — | TODO |
| Quests and objectives | State machine per quest, with steps | Flags, Events, Save | dialogue content | TODO |
| Journal and codex | What the player has learned | Quests, Flags | — | TODO |
| Plot gating | Chapter progression and content locks | Flags | — | TODO |
| Map markers | Objective and discovery markers | Quests, Area root | — | TODO |

## 5. Interface

| System | Purpose | Depends on | Boundary | Status |
|---|---|---|---|---|
| Screen stack | Push/pop screens, one gameplay-input truth, the UiMode announcement | Events, Actions | what any screen contains, or that the player exists | DONE |
| Screen contract | UiScreen: a screen declares whether it pauses and whether cancel closes it | — | pausing, locking input, or its own lifetime | DONE |
| Input lock | Named tokens so two systems holding input cannot release each other | nothing | what input is | DONE |
| Pause semantics | Deliberate process_mode per node; music and the fade keep running | — | — | DONE |
| HUD | Minimal: prompts, notifications, clock | Events | game rules | TODO |
| Notifications | Transient localized toasts | Events | — | DONE |
| Pause menu | The actual menu. The pause mechanism underneath it is DONE | Actions, UiRoot | — | TODO |
| Main menu | New game, continue, settings, quit | Save, Director | — | TODO |
| Save and load screen | Slot list with headers and playtime | Save | — | TODO |
| Settings screen | Every entry in the Settings defaults table | Settings | — | TODO |
| Key rebinding | Rebind, and glyph swapping per device | Actions, Settings | — | TODO |
| World map | Region map, discovery, fast travel | Director, Flags | — | TODO |
| Controller navigation | Every screen fully usable on a gamepad | Actions | — | TODO |
| Loading screen | Covers threaded area loads | Director | — | PART — fade exists, no progress display |

## 6. Content pipeline and production

| System | Purpose | Status |
|---|---|---|
| Placeholder art generation | Procedural stand-ins so code can be finished before art | DONE |
| Content validator | tools/check_content.gd — ids, duplicate object_ids, CSV keys, stray defs | DONE |
| Line-budget checker | Mechanical enforcement of file and function size limits | DONE |
| Test runner | Headless integration tests, scene-entered, exit 1 on failure | DONE |
| Hard-coded string audit | Catches player-facing text that is not a localization key | TODO |
| Localization | String IDs from the first string; CSV translation | PART — CSV wired, 28 keys, all UI text localized. No audit tool yet |
| Smoke test | Boots, loads an area, saves, reloads, asserts zero errors | TODO |
| Export presets | Windows build configuration | LATER |
| Performance overlay | Frame time, draw calls, node counts | TODO |
| Debug console | Teleport, set flag, set time, spawn item | TODO |

---

## Commonly forgotten — the list that saves a month later

These are the things hobby projects skip and regret. Written down now so they are decisions
rather than oversights.

1. **Pause semantics.** Pausing needs `process_mode` set deliberately per node. Music must
   keep playing, animations must stop, and the fade must still work. Already handled for
   audio and the screen fade.
2. **Save on quit,** and the window close button. `set_auto_accept_quit(false)` is already
   wired so this can be added without restructuring.
3. **Window focus loss.** Unfocused should not mean the character keeps walking because a
   key was held when focus went away.
4. **Controller hotplug** mid-session, and switching glyphs when it happens.
5. **Text speed and instant skip.** A player who reads fast will hate the game without it.
6. **Autosave indicator,** and never autosaving during a transition.
7. **"Are you sure"** on overwriting a save and on quitting with unsaved progress.
8. **First-run defaults** that are actually pleasant, since most players never open settings.
9. **Reduced motion,** and a depth-of-field toggle. Heavy DOF causes real nausea for some
   people, which is why `set_dof_enabled` exists on the camera rig from day one.
10. **Subtitles and speaker names,** on by default.
11. **Localization from the first string.** Retrofitting 200 hard-coded strings is exactly
    the debt the previous project logged.
12. **A photo mode,** which costs little and is how players market the game for you.
13. **Credits,** including every asset licence, tracked as they are added rather than
    reconstructed in a panic.
14. **Shader pre-compilation.** Godot compiles shaders on first use, which shows up as a
    stutter the first time it rains. Needs a warm-up pass before shipping.
15. **A corrupt-save path** that loses one slot instead of the whole profile. Atomic writes
    are in; recovery messaging is not.

---

## The slice-one subset

The smallest set that makes a real game loop, and the current target:

**Have it:** logging, events, settings, save, flags, input, game root, director, area root,
camera rig, character visual, player controller, clock, weather state, environment driver,
screen fade, audio buses, dev capture, placeholder art, the screen stack and pause semantics.

**Still needed:** interaction sensor, interactable component, prompt UI, item definitions,
inventory, pickups, containers, doors, object persistence, a minimal HUD, the test runner and
the smoke test.

**Explicitly not in slice one:** dialogue, quests, NPCs, weather visuals, navigation, world
map, main menu, streaming, followers, crafting, water.
