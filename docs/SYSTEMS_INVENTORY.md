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
| Flag store | Plot and world state, one source of truth. A prefix may be declared DERIVED, so its keys are readable and announced but left out of the save file — one publisher re-derives them | Log, Events, Save | what any flag means, and how to derive anything | DONE |
| Game root | Builds the persistent tree, spawns the player, asks for the main menu | Director | game logic of any kind. 60-code-line hard budget | DONE |
| Input actions | Action names and default bindings, declared in code | Log | what an action means; it names, never interprets | DONE |
| Key bindings store | One player's overrides of the input map, in user://input.cfg | Log, DictRead | naming an action or deciding a default; it never mentions Actions | DONE |
| Verification harness | Parse gate, import gate, headless run, visual capture | Godot only | — | PART |

## 1. World and presentation

| System | Purpose | Depends on | Boundary — must NOT know | Status |
|---|---|---|---|---|
| Scene director | Area load, unload, transition, player placement, shader warm-up | Log, Events, Save | what is inside an area; no per-area special cases | DONE — two areas really swap, 20 round trips flat |
| Area root | The uniform contract every area scene satisfies | Weather, Audio, Log | gameplay logic | DONE — the ten required children are asserted, not just documented, and authored in `docs/AUTHORING.md` |
| Area doors | The one object that asks to travel. Names an id and a spawn, nothing else | Interactable, Director | loading, fading, or moving the player | DONE |
| HD-2D camera rig | Long-lens diorama framing, tilt-shift depth of field, every framing value an `@export` set PER AREA in the area scene | Events, Director | input; what it follows beyond a Node3D; any framing number of its own | DONE — the exports were always there; T3.2 gave the interior its own 36-degree / 9.5 m framing so the seam is USED, and a test fails if no area authors one |
| Character visual | Billboarded, lit, correctly-sorted sprite, facing quantised from the sheet layout | Events, SpriteSheetLayout | input, movement, game rules, or any sheet dimension of its own | DONE — T2.1 moved every dimension out to a resource |
| Sprite sheet layout | The art CONTRACT: facings, frames, cell size, animation blocks and idle/walk rows, as authored data. The sector width is derived from the facing count, so the two cannot disagree | nothing — it is a data shape | a texture, a node, or what animation is playing | DONE — T2.1, and a sheet with a different cell and frame count was swapped in with no code change, demonstrated by capture |
| Player controller | Movement, gait, movement state, authored climb, token input lock | Actions, Settings, Events, Layers | dialogue, inventory, interaction rules, the camera | DONE |
| World clock | Day, hour, minute, time-of-day phase | Log, Events, Save | what time *means* to anything | DONE |
| Weather state | Current kind, blend, intensity, scheduling | Log, Events, Save | particles, lights, sounds | DONE |
| Environment driver | Turns clock and weather into real lighting and post. The twenty post-stack values are `@export`s per area since T3.2; what stays in code is the STRUCTURE (tonemapper, fog mode, ambient source) the rest of the file assumes | Clock, Weather | what time it is or what weather it is; it only renders consequences. Since T3.2 also: any post-stack NUMBER, and a test fails if one grows back | DONE |
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
| Shared area materials | `assets/materials/*.tres` that more than one area points at with an `ExtResource`, so one edit changes both | nothing — scene-authoring convention, no registry, no id, no scan | which area uses it, and what a tiling rate should be — a rate belongs to the surface, not the substance, so only genuinely identical materials are shared | DONE — T3.2. One shared material used by two areas, tinted in one file and photographed changing in both. A test fails if two areas declare the same material inline |
| Texture import defaults | `[importer_defaults]` in `project.godot`, so a PNG a game drops in imports correctly first time | nothing | anything but texture import; exactly one value is set, `detect_3d/compress_to = 0` | DONE — T3.2, and settled by MEASUREMENT because the section is absent from `--doctool` (gotcha 39). Closes the hazard that a re-import puts VRAM block artefacts through pixel art |

## 2. Interaction, items, objects — the current milestone

| System | Purpose | Depends on | Boundary — must NOT know | Status |
|---|---|---|---|---|
| Interaction sensor | Finds and ranks candidate targets, fires the chosen one | Actions, Events, Layers | what any interactable does | DONE |
| Interactable contract | The base class every interactable satisfies | Events | who is interacting, beyond a Node3D | DONE |
| Interaction prompt UI | Shows verb and label for the current target, localized | Events | how to perform an interaction | DONE |
| Item definitions | Typed Resource, id equals filename, ADR-0006 | — | inventory or world state | DONE |
| Content scan | `ContentScan.into()` — the ONE scan-and-validate behind all five catalogues: find the .tres under a root, load each, check its id against its file name, refuse a wrong type and a duplicate, and report what is wrong PER FILE. Fills the CALLER'S typed dictionary, so no accessor is a cast | ContentEntry | caching anything, remembering a directory, or knowing a content type by name | DONE — T3.1 |
| Content entry | `ContentEntry` — the base every catalogued .tres extends: an `id` and a `problems()`. What the shared scan needs, and the reason it compiles under `unsafe_property_access=error` | — | knowing where it was found, or holding a field only one content type needs | DONE — T3.1 |
| Item registry | id to definition by directory scan; static, not an autoload. A typed façade over `ContentScan` since T3.1 | ContentScan | who carries anything | DONE |
| Item instances | Per-item mutable state: durability, contents | Item definitions | UI | LATER — deferred until something has durability; id plus count suffices |
| Inventory | Held items, stacking, a capacity seam. A component, not an autoload. PUBLISHES each count as the derived flag `bag/<carrier_id>/<item id>`, which is what makes "bring me three of these" an authorable quest step with no dependency from `systems` on `gameplay` | Events, Save, Flags, BagKeys | how items are displayed, and what counts a step; it never reads the flags it publishes | DONE — the count projection is T3.3 |
| Inventory UI | A UiScreen: rows grouped by category, localized names and counts, focus navigation, and Enter on a row equips or stows it through `Equipment.toggle` | Events, Inventory, Equipment, ItemDb | inventory rules, what may be held, pausing, locking the player | PART — no tooltips, sorting or drag-and-drop |
| Pickups | World items that enter the inventory | Interactable, Inventory | — | DONE |
| Containers | Take-all chests. Named ItemContainer: Container is a native class | Interactable, Items | — | DONE |
| Authored refusal lines | An `Interactable` may name a localization key per refusal reason, carried on `interaction_refused` and preferred by the prompt over the `refusal.<reason>` line computed from the enum | Events, the prompt | deciding WHY something is refused | DONE — WP-09; `Gate.locked_key` and `PathAction.refusal_key` had been declared and unread since WP-01 and WP-07 |
| Doors and gates | Locked, unlocked, flag-gated, with refusal reasons | Interactable, Flags | — | DONE |
| Readables | Signs, books, notes | Interactable, Localization | — | DONE |
| Switches and levers | Toggle world state | Interactable, Flags | what the state causes | DONE |
| Trigger volumes | Fire on entry, once or every time, persisted by object_id | Layers, Flags, Events | what its firing causes | DONE |
| Harvestables | Gather with a regrowth timer | Interactable, Clock, Inventory | — | TODO |
| Sittables and beds | Rest, and skip time through `Clock.skip_to_hour` | Interactable, Clock | why the hour it jumps to matters | DONE |
| Climbables | Ladders and authored climb points, two markers per object | Player controller | how to move a body — it asks the mover | DONE |
| Physics props | Push, drop, stack | Layers | — | TODO |
| Water volumes | Wading and swimming | Player controller, Layers | — | LATER |
| Equipment | What a carrier holds READY. A component beside Inventory that owns no dictionary: a slot is the flag `equip/<wearer>/<item>`, so a gate, a quest step or a dialogue condition gates on it with no code. One item per slot; the item stays in the bag | Inventory, Flags, Events, ItemDb | what any slot MEANS, what an item does, combat — there is none | DONE — WP-09 |
| Object persistence | Authored object_id, state via Flags. ADR-0005 | Flags, Save | object behaviour | DONE |

## 3. Characters and life

| System | Purpose | Depends on | Boundary | Status |
|---|---|---|---|---|
| Character attributes | What a character is LIKE: `attr/<who>/<name>` in Flags, integer steps clamped to ±4, no resource and no save section — the FIFTH namespace-over-Flags after PersistentState, Standing, Equipment and the world map | Flags | an attribute's NAME, what any attribute means, or what reads one. A name is a const on its CONSUMER, so an attribute nobody reads has nowhere to be written down | **DONE — WP-09b, 2026-08-29.** One consumer, deliberately: `PlayerController.current_speed()` scales every gait by `pace`, measured windowed at 2.861 m against 4.687 m over the same 60 frames |
| Footsteps and surfaces | `metadata/surface` on area geometry, inherited from the nearest tagged ancestor; a `Footsteps` component under a body takes a step per 1.7 m and generates its sound from the surface's NAME | Log, Layers, AmbienceBed | any surface name, or what a surface costs to cross. A table of names in src/ would be engine code naming demo content | **DONE — WP-09b, 2026-08-29.** Three surfaces reported correctly in a windowed run, two tagged directly and one inherited. No audio files: art is deferred, so the step is generated the way the rain is. Particles NOT built — `current_surface()` is the hook |
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
| Quests and objectives | A quest is authored data; each step names a FLAG CONDITION and `QuestTracker` derives progress from `Flags`. Started and completed are latched and saved by id; the current objective is re-derived | Flags, Events, SaveSystem, QuestDb, FlagQuery | what any objective MEANS, how it is drawn, or how to grant a reward — it emits `quest_completed` and stops | DONE — WP-08 |
| Quest content format | `Quest` / `QuestStep` as .tres in `data/quests`, found by directory scan like an item (ADR-0006). A step may test an ITEM COUNT, because `bag/<carrier>/<item id>` is a flag — no new field | — | reading a flag, tracking progress, or granting anything | PART — one condition per step, no branching, no failure state |
| Journal | A `UiScreen` listing active and settled quests with the current objective of each, bound to `J` through `ScreenKeys`. A counted objective draws its tally, asked of the tracker rather than of `Flags` | QuestTracker, QuestDb, the project Theme | starting, advancing or completing anything, or reading a flag; it draws what the tracker holds | PART — no detail pane, no sorting or filtering, no codex |
| Flag conditions | The one evaluator of `GameEnums.FlagTest`, shared by a dialogue condition and a quest step, and since T3.3 the one answer to "is this condition a COUNT, and how far along is it" | Flags | what any flag means, and writing one | DONE — WP-08, extended T3.3 |
| Plot gating | Chapter progression and content locks | Flags | — | PART — a quest's start condition and a dialogue node's condition are both flag tests, so chapter gating is authorable today; no chapter concept of its own |
| Map content format | `AreaDef` as .tres in `data/areas`, found by the fifth directory-scan registry (ADR-0006). Carries the map position, the arrival spawn and `known_from_start` | — | reading a flag, loading a scene, or deciding what is discovered | DONE — WP-11 |
| Map screen | A `UiScreen` drawing one dot per `AreaDef` at its authored normalised position, in three states, bound to `M` through `ScreenKeys`. Pressing a found place travels | WorldMap, AreaDb, Director, the project Theme | discovering, loading or placing anything | PART — no fog of war, no zoom or pan, no map art, and no objective markers |
| Objective markers | A quest objective drawn on the map | QuestTracker, WorldMap | — | TODO — `Events.quest_advanced` has an emitter now, so this is a listener and no new state |

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
| World map | `WorldMap` under `GameRoot`, found by group. Discovery is the flag `map/<area id>` and there is NO store, so it is already saved, already announced and writable by anything. `travel_to` emits `area_change_requested` and stops | Director, Flags, Events, AreaDb | loading an area, fading, placing the player, or keeping a copy of what is discovered | DONE — WP-11 |
| Controller navigation | Every screen fully usable on a gamepad | Actions | — | DONE — a VBoxContainer of Buttons answers ui_up/ui_down and ui_accept, so no screen owns a cursor; proved windowed with real events |
| Loading screen | Covers threaded area loads | Director | — | DONE — fade plus a progress readout drawn above it; the one node after ScreenFade |
| Project UI theme | `assets/theme/ui_theme.tres`, wired as `gui/theme/custom`: every font size, colour and inset the UI draws with. Type variations carry sizes; a `UiPalette` and a `UiMetrics` carry the colours and insets once each, NOT copied into the variations | nothing | a localization key, or a size only one screen could want | DONE — T2.1. One edit to that file restyled the menu, the inventory screen and the HUD at once, demonstrated by captures before and after; a test case fails if a screen writes a colour or a font size down again |

## 6. Content pipeline and production

| System | Purpose | Status |
|---|---|---|
| Placeholder art generation | Procedural stand-ins so code can be finished before art. Two character sheets since T2.1: the 8x4 default, and a 4-facing/3-frame/2-block sheet whose every cell carries a column tally and a frame tally so a capture of it can be READ rather than judged | DONE |
| Content validator | tools/check_content.gd — ids, duplicate object_ids, CSV keys, stray defs | DONE |
| Engine/demo boundary gate | tools/check_boundary.gd — FAILS if any file under src/, tests/framework/ or tests/unit/ names demo content, and fails if the exempt debug surface loses its release guard. Demo ids derived from scenes/areas/ and data/, never listed | DONE — T1.2 |
| Line-budget checker | Mechanical enforcement of file and function size limits | DONE |
| Test runner | Headless integration tests, scene-entered, exit 1 on failure. Four silent-pass modes now fail loudly: a case that crashes, one that returns early, one that asserts nothing, and a suite file that exists and is not in CASES | DONE — hardened T1.3 |
| Test fixtures | tests/framework/fixtures.gd + fixture_content.gd — the content a case needs, built in code. In memory where a system is HANDED content, written to a temp directory the registries scan where a system looks it up by id | DONE — T1.3 |
| Engine script-error watch | tests/framework/error_watch.gd — an OS.add_logger Logger counting ERROR_TYPE_SCRIPT, because a GDScript crash aborts only its own frame and the tally cannot see it | DONE — T1.3 |
| Redirectable content root | ItemDb/DialogueDb/ScheduleDb/QuestDb/AreaDb.content_dir — a static var on each façade, never a const, so a game or the fixtures may point the scan somewhere other than data/. Five variables and not one on a shared base, deliberately: a base-class `static var` is ONE storage shared by every subclass (gotcha 37) | DONE — T1.3, five-way since T3.1 |
| Continuous integration | .github/workflows/ladder.yml — seven of the eight rungs on every push, PR and manual dispatch, in two jobs: full checkout and a stripped template. Engine downloaded, SHA512 verified against a pinned literal, build string asserted. Rung 2 grepped for SCRIPT ERROR / Parse Error with zero tolerance, and since WP-14 rung 3 greps its WHOLE boot log rather than only the last line — it could not, while Director left its loader thread to be killed mid-load and the engine printed false Parse Errors on the way out. .godot/ deliberately NOT cached | DONE — T1.4; rung 8 added and rung 3 strengthened by WP-14 |
| Pinned engine setup | .github/actions/setup-godot — the version lives in one file so two jobs cannot drift onto different engines | DONE — T1.4 |
| Hard-coded string audit | tools/check_strings.gd — TWO rules, both anchored at a SINK or a DECLARATION rather than at a literal, because check_content.gd refused a literal-classifier in writing and was right: (1) the right-hand side of a `.text`/`.tooltip_text`/`.placeholder_text`/`.title` assignment passes through tr() or holds no literal at all; (2) every `*_KEY` const under src/ names a real CSV row — 71 of them, checked by nothing before this. Key PATTERNS it cannot follow are counted and printed, never skipped | **DONE — WP-14, 2026-09-01.** Rule 2 proved to close a live hole: one transposed character in a toast key passed check_content, check_boundary AND all 1,517 assertions |
| Localization | String IDs from the first string; CSV translation | PART — CSV wired, **218 keys**, all UI text localized. Unquoted commas are a gate, and since WP-14 `tools/check_strings.gd` is the full audit: a literal reaching `.text` without `tr()` fails the build, and every `*_KEY` const under `src/` must name a real row. No runtime language switch yet. docs/NEW_GAME.md names the engine and demo halves |
| New-game checklist | docs/NEW_GAME.md — what to delete, what to keep, the full rename surface | DONE — T1.2, and its claims were run against a stripped copy |
| Consumer documentation | docs/AUTHORING.md (task-first: an area, an object, an item, a conversation, an NPC), docs/ART_CONTRACT.md (the sheet grid, the theme split, and the Button stylebox gap), docs/TESTING.md (the five non-obvious rules of the suite), and ARCHITECTURE.md § The extension surface (what may be subclassed, what is internal) | **DONE — T2.2, 2026-08-27.** The criterion was PERFORMED: an area, an NPC and a conversation authored from the docs alone, run and captured, six doc defects found and fixed, then deleted |
| Documentation rot gate | tests/unit/docs_test.gd — every res:// path the docs name resolves, and every property named in a worked .tres example exists on the class that block declares. DEVLOG.md exempt: a history necessarily names files it correctly removed | DONE — T2.2 |
| Smoke test | tests/unit/smoke_test.gd — ONE composed session driven through public APIs and built entirely from fixtures: a run begins and empties the bag, a flag starts a quest, items publish their counts, a counted objective notices, an item is picked up and put in hand, time skips, and the whole session is saved, wiped and restored. Asserts the log tally moved by ZERO across all of it | **DONE — WP-14, 2026-09-01.** The row said "the whole demo" and was RE-FRAMED: it drives *a* game and names no content, and its one game-shaped block asserts only that the configured first area RESOLVES, skipping counted in a stripped checkout. It cannot load an area — TestCase.run() is synchronous — so it is the CHAIN, not a playthrough |
| Export presets and the export proof | Windows preset committed in `export_presets.cfg`; `export_filter="all_resources"` measured as the one setting that ships directory-scanned content, and asserted by `tests/unit/export_test.gd`; `src/systems/debug/catalogue_report.gd` reports every catalogue's count and resolved paths at boot of a debug build, and WARNS on an empty one in an export | **DONE — T2.0, 2026-08-26.** The exported `.exe`, run outside the editor, reports 3 items, 1 conversation, 1 schedule — identical to the editor. A second export-only defect was found on the way: a missing `[editable]` marker silently dropped instance overrides, now a `check_content` gate |
| Performance overlay | Frame time, fps, process time, draw calls, node count and ORPHAN node count, over live gameplay. `src/ui/hud/perf_overlay.gd`, on F3 | **DONE — WP-14b, 2026-09-02.** A `CanvasLayer` at layer 101 beside the HUD and deliberately NOT a `UiScreen`: a screen stops the world and these numbers are worthless unless the thing being measured is still happening. Every monitor name checked against `--doctool`. Measured windowed across a load spike: 41.67 ms/frame at 24 fps, then 16.67 at 60 |
| Debug console | `goto`, `flag`, `time`, `give` typed at a prompt, with the last twelve answers above it. `src/ui/screens/debug_console_screen.gd`, on F1 | **DONE — WP-14b, 2026-09-02.** A `UiScreen` declaring `pauses_world`, so `UiRoot`'s pause table owns it and there is no second pause mechanism. It lives under `src/ui/` and is therefore INSIDE the boundary gate, which is the point: it names no content, because a command takes its argument from whoever typed it |
| Dev commands | `src/systems/debug/dev_commands.gd` — the four verbs' single implementation, returning a report rather than logging one | **DONE — WP-14b, 2026-09-02.** `--goto=`, `--flag=`, `--time=` and `--give=` and the console's four commands are now ONE body each: what you type in the console is exactly what you pass on the command line. `dev_stage.gd` had been sitting at exactly 250/250 code lines, and this is what made room for a sixth staging flag |

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
