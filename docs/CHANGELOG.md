# Changelog

**What this file is for, and it is not release notes for players.** A game built on this base
merges the base's later commits ([`UPGRADING.md`](UPGRADING.md)), and the only question that
matters at that moment is *what will this do to the files I wrote*. So every entry says what
changed and, more importantly, **what a consuming game has to do about it** — which for most
entries is nothing, and saying so explicitly is the point.

**The top `##` heading is the version in `project.godot`'s `[template] base/version`**, and
`tests/unit/version_test.gd` fails rung 4 if the two disagree. Bumping one without the other is
the exact rot this discipline exists to prevent.

**What the numbers mean** — the full promise is in [`UPGRADING.md`](UPGRADING.md):

| Bump | Means | A consuming game |
|---|---|---|
| **MAJOR** | a file the game wrote must change | must read the entry before merging |
| **MINOR** | the base gained something a game may ignore | merges and carries on |
| **PATCH** | nothing a game wrote is affected | merges and carries on |

---

## 3.0.0

*2026-09-05 — the music ducks under dialogue, the duck is measured from the player's own volume
instead of from an absolute decibel, and `Audio.stop_music()` is deleted. The deletion is
the whole reason this is a MAJOR bump; everything else here is additive.*

**A consuming game does: `grep -rn 'stop_music' your_game/`.** If it returns nothing — and it
almost certainly does, because it returned nothing in this repository either, which is why the
method went — this version is additive for you and you can stop at the next paragraph. If it
returns something, **replace `Audio.stop_music(fade)` with `Audio.play_music(null, fade)`**, which
is the same operation and always was: `stop_music` was a two-line alias over exactly that call.
There is no other break in this version.

**The second thing to check, and it is a behaviour change rather than a compile error.**
`Audio.duck()` no longer moves the buses to the decibel you pass it — it moves them that far
BELOW wherever the player's own volume settings have put them. If you were calling `duck()` with
a hand-tuned absolute figure, that figure is now an offset and you want a small negative number
(the default is `Audio.DUCK_DB`, −8 dB). Nothing warns you, because both readings are
valid floats. The old behaviour was a defect and not a choice: against a player who had turned
music down to 0.25 linear (−12 dB), a "duck" to −8 dB made the music four decibels LOUDER every
time somebody spoke, and against the default it ducked by eight. One call, opposite effects,
chosen by a slider on the options screen.

**What you gained**, none of which needs an edit under `src/`:

| Thing | Where | Default |
|---|---|---|
| `DialogueDuck` | the `DialogueDuck` node in `game_root.tscn` | on |
| `Audio.target_db(bus)` | anywhere | — |
| `Audio.DUCK_DB` / `DUCK_SECONDS` / `RESTORE_SECONDS` / `DUCKED_BUSES` | anywhere | −8 dB / 0.4 s / 0.6 s / Music + Ambience |
| `TestCase.parent_of_script(scene, script)` | any test case | — |

**The music now ducks while anybody is talking, and comes back when the last one stops.** The
occasion is `Events.dialogue_started` and `dialogue_finished`, which have been on the bus since
Phase 0 with one emitter each — **no signal was added**, and no new setting either. The buses it
moves are Music and Ambience; SFX and UI are deliberately untouched, since ducking exists so that
those can be heard. If your game wants ducking somewhere else — a cutscene, a codec call, a boss
door — call `Audio.duck()` and `Audio.unduck()` from your own occasion, or add a node beside
`DialogueDuck`; if it wants no ducking under dialogue at all, delete that one node from
`game_root.tscn` and nothing else changes.

**A duck holds while ANY conversation is running, counted.** Two overlapping conversations mean
two holds, and the music comes up after the second ends rather than the first. `DialogueDuck.held()`
is the count.

**A volume slider moved mid-duck no longer lifts the duck.** `_apply_all_volumes` re-applies every
bus on any `audio/*` change and now goes through `target_db`, so the slider lands on the ducked
level and the duck survives it. A bus the player has muted stays muted while ducked: nothing may
raise a level set to zero.

**If you subclassed or copied `tests/framework/test_case.gd`,** it gained one method,
`parent_of_script(scene_path, script_path)` — the `SceneState` walk that asks whether a scene
really carries a node with a given script. It moved out of `settings_consumers_test.gd` on its
second caller. A game that copied that private helper into its own case can keep it; nothing
forces the change.

---
## 2.5.0

*2026-09-05 — the base autosaves, and `gameplay/autosave` is back in `Settings.DEFAULTS` as the
player's veto over it. It is the second of the three settings version 2.0.0 removed to come back
with the feature it was waiting for; only `accessibility/subtitles` is still out.*

**A consuming game does:** nothing, unless one grep says otherwise. **No save file already on
disk changes meaning, and the format is untouched** — `SCHEMA_VERSION` is still 1, slots 0..5
still hold what they held and still carry the numbers your players know. That is why this is a
MINOR bump and not a MAJOR one, and it was the deciding factor in the slot design below.

**`grep -rn 'gameplay/autosave' your_game/`.** If it returns nothing, this version is additive
for you and you can stop here. If it returns something, you re-added the key yourself after 2.0.0
removed it — which that entry explicitly invited — and you now have **two declarations of the
same key** in a merged `settings.gd`. Keep the base's and delete yours: it is the same key with
the same boolean meaning and the same row in `settings_screen.gd`, and `Autosave.AUTOSAVE_SETTING`
is now the const that names it. If your own consumer wrote into a slot of its own choosing, that
consumer is the thing to delete, and it is yours — see the slot warning below before you do.

**What you gained**, all of it opt-in except the two occasions:

| Thing | Where | Default |
|---|---|---|
| `SaveSystem.AUTOSAVE_SLOT` | one past the six manual slots | 6 |
| `SaveSystem.AUTOSAVE_FILE` | `user://saves/autosave.json` | — |
| `SaveSystem.is_autosave(slot)` | anywhere | — |
| `Autosave.request()` | the `Autosave` node in `game_root.tscn` | — |
| `gameplay/autosave` | the options screen | **true** |
| `notify.autosaved`, `ui.save.autosave`, `ui.save.autosave_empty` | `localization/strings.csv` | — |

**THE ONE THING TO READ IF YOU ALREADY WROTE AN AUTOSAVE OF YOUR OWN.** The base's autosave slot
is `MAX_SLOTS`, i.e. **one past** the six the save screen offers, stored under a NAME rather than
a number. It was placed there and not at slot 5 precisely so that no save any player already has
changes meaning. If your own autosave reserved one of the manual slots, you now have two autosave
mechanisms and one of them can overwrite a save your player made on purpose — delete yours and
call `Autosave.request()`, or keep yours and set `gameplay/autosave` to false in your defaults.
Do not do both.

**Two occasions fire automatically, and both are refusable.** The base autosaves when the
application is ending (`Events.game_ending`, so the window's close button is covered too) and one
frame after arriving in a new area (`Events.area_entered`). Your own occasions — a chapter break,
a bed slept in — are one call to `request()` on the node, with no edit to `src/`. Every occasion,
yours included, is refused when the player has turned the setting off, when `Director` is
mid-transition, and when there is no run in progress at all.

**`SaveSystem.latest_slot()` now sees the autosave slot**, which is the one behaviour change to a
method you may already call: Continue resumes the autosave when it is the most recent save. The
save screen's writing half still counts to `MAX_SLOTS` and therefore still cannot name the
autosave; its reading half now lists it as a row of its own. If you subclassed `SaveScreen` or
wrote your own slot list, check which range you iterate: `MAX_SLOTS` is the manual range and
`AUTOSAVE_SLOT + 1` is everything.

**A save is a FILE, so this row is proved in the suite rather than in a photograph** — 50 new
assertions, including that six manual writes leave the autosave byte-identical. What the windowed
capture adds is the indicator: `notify.autosaved` on the toast that already existed, which is what
`SYSTEMS_INVENTORY.md` item 6 has asked for since WP-00. On the quit path that toast is emitted
and never seen, because the window is gone the same frame, and that is recorded rather than
special-cased.

## 2.4.0

*2026-09-05 — the base has a screen shake, and `gameplay/camera_shake` is back in
`Settings.DEFAULTS` as its scale. It is the first of the three settings version 2.0.0 removed to
come back with the feature it was waiting for, which is what removing them was for.*

**A consuming game does:** nothing, unless one grep says otherwise.

**`grep -rn 'gameplay/camera_shake' your_game/`.** If it returns nothing, this version is
additive for you and you can stop here. If it returns something, you had re-added the key
yourself after 2.0.0 removed it — which that entry explicitly invited — and you now have **two
declarations of the same key** in a merged `settings.gd`. Keep the base's and delete yours: it is
the same key with the same 0..1 meaning and the same `[0.0, 1.0, 0.1]` row in
`settings_screen.gd`, and `HD2DCameraRig.SHAKE_SETTING` is now the const that names it. If your
own consumer read it as something other than a 0..1 scale — a boolean, say — that consumer is the
thing to change, and it is yours.

**What you gained**, all of it opt-in:

| Thing | Where | Default |
|---|---|---|
| `HD2DCameraRig.shake(strength, seconds)` | the rig in your area scene | — |
| `Events.camera_shake_requested(strength, seconds)` | the bus, ask from anywhere | — |
| `shake_metres`, `shake_hz` on the rig | your area scene | 0.35 m, 18 Hz |
| `Gate.open_shake` | per gate | **0.0 — silent** |
| `gameplay/camera_shake` | the options screen | 1.0 |

**Nothing in your game shakes until you ask it to.** `Gate.open_shake` defaults to zero, so every
gate you have already authored opens exactly as silently as it did before; the base's own demo
courtyard sets `0.7` on its north gate and that is authoring in a `.tscn`, not a behaviour change
in `src/`. The two new exports on the rig have defaults, so an area scene you wrote before this
version loads unchanged and its rig shakes 0.35 m when something asks.

**The amplitude is the AREA AUTHOR'S and the setting is the PLAYER'S VETO**, which is the same
contract `video/depth_of_field` and `accessibility/reduce_motion` already have on this rig. The
setting is a 0..1 scale on `shake_metres` and cannot exceed it, so **a rig you authored at
`shake_metres = 0.0` never shakes, whoever asks and whatever the player prefers.**
`accessibility/reduce_motion` removes it outright rather than making it smaller — a smaller shake
is still a shake — so that setting now reaches four motions instead of three, which T5.7 recorded
as its own gap the day it shipped.

**No autoload, no ADR, no save version, no layer change.** One signal was ADDED to the registry
and none removed or altered, so nothing you connected has changed shape. `settings_screen.gd`,
`menu_screen.gd` and the theme resource were not touched: the screen is generated from `DEFAULTS`
and already carried the range row for this key, which is the seam claim from 2.0.0 tested
literally rather than repeated.

---

## 2.3.0

*2026-09-05 — both placeholder character sheets now draw a different figure for every facing.
They drew one pose repeated across every column, so the base's facing system was invisible on
screen for five phases while being correct and asserted the whole time.*

**A consuming game does:** almost certainly nothing. One grep decides it:

**`grep -rn 'character_placeholder\|character_alt' your_game/`.** If it returns nothing, stop
here — this version cannot reach you. If it returns something, you are drawing characters from
the base's placeholder art, and **those two PNGs now look different**. Nothing about their SHAPE
changed — `character_placeholder.png` is still 256x576 with 8 facings × 4 frames × 3 blocks and
`character_alt.png` is still 96x600 with 4 × 3 × 5, and **neither `.tres` layout changed at all**
— so nothing you wrote has to change and no code path behaves differently. What changed is the
pixels inside the cells: a facing now reads as front, three-quarter, side or back, with a profile
showing one eye and a nose and a back view showing no face. That is a visible change to your
characters and you should see it before your players do.

**Why this was worth a version.** Measured over the figure band, the old sheet's back view
differed from its front by **0.7%** of a cell — the two eyes and nothing else — and facings 2 and
3 were byte-identical. Three of the four-facing sheet's columns differed only by their column
tally. So a character walking east and a character walking west drew the same picture, and an
owner playing the game reported that sideways movement "just slides to the side". Nothing in
`src/` was wrong and nothing in `src/` changed.

**Added, and safe to ignore:** `--facing-shots=<dir>` on the existing
`src/systems/debug/dev_gait_shots.gd`, which walks a character north, east, south and west and
photographs each with the sheet column decoded out of `sprite.frame`. Same debug gating as the
rest. `tests/unit/sheet_facings_test.gd` is new: it requires every facing of a shipped sheet to
differ from every other by more than 5% of the cell, and asserts only the base's own placeholder
art, so it survives the demo strip. **If you ship your own sheets and add them to that case, note
that it measures the FIGURE and ignores four columns down each edge** — the alt sheet's pip
tallies live there and are deliberately not mirrored.

Nothing else in this version can reach a game. No file under `src/` changed except the debug
capture tool; no signal, enum value, setting, autoload, save version or layer moved.

---

## 2.2.0

*2026-09-05 — `accessibility/reduce_motion` reaches all three motions the base draws instead of
one, and the shadow atlas is restored to the size your `project.godot` authored instead of to a
constant that was wrong.*

**A consuming game does:** nothing, and there is nothing to grep for. Both changes are inside
files the base owns, and both make an existing setting do what its label already promised. But two
of them are VISIBLE, so see them before your players do.

**`accessibility/reduce_motion` now zeroes `HD2DCameraRig.follow_lag` and cuts `ScreenFade`.** It
previously reached only the dialogue typewriter. If your game ships rigs with a smoothed follow —
the base's default is `0.10` — a player with reduce-motion ON will now get a camera locked to the
character instead of one that slides after it, and area transitions will cut to black instead of
dissolving. **Your authored `follow_lag` is remembered and restored** when the setting goes off, on
the same `_authored_dof` pattern `video/depth_of_field` has used since 2.0.0: the setting is the
player's VETO over what your area author chose, never a replacement for it, and a rig you shipped
at `follow_lag = 0.0` stays rigid however the setting moves. Nothing to change in your area scenes.

**`video/shadows` no longer replaces your shadow atlas size with 2048.** This one is a fix to a
defect that was live in the base, and if you authored
`rendering/lights_and_shadows/positional_shadow/atlas_size` or `.../directional_shadow/size` in
your `project.godot`, **the base was silently discarding it at boot.** `Settings._apply_shadows`
restored a `const POSITIONAL_ATLAS: int = 2048` described as "the engine's own default"; the
engine's default is **4096**. Measured on the base itself: it booted every windowed session at
`2048` and now boots at `4096`. The new `ShadowAtlas` (`src/core/state/shadow_atlas.gd`) reads
both sizes back before the first zeroing and restores those, so whatever you authored is what you
get. **If your game looked correct to you before this version, your shadows may now be sharper and
slightly more expensive than you tuned for** — that is the authored value arriving, not a
regression, and you can set the two project settings to 2048 to get the old picture back
deliberately.

Nothing else in this version can reach a game. `settings.gd` came down from 144 to 139 code lines
and gained no new key; no setting was added or removed, so `settings_screen.gd` draws the same
twenty rows; no signal, enum value or autoload changed. `tests/unit/settings_consumers_test.gd`
split at its budget and `tests/unit/settings_effects_test.gd` is the new half — a test-only change,
but worth knowing if you carry local edits to that file.

---

## 2.1.0

*2026-09-05 — the second placeholder sheet gained a complete gait set, so the wholesale character
swap the base promises can be performed and photographed rather than described.*

**A consuming game does:** almost certainly nothing. One grep is worth running:

**`grep -rn 'character_alt' your_game/`.** If it returns nothing, stop here — this version is
purely additive to you. If it returns something, you are using the base's *swap demonstration
asset* as real art, and it changed shape: `character_alt.png` went from **96x240** (2 animation
blocks) to **96x600** (5), and `character_alt_layout.tres` now declares `animations = 5` with
`run_row = 2`, `sneak_row = 3` and `climb_row = 4` where it previously left all three at `-1`. The
two are committed together and `character_swap_test.gd` asserts they agree, so taking both is
safe and taking one is not. A character pointed at that pair will start drawing a distinct run,
sneak and climb cycle instead of replaying its walk block — which is the improvement, but it is a
visible change and you should see it before your players do.

Nothing else in this version can reach a game. No file under `src/` changed for the swap itself —
that was the point of the row, and it is what a fork inherits: your own sheets, your own layouts,
no code. `SpriteSheetLayout`, `CharacterVisual` and `PlayerController` are byte-identical to
2.0.0. No signal, no autoload, no setting, no save version, no layer.

**Added, and safe to ignore:** `src/systems/debug/dev_gait_shots.gd` and its `--gait-shots=<dir>`
flag, which drives a character through all five gaits and photographs each one with the block
decoded out of `sprite.frame`. Debug surface, gated on `OS.is_debug_build()` like the other three,
and deleting it cannot break a game. `tests/unit/character_swap_test.gd` is new and asserts only
the base's own placeholder sheet, so it survives the demo strip.

---

## 2.0.0

*2026-09-05 — every setting the options screen draws is now read by something. Nine were wired to
a consumer; three were removed, and `Actions.JUMP` went with them.*

**A consuming game does:** two things, and both are greppable.

1. **`grep -rn 'Actions.JUMP' your_src/`.** If it returns anything, that line will no longer parse:
   the const is gone. There was never anything in the base polling it, so a game that used it wrote
   the poller itself and knows where it is. Declare your own action if you need one — that is one
   `_define` call in your own `Actions` subclass or one line in `project.godot`.
2. **`grep -rn 'gameplay/autosave\|gameplay/camera_shake\|accessibility/subtitles' your_src/`.**
   Those three keys are gone from `Settings.DEFAULTS`, so `get_bool` on one now logs
   *"Unknown setting"* and returns `false`, and `set_value` refuses. If you had built a consumer
   for one of them, re-add the key: one line in `DEFAULTS` and one row in
   `localization/strings.csv`, and the settings screen picks it up with no edit, because it is
   generated from `DEFAULTS`.

Everything else in this version is additive. Nine settings that previously did nothing now do
something — if you had been shipping them to players as inert rows, they will start working, which
is the change and the point. No signal was added or removed, no autoload, no save version, no
layer. `settings_screen.gd`, `menu_screen.gd` and the theme resource were not touched.

**Why this is MAJOR for a change that only deleted four public names.** This file's own table says
MAJOR means *a file the game wrote must change*, and both greps above can require exactly that.
The first fails at parse time, which is the good kind; the second fails at runtime with a logged
error and a `false`, which is the kind worth a version number.

**What was wrong.** **Twelve of twenty-three settings had no consumer.** All twelve were declared
in `settings.gd`, drawn to the player by `settings_screen.gd`, translated in both languages, and
inert. Four were video settings, three gameplay, and five were the whole of `accessibility/*` —
and those five were the sharpest, because **a game forked from this base could not wire them
without editing `src/`.** The thing a text-size preference has to change is the project theme, and
every screen that draws from it lives under `src/ui/`. That makes it a defect in the TEMPLATE
rather than a missing feature of a game, which is the distinction this whole repository turns on.

**What each of the nine reaches now**, and the placements are the interesting part because two
identical-looking settings went to opposite places:

| Setting | Consumer |
|---|---|
| `video/resolution_scale` | `Settings._apply_render_scale` — `scaling_3d_scale` is the viewport's and no system owns the viewport |
| `video/shadows` | `Settings._apply_shadows` — the shadow ATLAS, so every light an area author placed obeys it |
| `video/bloom` | `EnvironmentDriver` — the `Environment` is that node's and nothing else may touch it |
| `video/depth_of_field` | `HD2DCameraRig` — `set_dof_enabled()` finally has a caller |
| `gameplay/show_interact_hints` | `InteractPrompt` |
| `accessibility/text_scale` | new `UiAccessibility`, under `UILayer` in `game_root.tscn` |
| `accessibility/high_contrast_prompts` | `InteractPrompt` — a 4px outline, a value picked by photograph |
| `accessibility/reduce_motion` | `DialogueScreen` — the typewriter reveal arrives whole |
| `accessibility/hold_to_confirm` | `InteractionSensor` — a 0.4s floor under `Interactable.hold_seconds` |

`video/bloom` and `video/shadows` look like the same kind of setting and are not. Bloom is one
property of one `Environment` that one node owns, so it went to that node. Shadows are cast by
**lights an area author placed** — the demo courtyard has four — and no node owns the set of them,
so a driver enumerating lights would be wrong for every light added after it was written. Applying
it at the atlas instead means **a game that adds a hundred lights gets the setting for free and
writes no code.** If you author a different `positional_shadow_atlas_size` in `project.godot`, note
that toggling this setting restores the base's `2048` rather than your value — recorded as a gap.

**Three settings removed rather than wired**, because honouring them would have meant inventing a
feature inside a row about connecting existing ones: there is no screen shake anywhere under
`src/`, there is no autosave and `SaveSystem` has no notion of the slot a run belongs to, and
nothing is voiced. **A row drawn to the player that cannot do anything is worse than a dead
constant, because the player is the one who finds out.** The reason each was removed is written in
the `DEFAULTS` block, where the next person to consider re-adding one will be standing.

**Four defects fixed alongside**, each one line to a few:
`Settings.reset_to_defaults()` never called `_apply_locale()`, so Reset wrote `locale = "en"` and
left the UI in the old language · `set_dof_enabled()` had no caller · `Actions.JUMP` was offered as
a rebinding row for a verb `player_controller.gd` says three times over this template does not have
· `KeyBindings.rebind()` gated on `InputMap.has_action` rather than `Actions.REBINDABLE`, so
`debug_console` could be overridden into `input.cfg` and then never reset, because
`reset_bindings()` re-declares only the rebindable groups.

**And the question the six checkers cannot ask is now asked, as an assertion rather than a seventh
checker.** A setting is a string key read through `DictRead` — not a `class_name`, a `signal` or a
CSV row — so none of T5.4's three gates can see it. `tests/unit/settings_consumers_test.gd` loops
over `Settings.DEFAULTS` as the engine loaded it and requires every key to be consumed. It went to
the suite rather than to `tools/` because that dictionary is available at runtime and a `check_*`
tool would have to parse `settings.gd` to reconstruct it. **If you add a setting to a fork and
nothing reads it, rung 4 goes red and names the key.**

---

## 1.2.0

*2026-09-04 — an animation block per GAIT, so a character's movement styles come from its sheet
rather than from its code.*

**A consuming game does:** nothing, unless it wants the new gaits. Every existing
`SpriteSheetLayout` keeps drawing exactly what it drew — `run_row`, `sneak_row` and `climb_row`
default to `-1`, which means "replay the walk block", and that is precisely what run and sneak did
before this version. To add a run cycle: draw the block, set `animations`, name `run_row`. No code,
in your project or in the base. **If you replaced `character_placeholder.png`** with your own
sheet, nothing changes for you; if you were using the shipped one, it is now 256×576 with three
blocks instead of 256×192 with one, and its layout names `walk_row = 1` and `run_row = 2`.

**`animation_for` took a BOOLEAN, so a sheet could only ever hold an idle cycle and a walk
cycle.** Run and sneak replayed the walk block faster and there was nowhere to put a distinct one —
while `GameEnums.MoveState` had ten values and `Events.player_state_changed(state)` was declared,
emitted by `PlayerController` and **listened to by nothing.** The information the sprite needed
existed, was announced every time it changed, and had no route to the thing that would draw it.
Sixth instance of this project's most expensive shape, after `Gate.locked_key`,
`PathAction.refusal_key`, `ItemDb.reload`, `HD2DCameraRig`'s framing exports and 1.1.0's locale
setting.

It now takes a `GameEnums.MoveState`. `CharacterVisual` is TOLD the state by whoever drives it —
never read from `player_state_changed`, because every NPC uses the same class and none of them is
the player. `NpcBrain` passes `WALK` or `IDLE` from whether it is stepping, which is the honest
extent of what a schedule-driven actor knows, and gets a game's walk block for free without
knowing that animation blocks exist.

**The fallback chain is the compatibility promise**, and it is asserted before the feature is:
a gait row left at `-1` inherits `walk_row`, and states with no gait of their own (`JUMP`, `FALL`,
`SWIM`, `BUSY`, `LOCKED`) fall to `idle_row` rather than to walk — something else driving the
character looks like standing there, not walking on the spot. `-1` rather than `0` is load-bearing:
row 0 is a real row, so a default of `0` would have drawn a standing character for anything running
on every sheet not yet updated.

**`problems()` now validates every named row, not just two.** A gait row past the end of the sheet
is reported by field name — `names run_row row 9, past its 3 animation(s)` — because the draw call
clamps to the last block, so an unreported typo animates plausibly and wrongly.

**`PlayerController` computes its state BEFORE drawing.** `_update_state` ran after the visual
update, which was invisible while nothing read the state and became a one-frame lag on every gait
change the moment something did.

**Also in this version:** the shipped placeholder sheet gains idle, walk and run blocks with a
different cloth tint each and a forward lean on the run, so which gait is drawn can be READ off a
capture instead of guessed at — proved by three captures in which the player walks in green and
runs in rust while the keeper NPC stands beside them in blue, from the same sheet in the same
frame. `art_contract_test.gd` gains 19 assertions over the mapping, the fallback and the clamp.
Suite 1,653 → 1,676; stripped 1,579 → 1,602, its 25 skips unchanged.

---

## 1.1.0

*2026-09-04 — the skeleton's four open exit criteria closed, and one of them was a missing
feature rather than a missing proof.*

**A consuming game does:** two things, both small, and only if it wants the second language.
`localization/strings.csv` gains an `en_XA` column, so **expect a conflict in that file** — it is
the one that conflicts on every merge (see [`UPGRADING.md`](UPGRADING.md)). Resolve it by keeping
your own rows, then run `godot --headless --script tools/gen_pseudolocale.gd` to refill the
column and `--headless --import` to regenerate the translation. If you do **not** want a
pseudolocale, delete the `en_XA` entry from `locale/translations` in `project.godot` and drop the
column — nothing in `src/` names it. Everything else here is additive.

**The locale setting was wired to nothing, and now it applies.** `settings_screen.gd` cycled a
locale and stored it; `Settings` announced `setting_changed`; and **no system anywhere called
`TranslationServer.set_locale`.** So changing the language did nothing at all, in a project whose
first non-negotiable about text is that every string is a key. `Settings._apply_locale` now
applies it, on `_apply_display`'s stated reasoning rather than by analogy with it — nothing else
owns `TranslationServer` either, exactly as nothing else owns the window. It is deliberately
**not** skipped under `--headless`, which is the one way it differs from the display: a
translation has no window in it, so the suite asserts against `tr()` instead of taking a
screenshot on trust.

**And there was no second language to switch to.** The CSV had one locale column, so the
criterion was unreachable however well the wiring worked.
[`tools/gen_pseudolocale.gd`](../tools/gen_pseudolocale.gd) generates an `en_XA` column —
`[~~English~~]` — which is the same argument that generates placeholder ART rather than shipping
art: the stand-in exists so the system can be verified before the content is. It earns its keep
afterwards too: a string that appears **unbracketed** on screen never went through the CSV, which
is `check_strings.gd`'s static rule caught visually and including anything computed, and the
padding makes every label longer than its English so a layout that only just fits fails here
rather than in a translated build.

**`check_content.gd`'s CSV rule is now the header width, not the literal two.** It failed any row
parsing to more than two columns, which caught WP-01's unquoted comma and would have failed the
second language outright. It compares against the header instead, and requires equality rather
than a maximum so a half-added locale filling only some rows is caught too. Planted: the original
WP-01 row, unquoted, gives *"object.lever.gate.on has 4 column(s) where the header has 3, so an
unquoted comma has cut its text off at 'The lever gives with a heavy clack. Somewhere north'"* —
the same bug, still caught, with three columns.

**`save` and `load` join the console vocabulary**, so there are six verbs rather than four, with
one body each as ADR-settled. Slots are zero-based because `SaveSystem` and the save screen both
are — a verb that renumbered them for friendliness would make `save 1` and menu slot 1 two
different files.

**`--locale=<code>` is a new capture flag** in `dev_capture.gd`, routed through `Settings` rather
than straight to `TranslationServer` so it exercises the path a player takes. **It PERSISTS**,
because a language choice should — pass `--locale=en` to put it back.

**The suite now pins its own language.** That persistence bit immediately: a `--locale=en_XA`
capture left the setting on disk and the next suite run failed in four unrelated cases that
compare `tr()` output. `test_runner.gd` pins the project's declared fallback locale for the same
reason it pins `Clock.paused`, and reads it from `ProjectSettings` rather than hard-coding
English — so a consuming game whose default is not English gets a deterministic suite too.

**Also in this version:** `facing_test.gd` (21 assertions) covers the direction-of-travel to
facing and column mapping, which `art_contract_test.gd`'s MUST NOT line forbade it from
asserting; `dev_probes.gd` gains the `--save-state` / `--load-state` pair for a two-process save
proof, and `--face-all` was a temporary probe that has been removed. The verb-count assertion
gained a companion that cannot rot — every verb in `VERBS` must dispatch — because a count alone
would pass on a seventh verb declared and forgotten. Suite 1,625 → 1,653; stripped 1,551 → 1,579
with its 25 skips unchanged.

---

## 1.0.2

*2026-09-04 — one defect in the TEST RUNNER, found by performing [`TESTING.md`](TESTING.md).*

**A consuming game does:** nothing, unless its suite has a case that does not compile — in which
case rung 4 will now fail where it previously passed, and the failure names the file. That is the
bug being fixed, not a new restriction: the case was never running.

**A listed test case that does not parse no longer reports a clean pass.** `load()` on a script
with a parse error returns a `GDScript` that is **not null** and cannot be instantiated, so
`_run_case` walked straight into `script.new()`; that call's failure is a runtime error, and a
GDScript runtime error aborts only the innermost frame, so the `does not extend TestCase` failure
below it was never reached and the loop in `_ready` moved on. Measured on this repository: a
parse error planted in one listed case produced `=== 1608 passed, 0 failed, 0 skipped ===` and
**exit 0**, indistinguishable from a run in which the case did not exist.
`tests/framework/error_watch.gd` had counted the error and nothing ever asked it.
[`tests/test_runner.gd`](../tests/test_runner.gd) now checks `can_instantiate()` before
instantiating, and separately fails the run on any engine script error that no named case
accounted for — the second guard being the general one, since the next hole in that wall will not
be a parse error.

**`TESTING.md`'s worked example now compiles.** Its one assertion example read
`inventory.count()`, which is wrong twice over — nothing declares `inventory`, and `Inventory`
has no `count()`. Copying it verbatim is what began this package. The document also states what
`TestCase` actually provides, that `Fixtures.activate()` returns a bool a case must check, and
that fixture ids are consts in `tests/framework/fixture_content.gd` rather than strings to
retype.

**Also in this version:** `bag_mirror_test.gd` asserts that the `bag/<carrier>/<item>` count
flags are already current when `item_gained` and `item_lost` fire — an ordering `Inventory.add`
documents in a comment and which nothing tested on either path. `TESTING.md`'s suite total,
gotcha count and `transitions_test.gd` plan are re-measured rather than inherited.

---

## 1.0.1

*2026-09-03 — two defects found by performing [`NEW_GAME.md`](NEW_GAME.md) as a fork.*

**A consuming game does:** nothing, unless it forked at 1.0.0 and followed `NEW_GAME.md`, in
which case check `localization/strings.csv` for rows starting `quest.` and delete them — they
are this template's demo quest, and the pruning instructions did not list them.

**`core_test.gd` no longer fails a fork that has not authored its first area yet.** It asserted
`[game] world/first_area != ""` unconditionally, which contradicted its own case name, the
comment eight lines below it, and `NEW_GAME.md` § 4 — all three of which call an empty setting a
legal state. It was green in the full template and in the stripped one, because neither ever
empties that field, and red only in a real fork during the window `NEW_GAME.md` walks an author
through. The claim now lives only in [`tests/unit/smoke_test.gd`](../tests/unit/smoke_test.gd),
which gates it on whether any area exists and also requires the named area to resolve, so a game
WITH areas and an unset first area still fails rung 4.

**`NEW_GAME.md` § 3 now prunes `quest.` from the localization CSV.** The prefix list was written
before quests existed (WP-08) and was never extended, so a fork that followed the document
shipped the demo's `quest.keepers_errand.*` rows inside its own game — with all four checkers and
the whole suite green, because no gate reads `localization/` for demo content. The section now
lists the prefix, and states that nothing checks this file for you.

**Also in this version:** `NEW_GAME.md`'s verification output, row counts and suite totals are
re-measured rather than inherited, and § 6 now gives the `--` separator that `--new-game`
requires — without it the run stops at the main menu and reports `0 warnings, 0 errors`, a green
run that proves nothing.

---

## 1.0.0

*2026-09-02 — the first version the template states about itself.*

**The baseline.** Everything up to and including WP-14b, which closed Phase T3: every system in
[`SYSTEMS_INVENTORY.md`](SYSTEMS_INVENTORY.md) has a working minimal implementation and one piece
of placeholder content proving it. There is nothing to migrate *from*, so this entry records what
a fork is forking rather than what changed.

**A consuming game does:** nothing. This is the first release.

**New in this version, and it is only the two things Phase T4 named:**

- `[template] base/version` in `project.godot`, read through
  [`src/core/util/template_version.gd`](../src/core/util/template_version.gd) and printed in the
  boot banner as `base <version>`. A fork leaves this line alone; a merge that changes it is the
  base announcing a release in the diff.
- [`UPGRADING.md`](UPGRADING.md) — how a game already forked from this base receives a later fix,
  performed against a real stripped fork rather than written from intent.

**Known and stated rather than fixed:** `project.godot` and `localization/strings.csv` are MIXED
files, and a merge into a diverged fork can conflict in both. `UPGRADING.md` § *The two files
that will conflict* says what those conflicts actually look like, because they were produced.
