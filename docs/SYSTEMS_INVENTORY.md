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
| Logging | Severity- and category-tagged log to console and rotating file | GameConfig | any game rule; it never reads Flags, and since T1.2 it does not know the game's NAME either | DONE |
| Game config | The four values a consuming game sets in project.godot: first area, first spawn, name, slug | nothing | what an area contains, or whether the id it hands out is real | DONE — T1.2 |
| Event registry | One declared, typed home for every cross-system signal | nothing | holds zero state and zero logic, permanently | DONE |
| Shared enums | Vocabulary two or more systems must agree on | nothing | anything used by only one system | DONE |
| Safe data reads | Typed reads out of untyped JSON and save data | nothing | what the data means | DONE |
| Collision layers | Named layer and mask constants | nothing | who uses them | DONE |
| Settings | Player machine preferences, on disk | Log, Events | how to apply audio or gameplay settings; it announces, owners react | DONE |
| Save system | Slots, atomic writes, schema version, migration | Log, Events | what any save section contains | DONE |
| Flag store | Plot and world state, one source of truth | Log, Events, Save | what any flag means | DONE |
| Game root | Builds the persistent tree, spawns the player, asks for the main menu | Director | game logic of any kind. 60-code-line hard budget | DONE |
| Input actions | Action names and default bindings, declared in code | Log | what an action means; it names, never interprets | DONE |
| Key bindings store | One player's overrides of the input map, in user://input.cfg | Log, DictRead | naming an action or deciding a default; it never mentions Actions | DONE |
| Verification harness | Parse gate, import gate, headless run, visual capture | Godot only | — | PART |

## 1. World and presentation

| System | Purpose | Depends on | Boundary — must NOT know | Status |
|---|---|---|---|---|
| Scene director | Area load, unload, transition, player placement, shader warm-up | Log, Events, Save | what is inside an area; no per-area special cases | DONE — two areas really swap, 20 round trips flat |
| Area root | The uniform contract every area scene satisfies | Weather, Audio, Log | gameplay logic | DONE — the eight required children are now asserted, not just documented |
| Area doors | The one object that asks to travel. Names an id and a spawn, nothing else | Interactable, Director | loading, fading, or moving the player | DONE |
| HD-2D camera rig | Long-lens diorama framing, tilt-shift depth of field | Events, Director | input; what it follows beyond a Node3D | DONE |
| Character visual | Billboarded, lit, correctly-sorted sprite with 8-way facing | Events | input, movement, game rules | DONE |
| Player controller | Movement, gait, movement state, authored climb, token input lock | Actions, Settings, Events, Layers | dialogue, inventory, interaction rules, the camera | DONE |
| World clock | Day, hour, minute, time-of-day phase | Log, Events, Save | what time *means* to anything | DONE |
| Weather state | Current kind, blend, intensity, scheduling | Log, Events, Save | particles, lights, sounds | DONE |
| Environment driver | Turns clock and weather into real lighting and post | Clock, Weather | what time it is or what weather it is; it only renders consequences | DONE |
| Screen fade | The black rectangle transitions hide behind | Events | why it is fading | DONE |
| Audio director | Bus layout, music and ambience cross-fade | Settings, Events | positional world sound; a door owns its own player | PART |
| Ambience bed | Several named environmental layers at once, each at its own level | Log | what weather is; it is told a name and a level | DONE — two layers, on generated filtered noise, because there is no audio in the project |
| Dev capture | Screenshots, and forcing time, weather, wetness and a time skip from the CLI | Clock, Weather | driving a scenario; nothing may depend on it | DONE |
| Dev probes | Scripted scenarios no assertion can run: round trips, cross-area saves, a whole NPC day, a crowd | everything | posing the world, or being depended on by gameplay | DONE |
| Dev staging | Puts the world into the state a capture needs: stand here, hold this, feel that way, press the button | everything | measuring anything | DONE |
| Weather visuals | Rain, snow, wind particles, wet surfaces and the ambience mix | Weather, Audio, Director | what the weather is, or when it changes | DONE — one node per area; captures of clear, rain and storm are visibly different |
| Precipitation emitter | One self-building GPUParticles3D per kind, mesh and material generated | GameEnums | Weather; it is told a weight | DONE |
| Wetness model | The 0..1 that rises in rain and dries slowly afterwards | nothing | materials, particles, Weather | DONE — pure, so the dry-out is asserted rather than photographed |
| Surface wetness | Darkens and clearcoats an area's materials as it soaks | Log, DictRead | Weather or the clock; it is handed a 0..1 | DONE — duplicates each material, so wetness cannot outlive the area |
| Area streaming | Chunked load for large regions | Director | — | LATER — discrete areas first; Director already loads threaded, so this is a swap, not a rewrite |
| Navigation | Navmesh baked from each area's own geometry at load, behind the fade | Area root | who is walking | DONE — polygon count logged, so an empty bake is an error rather than silence |
| Interior lighting | Areas that ignore the outdoor sun | Environment driver | — | DONE — authored ambient, fog and background applied once; the outdoor path never touches an interior sun |

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
| Inventory UI | A UiScreen: rows grouped by category, localized names and counts, focus navigation | Events, Inventory, ItemDb | inventory rules, pausing, locking the player | PART — no tooltips, sorting or drag-and-drop |
| Pickups | World items that enter the inventory | Interactable, Inventory | — | DONE |
| Containers | Take-all chests. Named ItemContainer: Container is a native class | Interactable, Items | — | DONE |
| Doors and gates | Locked, unlocked, flag-gated, with refusal reasons | Interactable, Flags | — | DONE |
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
| NPC brain | Schedule-driven: travel to a named waypoint, then stand, wander or sleep | Navigation, Clock, ScheduleDb | what a waypoint means, routes, dialogue content | DONE |
| NPC schedules | Hour blocks as authored .tres, found by directory scan like items | — | moving anything, or resolving its own waypoint | DONE |
| NPC level of detail | Cheap offscreen behaviour so a town scales | NPC brain | — | LATER — 30 NPCs cost +0.077 ms/frame, so nothing forces it yet |
| Path actions | Non-combat NPC verbs. One Interactable per action, selected with the cycle key | Interactable, Flags, Standing | performing itself, or what a standing level means | DONE — 2 of 5 verbs authored |
| Standing | What one person thinks of the player. A clamped namespace over Flags, not a store | Flags | what any level means, or what changes it | DONE |
| Followers | A companion that trails the player | Navigation | — | LATER — leave a seam, build nothing |
| Animation state machine | Drives sprite animation from movement and actions | Character visual | — | PART — code-driven frames work now; revisit if authored animation is needed |

## 4. Narrative

| System | Purpose | Depends on | Boundary | Status |
|---|---|---|---|---|
| Dialogue runner | Walks a conversation: conditions, branching, effects. A component, not an autoload | Events, Flags, DialogueDb | how it is displayed, pausing, locking input | DONE |
| Dialogue UI | Box, choices, typewriter reveal. The first non-pausing overlay | Runner, Settings | conversation logic, pausing, locking input | PART — no portraits (art is deferred), no history log, no skip-all |
| Speakers | An interactable that names a conversation id and emits | Interactable, DialogueDb | opening a screen, or what is said | DONE |
| Dialogue content format | Conversation/DialogueNode/DialogueChoice as .tres, found by directory scan like items | — | running itself, or reading a flag | PART — one condition and one effect per node |
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
| HUD | Clock readout. The prompt and the toasts are their own siblings under UILayer | Events, Clock | game rules, and owning the other readouts | DONE |
| Screen keys | Action-to-screen and request-to-screen bindings, the one menu factory, and unwinding the stack on travel | Actions, UiRoot | holding a screen reference, or a flag for "a screen is open" | DONE |
| Notifications | Transient localized toasts | Events | — | DONE |
| Menu contract | MenuScreen: a titled column of focusable rows, written once for all five menus | UiScreen, UiRoot | what a row means, or pausing | DONE |
| Pause menu | Resume, save, load, settings, controls, main menu, quit, over a stopped world | Actions, UiRoot, Save, Director | unloading an area or writing a save itself | DONE |
| Main menu | New game, continue, load, settings, controls, quit. The boot path now stops here | Save, Director | loading an area or clearing a flag itself | DONE |
| Save and load screen | Slot list with headers and playtime, in either direction | Save | the save format, or what a section holds | DONE |
| Settings screen | Every entry in the Settings defaults table, generated from it | Settings | applying a setting; it writes and Settings announces | DONE |
| Key rebinding | Rebind a key or a pad button per action; overrides persist in user://input.cfg | Actions, KeyBindings | naming an action or deciding a default | PART — no glyph swapping per device, and no duplicate-binding warning |
| World map | Region map, discovery, fast travel | Director, Flags | — | TODO |
| Controller navigation | Every screen fully usable on a gamepad | Actions | — | DONE — a VBoxContainer of Buttons answers ui_up/ui_down and ui_accept, so no screen owns a cursor; proved windowed with real events |
| Loading screen | Covers threaded area loads | Director | — | DONE — fade plus a progress readout drawn above it; the one node after ScreenFade |

## 6. Content pipeline and production

| System | Purpose | Status |
|---|---|---|
| Placeholder art generation | Procedural stand-ins so code can be finished before art | DONE |
| Content validator | tools/check_content.gd — ids, duplicate object_ids, CSV keys, stray defs | DONE |
| Engine/demo boundary gate | tools/check_boundary.gd — FAILS if any file under src/, tests/framework/ or tests/unit/ names demo content, and fails if the exempt debug surface loses its release guard. Demo ids derived from scenes/areas/ and data/, never listed | DONE — T1.2 |
| Line-budget checker | Mechanical enforcement of file and function size limits | DONE |
| Test runner | Headless integration tests, scene-entered, exit 1 on failure. Four silent-pass modes now fail loudly: a case that crashes, one that returns early, one that asserts nothing, and a suite file that exists and is not in CASES | DONE — hardened T1.3 |
| Test fixtures | tests/framework/fixtures.gd + fixture_content.gd — the content a case needs, built in code. In memory where a system is HANDED content, written to a temp directory the registries scan where a system looks it up by id | DONE — T1.3 |
| Engine script-error watch | tests/framework/error_watch.gd — an OS.add_logger Logger counting ERROR_TYPE_SCRIPT, because a GDScript crash aborts only its own frame and the tally cannot see it | DONE — T1.3 |
| Redirectable content root | ItemDb/DialogueDb/ScheduleDb.content_dir — a game, or the fixtures, may point the scan somewhere other than data/ | DONE — T1.3 |
| Continuous integration | .github/workflows/ladder.yml — six of the seven rungs on every push, PR and manual dispatch, in two jobs: full checkout and a stripped template. Engine downloaded, SHA512 verified against a pinned literal, build string asserted. Rung 2 grepped for SCRIPT ERROR / Parse Error with zero tolerance. .godot/ deliberately NOT cached | DONE — T1.4 |
| Pinned engine setup | .github/actions/setup-godot — the version lives in one file so two jobs cannot drift onto different engines | DONE — T1.4 |
| Hard-coded string audit | Catches player-facing text that is not a localization key | TODO |
| Localization | String IDs from the first string; CSV translation | PART — CSV wired, 188 keys, all UI text localized. Unquoted commas are now a gate; no full audit tool yet. docs/NEW_GAME.md names the engine and demo halves |
| New-game checklist | docs/NEW_GAME.md — what to delete, what to keep, the full rename surface | DONE — T1.2, and its claims were run against a stripped copy |
| Smoke test | Boots, loads an area, saves, reloads, asserts zero errors | TODO |
| Export presets and the export proof | Windows preset committed in `export_presets.cfg`; `export_filter="all_resources"` measured as the one setting that ships directory-scanned content, and asserted by `tests/unit/export_test.gd`; `src/systems/debug/catalogue_report.gd` reports every catalogue's count and resolved paths at boot of a debug build, and WARNS on an empty one in an export | **DONE — T2.0, 2026-08-26.** The exported `.exe`, run outside the editor, reports 3 items, 1 conversation, 1 schedule — identical to the editor. A second export-only defect was found on the way: a missing `[editable]` marker silently dropped instance overrides, now a `check_content` gate |
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

**Still needed:** nothing. Interaction, items, inventory, pickups, containers, doors, object
persistence, the HUD, the inventory screen, the test runner and the smoke test all exist and
are verified by running the engine.

**Explicitly not in slice one:** quests, world map, streaming, followers, crafting, water.
Dialogue (WP-05), NPCs and navigation (WP-06), path actions (WP-07), the menus (WP-12) and the
weather visuals (WP-13) have all since shipped, several of them ahead of this list rather than
in it.
