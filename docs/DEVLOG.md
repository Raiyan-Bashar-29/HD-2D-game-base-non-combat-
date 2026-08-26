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

## 2026-08-26 — WP-13: weather you can see, and the leak the Dummy audio driver leaves behind

**Did:**

`Weather` had published a kind, a blend and an intensity since Phase 0, and the only thing
that had ever read them was one fog-density multiplier. It is now visible.

- `src/systems/weather/wetness_model.gd` — `WetnessModel`. A pure `RefCounted`: one 0..1 that
  rises over eight seconds of rain and falls back over twenty-six. No node, no material, no
  autoload.
- `src/gameplay/world/precipitation.gd` — `Precipitation`. One `GPUParticles3D` per kind that
  builds its own mesh, process material, draw material and — for snow — its own soft flake
  texture from a radial `GradientTexture2D`. Nothing authored, nothing loaded.
- `src/gameplay/world/weather_visuals.gd` — `WeatherVisuals`. The listener that was missing.
  One node per area; it owns the `MIX` table that says what each kind looks like, follows the
  player, cross-fades across a blend, steps the wetness and sets the ambience levels.
- `src/gameplay/world/surface_wetness.gd` — `SurfaceWetness`. Darkens and clearcoats an
  area's materials as they soak, on private duplicates.
- `src/systems/audio/ambience_bed.gd` — `AmbienceBed`, reachable as `Audio.beds`. Named
  layers, each at its own level, on procedurally generated filtered noise.
- `dev_capture.gd` gains `--wet=<0..1>` and `--dry-for=<seconds>`.
- Nine localization keys: `weather.*` per kind, plus `notify.weather.turns`.
- `tests/unit/presentation_test.gd` — 47 new assertions. 460 -> 507.

**Why:**

*Why the wetness model is a separate pure object.* Everything else about the weather can be
computed from Weather's state in one frame. Drying cannot — "it stopped raining forty seconds
ago" is memory, and memory is the part that drifts. Gotcha 10 says `TestCase.run()` is
synchronous, so a node that only dries in `_process` could never be asserted on; a
`RefCounted` can be stepped a thousand simulated seconds inside one test.

*Why nothing is authored.* Art is deferred indefinitely. A rain texture would be a dependency
this project has refused to take on, so the mesh is a quad and the flake is a gradient. It
also means the three emitters cannot drift apart in an inspector.

*Why `Precipitation` is told a weight instead of reading Weather.* An emitter that polled the
weather would be a second place the rules live, and the two would disagree the first time a
cross-fade was half done. Same split as Weather and EnvironmentDriver, one level down.

*Why `SurfaceWetness` duplicates its materials.* The terrain materials are sub-resources of
the area scene, and a sub-resource is shared across every instantiation of it. Writing
roughness onto one would leave the courtyard wet after an unload and reload on a clear day —
and would follow the player into any other area using the same material.

*Why a clearcoat and not just darkening.* The first captures came back reading as "in shadow"
rather than "wet". A low roughness only shows where the sun's mirror angle points, and on a
flat courtyard under a fixed camera it mostly does not. A clearcoat is literally a thin smooth
film over the surface; it reflects the sky, which is visible from any angle.

**Connects:**

`WeatherVisuals` reads `Weather.current/target/blend/intensity/is_wet/sheltered` and writes to
`Precipitation`, `SurfaceWetness` and `Audio.beds`. Nothing flows the other way — `Weather`
still MUST NOT render, and gained no line. The toast goes out on `Events.notify_requested`
like every other announcement, so `Weather` still does not know a screen exists. `AreaRoot`
already set `Weather.sheltered` for interiors and that now genuinely stops the rain.

**Verified:**

- `--headless --import` — exit 0, clean. Run twice; the first pass is where the five new
  `class_name` globals get registered, and every parse error before it was gotcha 1.
- `--headless --quit-after 120` — `Session ended after 1.0s — 0 warnings, 0 errors`, exit 0.
- `--headless res://tests/test_runner.tscn --quit-after 150` — **507 passed, 0 failed**,
  exit 0, no leaked instances.
- A deliberately broken assertion in `presentation_test.gd` → `506 passed, 1 failed`, exit 1,
  naming the assertion and its line. Reverted.
- `--headless --script tools/check_budgets.gd` — 73 files, 5,625 code lines, 0 warnings,
  0 violations, exit 0.
- `--headless --script tools/check_content.gd` — 92 localization keys, PASS, exit 0.
- **Seven windowed captures, every one opened and looked at**, all at
  `--resolution 960x540 --time=13:00 --freeze-time --shot-frame=40`:
  - `CLEAR` — bright green grass, warm orange dais, cream walls, no particles.
  - `RAIN --wet=1.0` — fine pale streaks across the whole frame, everything greyer, ground
    visibly darkened.
  - `STORM --wet=1.0` — markedly denser rain than `RAIN`, pale wind motes blowing through it,
    darker again. Unmistakably a third image and not a brighter second one.
  - `SNOW` — soft round flakes at varied sizes and depths, ground still dry, which is right:
    `is_wet()` is RAIN and STORM only.
  - The dry-out, three frames, all `CLEAR` so the ONLY variable is the wetness:
    `--wet=1.0` / `--wet=1.0 --dry-for=13` / `--wet=1.0 --dry-for=40`, logged as wetness
    `1.000` / `0.500` / `0.000`. Dark olive grass and dull walls -> a midpoint -> bright green
    grass and cream walls indistinguishable from the plain `CLEAR` capture. Indistinguishable
    by eye, not byte-identical: the two PNGs hash differently, as two renders of one frame
    do. That drying restores the *exact* authored albedo and roughness is proved by an
    assertion instead, which is the right tool for an exactness claim.
  - `STORM --goto=lantern_hall` — not one drop indoors, interior lighting untouched.

**One real bug and one engine trap, both found by running it:**

1. **`SurfaceWetness` was driven before it had collected anything.** `WeatherVisuals` sits
   under `Environment` and the wetness node under `Terrain`, so the driver's `_ready` ran
   first and called `apply()` at an empty list. Because `apply()` skips a value that has not
   moved, arriving in an area mid-downpour would have shown a dry courtyard until the wetness
   happened to change — and it does not change once it has reached its target. Now `apply()`
   records what was wanted and `_ready` paints it after collecting. Found by reading the boot
   log's line ordering, not by a failing assertion.
2. **Every `play()` against the Dummy audio driver leaks.** The test suite started reporting
   `6 ObjectDB instances were leaked at exit`: one `AudioStreamPlaybackWAV` per `play()` call
   — four — plus the two generated streams they held. The AudioServer releases a stopped
   playback on the NEXT MIX, and `--headless` quits before there is one. Stopping the players
   and nulling their streams in `_exit_tree` does nothing, because the server owns the
   playbacks, not the players. `AmbienceBed.is_audible()` now checks
   `AudioServer.get_driver_name()` — measured as `Dummy` headless and `WASAPI` windowed, not
   assumed — and skips playback it could not be heard through anyway. The levels are the real
   state and are what the assertions read.

**Unblocks:**

Footstep surfaces, which need to know the ground is wet and now can, from the same
`Weather.is_wet()` the visuals key off. Any area that wants weather needs one node and no
code. A fourth and fiftieth weather kind need a row in `MIX` and a CSV line, and the suite
fails if either is missing.

**Known gaps:**

`dev_capture.gd` is at 238 of its 250 code lines and is the next file to need splitting —
WP-14 owns it. The ambience is two layers of filtered noise, not sound design; there is still
no real audio in the project. Rain does not collide, so it falls through the terrace roof and
the arch — `ParticleProcessMaterial.collision_mode` is the seam and it was left off because it
costs a depth pass for a placeholder scene. Nothing splashes where a drop lands. Wetness is
per area and not saved, so walking out of a downpour into the hall and back resets the soak;
that is a `SaveSystem.register` away if it ever matters. This package added 562 code lines
against the board's ~500 guideline — 435 of them production, 127 assertions.

## 2026-08-26 — WP-05: dialogue, and a comma that had been eating text since WP-01

**Did:**

The largest unproven system. A conversation format, a runner, and the first screen in this game
that does not stop the world.

- `src/content/dialogue/` — `DialogueChoice`, `DialogueNode`, `Conversation`, `DialogueDb`.
  Data only; none of them touches an autoload, so `tools/check_content.gd` can still load them
  under `--script`.
- `src/systems/dialogue/dialogue_runner.gd` — `DialogueRunner`. Picks the next node, tests
  conditions, applies effects, announces lines. A component, not an autoload.
- `src/ui/screens/dialogue_screen.gd` — `DialogueScreen`. `pauses_world = false`,
  `closes_on_cancel = false`, typewriter reveal, focusable choices.
- `src/gameplay/interactables/speaker.gd` — `Speaker`. Names a conversation id and emits.
- `Events.dialogue_requested`, `GameEnums.FlagTest`, `GameEnums.FlagWrite`.
- `data/dialogue/gardener.tres` — five nodes, four choices, one branch on a flag.
- `tests/unit/dialogue_test.gd` — 46 new assertions. 414 -> 460.
- `tools/check_content.gd` now validates conversations, and catches unquoted CSV commas.

**Why:**

**A closed set of comparisons, not an expression language.** `FlagTest` has six values and
`FlagWrite` has five. The moment a conversation can contain an expression it needs a parser,
error reporting and a sandbox, and the authored `.tres` stops being reviewable in a diff. When
six comparisons are genuinely not enough, the honest move is a seventh, not a grammar.

**Nodes are an ordered array and the runner falls through.** The entry point is the first node
whose condition passes, not `nodes[0]`, and a skipped node falls through to the next in authored
order. That makes the commonest shape in the game — "if we have met, greet me differently" — two
nodes in sequence with no wiring at all. Lookup by id still exists for `next_node` and
`target_node`, but order is what a writer edits and an array is what diffs cleanly.

**Effects fire on arrival, not departure**, so a node has the same consequence however it was
reached. That is why a choice carries a condition but no effect.

**A failing choice is omitted, not shown disabled** — the opposite of how a locked gate behaves,
deliberately. A gate you cannot open teaches you there is something to come back for; a reply
you cannot give teaches you only that the writer thought of it. `choose(index)` therefore
indexes what is on screen, not the authored array, and there is an assertion for exactly that
because indexing the wrong one silently takes the wrong branch.

**`Speaker` goes through the bus.** It is in the gameplay layer and a dialogue box is in the ui
layer, and dependencies here point downward only. The first draft of this file reached for
`UiRoot` and `DialogueScreen` directly; that is a layer violation, so it now emits
`Events.dialogue_requested` and stops, exactly as `AreaDoor` emits `area_change_requested`
rather than loading an area itself. `ScreenKeys` listens, because it is already the one place a
thing becomes a screen.

**A conversation is not saved, and that is a decision.** Persisting a position means writing a
node id into the save file, which makes every node id in every `.tres` a permanent public
identifier: rename one and old saves load into a position that no longer exists. So the save
section exists, is always empty, and logs a warning naming the conversation it discarded. A save
taken mid-conversation reloads with the conversation over and control returned — recoverable and
obvious, where the alternative fails silently, later, in someone else's save file. That is the
"or explicitly refuses to be saved mid-conversation" half of the exit criterion, chosen on
purpose over the other half.

**A defect from WP-01, found by a capture:**

`object.lever.gate.on` read `The lever gives with a heavy clack. Somewhere north, iron shifts.`
with no quotes, so the CSV parser cut it at the comma and the lever's toast had said
`Somewhere north` for three packages. Nothing caught it: the key still resolved, `tr()` still
returned a string, and the line quietly lost its second half. `talk.gardener.menu` had the same
fault, which is how it surfaced — the first dialogue capture showed `Well? Ask` where the line
reads `Well? Ask, or do not.` Both rows are quoted now, and `check_content.gd` fails any row
that parses to more than two columns. Proved by adding a bad row and watching the gate bite.

**Connections:**

`Speaker` -> `Events.dialogue_requested` -> `ScreenKeys` -> `UiRoot.open(DialogueScreen)` ->
`DialogueRunner.begin()`. The runner emits `Events.dialogue_started`, which
`PlayerController` and `InteractionSensor` have listened for since Phase 0 — each takes its own
`&"dialogue"` token, so nothing in this package locks anybody. `DialogueDb` reuses
`ItemDb.resource_paths()` rather than copying it, so the export-time `.remap` handling has one
implementation. Conditions read `Flags`; effects write `Flags`; nothing else in the package
touches either. `gameplay/text_speed` gets its first consumer since it was declared.

**Verified:**

```
--headless --import                                   clean
--headless --quit-after 120                           0 warnings, 0 errors
--headless res://tests/test_runner.tscn                460 passed, 0 failed, exit 0
  with one assertion deliberately broken               459 passed, 1 failed, exit 1
--headless --script tools/check_budgets.gd            67 files, 5063 lines, 0 violations
--headless --script tools/check_content.gd            PASS, incl. 1 conversation, 83 keys
```

**Captured and looked at**, three times. The first showed the truncated line and the third of
three choices clipped off the bottom edge — the box is bottom-anchored, so anything that does
not fit is simply gone, and it was sized from the common case instead of the worst one. Height
went 260 -> 380 and the CSV rows were quoted. The third capture shows the full line, all three
choices, the first focused, and the courtyard still lit and running above the box.

**The real input path**, proved with a temporary probe per gotcha 15 and then removed:

```
TEMP target=Gardener locked=false
TEMP after INTERACT: depth=1 node=greet_first locked=true suspended=true
TEMP world paused=false clock ticking=true
TEMP after advance: node=menu choices=3
TEMP focus=Who are you?
TEMP after choosing: node=who met=true
TEMP after end: depth=0 locked=false suspended=false
```

`world paused=false, clock ticking=true` is the line that matters: this is the first screen to
exercise the OVERLAY path `UiRoot` has had since WP-02, and it is the first proof that the
distinction between OVERLAY and MODAL was worth building two packages early.

One probe artifact worth recording: a synthetic `ui_accept` press alone never fires a `Button`,
because `BaseButton` acts on RELEASE by default. The probe has to send both. That is a fact
about probes, not a defect.

**Unblocks:**

WP-06's NPCs, which need something to say before they are worth animating, and WP-08's quests,
which need a conversation that can set a flag. `Speaker` is already the shape an NPC's talk
component will take. The overlay path is now walked by something real, so WP-12's menus can
assume it works.

**Known gaps:**

One condition and one effect per node. The seam is `_apply_effect` in the runner plus one field
becoming an array, and no authored `.tres` is invalidated by that change — but it is a real
limit and a conversation that wants "set two flags" cannot say so today. No portraits: the
format has a `speaker_key` and no portrait field, because art is deferred and a field nothing
reads is a guess. No barks, no auto-advance, no history log, no skip-all. The reveal speed is
one setting and one constant; a per-line pause or emphasis would need markup the format does not
have. And a conversation still cannot be entered from anything but a `Speaker` — a trigger
volume that starts a conversation would work today by emitting the same signal, but nothing
does it yet.

## 2026-08-26 — WP-04: a second area, and three bugs only a second area could find

**Did:**

`Director` has swapped two areas. It was written, guarded and logged in Phase 0 and had never
actually done the thing it exists for.

- `scenes/areas/lantern_hall/lantern_hall.tscn` — an interior. `sheltered = true`,
  `follow_clock = false`, its own lanterns, open toward the camera.
- `src/gameplay/interactables/area_door.gd` — `AreaDoor`, the one object that asks to travel.
  It emits `Events.area_change_requested` and does nothing else.
- `src/ui/hud/loading_indicator.gd` — the only thing in the game drawn ABOVE `ScreenFade`.
- `Events.area_load_progress(area_id, ratio)`, emitted from the load loop that was already
  collecting the number and throwing it away.
- `Director.WARM_UP_FRAMES` — the curtain is held three frames after the area enters the tree,
  so shader compilation happens behind black.
- `EnvironmentDriver` gained an Interior group.
- `dev_capture.gd` gained `--round-trips=<n>`, `--cross-area-save` and `--goto=<area>`.
- `tests/unit/transitions_test.gd` — 44 new assertions. 370 -> 414.

**Why:**

**A door names an id and nothing else.** It does not load, fade, or place the player. Every
transition goes through one guarded path, and a door that ran its own would be the start of a
second, unguarded one — which is how two doors firing at once leaves two areas in the tree.

**The loading indicator is the one exception to gotcha 12.** `ScreenFade` must be the last child
of `UILayer` so the curtain covers every screen. The indicator has to be legible *while* the
curtain is up, so it is the single node placed after it. Child order is draw order, and that
ordering is the whole mechanism.

**Twenty round trips is a RUN, not an assertion.** `TestCase.run()` is synchronous and a threaded
load needs frames. So the criterion is measured by `--round-trips=20`, which also fires a second
travel request in the same frame each way, so the re-entrancy guard is exercised forty times.

**Three real defects, none of which any earlier package could have exposed:**

1. **`DictRead.get_name()` never worked.** `Resource` declares `resource_name` with the getter
   `get_name`, and a GDScript *is* a Resource, so the static call dispatched to the native
   zero-argument method and threw at runtime — while compiling perfectly. The one caller was
   `Director._apply_save`, which meant **loading a save had never restored the area**. It looked
   fine for three packages because with one area you always reloaded into the area you were
   already in. Renamed `get_string_name`. Same family as `Area3D.priority` and
   `class_name Container`, and the third time this project has been bitten by it.

2. **A freed object compares EQUAL to `null` in Godot 4.** `InteractionSensor` pruned its
   candidate list but never validated `_current`, so after an area unloaded it held a dangling
   reference — and `best != _current` reported "unchanged", so nothing was re-announced and the
   prompt kept offering an Iron Lever in an area that no longer existed. The obvious guard,
   `if _current != null`, does not fire for a dangling reference. `_announced_id: int` now
   carries the identity, because an int survives the object it names. A freed instance also
   cannot be *passed* to a parameter typed `Interactable` — the argument type check itself
   fails — so the liveness check takes no argument and reads the field in place.

3. **`follow_clock = false` did not mean "do not use the clock".** It only stopped the driver
   *updating*; `_ready()` still called `_apply_now()` once, so the first interior ever built
   inherited whatever hour it was entered at and had its sun hidden below the horizon. Entered
   at 02:30 it was pitch black; entered at noon it was fine. From the same scene file. An
   interior now has its own authored ambient, fog and background, applied once, and the outdoor
   path never touches its sun.

**Connections:**

`AreaDoor` -> `Events.area_change_requested` -> `Director` -> `area_unloading` /
`area_load_progress` / `area_entered` -> `LoadingIndicator` and `ScreenFade`. `AreaRoot` still
configures weather and audio on entry; `EnvironmentDriver` reads `Clock` outdoors and nothing
indoors. `TriggerVolume`, built in WP-01 for exactly this, is still available as a walk-through
entry and is deliberately not used yet — the hall is entered deliberately, through a door.

**Verified:**

```
--headless --import                                   clean
--headless --quit-after 120                           0 warnings, 0 errors
--headless res://tests/test_runner.tscn                414 passed, 0 failed, exit 0
  with one assertion deliberately broken               413 passed, 1 failed, exit 1
--headless --script tools/check_budgets.gd            59 files, 4441 lines, 0 violations
--headless --script tools/check_content.gd            PASS
```

**Twenty round trips**, `--round-trips=20`:

```
--round-trips 20 from 'courtyard': 120 nodes, 31417 KiB
  trip 1/20: 120 nodes, 31331 KiB    ...    trip 20/20: 120 nodes, 31332 KiB
--round-trips done: nodes 120 -> 120 (+0), memory 31417 -> 31404 KiB (-12)
```

Node count is exactly flat across all twenty. Memory moves by 12 KiB, downward, which is noise.
The forty warnings are the forty second-requests the guard refused, two per trip — the
"two transitions in one frame are refused" criterion, exercised rather than asserted.

**World state on both sides**, `--cross-area-save`:

```
hall coffer emptied: true
saved in 'lantern_hall': OK
wiped: carrying 0, coffer emptied=false        <- deliberately destroyed before reloading
loaded: OK
after reload: area='lantern_hall', carrying 3
coffer still empty: true
```

Saved in the hall and reloaded from the courtyard, deliberately: a save taken where the reload
already is cannot tell "the area was restored" from "the area never changed", which is exactly
how the broken `get_name` hid for three packages. The wipe matters for the same reason — without
it, a value nobody cleared passes for a value that was restored.

**Both areas captured and looked at.** The hall took four attempts, and each one was a real
defect rather than a tweak: pitch black (bug 3), then a full frame of wall because the camera
sits fourteen units back and the room was closed on the camera side, then the door slab
occluding the room from the foreground, then correct. The stale "Use Iron Lever" prompt was
visible in every one of those captures and is what led to bug 2.

**Unblocks:**

WP-05's dialogue and WP-06's NPCs now have somewhere other than the courtyard to be, and WP-11's
fast travel has a real destination to travel to. More importantly the transition path is no
longer theoretical: anything that needs to happen across an area boundary can now be tested
against something that actually crosses one.

**Known gaps:**

`Director` still does not cancel its threaded load on shutdown, which is gotcha 13 and remains
WP-14's. `UiRoot` does not close its screens on `area_unloading`; it cannot currently matter,
because travel requires gameplay input and a modal screen suspends it, but a load triggered from
a save menu in WP-12 will need it. The loading indicator shows a percentage only once the loader
reports one, which for a small area is never — both areas here load in under a frame, so the
"Loading" word is what is actually seen. Interior lighting is four exported values applied once;
a room that wants light that changes has no mechanism yet, and should get one when something
actually needs it.

## 2026-08-26 — WP-03: the HUD clock and the inventory screen

**Did:**

The screen stack got its first real occupants. A HUD clock readout, an inventory screen that
renders what the player is actually carrying, the one node that binds `I` to it, twenty-two
new localization rows, and a new test case file. `StubScreen` is gone.

- `src/ui/hud/hud_clock.gd` — a `Label` on `Events.minute_passed` showing day, time and the
  localized phase name. Pausable on purpose: behind an open menu no in-game minute passes, so
  a clock that kept ticking would be lying.
- `src/ui/screens/inventory_screen.gd` — a `UiScreen`. Reads `Inventory.ids()`, emits a
  heading wherever the category changes, and a focusable row per item. Rebuilds on
  `Events.inventory_changed`, connected only while it is open.
- `src/ui/root/screen_keys.gd` — `ScreenKeys`. The whole action-to-screen table, which today
  has one row. `PROCESS_MODE_ALWAYS`, so the key that opened a screen also closes it.
- `tests/unit/screens_test.gd` — 61 new assertions. 294 -> 355.
- `dev_capture.gd` traded `--open-screen` for `--give=<list>` and `--open-inventory`, so a
  capture shows real rows produced by the real `Inventory.add()`.

**Why:**

**The HUD is a layer, not a class.** The obvious move was a `Hud` node owning the clock, the
prompt and the toasts. It was rejected: those three already exist as independent siblings under
`UILayer`, each subscribing to the one signal it draws, and a parent whose only job is to
forward signals to them adds a hop and a place for the fourth readout to accumulate. The HUD is
the set of nodes on that layer.

**The carrier is injected, not looked up.** `InventoryScreen.for_carrier(who)` mirrors the
interaction contract's `attempt(who)`. The same screen shows an NPC's satchel or a stash
without knowing that `Director` or a player exists, and a test hands it a bare `Node` with an
`Inventory` child.

**The screen holds no rules, and no pause.** It declares `pauses_world` and renders. It never
touches `get_tree().paused`, never locks the player, and never asks whether another screen is
open. Nothing in WP-02 had to be widened to make that work, which is the result WP-02 was
scheduled to produce.

**A screen declares its flags in `_init`, not `_build`.** Found while repointing `ui_test.gd`:
`_build` runs from `_ready`, i.e. *after* a caller has set a flag, so `StubScreen` setting
`pauses_world = true` there silently discarded the overlay test's `pauses_world = false`. The
overlay case had been passing vacuously since WP-02 — it asserted "the world stays paused" of a
screen that was, unknown to it, still a modal. `InventoryScreen` sets identity in `_init`, the
test now asserts the override survives `_ready`, and it fails if that regresses.

**Rows are `Button`s, and that is the whole of the focus work.** A `VBoxContainer` of focusable
children already answers `ui_up` and `ui_down`, which are bound to arrows, the d-pad and the
left stick. Pressing a row does nothing yet; tooltips and use are later packages.

**Connections:**

`Clock` -> `minute_passed` -> the HUD. `Inventory` -> `inventory_changed` -> the screen.
`Actions.INVENTORY` -> `ScreenKeys` -> `UiRoot.open()`. `UiRoot` -> `ui_mode_changed` -> the
player's and the sensor's own `&"ui"` tokens, unchanged from WP-02. `ItemDb` supplies
`name_key` and `category`; the screen never reads a `.tres`.

**Verified:**

```
--headless --import                                   clean
--headless --quit-after 120                           0 warnings, 0 errors
--headless res://tests/test_runner.tscn                355 passed, 0 failed, exit 0
  with one assertion deliberately broken               354 passed, 1 failed, exit 1
--headless --script tools/check_budgets.gd            56 files, 4152 lines, 0 violations
--headless --script tools/check_content.gd            PASS
--resolution 960x540 -- --shot=... --open-inventory   looked at, twice: 18:40 and 12:20
```

Two windowed captures were opened and examined, not merely produced. Both show the rows grouped
under "Key Items" and "Materials" with localized names and counts, the focus ring on the first
row, "Escape to close" at the foot, the clock top right, and the courtyard still drawn and
stopped behind the panel. The first capture was at `DIM` alpha 0.88 and the world behind it was
nearly invisible; lowered to 0.78 and re-shot at midday, where the dais and the character read
clearly through it.

Headless cannot see any of that, and it also cannot press a key: `TestCase.run()` is
synchronous, so no assertion can span the frames an input event needs. So the input path was
proved by a **temporary probe** added to `dev_capture.gd`, run windowed, and then removed. It
fed real `InputEventAction`s into the live tree and logged the result:

```
TEMP pressed inventory      -> Mode -> MODAL, Opened 'inventory' at depth 1
TEMP after I: depth=1, gameplay=false, player locked=true
TEMP focus after open: Rose Key  x1
TEMP focus after ui_down: Rose Petal  x7
TEMP focus after 2x ui_down: Chipped Stone  x2
TEMP focus after ui_up: Rose Petal  x7
TEMP pressed cancel         -> Mode -> GAMEPLAY, Closed 'inventory', depth now 0
TEMP after Escape: depth=0, gameplay=true, locked=false
TEMP toggle twice: depth=0
```

**Unblocks:**

Every remaining screen. The pause menu, the journal, the map and the settings screen are now
each a `UiScreen` subclass plus a row in `ScreenKeys`, with no new pause, no new boolean and no
new signal. WP-05's dialogue box is the first `pauses_world = false` occupant, and the overlay
assertion above is now a real guard for it rather than a vacuous one.

**Known gaps:**

A row does nothing when pressed — there is no use, no tooltip, no sorting and no drag-and-drop,
all deferred by the package. The screen rebuilds every row on any change, which is fine for a
few dozen entries and would not be for a few hundred. `refresh()` frees the old rows with
`queue_free()`, so within a single frame the freed children are still present; the test skips
`is_queued_for_deletion()` children and any future reader must too. The HUD clock is drawn
beneath the screens, so an open inventory dims it — legible, and arguably right, but it is a
choice rather than an accident. Still no hard-coded-string audit tool: the enum-built keys
(`verb.*`, `refusal.*`, `item.category.*`, `time.phase.*`) are each covered by a loop in the
suite, and everything else is caught only by review.

## 2026-08-26 — WP-02: the screen stack, pause semantics and a token input lock

**Did:**

- `src/core/util/input_lock.gd` — `InputLock`, a set of named holds. `lock(&"dialogue")`,
  `release(&"dialogue")`, `is_locked()`, `holders()`. Twenty-one code lines.
- `src/ui/root/ui_root.gd` — `UiRoot`, the screen stack. `open()` / `close_top()` /
  `close_all()`, `is_gameplay_input_allowed()` as the single truth, and the whole pause table
  written down in its header. Found by group, not by path: `UiRoot.find(node)`.
- `src/ui/screens/ui_screen.gd` — `UiScreen`, the contract every screen satisfies. A screen
  declares `pauses_world` and `closes_on_cancel` and then renders. It never touches
  `get_tree().paused`, never locks the player, never frees itself.
- `src/ui/screens/stub_screen.gd` — scaffolding, marked for deletion once two real screens
  exist. It exists so this package could be verified without WP-03.
- `GameEnums.UiMode { GAMEPLAY, OVERLAY, MODAL }` and `Events.ui_mode_changed(mode)`, emitted
  by UiRoot and by nothing else.
- **Deleted `PlayerController.set_input_locked(bool)`.** Its four callers now hold named
  tokens: `&"dialogue"`, `&"climb"`, `&"ui"`.
- `InteractionSensor` grew its own `InputLock` and now knows an open screen exists at all,
  which it previously did not. `InteractPrompt` hides itself while the mode is not GAMEPLAY.
- Four nodes opted out of pause in their own `_ready()`: `Audio`, `Director`,
  `NotificationToast`, `DevCapture`. `ScreenFade` already had.
- `scenes/boot/game_root.tscn` gained `UiRoot`, and `ScreenFade` moved to be the LAST child
  of `UILayer` — a curtain that does not cover the screens is not a curtain.
- `--open-screen` on `dev_capture.gd`, so the capture can photograph a paused world.
- `tests/unit/ui_test.gd`, 79 assertions. Suite is 215 -> 294.

**Why:**

Nothing in this project had a home for modal UI. The only hand-over mechanism was one boolean
behind `set_input_locked(bool)`, and WP-01 gave it a second caller, which is when a boolean
stops working: dialogue locks the player, a climb starts and finishes inside the conversation,
the climb's own `set_input_locked(false)` clears the dialogue's hold, and the player strolls
away mid-sentence. Nothing errors. Nothing logs. It reads as a physics bug.

A count would fail the other way — lock twice, release once, and the lock is stranded with
nothing to point at. Named tokens are idempotent, so a doubled `dialogue_started` is free, and
`holders()` can name whoever is still holding when something does go wrong.

The stack had to come before any screen, which is why this is WP-02 and the inventory screen
is WP-03. Build a screen first and you get one boolean per screen, forever, each owned by a
different file and each able to clear the others.

**On pause, deliberately:** this does set `get_tree().paused`, but which nodes that actually
stops was decided node by node, and the table lives in `ui_root.gd`'s header. Clock and
Weather stop, because in-game time must not pass behind a menu. Audio does not, because the
score cutting out is the one thing every player notices — and note it is the autoload itself
that needed the opt-out, since the cross-fade tweens are created on it. Director does not,
because a transition in flight would otherwise strand the game on black. Each of those is set
in the owning node's own `_ready()`, never from UiRoot: a central pause that reaches into ten
nodes is the god object all over again.

**Connects:**

UiRoot announces `ui_mode_changed`; `PlayerController`, `InteractionSensor` and
`InteractPrompt` listen. UiRoot does not know the player exists, and the player does not know
which screen opened — it takes one `&"ui"` token and gives it back. The player and the sensor
hold *separate* locks, because the sensor lives in `src/systems/` and the controller in
`src/gameplay/`, and reaching upward across that line is what the layer rule forbids.

**Verified:**

```
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --import                                        # clean
"$G" --headless --quit-after 30                                 # "0 warnings, 0 errors", x3, zero ERROR/WARNING lines
"$G" --headless res://tests/test_runner.tscn --quit-after 150   # 294 passed, 0 failed, exit 0
"$G" --headless --script tools/check_budgets.gd                 # 53 files, 3879 lines, 0 violations, exit 0
"$G" --headless --script tools/check_content.gd                 # PASS, exit 0
```

A deliberately inverted assertion (`get_tree().paused` expected `false`) gave
`293 passed, 1 failed` and **exit 1**, then was restored.

Windowed captures at 960x540, `--time=18:40 --freeze-time`:

- without a screen: the lit courtyard, the player, and `Use Iron Lever` on the prompt.
- `--open-screen`, frame 45: the stub screen centred and correctly sized over the world, the
  world still drawn behind it through the 0.82-alpha panel, **and the interaction prompt
  gone** — which is the prompt's new `ui_mode_changed` handler, visible in a photograph.
- `--open-screen`, frame 16: the fade curtain still partly up **over** the screen text. By
  frame 45 it has fully lifted. So the fade both draws above the screens and keeps tweening
  while the tree is paused, which is the pause table proving itself.

A throwaway probe scene (deleted afterwards) drove the live tree with a real injected
`InputEventAction`, because the suite is synchronous and cannot await a frame:

```
stack found: true              opened: true
depth 1, paused true, gameplay allowed false, player holders [&"ui"]
injected CANCEL
depth 0, paused false, gameplay allowed true, player holders []
```

The pause table is asserted, not merely documented: `ui_test.gd` opens a modal and reads
`can_process()` off `Clock`, `Weather`, `Audio`, `Director`, the stack, the screen and the
player. That confirmed empirically what would otherwise have been a guess about Godot's
default process mode for autoloads — they are pausable, so `Audio` genuinely needed the line.

**Unblocks:**

Every screen in the game. WP-03 (HUD and inventory screen) is now a `UiScreen` subclass with
content in it and nothing else — no new pause, no new boolean, no new signal.

**Known gaps:**

- Pre-existing, found while re-running the ladder and reproduced at baseline: `--quit-after
  30` does not reliably finish the threaded area load on a cold cache, and quitting mid-load
  prints spurious `courtyard.tscn` parse errors and leaked RIDs AFTER the run has already
  logged `0 warnings, 0 errors`. Documented as gotcha 13; the boot rung is now `--quit-after
  120` in `CLAUDE.md` and `CONTEXT.md`. The real fix is for `Director` to cancel its load on
  shutdown, which belongs in WP-14.
- No audio assets exist, so "music keeps playing" is verified as `Audio.can_process() == true`
  under pause, not by ear. That is the strongest claim available until there is an `.ogg`.
- Nothing gives a screen keyboard focus yet, so controller and keyboard navigation within a
  screen is unbuilt. It belongs with the first screen that has something to focus (WP-03).
- `Actions.PAUSE` and `Actions.CANCEL` share Escape and both merely close the top screen.
  Nothing *opens* a screen from gameplay input yet, deliberately — the pause menu is WP-12.
- `StubScreen` is scaffolding. Delete it when two real screens exist.

---

## 2026-08-26 — WP-01: triggers, resting and authored climbing

**Did:**

Three new interactables, the clock call they needed, and a climb state on the player body.

- `TriggerVolume` — an `Area3D` on `Layers.TRIGGER`, once-or-repeat, persisted by `object_id`.
  It sets a world flag and emits `Events.trigger_fired`, and that is all it does.
- `RestPoint` — the `SIT` verb, skipping to a target hour, with an optional `night_only` gate
  that refuses with `WRONG_TIME`.
- `Clock.skip_to_hour(hour)` — routed through `set_time`, returning the minutes skipped.
- `ClimbPoint` plus `can_climb` / `begin_climb` / `climb_step` on `PlayerController`.
- Prefabs in `scenes/objects/`, a stone terrace and all three objects placed in the courtyard,
  four CSV rows, `RefusalReason.NOT_GROUNDED`, and `--skip-to-hour=` on the dev capture.
- `tests/unit/traversal_test.gd`, 50 assertions. The suite is now 215.

**Why:**

The `Triggers/` node, `Layers.TRIGGER` and the inventory rows for sittables and climbables had
all existed since Phase 0 with nothing populating them. Three specific reasons shaped the code:

- **A trigger must not name its consequence.** `@export var door_to_open` is the same trap the
  lever avoids: the second time two things must react to one crossing, the coupling has to be
  undone. It sets a flag and announces itself; anything may watch either.
- **A time skip is one event, not a fast-forward.** Sleeping eight hours through
  `advance_minutes` emits 480 `minute_passed` signals, and any listener doing real work per
  minute does it 480 times in one frame. `skip_to_hour` is a single `set_time`.
- **`NOT_GROUNDED` is a new refusal reason, not a silent no.** A climb refused mid-air with no
  explanation is indistinguishable from a broken button, and this project's whole position on
  refusal is that the player should be told why.

**Connects:**

`ClimbPoint` asks the mover `can_climb()` and calls `begin_climb()` — it never writes a
position itself, so `PlayerController`'s boundary holds and interaction stays out of it.
`RestPoint` calls `Clock`, and everything downstream of the clock — the environment driver,
and later NPC schedules — reacts without knowing a bench exists. `TriggerVolume` reuses
`PersistentState` unchanged; it is not an `Interactable`, because nobody presses it.

**Verified:**

- `--headless --import` — clean.
- `--headless --quit-after 30` — **0 warnings, 0 errors**.
- `--headless res://tests/test_runner.tscn --quit-after 150` — **215 passed, 0 failed**,
  exit 0. A deliberately broken assertion gave 211/1 and exit 1.
- `--headless --script tools/check_budgets.gd` — 48 files, 3500 code lines, 0 violations,
  exit 0.
- `--headless --script tools/check_content.gd` — PASS, exit 0.
- Two windowed captures at 960x540 from the same `--time=06:30 --freeze-time` start, the
  second adding `--skip-to-hour=20`: warm dawn with south-cast shadows becomes cool night
  with both lantern pools lit. **The lighting genuinely changed**, which is the thing headless
  cannot tell you.
- A third capture with the spawn temporarily moved beside the terrace shows the ladder flush
  to the stone face and the prompt reading "Climb Trellis Ladder"; a fourth, from the top
  marker, shows the body standing on the terrace with the same prompt still offered, so the
  descent is reachable. Spawn restored afterwards.

**Two real bugs the engine caught, neither visible in the source:**

1. **The climb oscillated on its corner forever.** The path deliberately turns at the top —
   up-then-over ascending, over-then-down descending — because a straight line from the foot
   of a ladder to the ledge above passes *through* the ledge, and a climb that writes
   `global_position` has no collision left to stop it. But without a latch, the frame after
   arriving at the waypoint steps off towards the target, the next frame sees the body is no
   longer at the waypoint and steers back. 600 test steps, no convergence. Fixed with
   `_climb_turned`.
2. **The dais trigger toasted at spawn, from three metres away.** A spawning player exists at
   the area origin for one frame before `Director` places them on the spawn marker, so a
   trigger anywhere near that origin fires on load, every load. `TriggerVolume` now arms two
   physics frames late. Verified in both directions: no spawn toast now, and with the trigger
   temporarily moved onto the spawn point it still fires through `body_entered` under real
   physics, with the flag landing under its `object_id`.

**Unblocks:**

`Clock.skip_to_hour` is what NPC schedules (WP-06) need to be testable — a schedule you have
to wait twenty real minutes to observe is not one you will ever debug. Trigger volumes give
area transitions (WP-04) their entry mechanism, and give quests (WP-08) a way to fire a step
from a place rather than from an object.

**Known gaps:**

The unit test drives `fire()` directly and asserts the wiring (layer, mask, one `body_entered`
connection); the physical entry path is proven by the windowed run, not by the suite, because
`TestCase.run()` is synchronous and cannot wait on a physics frame. For the same reason the
*grounded* half of the climb refusal is asserted only in its negative direction — a body that
has never called `move_and_slide` is mid-air by definition, which is exactly the case worth
testing. The arm delay means anything still standing inside a volume when it arms is treated
as having entered; that is deliberate, and correct for a save reloaded inside a region.
`RestPoint` has no `PersistentState` because it has nothing to remember.


## 2026-08-25 — Work sliced into one-chat packages, and a roadmap to skeleton-complete

**Did:**

No gameplay code. Added `docs/WORK_PACKAGES.md`: fifteen packages from here to
skeleton-complete, in dependency order, each sized to one chat and each naming the exact files
that chat should read. Wired it into all four entry points — `CLAUDE.md`, `README.md`,
`docs/CONTEXT.md` and `docs/ROADMAP.md` — and put the per-chat open/close protocol in
`CLAUDE.md`, since that is the file a new session reads automatically.

**Why:**

A chat context window is the binding constraint on this project. This session hit usage limits
three times, and twice a delegated fan-out died mid-flight after burning several hundred
thousand tokens. Work has to be sliced so one chat finishes one coherent part.

The structure was already fine — `src/core` is 590 code lines, `src/systems` 725,
`src/gameplay` 867, `src/ui` 117 — and the downward-only layer rule means a package never has
to read upward. **The missing piece was not structure, it was a manifest.** A new session had
no way to know which subset to load, so it loaded too much. Every package now carries an
explicit file list, which is the load-bearing part of the whole document.

Also settled what "skeleton complete" means, because the phrase was doing a lot of unexamined
work: every system on the inventory has a working minimal implementation plus one piece of
placeholder content proving it. That is the standard items were held to — three throwaway
`.tres` files proved the pattern and the fiftieth item needs no code. After that point,
everything remaining is content.

**Connects:**

The board is the executable version of `ROADMAP.md`, and that file now says so, so the two
cannot silently drift. Dependency order is recorded with reasons rather than left implicit —
UI foundation before any screen, because a screen built first forces an ad-hoc pause and a
boolean per screen; dialogue before quests and path actions, because both are driven by it;
world map after a second area exists, because it is meaningless with one.

WP-15 carries a specific obligation: it must settle ADR-0006's open question. Items are found
by scanning a directory, verified in the editor and headless only, and the export preset must
export *all* resources or the catalogue ships empty.

**Decisions taken with the owner:** all four optional systems are IN the skeleton — path
actions, traversal equipment, world map and fast travel, crafting and gathering. Nothing on
the inventory is cut. Narrative systems are built against placeholder story; the real story is
content, supplied later.

**Verified:**

Docs-only, so the ladder is a regression check rather than a proof: boot `0 warnings, 0
errors`, tests 165 passed / 0 failed, `check_content` PASS. Every entry point references the
board.

**Unblocks:**

WP-01, triggers and traversal, in a fresh chat: trigger volumes (the folder, the collision
layer and the inventory row all exist and nothing populates them), a rest point with
`Clock.skip_to_hour`, and climb points — the authored vertical movement that "no jumping"
implies.

**Known gaps:**

Packages 02 through 15 are specified at goal-plus-manifest depth, not to WP-01's detail. That
is deliberate: writing detailed plans for work fourteen chats away is exactly the speculative
architecture this project keeps deleting. Each gets its detail when it comes up.

---

## 2026-08-25 — Items, inventory, pickups and chests: the demo loop closes

**Did:**

Planned this one properly before writing anything, because the last two attempts at
delegating research both died on usage limits. Two Explore agents mined the three surviving
audit reports and verified the existing seams; one design agent produced an implementation
plan; the whole thing was settled with the owner before line one. That paid for itself twice
over, below.

Shipped in two commits. First, prerequisites (`dd90da0`):

- **Layer order corrected.** The declared order put `content` *above* `gameplay`, but a
  `Pickup` must reference an `ItemDefinition` — an upward dependency failing ADR-0001's own
  test. Content is data, not a consumer: `core -> content -> systems -> gameplay -> ui`.
  Recorded as an ADR-0001 amendment rather than quietly fixed.
- **Signal payloads.** `notify_requested` had no substitution slot, so a toast could not say
  "Taken: Rose Key", and `interaction_refused` could not name the missing item. Both now carry
  a `Dictionary`; both had zero emitters, so it was free then and expensive later.
- **Per-section save versions.** `register()` takes a version, sections store as
  `{"v": n, "data": {…}}`, and appliers migrate themselves. One envelope version would have
  forced `_migrate` to understand every section — the god object via the back door.
- **`Flags` hands out deep copies** from `get_dict`/`get_array`. Godot passes Dictionaries by
  reference, so returning the stored object let a caller mutate world state without
  `set_flag`, meaning `flag_changed` never fired.
- **Test suite split** into `tests/framework/test_case.gd` plus `tests/unit/*.gd`, because the
  runner was at 184 of its 250 lines and the item cases would not fit. Raising the budget is
  the exemption the checker's own header forbids.

Then the feature:

- **`ItemDefinition`** — the project's first `Resource`. Four fields: `id`, `name_key`,
  `category`, `max_stack`. Five more were cut (`icon`, `description_key`, `value`, `tags`,
  `world_scene`) because nothing displays or reads them and adding one later edits one script
  while leaving every `.tres` valid.
- **`ItemDb`** — a static class, not an autoload, that scans `data/items`. ADR-0006.
- **`Inventory`** — a component on the player, with `can_accept()` as the single capacity seam.
- **`Pickup`**, **`ItemContainer`**, and `Gate.requires_item`.
- **`tools/check_content.gd`** — duplicate object ids, id/filename mismatches, localization keys
  missing from the CSV, and `ItemDefinition` files filed outside `data/items`.
- Courtyard content: a rose key on the dais, a wicker chest, an east gate that wants the key.

**Why:**

Items had to be next because they were the last missing piece of the Phase 1 loop *and* the
project's first typed `Resource`. `ARCHITECTURE.md` has claimed since day one that "adding the
fiftieth item must not touch a single line of code", and that claim had never been exercised —
the audit called it unrunnable rather than untested. It is now tested by a case that counts the
`.tres` files on disk instead of hard-coding three, so adding a fourth item keeps it passing.

Two design points worth keeping. **The inventory is not an autoload**: interactables are already
handed the interactor by `attempt(who)`, so `Inventory.of(who)` needs no global and works for an
NPC or a stash, whereas a global would hard-code "one bag in the universe" into every
interactable in the game. **The lever and the gate still know nothing about each other** — one
publishes a flag, the other reads one, and now a third thing can demand a carried item instead.

**Connects:**

Persistence added *zero* new machinery. `PersistentState.store(&"taken", true)` writes
`obj/<area>/<object>/taken` into `Flags`, which is already a tested save participant, so a
pickup that is gone stays gone because `flags` is applied before the area is even requested.
That is the whole return on ADR-0005. `Pickup` deliberately does not free itself — the sensor
may hold a reference inside the very call that took the item — it goes unavailable,
unmonitorable and invisible instead.

**Verified:**

- Type gate clean on every new script; `--import` clean.
- Boot: courtyard with **6 interactables**, `0 warnings, 0 errors`.
- Tests: **165 passed, 0 failed**, exit 0, no leaked instances. A deliberately broken
  assertion exits 1.
- `check_budgets`: 44 files, 3,202 code lines, **0 violations**.
- `check_content`: PASS — and proven to fail. A scratch copy with a mismatched item id, a
  duplicate `object_id`, a misspelled localization key and a stray definition produced four
  precise `file:line` violations and exit 1.
- Visual capture at 10:15 shows the placeholder-marker key on the dais and the chest, both
  casting shadows, with the localized prompt reading "Read  Weathered Notice".

**Two things the planning caught that would have cost real time:**

1. **`class_name Container` does not compile.** `Container` is a native Godot class (the
   `Control` base), so it would have cascaded into every subclass as "could not resolve class" —
   the same trap as `Area3D.priority`. Verified against the engine's own class list, and the
   chest is `ItemContainer`.
2. **Resource-typed `@export` from a hand-authored `.tscn` works** with no `node_paths` header,
   unlike Node-typed ones. Probed before authoring any prefab against the assumption.

And one bug the refactor caught in its own new helper: a one-step `spawn()` added nodes to the
tree before the caller could set `object_id`, which `Interactable` forwards in `_enter_tree` —
so it arrived too late and persistence silently died. Split into `build()` and `attach()` so the
ordering lives in the API rather than a comment.

**Unblocks:**

Trigger volumes and a rest point, then the screen stack that the inventory UI needs. Phase 1's
remaining exit criteria are now the walk-and-face check and a real save/quit/relaunch.

**Known gaps:**

**The export path is unproven** and this matters: items are found by scanning a directory,
verified in the editor and headless only. There is no export preset, and it must export *all*
resources or the catalogue ships empty — written up in ADR-0006 rather than left as a surprise.
No trigger volumes yet, no screen of any kind, no item instances (deferred until something has
durability), no equipment. The sprite sheet layout is still two hardcoded constants. Only one
area exists, so the transition code has still never swapped two.

---

## 2026-08-24 — Object identity, and the interaction loop end to end

**Did:**

- **ADR-0005: authored object identity.** Every persistent object carries a `PersistentState`
  child with an `object_id`, unique within its area. State is written through `Flags` under
  `obj/<area_id>/<object_id>/<field>`. Rejected node-path identity, which is free but couples
  identity to scene structure: renaming a node silently orphans its state, the chest refills,
  and nothing errors. Rejected generated UUIDs as unreadable in a save file and in a diff.
  No new autoload — `Flags` is already a generic store and already a tested save participant.
- **`Interactable`**, a deliberately shallow base class over `Area3D`. Subclasses override
  `refusal()` and `perform()`; detection, ranking, prompts, refusal messaging, one-shot
  handling and hold-to-confirm are all handled once. Chose a base class over a duck-typed
  component because warnings-as-errors forbids calling a method on an untyped value, so a
  component would need a cast at every call site.
- **`InteractionSensor`** on the player. Ranks candidates by authored priority, then
  proximity, then how squarely the player faces the target, with ties broken by node name so
  physics callback order cannot reshuffle the prompt between frames. Tab cycles overlapping
  targets. Hold-to-confirm is supported and drawn as a progress bar.
- **Three interactables:** `Readable` (signs), `Lever` (toggles a persistent flag), `Gate`
  (refuses with a reason until a flag is set, then opens and stays open).
- **Localized UI:** `InteractPrompt` and `NotificationToast`, plus `localization/strings.csv`
  with 28 keys wired through `tr()`. This closes the "zero `tr()` calls" audit finding —
  there is now no code path by which raw player-facing text reaches the screen.
- Placed a notice, a lever and a north gate in the courtyard as instanced prefabs from
  `scenes/objects/`.

**Why:**

The audit named object identity as the thing blocking everything else, because interaction,
items, containers and doors all persist state through it, and retrofitting it means touching
every scene. It had to be decided before content existed.

The lever deliberately does not know what it opens. The tempting design is
`@export var door_to_open`, which couples every lever to one consequence; the second time a
lever needs to do two things, the coupling has to be undone. The lever owns a flag and
anything may watch it, so one lever can gate five things without knowing they exist.

Refusal is a first-class result rather than a hidden prompt. Hiding the prompt on a locked
gate is cheaper but worse: the player cannot tell a locked door from scenery, so they never
learn there is something to come back for.

**Connects:**

`PersistentState` walks up to the enclosing `AreaRoot` for its namespace, so an id only has to
be unique within one area file. `Interactable` forwards `object_id` to that child in
`_enter_tree`, which runs top-down before any child `_ready`, so an instanced prefab sets its
identity with one root-level property override instead of a child-node edit that hand-authored
`.tscn` files cannot express robustly. Interaction input is read by the sensor, not by
`PlayerController`, because the controller's own MUST NOT line forbids it knowing about
interaction; the comment claiming "one of only two scripts allowed to read input" was corrected.

**Verified:**

- Type gate clean on all eight new scripts.
- `--headless --import` clean; boot loads the courtyard with 3 interactables,
  **0 warnings, 0 errors**.
- Test suite **74 passed, 0 failed**, exit 0. The new cases drive the whole loop with no
  simulated keypress: the gate is offered and refuses with LOCKED, the lever publishes its
  flag, the same gate then opens, its state lands at `obj/global/t_gate/open`, and after the
  node is freed and re-instantiated it is *still open* — which is what an area reload does.
  Clearing one object's state leaves unrelated flags intact.
- `check_budgets.gd` — 32 files, 2,485 code lines, 0 violations. It caught one of these very
  test functions at 42 lines against the 40 limit; the function was split rather than the
  budget raised.
- Visual capture at 09:30 shows the prompt reading "Read  Weathered Notice", both words
  resolved through the translation table.

**Unblocks:**

Items and inventory, which is the last big piece of the demo loop, and which will be the first
typed `Resource` content class — the thing that finally tests the "adding the fiftieth item
touches no code" claim.

**Known gaps:**

Still zero typed `Resource` content classes. No duplicate-`object_id` detection, so two objects
sharing an id inside one area would silently share state; a content validator scanning scenes
would catch it. No hard-coded-string audit, so the localization rule is enforced by discipline
rather than mechanically. Trigger volumes still have a folder, a collision layer and no system.
The gate opens but leads nowhere, because there is only one area.

Two engine traps cost time and are now recorded in `CONTEXT.md`: `Area3D` already defines
`priority`, and redefining it is a parse error that cascades into every subclass as "could not
resolve class"; and `set_anchors_preset()` leaves offsets at zero, producing a zero-size
Control whose text spills off the screen.

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
