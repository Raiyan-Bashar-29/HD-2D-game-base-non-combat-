# Context — read this first, it takes one minute

A state snapshot for a new session. `CLAUDE.md` has the *rules*; this file has the *situation*.
Keep it short. When it drifts from reality, fix it in the same commit as the change.

**Last updated:** 2026-09-06 · **T5.12 (two capture gaps closed, and the third argued away)
complete — A GATE OPENED BY A KEY PRESS HAS NOW BEEN PHOTOGRAPHED SHAKING THE CAMERA, AND AN
AUTOSAVE WRITTEN IN ONE PROCESS HAS BEEN PHOTOGRAPHED COMING BACK IN ANOTHER.** Three consecutive
rows — T5.9, T5.10 and T5.11 — closed with the same admission in their own Gaps section and each
named a probe as the fix. Three rows deferring the same work is one gap, not three, and the first
job of this row was to ask whether all three deserved it. **They did not: two were built and the
third was argued away.** A still frame cannot show a decibel, so T5.11's probe would have produced
nothing but a log line, and gotcha 66 had already retired the limit that made it look necessary —
the one hazard that would have justified it (a duck tween on a paused node) was checked and does
not exist, because `AudioDirector` is `PROCESS_MODE_ALWAYS` and `DialogueScreen` sets
`pauses_world = false`.

**`src/systems/debug/dev_scenario_shots.gd` IS THE FIFTH DEBUG FILE**, 198 of its 250, with a
`DevScenarioShots` node in `game_root.tscn`. `--gate-shot=<dir>` throws the demo's lever, opens its
gate through the interact key and photographs the shake **the gate** asked for;
`--autosave-write` and `--autosave-continue=<dir>` are two processes that write an autosave from a
real `Events.area_entered` and read it back by pressing the main menu's own Continue row. The
budget forced the split for the third time in this directory and the seam was already there:
`dev_probes.gd` prints a NUMBER, `dev_capture.gd` shoots at a FRAME NUMBER, and neither can
photograph a moment that lasts six tenths of a second and only after a scripted sequence produced
it.

**THE PROBE FOUND TWO DEFECTS IN ITSELF BEFORE IT FOUND ANYTHING ELSE, and both ran green.**
Standing beside a thing does not SELECT it — the first run pressed interact on a barter action two
metres away, so the lever was never thrown and the gate refused with `LOCKED`; cycling is what a
player does about that. And `rest` sampled twenty frames after a teleport is the follow-lag tail,
which the probe reported as a **0.4288 m "shake" of a gate that had not opened** — that is
**gotcha 67**, and its tell is that an asymptotic approach never crosses its rest position while a
decaying oscillation crosses it repeatedly. **Gotcha 68** came from the same run: a `UiScreen` is
`.new()`d, so its node name is the ENGINE class it extends and `find_child("MainMenuScreen")`
finds nothing — `UiRoot.top()` is the answer, and that is why the stack is public.

**THE MEASUREMENTS: 0.154743 m against a `camera_shake=0` control at 0.000050 m**, the same
command with one line of `settings.cfg` changed and `NorthGate opened` in both logs — reproducible
to the micrometre, because T5.9 chose a sine over noise and this is the first thing to depend on
it. The autosave pair's two reports are identical line for line with a boot report between them
reading `area='' day=1 time=06:00 weather=0 carrying=0`, and `autosave_continued.png` shows
**Day 4 | 22:15 | Night** with an "Autosaved." toast. Suite 1,935 -> 1,947; two plants, each a real
reversion, each exit 1 with its control at exit 0. **Version 3.1.0 — MINOR and not PATCH on one
line**: nothing under `src/` outside the debug directory changed, but `game_root.tscn` gained a
node a consuming game has to merge. **Found and not fixed:** the Continue row reads "Continue —
Slot 7" for the autosave, which is the reading T5.10's file naming was chosen to avoid; it is a
wording question on a UI string. `gen_placeholders.gd` is still at 230 of its 250 and is still the
next file to split. **C, F and K remain on the board — and C is no longer a question**: the
owner answered its seam on 2026-09-06, both askers, with the NPC half on `NpcBrain`, so it is now
a build rather than a decision.

**T5.11 (music ducking, built — and the alias beside it deleted) is the row before it —
complete — THE MUSIC DUCKS UNDER DIALOGUE, AND `AudioDirector` IS NOW THE ONE FILE IN THIS
REPOSITORY WITH NO PUBLIC METHOD THAT NOTHING CALLS.** The row was "build it or delete it" and the
answer is BOTH, split on one line: `duck()` and `unduck()` were built, because the occasion already
existed on the bus and lowering music under dialogue is what ducking IS; `stop_music()` was
DELETED, because it was two lines of alias over `play_music(null, fade)` with no caller in three
phases and no occasion that the surviving spelling does not already serve. **Deleting a public
method is a MAJOR bump, so the base is 3.0.0**, and that was not a reason to keep it — the entry
names the replacement and the fix at a call site is one line.

**AND IT WAS NOT MERELY UNCALLED, IT WAS WRONG — WHICH ONLY WIRING IT COULD REVEAL.** `duck()`
tweened the buses to an ABSOLUTE −8 dB, which is not a duck but "set the music to −8 dB". Against a
player who had moved `audio/music` to 0.25 (−12 dB) **the same call made the music four decibels
LOUDER every time somebody spoke**, and at the default it ducked by six. `target_db(bus)` is the
fix and the file's new answer to where a bus belongs: the level the player's own setting puts it
at, plus whatever duck is in force, with a muted bus staying muted. Three smaller defects came out
of the same wiring — a settings change lifted the duck, two ducks raced because no call cancelled
the last, and a POSITIVE duck would have worked. **Code with no consumer is not merely unused, it
is unverified**, and eight instances have now said so.

**THE COUNT IS THE DESIGN DECISION.** `DialogueDuck` is a node under `GameRoot` that holds the
music down while ANY conversation runs and releases after the LAST — because two overlapping
conversations (an NPC talking to an NPC while the player reads a sign) make a plain duck/unduck
pair lift the music underneath a conversation still running, with nothing red anywhere. It is a
node and not a `connect` line in the mixer for T5.10's reason exactly: the mixer owns how far down
a duck goes, this owns what makes it happen, and a game that wants none deletes ONE NODE from
`game_root.tscn`. **No new signal** — `dialogue_started` and `dialogue_finished` have been on the
bus since Phase 0 — **and no new setting**, deliberately: nothing was owed one, and the player
already owns the outcome through `audio/music` and `audio/ambience`, which the duck is now measured
FROM.

**A BUS VOLUME IS A NUMBER, SO ESSENTIALLY ALL OF THIS ROW IS PROVED IN THE SUITE** — the level,
the relativity, the timing, the balance, and the wire from a real `DialogueRunner.begin()` through
the real signal to the real mixer — which T5.7's and T5.9's camera work could not be. Suite
1,898 -> 1,935; five plants, each a real reversion, each exit 1. **Gotcha 66 retires an honest
limit T5.7 wrote down**: a fade and a cut read the same in a synchronous `run()`, and
`SceneTree.get_processed_tweens()` plus `Tween.custom_step()` give the frames back, so "the bus has
NOT moved yet" and "half the fade is half the drop" are both assertable. A windowed run adds
nothing — a still frame cannot show a decibel — and the standing dusk capture was taken only as a
regression check and is unchanged. **What is genuinely unproved is whether any of it can be HEARD,
and nothing here can prove that: there is no audio in the project at all**, which is why the
inventory row stays `PART`. **The fourth consumer gate was considered and deliberately NOT built**
— a public-method liveness gate is a package, not a paragraph, and it is on the board as candidate
K. Version 3.0.0, untagged. `gen_placeholders.gd` is still at 230 of its 250 and is still the next
file to split.

**T5.10 (autosave, and the slot policy it needed first) is the row before it —
THE BASE AUTOSAVES, and `gameplay/autosave` is the SECOND of the three settings 2.0.0 removed to
come back with the feature it was waiting for.** Only `accessibility/subtitles` is left out, and it
still has nothing to caption. T5.5 refused to fake this one for a stated reason — `SaveSystem` had
no notion of the slot a run belongs to, so there was nothing for `true` to mean — which is why
**the SLOT was this row's design question and the trigger was the easy half.**

**THE ANSWER IS A DEDICATED SLOT ONE PAST THE MANUAL SIX.** `SaveSystem.AUTOSAVE_SLOT` is
`MAX_SLOTS`, written to `user://saves/autosave.json` — a name rather than a number, because
`slot_07.json` beside six `slot_NN.json` files reads as a seventh manual slot. **No manual list can
reach it, because every manual list iterates `MAX_SLOTS` and simply never counts that high** — no
filter anyone has to remember. Reserving slot 5 of the existing six was rejected twice over: an
autosave that can destroy a save the player made on purpose is the one thing an autosave must never
be, and it would have changed what slot 5 MEANS in every save file already on disk. Nothing on disk
changes meaning and `SCHEMA_VERSION` is still 1, which is why this is **2.5.0 and not 3.0.0**.
**Reading is deliberately wider than writing**: `latest_slot()` iterates `AUTOSAVE_SLOT + 1`, so
Continue resumes the autosave and the load list offers it as a row of its own, while the save list
— built over the identical files — cannot name it.

**THE POLICY IS A NODE, AND `game_root.gd` GAINED NOTHING.** `Autosave` lives under `GameRoot` in
`src/systems/autosave/`: not in `SaveSystem`, which owns the format and not the occasion and whose
header refuses exactly that second job; not an autoload, which would need an ADR. Both occasions —
`Events.game_ending` (so the window's close button is covered) and `Events.area_entered` — were
already on the bus, so **no signal was added**, and the WP-00 comment saying an autosave would go
in `game_root.gd` is gone because it did not have to. Three refusals, each proved by the ABSENCE of
a file and not only by a return code: the player's veto, a transition in flight, and no run in
progress. `request()` is public, so a consuming game's own occasion is one call and no edit to
`src/`.

**GOTCHA 65 CAME OUT OF THE TRANSITION GUARD AND IS THE HALF THAT TRANSFERS.**
`SYSTEMS_INVENTORY.md` item 6 has asked since WP-00 for "never autosaving during a transition", and
`Director.is_transitioning()` is obviously the guard — but `_run_transition` emits `area_entered`
and clears `_transitioning` **two statements later**, correctly. So reading the guard on the spot
would have refused **every arrival** and the feature would never have fired once, with nothing red
anywhere: no error, no warning, both ends of the wire correct, the guard behaving exactly as
specified. Gotcha 54's family with the unwired middle made of ORDERING. One
`await get_tree().process_frame` fixes it, and the assertion that pins it emits `area_entered`
inside a synchronous `run()` and requires that nothing was written.

**A SAVE IS A FILE, SO MOST OF THIS ROW IS PROVED IN THE SUITE** in a way T5.7's and T5.9's camera
work was not — including the policy's whole promise driven end to end: write the autosave, then
write into all six slots the save screen offers, and its header is still `equal` to what it was.
Suite 1,848 -> 1,898; four plants, each a real reversion, each exit 1. **The layer gate caught this
row's own trailing comment** — a `core` file naming `Autosave`, which is `systems`. **What the
capture carries is the INDICATOR**, which no assertion can: two runs of the standing regression
command differing by one line of `settings.cfg` — with defaults, `[save] Slot 6 written`,
`autosave.json` on disk and `Autosaved.` on the toast; with `autosave=false`, no log line, an EMPTY
saves directory and no toast, over an otherwise identical frame. **The standing dusk capture now
carries that toast**, which is the feature and not a regression. Version 2.5.0, untagged.
`gen_placeholders.gd` is still at 230 of its 250 and is still the next file to split. **CI green on
`0e99c86`, PR #39** — full checkout 1,898, stripped template 1,824, so all 50 of this row's
assertions survive the demo strip.

**T5.9 (screen shake, and the setting that scales it) is the row before it —
`accessibility/reduce_motion` NOW REACHES FOUR MOTIONS AND THERE IS NO FIFTH TO FIND, and
`gameplay/camera_shake` is the FIRST of the three settings 2.0.0 removed to come back with the
feature it was waiting for.** T5.5 refused to fake it, T5.7 wrote down as its own gap that a shake
would have to be reached in the SAME row as it was built, and both halves are here. The shake
lives on `HD2DCameraRig` (102 -> 138 of 250, so no new class was needed), is asked for through
`Events.camera_shake_requested(strength, seconds)` from anywhere, and the template's own asker is
`Gate.open_shake` — **defaulting to 0.0, so every gate already authored opens exactly as silently
as before.** The pattern was copied and not reinvented: `_authored_shake` beside `_authored_dof`
and `_authored_lag`, the scale folded INTO `shake_metres` rather than kept beside it, and the key
named as a `const` on the consumer.
**IT IS A DECAYING SINE AND NOT NOISE, WHICH IS THE DECISION THE VERIFICATION RESTED ON.** Random
jitter cannot be verified — two runs differ — so "exactly half as far" would have been an
unassertable claim. Five windowed runs of one command differing only by `user://settings.cfg`:
camera x of **0.302357 / 0.151178 / 0.000000** at `camera_shake` 1.0 / 0.5 / 0.0, best rigid image
offsets of **(+14,-12) / (+8,-6) / (0,0)** with residuals 0.0173 / 0.0125 / 0.0004 against 0.0513
/ 0.0402 / 0.0004 at zero, and **0.000000 with `reduce_motion` on**. The picture halves when the
number halves. Looked at rather than only measured: the whole world is displaced while the HUD and
the prompt sit at identical pixels, which is the difference between a camera shake and a screen
shake and the half no log line could carry. **Gotcha 64** came out of reconciling the two columns:
a camera TRANSLATION parallaxes, so a rigid-offset search under-reports it and the pixel count is
corroboration rather than measurement. Suite 1,829 -> 1,848; two plants, each exit 1, the second
aimed at gotcha 54 deliberately — cutting the `connect` line leaves both ends green and only the
connection assertion notices. Version 2.4.0, untagged. `gen_placeholders.gd` is still at 230 of
its 250 and is still the next file to split.

**T5.8 (a placeholder sheet whose facings are distinguishable) is the row before it —
BOTH SHEETS NOW DRAW A DIFFERENT FIGURE FOR EVERY FACING, and the row exists because
the owner played the game and said sideways movement "just slides to the side". It did.**
`character_placeholder.png` drew ONE POSE EIGHT TIMES: measured over the figure band, facing 4 —
the back, 180 degrees from the front — differed from facing 0 by **0.7%** of the cell, which was
the two eyes and nothing else, and **facings 2 and 3 were byte-identical**. The alt sheet was
worse: three of its four columns differed only by their column tally. **THE CODE WAS NEVER
WRONG** — `_aim` quantises the facing and `column_for_angle` derives the sector from the layout,
both asserted since Phase 1 — so this is gotcha 54's shape with the unwired middle made of
PIXELS, and it is **gotcha 62**. No file under `src/` changed except the debug capture tool.
Five poses and a mirror: front, three-quarter, side, three-quarter back, back, with facings 5-7
drawn as 1-3 flipped, which is what makes east differ from west by a whole asymmetric figure.
Worst facing pair now 7.5% (default) and 21.9% (alt), against 0.0% before.
**AND IT IS PHOTOGRAPHED — the same character walking north, east, south and west, which nothing
in this repository had ever captured.** `--facing-shots=<dir>` on `dev_gait_shots.gd`, columns
4, 2, 0 and 6 decoded out of `sprite.frame` and agreeing with four pictures that read as back,
right profile, front and left profile. T5.6 had recorded that absence as its own gap.
Suite 1,821 → 1,829 and the STRIPPED run 1,755, so all 8 new assertions survive the demo strip;
one plant (the old single-pose draw regenerated) at **exit 1, 6 failed**. CI green on `30c8304`,
PR #37.
Version 2.3.0, untagged. `gen_placeholders.gd` is at 230 of its 250 and is the next file to
split. **Gotcha 63 came out of writing the assertion**: a colour written into an RGBA8 image
does not read back equal to itself, and an IMPORTED texture is not the PNG, because
`process/fix_alpha_border` rewrites the RGB under transparent pixels.

**T5.7 (`reduce_motion` finished, and the shadow atlas) is the row before it —
`accessibility/reduce_motion` NOW REACHES ALL THREE MOTIONS THIS TEMPLATE DRAWS, and the shadow
atlas fix turned out to be a live defect in this repository rather than a hypothetical fork's.**
`ScreenFade` cuts instead of dissolving and `HD2DCameraRig.follow_lag` goes to zero, both on
`_authored_dof`'s veto shape: the setting may remove motion an area author authored and may never
add motion they did not. **THE SHADOW CONST WAS WRONG, NOT MERELY UNPORTABLE.** `_apply_shadows`
restored `2048` under a comment calling it "the engine's own default"; the engine's default is
**4096**, so every windowed boot of this repository ran at half the authored shadow resolution —
measured `boot = 2048` against `boot = 4096` on a real display server. `ShadowAtlas` (new, `core`)
reads the authored sizes before the first zeroing, and `settings.gd` went 144 → 139 of its 150.
That is **gotcha 61**, and its second half is the one that transfers: `_apply_display()` returns
early under `--headless`, so **no rung below the windowed capture executes that code at all** —
the suite could not have caught it however many assertions were aimed at the setting.

**AND THE CAMERA MOTION WAS PHOTOGRAPHABLE AFTER ALL, WHICH CONTRADICTS THIS ROW'S OWN
PREDICTION.** T5.5's honest limit — an instant reveal photographs identically to a finished one —
holds for the fade and does NOT hold for the camera, because a camera following a moving character
has no "finished" state to converge on. Two `--gait-shots` runs differing by one line of
`settings.cfg`: the whole world is translated **42 px** between them, and a brute-force offset
search over a static band puts the residual at 0.0268 at −42 px against 0.0975 at zero — a rigid
shift, so it is the camera and not the light. The fade is still proved by assertion only, and the
reason is written down rather than left as an omission. Version 2.2.0, untagged. Suite 1,798 → 1,821; four plants, each
exit 1, including the `[ext_resource]` one that re-proves gotcha 56 on a second node.

**T5.6 (a wholesale character swap, photographed) is the row before it —
PHASE T5'S LAST PROOF CRITERION IS MET AND THE PHASE IS CLOSABLE AT THE OWNER'S WORD.** The
repository held a sheet with a different GRID and a sheet with GAITS and **never one with both**,
so the phase's claim — a future game inherits working characters and changes only assets — had
been demonstrated in halves and never end to end. `character_alt.png` is now five blocks (idle,
walk, run, sneak, climb, 96x600) and `character_alt_layout.tres` is **the only layout in the
project that leaves no gait at -1**. The player was pointed at the pair, driven through all five
gaits through the real input path, and photographed. **NO FILE UNDER `src/` CHANGED FOR THE
SWAP** — it is two `ExtResource` paths in `player.tscn` — which is the claim the row exists to
test rather than a happy accident.

**THE CONTROL IS THE STRONGEST THING IN IT.** The same probe, the same code, the DEFAULT sheet:
blocks 0, 1, 2, **1, 1** — sneak and climb falling back to the walk block. That is the `-1`
fallback contract measured in the live game for the first time, rather than in an assertion.

**FOUR GOTCHAS, THREE OF THEM DEFECTS THIS ROW CREATED, ALL FOUR INVISIBLE TO ANY RUNG THAT DOES
NOT OPEN A WINDOW.** 57: a generator that clips to the IMAGE and not to the CELL draws into the
next cell, and the sheet still looks like people. 58: a sprite anchored by its feet has its bottom
rows eaten by the ground plane, so a tally drawn there cannot be read in a capture — a capture
STANDARD failing, not a drawing failing. 59: reading `sprite.frame` before the post-draw await
measures a different moment from the photograph, and the disagreement looks exactly like a content
bug. 60: `unproject_position` answers in the viewport's LOGICAL size, so at `--resolution
960x540` every crop was off by a factor of two. Two plants, each exit 1, and **plant 2 re-created
T5.3's defect exactly** — `climb_row = -1` gives `expected [2, 3, 4], got [2, 3, -1]` — which
makes good T5.3's own note that this row would have caught it. Suite 1,782 -> 1,798 (the last two are `doc_counts_test` gaining claims from this row's own prose). Version
2.1.0, untagged.

**T5.5 (the twelve settings with no consumer) is the row before it — EVERY ONE
OF THE TWENTY REMAINING SETTINGS IS NOW READ BY SOMETHING, and an assertion refuses a
twenty-first that is not. Nine were wired; THREE WERE REMOVED, because honouring
`gameplay/camera_shake` (BACK at T5.9 with its feature), `gameplay/autosave` and
`accessibility/subtitles` would have meant inventing three features rather than connecting
existing ones — there was no shake anywhere under `src/`, there is still no autosave and no
notion of the slot a run belongs to, and nothing is voiced. A row drawn to the player that cannot
do anything is worse than a dead constant, because the player finds out.
Each returns in one line plus one CSV row; `settings_screen.gd` is generated from `DEFAULTS` and
needed no edit. **THE FIVE `accessibility/*` WERE A TEMPLATE DEFECT AND NOT A MISSING FEATURE OF A
GAME**: the thing a text-size preference has to change is the project theme every screen in
`src/ui/` draws from, so a fork could not honour it without editing `src/`. `UiAccessibility`
under `UILayer` owns it now. Also fixed: `reset_to_defaults()` never called `_apply_locale()` (a
live bug), `set_dof_enabled()` had no caller, `Actions.JUMP` is gone entirely, and
`KeyBindings.rebind()` gates on `Actions.REBINDABLE` instead of `InputMap.has_action`.
**THE SEVENTH GATE WAS DELIBERATELY NOT BUILT** — the consumer question is asked as an ASSERTION,
because `Settings.DEFAULTS` is available at runtime and a `check_*` tool would have to parse
`settings.gd` to get it; T5.4's three went to `tools/` for the mirror reason. Writing it found a
third way to be a consumer (`audio_director.gd` handles a whole SECTION and computes its keys, so
five appear nowhere as literals) and a defect in this row's own work, which is **gotcha 56: a text
search for a wire stays green after the wire is cut, because an `[ext_resource]` line outlives
every node that used it.** Suite 1,728 → 1,782, and the STRIPPED run 1,654 → 1,708, so all 64
new assertions survive the demo strip. Eight plants, each exit 1; six settings photographed in
pairs. CI green on `31fea16`, PR #34.**

**T5.4 (the three missing enforcement gates) is the row before it — THE LADDER
IS SIX CHECKERS NOW, and the two new ones ask the question the first four never did: does a
declared thing have a CONSUMER? `check_signals.gd` requires every signal in the registry to have
an emitter; `check_layers.gd` enforces `core -> content -> systems -> gameplay -> ui`;
`check_boundary.gd` now fails a CSV row translating content that is not there, which closes
gotcha 48. Each was proved red by planting a real violation and green by removing it — the
exit codes are in the DEVLOG. THE LAYER GATE FOUND A REAL VIOLATION ON ITS FIRST RUN: 55 upward
references, of which 13 were `interaction_sensor.gd` sitting in `systems/` while typed on
`Interactable`, which is `gameplay`. It was in the wrong layer — a player component is not a
game-agnostic service — and is now `src/gameplay/interaction/`. That is gotcha 55, and it is the
same shape as `FIRST_AREA` in `core` before T1.2 with the roles reversed: the rule existed and
the enforcement did not. Suite 1,694 → 1,728.**

**T5.3 (delivering the gaits that were already declared) is the row before it.
PHASE T5 IS OPEN — the base as a reusable CHARACTER kit, which is what the owner says it is FOR:
a future game inherits working characters and changes only assets. `main` declares `1.2.0`;
`v1.0.0` and `v1.0.1` are the tags, and 1.0.2, 1.1.0 and 1.2.0 are deliberately untagged.**

**A FULL-BASE AUDIT FOUND THE SEVENTH INSTANCE OF THE CHARACTERISTIC DEFECT, AND T5.2 HAD CREATED
IT TWO COMMITS EARLIER.** `MoveState.CLIMB` never reached `CharacterVisual` at all.
`_physics_process` returns early while a climb owns the body, and `climb_step` touched the visual
only after resetting the state to IDLE — so of the three callers of `update_from_velocity` none
could ever pass CLIMB, and `climb_row` was exported, defaulted, range-limited, validated by
`problems()` and asserted by `art_contract_test.gd` while being **impossible to draw.** A ticked
exit criterion was false. **Both ends of the seam were asserted and the wire was not** — that is
now gotcha 54, and it is the most transferable thing the audit produced. Second defect in the
same function: `update_from_velocity` pinned `_frame = 0` whenever horizontal speed was zero, so
**no idle block had ever advanced a cell** — three of the shipped sheet's four idle cells were
undrawable while "more than one idle" sat on the exit criteria. Both fixed and both proved by
planting the revert: `1688 passed, 6 failed`, exit 1 without the fix; `1694 passed, 0 failed`
with it.

**WHAT IS LEFT OF THE T5.3 AUDIT'S LIST, and it is two items.** **Music ducking is entirely dead**
— `stop_music`, `duck` and `unduck` have no callers anywhere, and the only `duck` hit in the
repository is the phrase "duck-typed" in a comment; that is candidate E, and `DialogueRunner` is
the natural home. **`face_direction()` still has only test callers**, so nothing changes facing
while stationary; that is candidate C, and WHO may ask for a turn is an owner's seam decision that
T5.3, T5.5 and T5.6 all declined to pick silently.

Everything else on it is closed. **T5.4 closed the three enforcement holes** — the layer direction,
the signal registry's shape and `localization/` demo content all have gates now, and the corrected
measurement is **51 of 214 CSV rows** in a content namespace, not 59: the audit counted the eight
`item.category.*` rows, which are engine. **T5.5 closed the settings four** — `set_dof_enabled()`
has a caller, the twelve consumerless settings are nine wired and three removed, `Actions.JUMP` is
gone entirely, and `KeyBindings.rebind()` gates on `Actions.REBINDABLE`. **T5.6 closed the swap.**

**EVERY EXIT CRITERION IN PHASES 0 TO T4 IS TICKED, and each was PROVED rather than asserted** —
T5.1 closed the last four, one of which (the locale) was a missing FEATURE rather than a missing
proof. Phase 2 closed with it. **Phase T5 is the open one and has TWO criteria left**, neither of
them a defect: more than one idle, which is a chooser on top of machinery that now works, and a
turn in place, which is the owner's seam decision. The wholesale character swap was the third and
T5.6 photographed it. **The phase is closable, and closing it is the owner's call, not mine.**

**THE TEST RUNNER SILENTLY SKIPPED A LISTED CASE THAT DID NOT PARSE, AT EXIT 0.** `load()` on a
script with a parse error returns a `GDScript` that is **not `null`** and cannot be instantiated;
`_run_case` tested only for `null`, walked into `script.new()`, and **gotcha 24 already said a
GDScript runtime error aborts only the innermost frame** — so the failure two lines below was
never reached and the loop moved on. Measured: `=== 1608 passed, 0 failed, 0 skipped ===` and
exit 0, a last line byte-identical to a checkout where the file does not exist. T1.3 built two
mechanisms here because the first was measured and found wanting; this was the third hole in the
same wall, and `error_watch.gd` **had counted the error the whole time** — `_no_script_errors` is
read per case from inside `_run_case`, after `run()` returns, so an error raised on the way IN is
tallied by the watch and read by nobody. Two guards now: `can_instantiate()`, which names the
file, and a run-level check on any script error no named case accounted for. See gotcha 49.

**AND THE DOCUMENT'S ONE WORKED EXAMPLE DID NOT COMPILE.** `inventory.count()` is wrong twice
over: nothing declares `inventory`, and `Inventory` has no `count()`. Copying it verbatim is what
began the package. Three documents also gave three different gotcha counts — 44,
48 and 43, over a list of 48 — so `doc_counts_test.gd` now counts the
entries and requires every document stating the number to state that one.


**THE STACK LANDED AND THE TAG IS TAKEN.** For twenty-six PRs `origin/main` sat at `d0bf153` and
nothing had merged, which is exactly why the owner refused a tag on 2026-09-02. The stack turned
out to be one linear chain — every one of the 25 ancestor branches was contained in T4.2's tip,
71 commits ahead — so retargeting PR #26 to `main` merged all of it at once as `648bac1`, and
`v1.0.0` now names a tree that genuinely declares `base/version="1.0.0"`. Six PRs auto-closed as
merged; the other 19 cannot be retargeted (*"There are no new commits between base branch 'main'
and head branch"*) and were closed with a comment, so they read **Closed** rather than Merged
while their commits are all on `main`.

**PERFORMING `NEW_GAME.md` FOUND TWO DEFECTS, AND ONE WAS THE TEMPLATE.** The fourth document
walked, and like the three before it, it found what reading would not. A fresh clone was forked,
stripped and renamed from the document alone.

**`core_test.gd` FAILED A FORK THAT HAD NOT AUTHORED ITS FIRST AREA YET.** It asserted
`[game] world/first_area != ""` UNCONDITIONALLY, contradicting its own case name, the comment
eight lines below it, `NEW_GAME.md` section 4 and its own file header's MUST NOT line — four
statements that an empty setting is legal. Green in the full template and green in the stripped
one, because neither ever empties that field; red **only** in a real fork, in the exact window the
document walks an author through. `1537 passed, 1 failed, 20 skipped`, exit 1. The control shows
what it was really asserting: a first area naming a nonexistent scene made it pass. The claim now
lives only in `smoke_test.gd`, which gates on `Fixtures.area_ids()` and also requires the area to
resolve — planted, and a game WITH areas and an unset field is still red.

**AND THE PRUNE LIST NEVER LEARNED ABOUT QUESTS.** Written at T1.2, before WP-08 existed, it
omitted `quest.` — so a fork that followed the document shipped `quest.keepers_errand.*`, *"The
Keeper's Errand"* and *"three rose petals"*, inside its own game, with all four checkers and the
whole suite green. See gotcha 48: **no gate reads `localization/` for demo content at all.** Four
prose defects were re-measured rather than inherited, including a `--new-game` command that is
silently green without a `--` (gotcha 47).

*(Previously: T4.2, a second worked example authored from `AUTHORING.md` alone — `4f5f753`,
PR #26. Five defects, two in the template: `check_boundary` matched SUBSTRINGS, so an item called
`pear` failed on the word `appeared`; and `--stand-by` always resolved in the DEPARTURE area, so
no object in an authored area could be photographed at all. See gotchas 45 and 46.
Before that: T4.1, the version and the upgrade note — `799d957`, PR #25, and WP-15 was CLOSED by
the owner on the same day rather than built.)*

> **This is a TEMPLATE, not a game.** Read [`TEMPLATE.md`](TEMPLATE.md) — it is short, and the
> roadmap, the board and parts of this file were written before that reframing. The courtyard and
> the garden-keeper are *proof that a system works*, not the product.

## Which branch to work from

**`main`. Branch from it, target it, and stop stacking.** As of 2026-09-03 every package from
WP-01 to T4.2 is on `main` — PR #26 was retargeted to `main` and merged, which landed the whole
71-commit chain at once as `648bac1`, tagged `v1.0.0`. **T5.6 is on `claude/t5-6-character-swap`, branched from T5.5's `claude/t5-5-settings-consumers` (PR #34) because that row had not merged yet — so T5.5 and T5.6 are a two-deep stack and T5.6's PR targets T5.5's branch.** T4.3 was on
**`claude/t4-3-new-game-perform`**, branched from `main`.

**The stack is history and should not be built on.** Every `claude/wp-*` and `claude/t*` branch
named in earlier versions of this section is merged into `main` and kept only as history. Nineteen
of their PRs read **Closed** rather than Merged: once their commits were on `main`, GitHub refused
to retarget them (*"There are no new commits between base branch 'main' and head branch"*), so
they were closed with a comment pointing at #26. That is a GitHub limitation and not a gap in the
record — every commit is reachable from `main` and from `v1.0.0`.

**A one-package chat now starts:** `git checkout -b claude/<package> origin/main`, then
`--headless --import` before anything else, or every `class_name` global fails to resolve.

**Remote:** https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-

## What this is

A reusable BASE TEMPLATE for HD-2D exploration games. Godot 4.7.2, GDScript.
Visual reference: Octopath Traveler I/II/0, The Adventures of Elliot.

**No combat.** Explicitly retracted by the owner — not an oversight. **Art is deferred**;
everything runs on procedural placeholders, permanently â the template ships an art *contract*,
never art, and each game brings its own. The goal is a skeleton with a home for every system a
game built on this will need, so a new game is content and data rather than new architecture.

## Where it stands

Phase 0 complete, Phase 1 COMPLETE, Phase 2 well under way, **Phase T1 COMPLETE, Phase T2 COMPLETE
as of T2.2, Phase T3 COMPLETE as of WP-14b, and PHASE T4 COMPLETE as of T4.3 — all three exit
criteria are ticked and the repository is tagged.**

**WP-15 IS CLOSED and WP-10 stays OPTIONAL, so nothing is blocking.** The two rows that stood
between the board and Phase T4 are settled: the owner closed WP-15's remnant on 2026-09-02 rather
than build credits and an accessibility pass, both of which belong to a consuming game; crafting
was already optional and blocks nothing.

**THE RELEASE TAG IS TAKEN.** `v1.0.0`, on `648bac1` — the merge commit that landed WP-01 through
T4.2 on `main` as one 71-commit linear chain. It was refused on 2026-09-02 for a reason that had
not expired by the time it was asked again: `origin/main` was still at `d0bf153` and nothing had
merged, so the tag would have named either a commit lacking the version it claimed or an unmerged
branch. Landing the stack first is what made it honest. **Tagging is still a release action and
still the owner's** — T4.3 bumped `base/version` to `1.0.1` for its own fixes and deliberately did
NOT tag that, which is T4.1's precedent: stating a version is engineering, cutting a release is
not.

**THE BOARD WAS CLOSED ON 2026-09-04 AND REOPENED THE SAME DAY, AND BOTH DECISIONS WERE RIGHT.**
T4.4 put the choice to the owner — every phase closed, every document performed, nothing blocking
— and the answer was *nothing at all*, so the board was closed and that closure was recorded. The
very next question was whether the SKELETON was actually finished, and reading `ROADMAP.md`
instead of the closing summary answered no: **Phase 1 read COMPLETE while carrying three unticked
exit criteria, and Phase 2 read IN PROGRESS with one.** T5.1 closed all four by PROVING them, and
one turned out to be a genuinely missing FEATURE — the locale setting was wired to nothing at all.
**Every exit criterion in every phase is now ticked, and each was proved rather than asserted.**

**So the base is v1.1-complete, and what it is FOR has been sharpened.** The owner's intent is
reusable CHARACTER infrastructure that future games inherit by swapping assets — several idle
formats, several movement styles — so that a new game starts from a working base rather than going
in blind. That reframing names the next package rather than leaving it to taste, and the seam it
needs is already half-built: see the first gap below.

**A new session's default is still NOT to invent work.** A genuine defect, an unticked criterion,
or a seam the owner's reframing actually needs is a package. One invented so that there is one is
how the previous project reached 3,983 lines in a single file, twenty reasonable lines at a time.
**The version stays UNTAGGED at `1.1.0`** — 1.0.0 and 1.0.1 were each asked for separately and
granted, 1.0.2 and 1.1.0 were not.

**THE NEXT PACKAGE, and it is the owner's reframing made concrete.**
`SpriteSheetLayout.animation_for(moving: bool)` takes a **BOOLEAN**, so a sheet can carry only an
idle block and a walk block — run and sneak replay the walk row faster and nothing else. Meanwhile
`GameEnums.MoveState` has ten values, and `Events.player_state_changed(state)` is declared **and
emitted** by `PlayerController` and **listened to by nothing**. So the animation block should be
chosen by `MoveState` rather than by a bool, and then one sheet carries separate idle / walk / run
/ sneak / climb blocks and every future character — player or NPC, since both use `CharacterVisual`
unchanged — gets them by asset swap with no code. That is the **sixth** instance in this project of
something declared, validated and read by nothing, after `Gate.locked_key`,
`PathAction.refusal_key`, `ItemDb.reload`, `HD2DCameraRig`'s framing exports and the locale setting
T5.1 just fixed.


151 files, 13,728 code lines, 16 scenes, 2 areas, 4 items, 1 conversation, 1 schedule, 1 quest of
three steps (one of them a COUNT), 2 mapped areas, 2 path actions, 2 sprite sheet layouts,
3 tagged surfaces, 2 languages, **5 gait blocks on the swap sheet and 3 on the default one**,
1 shared area material, **21 settings and 21 consumers**.
Template version **2.4.0**, and that version is deliberately UNTAGGED — `v1.0.0` and
`v1.0.1` are the tags, each naming the tree that declares it.
Boots headless with **0 warnings, 0 errors**, and a run killed mid-load now shuts down clean too.

**Works, and verified by running it:** logging with rotation · signal registry (`events.gd`) ·
input actions · settings · save/load with atomic writes and versioning · plot flags · area
director with a re-entrancy guard and threaded loading · world clock · weather state · audio
buses · HD-2D camera rig with tilt-shift DOF · billboarded lit shadow-casting 8-way character ·
camera-relative walk/run/sneak · day/night lighting · screen fade · dev screenshot capture ·
**A CHARACTER WHOSE GAITS ARE DATA**: `animation_for` takes a `GameEnums.MoveState`, so idle,
walk, run, sneak and climb are separate cycles a SHEET names and every character - player or
NPC, both through the same `CharacterVisual` - picks up by asset swap with no code. An unnamed
gait inherits the walk block, so no sheet authored before T5.2 changed behaviour. Proved by
the asset's own pixels, by `sprite.frame` read live, and by a capture in which the player
walks in GREEN while the NPC beside them stands in BLUE - same sheet, same frame ·
**SETTINGS THAT ACTUALLY DO SOMETHING, ALL TWENTY OF THEM**: every key in `Settings.DEFAULTS` is
read by something and `settings_consumers_test.gd` fails on one that is not. Nine were wired at
T5.5 and three removed rather than faked. The placements are the lesson: bloom to
`EnvironmentDriver` because the Environment is that node's, but `video/shadows` to the shadow
ATLAS in `Settings` itself, because shadows are cast by lights an AREA AUTHOR placed and no node
owns the set of them - so a game that adds a hundred lights gets that setting for free and writes
no code. `UiAccessibility` under `UILayer` scales the project theme's font sizes from a cached
base, which is the seam a fork previously could not reach without editing `src/`. Six settings
photographed in pairs differing by one line of `settings.cfg` - text scale moved every font in the
UI including the HUD clock, shadows removed every cast shadow in the frame, and `set_dof_enabled()`
finally has a caller ·
**A LANGUAGE YOU CAN ACTUALLY SWITCH**: `Settings._apply_locale` reaches `TranslationServer`
on `_apply_display`'s reasoning — nothing else owns it — and `tools/gen_pseudolocale.gd`
generates an `en_XA` column so a second language EXISTS without the template pretending to
ship a translation. Two captures of the satchel differing only in that setting were read:
`Satchel / Key Items / Rose Key x1` against `[~~Satchel~~] / [~~Key Items~~] /
`[~~[~~Rose Key~~] x1~~]`, the row double-wrapped because the row format AND the item name
both come from the table. An unbracketed string on screen is therefore a hard-coded one,
which is `check_strings.gd`'s static rule made visible and including anything computed ·
**A SAVE THAT SURVIVES A REAL RELAUNCH**, proved in TWO PROCESSES rather than one reload:
`--save-state` / `--load-state` in `dev_probes.gd`, with the fresh process's boot line as
the control and the weather deliberately STORM because CLEAR is the boot default ·
placeholder art generator · line-budget checker · a headless test suite (1,798 assertions) that
builds its own content and passes with the demo deleted, and that FAILS on a case which crashes,
returns early, asserts nothing, or is not listed in the runner ·
an engine/demo boundary gate that derives the demo ids and fails on any of them in src/ ·
a LOCALIZATION gate that fails on a literal reaching a text sink and on any `*_KEY` const with no
CSV row — the second half proved to catch what nothing else could, since a planted typo passed
`check_content`, `check_boundary` and 1,517 assertions ·
a SMOKE TEST that drives a session end to end from fixtures and asserts it logged nothing ·
**CI that runs seven of the eight rungs on every push, PR and manual dispatch**, in two jobs (full
checkout and a stripped template), on a downloaded engine whose SHA512 and build string are both
verified — proved red on a broken assertion and green again ·
interaction sensor with ranking and Tab-cycling · Interactable contract · localized prompt and
toasts · readable signs · levers · gates gated by flag or by a carried key · per-object
persistence (ADR-0005) · typed item definitions found by directory scan (ADR-0006), and since T3.1 **ONE scan behind all
five catalogues** — `ContentScan.into()` fills each registry's own TYPED dictionary, so the five
façades keep their own content root, cache and accessor and nothing anywhere is a cast · an
inventory component with a capacity seam · pickups · take-all chests · a content validator ·
trigger volumes that fire on entry · a rest point that skips hours · authored climb points ·
a screen stack with real pause semantics · a token input lock · a HUD clock readout · an
inventory screen with focus navigation · one action-to-screen binding · a SECOND area, an
interior, and a door that really travels · a loading readout drawn above the curtain ·
shader warm-up behind black · a dialogue runner with conditions, branches and effects · a
non-pausing dialogue box with a typewriter reveal · an authorable .tres conversation format ·
a navmesh baked from each area's own geometry · an NPC that keeps a timetable and can be
talked to · schedules as authored data · path actions with a standing that gates them and
that they move Â· **weather you can see**: generated rain, snow and wind emitters driven by
`Weather.intensity()`, surfaces that darken and gain a wet clearcoat and then dry out over
twenty-six seconds, and a layered ambience bed on procedurally generated noise ·
**an exported build that finds its content**: a committed Windows preset, and a boot-time readout
of every catalogue's count and resolved paths that WARNS on an empty one in an export ·
**an art CONTRACT rather than art**: a `SpriteSheetLayout` resource carrying facings, frames,
cell size and animation blocks, with the direction sectors DERIVED from the facing count, so a
sheet with a different cell and frame count was swapped in with no code change at all · a project
`Theme` at `assets/theme/ui_theme.tres` wired as `gui/theme/custom`, holding every font size,
colour and inset the UI draws with, so one edit to that one file restyled the menu, the inventory
screen and the HUD at once. Both demonstrated by windowed captures that were LOOKED AT ·
**documentation a consumer can actually start from**: `AUTHORING.md`, `ART_CONTRACT.md`,
`TESTING.md` and an extension surface, routed to from `CLAUDE.md` and this file, and proved by
authoring a new area, NPC and conversation from them alone — plus a gate that fails on a
documented path or worked-example field the engine no longer has ·
**quests as authored data**: `Quest` / `QuestStep` .tres found by the fourth directory-scan
registry, every step naming a FLAG CONDITION rather than a callback, a `QuestTracker` that derives
progress from `Flags` and latches only the two things that cannot be derived, and a journal screen
on `J` — the placeholder quest is started by the keeper's conversation, advanced by the courtyard
lever and completed by the dais trigger volume, and **none of those three files was touched**.
Two windowed captures LOOKED AT, and the `J` key proved by a temporary probe that was removed ·
**equipment as a FLAG rather than a store**: `Equipment` is a component beside `Inventory` that owns
no dictionary — a slot is `equip/<wearer>/<item id>`, so it is already saved, already announced on
`flag_changed`, and a `Gate`, a `QuestStep`, a `DialogueChoice` and a `ClimbPoint` gate on what is
in hand **with no code and no new field in any of them**; the demo's equip-gated arch works with
`Gate` untouched. Enter on a satchel row holds or stows, proved by a temporary probe that was
removed. Three windowed captures LOOKED AT and READ · **a WORLD MAP whose discovery is a flag**: `AreaDef` .tres per area in `data/areas/`, found by the
fifth directory-scan registry, carrying the map position, the arrival spawn and
`known_from_start`; `WorldMap` under `GameRoot` turns `area_entered` into the flag `map/<area id>`
and emits the same `area_change_requested` an `AreaDoor` emits, so `Director` still owns every
transition; `MapScreen` on `M` draws one dot per def at its authored NORMALISED position in three
states, and names no area anywhere. Discovery needs no save section, no migration and no code in
anything that reveals a place — `--flag=map/<id>:true` is the second capture and a conversation
effect writes the identical key. Three windowed captures LOOKED AT and READ ·
**a refusal can carry an AUTHORED line**:
`Gate.locked_key` and `PathAction.refusal_key` had both been declared, validated by `check_content`
and read by nothing, and the player got a generic message about a different door ·
**an ATTRIBUTE with exactly one consumer, and GROUND you can hear**: `attr/<who>/<name>` is the
FIFTH namespace over `Flags` — an integer number of steps clamped to ±4, with no resource, no
registry and no save section — and `PlayerController.current_speed()` scales every gait by `pace`,
measured windowed at 2.861 m against 4.687 m over the same 60 frames. The attribute's NAME is a
const on its consumer, so an attribute nobody reads has nowhere to be written down.
`metadata/surface` tags an area's geometry and is INHERITED from the nearest tagged ancestor, so
the courtyard tags `Terrain` once and overrides two floors; a `Footsteps` component probes down,
steps every 1.7 m and GENERATES the sound from the surface's name, so `sand` is audible the day a
game writes it and no table of surface names ever exists under `src/`. Three surfaces reported
correctly in a windowed run, one of them inherited, and the sound following each ·
**"BRING ME THREE PETALS", AND THE QUEST SYSTEM STILL DOES NOT KNOW WHAT AN INVENTORY IS**:
`Inventory` publishes each count as `bag/<carrier_id>/<item id>` — the SIXTH namespace over `Flags`
and the first whose value is a number — so a step is `AT_LEAST 3` on that key, `QuestStep` gained
no field and `QuestTracker` gained no knowledge, and the dependency points DOWN from `gameplay` to
`core` rather than up from `systems` to `gameplay`. The mirror is declared DERIVED, so it is
readable and announced but never saved and no save version moved. A step reopens when a count falls
and a completed quest does not — WP-08's asymmetry, tested at last against something that really
decrements. The journal draws `— Gather three rose petals.   2 / 3` and still reads no flag. Two
windowed captures LOOKED AT and READ, differing by exactly one petal ·
**THE LOOK OF AN AREA IS DATA, AND ONE OF THE THREE SEAMS TURNED OUT TO EXIST ALREADY**:
`assets/materials/wood.tres` is one shared `StandardMaterial3D` that two areas point at, and
tinting that one file turns the courtyard's dais and the hall's plinth magenta together — a
library of ONE, because a tiling rate belongs to the surface and not the substance, so the other
five materials are genuinely not duplicates; the twenty post-stack numbers in
`EnvironmentDriver` are `@export`s at exactly the values T2.1 shipped, so
`volumetric_fog_density = 0.06` on one area's driver node hazes that area and no other; and
`HD2DCameraRig`'s framing exports, which have been there since it was written and which no area had
ever set, now give the interior 36 degrees at 9.5 m against the outdoor 27 at 14 — one run logs
both rigs. A PNG a game drops in imports correctly first time, because `[importer_defaults]` sets
`detect_3d/compress_to = 0`, which is the section T2.1 could not check against the API dump and
T3.2 settled by MEASURING instead. Six windowed captures LOOKED AT and READ, each pair differing by
one edit to one file, and six gates proved red with the real violation — one of which was the test
itself, passing while the thing it checked was deleted ·
**A CONSOLE YOU CAN TYPE IN AND AN OVERLAY YOU CAN READ WHILE THE GAME RUNS, AND THE SIX COMMANDS
ARE THE COMMAND LINE'S OWN**: `goto`, `flag`, `time` and `give` have ONE body each in
`src/systems/debug/dev_commands.gd`, which `dev_stage.gd`, `dev_capture.gd` and
`DebugConsoleScreen` all call, so what you type in the console is exactly what you pass after the
bare `--`. The console is a `UiScreen` on F1 declaring `pauses_world` — no second pause mechanism —
and it lives under `src/ui/`, INSIDE the boundary gate, because it names no content. The overlay is
a `CanvasLayer` on F3 beside the HUD that never enters the stack, reporting frame time, fps,
process time, draw calls, node count and ORPHAN count. Absence from a release export is MEASURED
with a control: a debug export logs both armed lines and a release export logs neither. Three
windowed captures LOOKED AT and READ, one of them a checkable prediction — launched at
`--time=12:00 --freeze-time`, handed `time 18:40`, and the HUD reads `Day 1 | 18:40 | Dusk` over a
dusk-lit courtyard.

**Not built:** command HISTORY and autocomplete in the debug console, and a watch list of live
flags — deferred by the row, and the transcript is deliberately un-scrollable for the same reason:
a console that needs scrolling wants history, and half of it is worse than none · a console command
that mutates content on disk, also refused by the row · a GRAPH on the performance overlay, which
is a second thing to get wrong when the averaged number already answers the question ·
`Actions.DEBUG_FREECAM` on F2, declared since WP-01 and still bound to nothing — inventing a free
camera was not a dev-tools row's job, and naming it is cheaper than a reader wondering whether F2
was missed · item instances (durability) ·
footstep PARTICLES, and a second attribute with a consumer — naming one is free, reading one is a
line of engine code ·
an equipment SCREEN, a character sheet, and no attribute gates an interaction ·
item tooltips, sorting and drag-and-drop · fog of war, map zoom and pan, map art, travel costs and
objective markers on the map — `quest_advanced` has an emitter, so markers are a listener and one
more marker state · **a quest step that TAKES the items it counted** — a step can REQUIRE N of an
item id since T3.3, and WP-08's layer refusal is unchanged: a completed quest emits
`quest_completed` and stops, so handing anything over is a listener's job · a DEPARTURE-side travel
point, which is a game policy rather than a mechanism · branch protection, so CI reports but nothing stops a
red branch merging · no CI export rung (a GPU-less runner has no platform template) · export
presets for platforms other than Windows · a release-build content readout, since the debug gate
means a release export prints nothing · a counted step whose CARRIER is validated by a gate — the
item id is checked, the carrier is an `@export` in a scene `check_content` does not open. The theme does not yet set the
`Button` styleboxes, so a light palette leaves every menu row drawing Godot's default dark
panel — the seam is right and in the same file, simply unpopulated. Third package to leave
them, each time for a stated reason.
Git LFS stays off, and T3.2 turned that from an omission into a written refusal with the reason
and the turn-on steps — stated once, in `ART_CONTRACT.md`.

## Known defects

**Fixed 2026-08-27 in WP-09, and both had been wrong for packages while every rung stayed green:**

1. **`Gate.locked_key` and `PathAction.refusal_key` were DECLARED, VALIDATED AND READ BY NOTHING.**
   Since WP-01 and WP-07 respectively. Authored content set them, `check_content` required a CSV
   row for them, and `interact_prompt.gd` computed `refusal.<reason>` from the enum and never asked
   the object — so every gate in the game told the player "It will not budge. Something holds it
   shut." whatever its author had written, and `PathAction.refusal_key`'s own comment claimed it was
   "shown for the LOW_STANDING refusal". This is gotcha 2's shape in its most invisible form: a
   message that is merely WRONG looks exactly like a message that is right, so eight rungs, both CI
   jobs and 1,149 assertions were green over it. Found by looking for where an equip-gated gate
   would say "you need a light". `interaction_refused` now carries a `message_key`, and the
   authored line is photographed in WP-09's second capture.
2. **The satchel screen redrew only on `inventory_changed`.** So equipping from anywhere other than
   a row press left a held item drawn as merely carried — the first WP-09 capture photographed
   exactly that while the log said `player equipped`. Found by a capture, not by a gate; the screen
   was still right about the bag, so nothing could fail. See gotcha 34.

**Also fixed 2026-08-27 in WP-09, and it is gotcha 32 for the third time:** `--open-inventory` did
not wait for the area, so with `--new-game` it drew over the title screen and the arriving
transition unwound it. Third staging flag to need that wait after `--open-menu` and `--flag`, and
`dev_stage.gd` now says any flag that puts something on screen needs it.


**Fixed 2026-08-26 in T2.0, and it was invisible until an export existed:**

1. **A missing `[editable]` marker silently dropped every instance override in an exported build.**
   `courtyard.tscn` set `object_id`, `label_key` and `conversation_id` on two nodes INSIDE its
   instanced `npc.tscn` with no `[editable path="Actors/Keeper"]`. From source the text loader
   applies them; an export converts `.tscn` to binary `.scn` and the conversion DROPS overrides on
   a non-editable instance. So the shipped keeper had no identity, no prompt, no conversation and
   never ran its schedule — while every ladder rung, both CI jobs and 930 assertions stayed green.
   This project hand-authors its `.tscn` files, so the marker the editor would have written is
   exactly what a hand-authored scene forgets. Now a `tools/check_content.gd` gate, proved red on
   the real bug. See gotcha 27.

**Fixed 2026-08-26 in T1.3, and it had been wrong since ADR-0006:**

1. **`ItemDb.reload()` had never called our function.** `Script` declares `reload()`, and
   `ItemDb` as an identifier IS the GDScript object, so the static call dispatched to
   `Script.reload()` — which reloads the script and resets its static variables. That happens to
   do exactly what our `reload()` was written to do, so nothing broke and no test could see it.
   It surfaced only when a redirectable `content_dir` was added: the assignment stuck, and the
   next `reload()` silently reset it. Proved with a print inside `_ensure_loaded()` that
   `ItemDb.reload()` never reached. All three registries now expose `rescan()`. Fourth
   native-name collision in this project, after `Area3D.priority`, `class_name Container` and
   `DictRead.get_name` — see gotcha 17, and note that a *static* function is no exception.
2. **The test suite could not fail on a crash**, which invalidated every green result the project
   had. Fixed with two mechanisms, because the first was measurably not enough — see gotcha 24.

**Fixed 2026-08-26 in T1.2, both found by doing rather than by a gate:**

1. **`dev_capture.gd` had failed to parse since the WP-13 merge and every rung stayed green.**
   `await _settled()` was added without the function, so F12, `--shot`, `--time`, `--freeze-time`
   and `--weather` were all dead for a package. See gotcha 22: `0 warnings, 0 errors` counts
   `Log.error` calls, not engine parse errors. Found by grepping `--headless --import`.
2. **A stripped template failed its own content gate on step one of `docs/NEW_GAME.md`**, because
   the three content registries reported an empty folder as a problem. Found by actually
   performing the checklist instead of writing it.

**Fixed 2026-08-26 in WP-13, both found by running it and neither by a static gate:**

1. **`SurfaceWetness` was driven before it had collected anything to drive.** `WeatherVisuals`
   readies before it, and `apply()` skips a value that has not moved â so arriving in an area
   mid-downpour would have shown a dry courtyard forever. Found by reading the line ORDER in the
   boot log, not by a failing test.
2. **Every `play()` against the Dummy audio driver leaks an instance.** See the audio gotcha.


**Fixed 2026-08-26 in WP-06. Three found by running it, eight more by an independent
adversarial review of code that had already passed every gate:**

1. **A HARD SOFT-LOCK in dialogue.** `advance()` asked the AUTHORED choice array while the
   screen drew the FILTERED one, so a node whose every choice failed its condition rendered a
   box with no buttons that would not advance and could not be escaped, holding the player's
   and the sensor's tokens until the process was killed. `advance()` now reads
   `available_choices()`.
2. **The navmesh baked EMPTY and said nothing.** `SOURCE_GEOMETRY_ROOT_NODE_CHILDREN` parses
   children of the `NavigationRegion3D`, which has none. An empty bake takes 0ms, so "baked in
   0ms" is what the failure looks like. Now group-sourced, and the log reports the polygon count
   and errors at zero.
3. **The navmesh bridged a step the body cannot climb.** `agent_max_climb` was above the dais's
   0.4m riser, but `move_and_slide()` has NO step-up, so the NPC walked into it and stopped
   while the agent insisted it had not arrived â silently. See the settled decision below.
4. **A non-`Node3D` area root left the curtain black forever**, with the old area already freed
   and `current_area_id` empty, so not even `reload_current_area()` could recover. Every failure
   path now goes through `Director._abandon()`, which lifts the fade on the way out.
5. **A failed load left "Loading" pinned over the game** for the rest of the session. It now
   hides when the curtain lifts, which every path out of a transition does.
6. **A refused transition left a save's position override armed for the NEXT one**, teleporting
   the player to coordinates authored for a different area. Cleared on every path that does not
   place the player.
7. **The loading readout could never appear during the boot load** â the one load, on a cold
   cache, that most needs it. Progress now shows it as well as updating it.
8. **Nothing closed screens on an area change; `UiRoot.close_all()` was dead code.** Travel does
   not lock the player, so a conversation opened during the fade-out kept running over the new
   area with its speaker freed. `UiRoot` now unwinds on `area_unloading`.
9. **Choice buttons and `choose(index)` indexed two different lists.** The world runs behind a
   dialogue box, so a flag written while it is open shifts every index between drawing a button
   and pressing it. The UI now calls `take(choice)` with the object it drew.
10. **`InteractionSensor._on_availability_changed` swapped `_current` without resetting the
    hold**, so a part-finished hold fired an adjacent object that became available mid-hold.

**Fixed 2026-08-26 in WP-05, found by a capture:**

1. **An unquoted comma in `strings.csv` had been eating text since WP-01.**
   `object.lever.gate.on` was cut at its comma, so the lever toast had read `Somewhere north`
   for three packages. Nothing caught it: the key still resolved and `tr()` still returned a
   string. Both offending rows are quoted, and `check_content.gd` now FAILS any row that parses
   to more than two columns. A translator adding a comma cannot reintroduce it silently.

**Fixed 2026-08-26 in WP-04. All three were invisible until a SECOND area existed, and all
three compiled cleanly and passed every static gate:**

1. **`DictRead.get_name()` never worked, and loading a save had never restored the area.**
   `Resource` declares `resource_name` with the getter `get_name`, and a GDScript *is* a
   Resource, so the static call dispatched to the native zero-argument method and threw at
   runtime. Its one caller was `Director._apply_save`. With one area it looked fine, because
   you always reloaded into the area you were already in. Now `get_string_name`.
2. **The interaction prompt survived an area change**, offering an Iron Lever in an area that
   no longer existed. `InteractionSensor` pruned its candidate list but never validated
   `_current`, and **a freed object compares EQUAL to `null` in Godot 4** — so
   `best != _current` reported "unchanged" and nothing was re-announced. `_announced_id: int`
   now carries the identity, because an int survives the object it names.
3. **`follow_clock = false` did not mean "do not use the clock".** It only stopped the driver
   *updating*; `_ready()` still sampled the clock once, so the first interior ever built was
   pitch black when entered at 02:30 and fine at noon, from the same scene file. An interior
   now has its own authored ambient, fog and background.

**Fixed 2026-08-26 in WP-01, both found by running the engine, neither visible in the source:**

1. **A climb oscillated on its corner forever.** The path turns at the top on purpose — a
   straight line from the foot of a ladder to the ledge above passes *through* the ledge, and
   a climb that writes `global_position` has no collision left to stop it. But the corner has
   to latch: without it, the frame after arriving at the waypoint steps off towards the
   target, and the next frame steers back. 600 test steps, no convergence.
2. **A trigger volume near the area origin fired at spawn.** The player exists at the origin
   for one frame before `Director` places them on the spawn marker, so the courtyard's dais
   trigger toasted from three metres away, on every load. `TriggerVolume` now arms two
   physics frames late.

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
- **THE PLACEHOLDER SHEET DRAWS ONE POSE EIGHT TIMES, so no facing is visible in any picture.**
  Measured on `character_placeholder.png`: every facing's walk cell is within 4% of facing 0's,
  and facing 4 — the one 180 degrees away, the back view — differs by **0.5%**, about eight pixels
  of a 1,536-pixel cell. The walk cycle itself is 1.6-5.8%. So a character moving sideways is a
  front-facing figure translating across the screen, which is what the owner reported as "they
  just slide to the side" on 2026-09-05. **The CODE is correct** — `_aim` quantises the facing
  (`facing_test.gd`) and `update_from_velocity` advances the cycle (`gaits_test.gd`, T5.3) — the
  sheet has nothing different to draw. Same shape as gotcha 54 one level up: the facing machinery
  is asserted at both ends and invisible in every capture ever taken. Fixable inside
  `tools/gen_placeholders.gd` alone, no `src/` and no art-contract change, and it is candidate J.
- **Three settings were REMOVED rather than wired, and each is a real feature a game will want.**
  Screen shake, autosave and subtitles. Autosave is the largest: `SaveSystem` has no notion of the
  slot a run belongs to, so it needs a slot POLICY before it needs a trigger, and picking one is a
  design decision rather than a wiring. All three are candidate rows.

## Decisions already made — do not re-litigate

- **A TURN IN PLACE IS BUILT, BOTH HALVES, AND THE NPC HALF BELONGS TO `NpcBrain` — THE OWNER
  ANSWERED THIS ON 2026-09-06 AND IT IS NOT THE ASSISTANT'S TO REOPEN.** T5.3 declined to pick the
  seam silently and candidate C has carried the question ever since: `face_direction()` on
  `CharacterVisual` has only test callers, so nothing in the game changes facing while standing
  still. The answer is **both askers**, not one — the player turns to face what they interact with,
  and an NPC turns to face the player when a conversation starts. Deleting `face_direction()`
  instead, which is what T5.11 did to `stop_music()` on the same reasoning, was offered and
  **rejected**: it is a seam a consuming game would plausibly want, and unlike the alias it has no
  second spelling. The NPC half lives on **`NpcBrain`**, because the brain already owns where an NPC
  goes and what it does and turning to face someone is behaviour — which keeps `Speaker` at the 17
  lines its header promises, and means a speaker with no brain (a plaque, a parrot) does not turn,
  which is correct rather than a gap. The player half is `InteractionSensor`, which already knows
  the current target and already lives on the player. **T5.8 is what makes this worth building at
  all**: while every facing drew the same picture a turn in place was invisible, and now every
  facing draws a different figure.

- **THE TEMPLATE'S VERSION IS `[template] base/version`, NOT `application/config/version`.** The
  obvious field is the wrong one, and `NEW_GAME.md` § 4 already said why without noticing: it tells
  a fork to reset it to `0.0.1` on day one, so after exactly one fork it records the GAME's version
  and nothing remembers which base the game came from. Two facts, two settings. It is a project
  setting rather than a `const` under `src/` for the same reason `[game] world/first_area` is —
  reading a `const` means opening engine code, and the premise of the whole boundary is that a
  consuming game does not read `src/`. A fork LEAVES THAT LINE ALONE.
- **`TemplateVersion` IS ITS OWN FILE AND WILL NOT BE FOLDED INTO `GameConfig`.** `GameConfig`'s
  header says it owns "the values a game author writes once"; the base's version is the one value
  a game author must NEVER write. Folding them would make that sentence false to save a small file.
- **THERE WILL BE NO AUTOMATIC UPGRADE AND NO COMPATIBILITY TABLE.** `UPGRADING.md` § 4 states both
  in writing, so shipping either would contradict the document. A table is a list of exceptions to
  the promise, and the promise is the product; `same_major_as()` and `compare_to()` are the whole
  surface. Git shows a diff and the game's author decides.
- **"IS THE BASE DONE" IS A QUESTION ABOUT `ROADMAP.md`, NOT ABOUT THE CLOSING SUMMARY — AND ON
  2026-09-04 THE TWO DISAGREED.** T4.4 closed the board on the owner's instruction and recorded
  the closure; asked an hour later whether the skeleton was finished, the honest answer came from
  the criteria and was **no**. Phase 1 read COMPLETE with three unticked exit criteria and Phase 2
  read IN PROGRESS with one, and one of the four was a missing FEATURE rather than a missing proof.
  T5.1 closed all four by proving them. **Two rules come out of it.** A phase marked complete "except
  for the hard ones" is a phase whose hard parts nobody has the answer to — and here that hid a
  system wired to nothing for the whole life of the project. And **a summary is not a state file**:
  when they disagree, the file with the checkboxes wins, which is why `CONTEXT.md` says to read the
  roadmap rather than the last package's write-up. WP-10 crafting is still OPTIONAL and unbuilt,
  and the reasoning for closing the board still stands for work with no criterion behind it: a
  package invented so that there is one is how the previous project reached 3,983 lines in one file.
- **WP-15's REMNANT IS CLOSED, BY THE OWNER, 2026-09-02.** Credits name a team a template does not
  have, and an accessibility pass over placeholder art and a UI every game restyles is a pass over
  something designed to be thrown away. What the template owes accessibility is the SEAMS, and they
  exist and are proved: the project `Theme`, rebindable input, and no timed input anywhere because
  there is no combat. Recorded rather than deleted, the way WP-10 is marked OPTIONAL.

- **A DEV TOOL THAT NAMES NO CONTENT BELONGS UNDER `src/`, NOT IN THE EXEMPT DEBUG DIRECTORY.**
  `DebugConsoleScreen` is a `UiScreen` in `src/ui/screens/` beside the journal and the map. The
  permission is that a command takes its argument from whoever typed it, so `goto courtyard` is
  input rather than a literal — but the REASON is stronger than the permission:
  `src/systems/debug/` is exempt from `check_boundary.gd`, so filing the console there would have
  bought it an exemption it does not need and switched off the gate that ought to be watching it.
  The rule generalises: the exemption is for code that must name the demo, and nothing else goes
  looking for it.
- **THE COMMAND LINE AND THE CONSOLE ARE ONE IMPLEMENTATION, AND THE VERB RETURNS ITS REPORT.**
  `DevCommands` holds `goto`, `flag`, `time` and `give`; `dev_stage.gd`, `dev_capture.gd` and the
  console all call it, and the console's argument is byte-for-byte the `--verb=` argument. Each
  verb returns a sentence rather than logging one, because a staging flag wants that line in the
  log and a console wants it on screen — a shared body that logged would have forced one of them
  to read the log to find out what happened.
- **THE CONSOLE PAUSES THE WORLD AND THE OVERLAY DOES NOT, WHICH IS ONE DECISION MADE TWICE.**
  Both answer *should the world be stopped?* and the answers are opposite for the same reason: a
  clock that runs while you type at it photographs a moving target, and a frame time is worthless
  unless frames are still happening. So the console declares `pauses_world` and `UiRoot`'s table
  does the rest, and the overlay is a `CanvasLayer` at layer 101 that never enters the stack, holds
  no pause, takes no focus and answers no cancel. **Anything that must be READABLE DURING
  gameplay is not a screen** — that is the general form.
- **A DEV TOOL'S CHROME IS TEXT AND ITS OUTPUT IS DATA.** The console's title and input hint are
  localization keys like every other screen's; its transcript is echoes of a typed command and the
  values that came back, and the overlay is numbers, neither of which any `strings.csv` could
  hold. This is the line `check_strings.gd` forces a developer surface to draw, and drawing it
  deliberately is the difference between satisfying the gate and routing around it.
- **A GUARD ASSERTED BY A TEXT SCAN MUST BE ANCHORED UNIQUELY, AND THE SCAN MUST SKIP COMMENTS.**
  `OS.is_debug_build()` is true everywhere the suite can run, so the release gate can only be
  asserted by reading source — and WP-14b's first attempt would have passed over a deleted guard
  twice over: once because the file EXPLAINS its gate in a comment, and once because the same
  fragment appeared in two functions. The second was fixed in the code rather than in the test.
  See gotcha 43.
- **GDScript, not C#.** The installed engine is the standard build; .NET is not available.
- **Warnings are errors.** `var x = 5` does not parse. Read untyped data via `DictRead`, never
  `int(value)` on a `Variant`.
- **Input actions live in code** (`src/systems/input/actions.gd`), so the editor's Input Map
  panel looks empty. Intentional — ADR-0003.
- **Ten autoloads, no `GameManager`.** Adding one requires an ADR.
- **THE STRING AUDIT CHECKS SINKS AND DECLARATIONS, NEVER LITERALS.** `check_content.gd` refused a
  general hard-coded-string audit in writing, and that refusal is right: nothing in a line of text
  says whether `"world"` is a log category, a flag namespace or a sentence for a player, and a
  partial tool that looks complete is how 409 passing checks happened. `check_strings.gd` (WP-14)
  therefore never inspects a literal and guesses. It asks two questions with mechanical answers —
  does the right-hand side of a **text sink** go through `tr()`, and does every `*_KEY` **const**
  name a real CSV row — because whatever reaches `.text` is player-facing by construction whatever
  it contains. Do not "improve" it into a literal classifier; that is the tool `check_content.gd`
  turned down, and its header says why.
- **A SMOKE TEST DRIVES A GAME, NOT THE DEMO.** WP-14's row said "the whole demo" and was re-framed
  in the commit that took it. `tests/unit/smoke_test.gd` composes the session from
  `tests/framework/fixtures.gd`, and its one game-shaped block asserts only that
  `GameConfig.first_area()` RESOLVES — never what it is called — and skips, counted, in a stripped
  checkout. The rule is TESTING.md's and `check_boundary` enforces it over `tests/unit/`; a smoke
  test is not an exception to it just because "end to end" sounds like it should name real places.
- **ONE content scan, five typed façades — and the base is on the RESOURCE, not the registry.**
  `ContentScan.into()` is the only scan-and-validate in the project; `ContentEntry` is the base
  every catalogued `.tres` extends. Each registry keeps its own `content_dir`, its own typed
  cache and its own typed accessor, because a base-class `static var` is ONE storage shared by
  every subclass (gotcha 37) and because an untyped accessor is against non-negotiable #2.
  Settled by T3.1 after WP-08 and WP-11 costed it twice. Do not re-argue it, and do not "finish
  the job" by moving `has()`/`count()`/`rescan()` onto a base — those name their own type.
- **No jumping.** Vertical movement is authored: a `ClimbPoint` names two markers and asks
  `PlayerController.begin_climb()`. The climb turns its corner at the *top* end, both going
  up and coming down, so it never cuts through the ledge.
- **A climb is refused, not hidden.** Mid-air gets `RefusalReason.NOT_GROUNDED` with a
  message, on the same reasoning that makes a locked gate offer its prompt.
- **A trigger volume never names its consequence.** It sets a flag and emits
  `Events.trigger_fired`; anything may watch either. Same reasoning as the lever.
- **A time skip is one event.** `Clock.skip_to_hour` routes through `set_time`, never
  `advance_minutes` — an eight-hour sleep must not emit 480 `minute_passed` signals.
- **Inventory is a component, not an autoload.** Interactables are handed the interactor, so
  `Inventory.of(who)` needs no global and works for an NPC or a stash too. A global would
  hard-code "one bag in the universe" into every interactable.
- **Capacity is unlimited**, behind `can_accept()`. Slots or weight go in that one method.
- **`ItemCategory` stays an enum.** The eight values are a closed set and a new *item* never
  needs a new category, so it does not violate the no-code-per-item rule.
- **Item instances are deferred** until something actually has durability; `{id, count}` is
  enough. Never persist an enum ordinal — persist ids.
- **Input is held by NAMED TOKENS, never a boolean.** `InputLock` on the player and on the
  interaction sensor. `lock(&"dialogue")`, `release(&"dialogue")`. A boolean broke the moment
  WP-01 gave it a second caller, and a counter would strand instead. Do not reintroduce
  `set_input_locked(bool)` as a convenience over the top of it.
- **A screen never pauses anything itself.** It declares `pauses_world` and `closes_on_cancel`
  as a `UiScreen`, and `UiRoot` does the rest. `UiRoot.is_gameplay_input_allowed()` is the one
  truth; everything else listens to `Events.ui_mode_changed`.
- **A screen declares its flags in `_init`, never in `_build`.** `_build` runs from `_ready`,
  i.e. after a caller has had its chance to override one, so setting `pauses_world` there
  silently discards an overlay's request to keep the world running. `StubScreen` did exactly
  that and made the overlay assertion in `ui_test.gd` pass vacuously for a whole package.
- **The HUD is a layer, not a class.** The clock, the prompt and the toasts are independent
  siblings under `UILayer`, each subscribing to the one signal it draws. There is no `Hud`
  node owning them, and adding one would only create somewhere for the fourth readout to
  accumulate.
- **An inventory screen is handed its carrier**, `InventoryScreen.for_carrier(who)`, on the
  same reasoning as `Inventory.of(who)`: the same window shows an NPC's satchel or a stash.
- **One node binds actions to screens.** `ScreenKeys`, under `UILayer`. The journal key and
  the map key join it there rather than each finding a different home, which is how a boolean
  per screen was born last time.
- **A dialogue condition is a CLOSED SET of comparisons, never an expression.** `FlagTest` has
  six values, `FlagWrite` has five. The moment a conversation can hold an expression it needs a
  parser, error reporting and a sandbox, and the .tres stops being reviewable in a diff. When
  six are genuinely not enough, add a seventh, not a grammar.
- **A conversation is an ORDERED ARRAY and the runner falls through.** The entry point is the
  first node whose condition passes, not `nodes[0]`, and a skipped node falls through to the
  next in authored order. That is what makes "if we have met, greet me differently" two nodes
  and no wiring. Effects fire on ARRIVAL, so a node has the same consequence however reached,
  which is why a choice has a condition but no effect.
- **A failing choice is OMITTED, not shown disabled** — the opposite of a locked gate, on
  purpose. A gate you cannot open teaches you there is something to come back for; a reply you
  cannot give teaches you only that the writer thought of it. So `choose(index)` indexes what is
  ON SCREEN, not the authored array.
- **A conversation is NOT SAVED.** Persisting a position writes a node id into the save file,
  making every node id in every .tres a permanent public identifier — rename one and old saves
  load into a position that no longer exists. The section exists, is always empty, and logs what
  it discarded. A save taken mid-conversation reloads with the conversation over and control
  returned.
- **A waypoint must be somewhere the BODY can walk, which is not the same as somewhere the
  navmesh covers.** A `NavigationMesh` bakes `agent_max_climb` into the walkable surface and
  will happily bridge a knee-high step, but `CharacterBody3D.move_and_slide()` has no step-up at
  all. This game has no jumping and authored vertical movement, so the climb limit is kept BELOW
  anything the body cannot manage and waypoints sit on the ground.
- **A navmesh is baked at load, never checked in.** A committed one goes stale the moment
  someone moves a wall, and a stale navmesh fails silently. It is baked behind the same curtain
  that already hides the shader warm-up, and the polygon count is logged so an empty bake is an
  error rather than silence.
- **A schedule names a WAYPOINT, not a position**, and has no `until_hour`: an entry runs until
  the next begins and the last wraps past midnight, so a day is always completely covered and
  two entries cannot disagree about who owns 14:00.
- **A UI takes a dialogue choice by IDENTITY, never by index.** `take(choice)`, not
  `choose(index)`. A conversation leaves the world running, so any flag written while the box is
  open can shift every index under the player's finger.
- **`Weather` renders NOTHING, and `WeatherVisuals` decides NOTHING.** Every number in the
  visuals is read from `Weather`; the toast on a change is emitted by the visuals, so the state
  machine still does not know a screen exists.
- **A weather emitter is TOLD its weight; it never polls.** One that read `Weather` itself would
  be a second place the rules live, and the two would disagree mid cross-fade.
- **Weather particles are GENERATED, never authored.** Art is deferred indefinitely, so a rain
  texture is a dependency this project will not take.
- **`SurfaceWetness` duplicates every material it touches**, or a scene's shared sub-resources
  would leave the courtyard wet after a reload on a clear day.
- **Wetness is a pure `RefCounted`, not a node field**, because drying is the only part with
  memory and no assertion can wait for a `_process` frame.
- **A REFUSAL and a FAILURE are different things.** A refusal happens before anything: the
  player is told why and nothing changes. A failure happens after committing: the action ran, it
  did not work, and it COST something. An action that could only refuse is a lock with extra
  steps; one that could only fail gives the player no way to read the situation first. Path
  actions have both, and `once` applies to SUCCESS only, or a single early failure would lock
  the player out forever with no way back.
- **A path action is a THRESHOLD, never a dice roll.** A random one makes the player save-scum,
  and a save-scummed mechanic is experienced as a slot machine rather than as a relationship.
- **Standing is a namespace over `Flags`, not a store**, keyed `standing/<who>` and NOT through
  `PersistentState` â that namespaces per area, which is right for a chest and wrong for a
  person: the keeper who dislikes you in the courtyard must still dislike you in the hall.
- **An NPC's actions are overlapping Interactables, not a menu.** The sensor already ranks and
  Tab-cycles between overlapping targets; a menu would be a second selection mechanism competing
  with the first.
- **A door names an id and a spawn, and nothing else.** `AreaDoor` emits
  `Events.area_change_requested` and stops. It does not load, fade or place the player.
  `Director` owns the sequence and the guard, and nothing else calls `change_area()` — a door
  that ran its own transition would be a second, unguarded path, which is how two doors firing
  at once leaves two areas in the tree.
- **An interior has its own light, not a frozen sample of the outdoor one.** `follow_clock =
  false` now means the Interior group on `EnvironmentDriver` is applied once and the outdoor
  path never touches that area's sun. It used to mean only "stop updating", which is not the
  same thing and made an interior's brightness depend on the hour it was entered at.
- **The loading indicator is the ONE node after `ScreenFade`.** Gotcha 12 says the curtain must
  be the last child of `UILayer` so it covers every screen. The indicator has to be readable
  *while* the curtain is up, so it is the single deliberate exception, and there should not be
  a second one.
- **Pause is per node, not global.** `get_tree().paused` is set by UiRoot, but each node
  decides for itself in its own `_ready()`. The full table is the header of
  `src/ui/root/ui_root.gd`. Clock and Weather stop; Audio, Director, ScreenFade,
  NotificationToast and DevCapture do not.
- **A TEST BUILDS ITS OWN CONTENT, and a test that names demo content is testing the demo.**
  `tests/framework/fixtures.gd` is the seam, and its rule is one line: **in memory when a system
  is HANDED content, on disk when a system LOOKS IT UP BY ID.** The three registries scan a
  directory (ADR-0006) and cache statically, so an in-memory `ItemDefinition` is invisible to
  `Inventory.add(id)`; the fixtures write `.tres` files to `user://test_fixtures/` and point
  `content_dir` there. A test-only injection method on each registry was rejected: a backdoor in
  engine code that exists for the suite and nothing else is worse than a temp folder, and going
  out through `ResourceSaver` and back through the real scan proves the authoring round trip as a
  side effect. Since T1.3 `check_boundary` scans `tests/` too, so this is a gate, not a habit.
- **A CASE THAT ASSERTS THINGS ABOUT THE DEMO SKIPS LOUDLY, never silently.** `skip()` stands in
  for the assertions it replaces, so the plan is the same number with or without `data/` and a
  stripped run prints what it gave up. `861 passed, 0 failed, 12 skipped` is a different claim
  from `861 passed`, and the difference is the whole point.
- **EVERY CASE DECLARES A PLAN, and the number is maintained by hand.** TAP's `1..N`. It is the
  only thing that can see a crash that swallowed an assertion, an early return, a commented-out
  block, or a case that asserts nothing — see gotcha 24 for why nothing cheaper works. A stale
  plan fails loudly with both numbers and the case name, so it is self-correcting friction rather
  than a trap.
- **A CONTENT ROOT IS A `static var`, NOT A CONST.** `ItemDb.content_dir` and its two siblings.
  A game may keep its items somewhere else, and the fixtures do. `ItemDb.ITEM_DIR` is now the
  DEFAULT, not the answer, and `tools/check_content.gd` validates whatever the root currently is.
- **NO FILE UNDER `src/` OR `tests/` MAY NAME DEMO CONTENT**, and since T1.2 `tools/check_boundary.gd` is
  what says so. It derives the forbidden names from `scenes/areas/` and the ids in `data/`
  rather than listing them, so it cannot go stale. **Comments are exempt, code is not:** a `##`
  line saying `data/items/rose_key.tres must declare id = &"item/rose_key"` is teaching by
  example and changes nothing; a `const` changes behaviour. One directory is exempt,
  `src/systems/debug/`, because those three files exist to drive the demo — and the exemption is
  conditional on their argument parsing staying behind `OS.is_debug_build()`, which the same
  tool checks. Do not widen the exemption; a second exempt directory means the rule is gone.
- **A GAME-SPECIFIC ANSWER LIVES IN `project.godot`, read through `GameConfig`.** The starting
  area is `[game] world/first_area`, the game's name is `application/config/name`, and
  `src/core/util/game_config.gd` is the only place under `src/` that reads either. An `@export`
  on the boot scene was rejected: `scenes/boot/` is engine too, so that would have moved the
  leak, not closed it. An empty `first_area` is a legal state — a template nobody has put a game
  in yet — and `Director` says so instead of clearing the flags and going quiet.
- **AN EMPTY CONTENT FOLDER IS NOT AN ERROR.** `ItemDb`, `DialogueDb` and `ScheduleDb` used to
  report "no items found" as a problem, which made a stripped template fail its own gate on step
  one of `docs/NEW_GAME.md`. A file that is present and does not load is the error, and it is
  reported per file. Whether a game needs items is that game's question, not this base's.
- **`export_filter="all_resources"` IS PART OF THE ENGINE CONTRACT, NOT A PREFERENCE.** The three
  registries find content by directory scan, so those resources are nobody's dependency and only
  that setting ships them — measured both ways in T2.0, and asserted by `tests/unit/export_test.gd`
  so a consuming game that narrows it fails rung 4 instead of shipping empty catalogues.
- **THE EXPORT IS VERIFIED BY A DEBUG BUILD, AND THE READOUT NEVER REACHES A PLAYER.**
  `CatalogueReport` reports every catalogue's count and RESOLVED PATHS at boot, behind
  `OS.is_debug_build()`. The paths and not only the counts, because a partial ship is worse than an
  empty one: three of four items is a plausible number. It ASKS the same registries the game asks —
  a reporter that did its own scan would be reporting on itself.
- **AN EXPORT PROOF CANNOT BE AN ASSERTION, and the suite says so out loud.** A test running under
  `res://` cannot test a build it is not running in, so `export_test.gd` asserts
  `is_exported() == false` rather than leaving the blindness implied. The proof is a RUN of the
  exported executable with both sides' numbers quoted in `DEVLOG.md`. There is deliberately no CI
  export rung: a GPU-less runner has no platform template, the same honesty T1.4 applied to the
  windowed capture.
- **A FACING IS NOT A COLUMN, and the sector width lives in exactly one place.** `GameEnums.Facing`
  has eight values because eight is how many directions the GAME reasons about; `layout.facings` is
  how many the ART distinguishes. The two are quantised SEPARATELY from the same angle — the enum
  from `GameEnums.Facing.size()`, the column from `SpriteSheetLayout.column_for_angle()` — because
  the obvious alternative, mapping the enum down with `int(facing) * facings / 8`, puts the number 8
  back in the code in a second place, which is the exact bug T2.1 existed to remove. When
  `facings == 8` they agree by construction, so the existing sheet did not move.
- **NO SHEET DIMENSION LIVES IN CODE.** `SpriteSheetLayout` is the art CONTRACT: facings, frames,
  animation blocks, cell size and the idle/walk row offsets. `CharacterVisual` reads all of it and
  holds none of it, and `tests/unit/art_contract_test.gd` FAILS if `character_visual.gd` regains a
  `TAU / 8` or a `FACING_COUNT`. The cell size is DECLARED and validated against the texture rather
  than divided out of it, so a sheet of the wrong size is a named problem instead of every
  character in the game silently misplaced.
- **AN UNWIRED `layout` IS LEGAL AND LOUD.** `CharacterVisual` falls back to 8x4/32x48 and WARNS,
  naming the node. Gotcha 2's whole lesson is that a silent default looks exactly like success, so
  the fallback exists to keep a node recognisable while the log says it is unwired — it is not a
  fallback anything should rely on.
- **THE UI LOOK IS ONE FILE, AND THE PALETTE IS NOT COPIED INTO THE VARIATIONS.**
  `assets/theme/ui_theme.tres`, wired as `gui/theme/custom` so it reaches the HUD too — which is
  drawn UNDER `UiRoot` and would have been missed by handing the theme to the stack. Type variations
  carry ONLY `font_size`, the one thing that genuinely differs by role; the four colours and six
  insets live once each in `UiPalette` and `UiMetrics` and the screens read them by name. A `Theme`
  resource has no variables, so a colour repeated into nine variations would be nine places to
  change and "one Theme edit restyles every screen" would simply be false. A test case fails if any
  of the five styled files writes a `Color(` or an `add_theme_font_size_override` down again.
- **A DOCUMENT IS TASK-FIRST OR IT IS A FILE HEADER.** The headers in this project are good and
  are found only by already knowing which file to open. `AUTHORING.md` therefore starts from
  "I want to add an area", not from `AreaRoot`, and the four consumer documents are routed to from
  both `CLAUDE.md`'s table and `CONTEXT.md` — a document nobody is routed to is a document nobody
  reads. The extension surface went into `ARCHITECTURE.md` rather than `AUTHORING.md` because
  `AUTHORING.md` opens with "you never edit `src/`" and a section on subclassing underneath that
  would contradict it.
- **A DOCUMENTATION CRITERION IS PERFORMED, NEVER ASSERTED.** T2.2's exit criterion was closed by
  authoring a real area, NPC and conversation from the documents alone and running them; the
  deliverable of that exercise is the list of six things the documents got wrong. A walkthrough
  that works first time means the author was still reading from memory.
- **THE DOCS ARE GATED FOR EXISTENCE, NOT FOR TRUTH.** `tests/unit/docs_test.gd` asserts that every
  `res://` path the documents name resolves and that every property in a worked `.tres` example
  exists on the class that block declares. It cannot check that a documented *sentence* is true —
  only a walkthrough does that. `DEVLOG.md` is exempt from the path scan, because a history
  necessarily names files it correctly removed.
- **A QUEST STEP NAMES A FLAG CONDITION, NEVER A CALLBACK.** The same closed set of six comparisons
  `GameEnums.FlagTest` gives a dialogue condition, evaluated by the same `FlagQuery.passes` both
  call. That is what makes a quest authored data (adding the fiftieth touches no code, ADR-0006's
  test) and it is what lets the rest of the game feed a quest without knowing quests exist — the
  placeholder quest is started by a conversation effect, advanced by the courtyard lever and
  completed by the dais trigger volume, and none of those three files was touched. The cost is
  stated rather than hidden: **a step cannot read an item count**, because `Inventory` keeps counts
  and not flags, so "bring me three petals" is not authorable and the seam is a `Pickup` that writes
  a flag.
- **QUEST PROGRESS IS DERIVED; EXACTLY TWO THINGS ARE LATCHED.** `flags.gd` says derive what can be
  derived, and the current objective is the first step whose test fails, asked live on every flag
  change. Two things cannot be derived: that a quest STARTED (clearing its start flag must not
  un-give a quest carried for three hours) and that it COMPLETED (a step testing `AT_LEAST 3` on a
  counter must not reopen when something decrements it). Those two are the whole save section, held
  as **two lists of quest ids** — never an enum ordinal. An ACTIVE quest's objective is deliberately
  NOT latched, so clearing the flag behind objective two brings objective two back; a per-step latch
  would double the saved state to remove a behaviour nobody has asked for. Both halves are asserted,
  because a latch nothing tests is indistinguishable from a cache.
- **A COMPLETED QUEST GRANTS NOTHING.** It emits `Events.quest_completed` and stops. A `reward_item`
  field would put `Inventory` and a player — both `gameplay` — inside a `systems` tracker, and
  `src/` points downward only. Anything that wants to hand over an item listens; anything that wants
  to gate a conversation tests the flag the last step tested, with no code at all. Same reasoning
  that keeps `Weather` from drawing rain.
- **THE FLAG-TEST TABLE LIVES IN EXACTLY ONE FILE**, `src/core/state/flag_query.gd`, extracted from
  `DialogueRunner` when a quest step began asking the identical question. Two copies of a rule
  eventually disagree, and the disagreement would surface as a quest that will not complete for a
  flag a conversation is perfectly happy with. A test fails if the table grows back in either file —
  the gate `art_contract_test.gd` established for sheet dimensions. Only the READ half is shared:
  `FlagWrite` still has one caller, and a shared file serving one consumer is not a seam.
- **THE FOURTH REGISTRY WAS RECONSIDERED AND THE COPY WAS KEPT.** `schedule_db.gd` said "three is a
  pattern, four is a problem — if a fourth registry appears, that is the moment to reconsider."
  Reconsidered in WP-08; GDScript has no generics, so a shared base could only cache `Resource` and
  hand it back untyped, making all four accessors a cast at the call site — and static typing is
  non-negotiable #2, not a preference. What is genuinely shared already is: `QuestDb` calls
  `ItemDb.resource_paths()` rather than copying the `.remap` handling. The refactor that pays is a
  base plus a thin typed façade each, and it is **T3.1 on the board** rather than a shrug.
- **A CONTENT CHECK PRINTS WHAT IT CANNOT VALIDATE.** `check_content` prints every flag a quest and
  its steps name and validates none of them. A flag can be written from a scene, a conversation, a
  path action or another quest, and the writer that matters most is a runtime one —
  `PersistentState` builds `obj/<area>/<object>/<field>` at load — so a checker that failed on any
  flag with no findable writer would be wrong most times it fired. A partial check that looks
  complete is the failure mode this project exists to prevent, so the flags go in the build log
  where a reviewer reads them.
- **EQUIPMENT IS A FLAG, NOT A STORE.** `Equipment` is a component beside `Inventory` — same
  `of(who)` reasoning, so an NPC or a stash can have one — and it owns NO DICTIONARY. A slot is
  `equip/<wearer_id>/<item id>` in `Flags`, which is `PersistentState`'s `obj/<area>/<object>/<field>`
  and `Standing`'s `standing/<who>` applied a third time. Three things fall out and together they
  are the whole argument against a `Dictionary[EquipSlot, StringName]` plus a save section: it is
  already saved (no register, no version, no migration, and a new game clears it because
  `start_new_game()` clears flags); a `Gate`, a `QuestStep`, a `DialogueChoice` and a `ClimbPoint`
  gate on it **with no code and no new field**, which is WP-08's seam used by a second system; and
  `flag_changed` already announces it. The cost is stated: the key contains an item id, so renaming
  an item's `.tres` brings it back stowed.
- **THE ITEM STAYS IN THE BAG WHILE IT IS HELD.** Moving it out would make equipment a second place
  items live — `Inventory.count_of()` would begin lying and `Gate.requires_item` would refuse a key
  that is in the player's hand. So equipping is purely a flag, and the price is that losing the item
  has to stow it: `Equipment._revalidate`, on `inventory_changed` rather than on `item_lost`, because
  that is the one signal every path emits including a restored save. It is the invariant the suite
  fails first when broken.
- **ONE ITEM PER SLOT, AND THE NEWCOMER WINS.** Holding a second LIGHT stows the first rather than
  being refused, because a refusal would make swapping a lantern a two-step chore the player cannot
  see a reason for. `can_equip()` is the seam a strength rule or a two-handed rule goes into, the
  analogue of `Inventory.can_accept()`.
- **`EquipSlot` HAS NO WEAPON AND NO ARMOUR VALUE**, the same absence `ItemCategory` has, and for
  the same retraction. A slot answers "what does holding this let you do", never "how hard do you
  hit". It is append-only, because an `ItemDefinition` stores it as an ordinal.
- **A REFUSAL MAY CARRY AN AUTHORED LINE, and a reason is a CATEGORY rather than a sentence.**
  `interaction_refused` carries a `message_key` beside `args` — travelling on the signal rather than
  asked of the target, exactly as `args` does — and `Interactable.refusal_key(who, reason)` is the
  override, with "" meaning "compute `refusal.<reason>` from the enum". The alternative was a new
  `RefusalReason` per authored line, which is a category per sentence and the growth the closed sets
  exist to prevent. `Gate.locked_key` and `PathAction.refusal_key` had been declared, validated by
  `check_content` and read by NOTHING since WP-01 and WP-07 — see the defects section.
- **A UI REDRAWS ON THE WORLD'S SIGNAL, NEVER ONLY ON ITS OWN INPUT.** `InventoryScreen` refreshed
  on `inventory_changed` alone, so a row press redrew and an equip from anywhere else did not — and
  the first WP-09 capture photographed a held lantern drawn as merely carried. A press is never the
  only writer: staging equips from the command line, and `_revalidate` stows on its own. That is
  why `equipment_changed` exists at all, and it is a general rule rather than one screen's bug.
- **DISCOVERY IS A FLAG, AND THE NAMESPACE CONVENTION IS NOW A PATTERN.** `map/<area id>` in
  `Flags`, with no store, no save section, no migration and no register — the FOURTH use of
  namespace-over-`Flags` after `PersistentState`'s `obj/<area>/<object>/<field>`, `Standing`'s
  `standing/<who>` and `Equipment`'s `equip/<wearer>/<item>`. Three independent systems on one
  convention is evidence it generalises rather than a coincidence, and the next thing that needs
  saved per-thing state should reach for it before reaching for a save section. Two things fall
  out and they are the whole design: anything that writes the key reveals a place (a
  `DialogueChoice` effect, a `TriggerVolume`, a `Lever`, a quest consequence — none of which was
  touched), and a `Gate` with `requires_flag = &"map/<id>"` is a road that opens once you know
  where it goes. The cost is stated: renaming an area's folder makes an old save forget it was
  found, the same price `Equipment` pays for an item id.
- **A MAP DOT'S POSITION IS AUTHORED DATA, IN NORMALISED 0..1 SPACE.** `AreaDef.map_position`, and
  `MapScreen` has never heard of any area. A map that knew where the courtyard goes would be
  engine code naming demo content, which `check_boundary` fails the build over — proved by
  planting it. Normalised rather than pixels so one authored number is right at every window size
  and every UI scale.
- **AN AREA ID HAS NO REGISTRY PREFIX**, unlike `item/` and `quest/`. Those prefixes make a save
  file self-describing about a thing that lives only in a save file; an area id is already a
  public identifier, because it is a folder name. `data/areas/orchard.tres` declares
  `id = &"orchard"`, which is what `Director` travels to, so there is no translation table
  between `AreaDb` and `Director` — and a translation table is a second place the truth lives.
- **FAST TRAVEL ASKS; IT DOES NOT TRAVEL.** `WorldMap.travel_to` emits
  `Events.area_change_requested` and stops, exactly as `AreaDoor` does. Four refusals, each
  logged: not on the map, not found, already there, already moving. Nothing but `Director` calls
  `change_area()`, which is what keeps two things firing at once from leaving two areas in the
  tree — and a fast-travel path that ran its own transition would have been the second one.
- **AN AREA WITH NO `AreaDef` IS NOT AN ERROR**, it is a cupboard a game chose not to draw. It is
  said at INFO level once per arrival rather than warned, because the boot rung counts warnings
  and a template with no map at all is a legal state — but it is said, because "the .tres is
  authored and the dot never appeared" must not be silent. Same shape as an empty content root.
- **STAGING THAT PUTS SOMETHING ON SCREEN WAITS FOR THE WORLD TO STAY STILL, NOT MERELY TO ARRIVE.**
  `dev_stage._settle_stable(20)` demands twenty CONSECUTIVE settled frames and resets on any
  transition, which is gotcha 21's persistence shape applied to staging. `--goto` and
  `--open-menu` both leave `_wait_for_area` on the same frame, so a fixed extra delay only moves
  the race; a counter that a starting transition resets cannot be satisfied early.
- **AN ATTRIBUTE'S NAME LIVES ON ITS CONSUMER, NEVER ON THE CONTAINER.** `attr/<who>/<name>` is the
  fifth namespace over `Flags`, and `Attributes` has NO registry, no `AttributeDef` and no enum of
  names — any StringName is an attribute the moment something writes it, which is ADR-0006's
  no-code-per-thing test met without a sixth directory scan. What stops that becoming the failure
  this project keeps catching is a rule about where a name is written down:
  `PlayerController.PACE` sits beside the line that reads it, so **an attribute nobody reads has
  nowhere to be declared** and `attributes.gd` cannot grow a table of good intentions. The cost is
  stated: naming an attribute is free, READING one is always a line of engine code, and
  `AUTHORING.md` says so to an author's face. The value is a STEP, not the number, because a flag
  holding `4.7` would be a walk speed authored into a save file and the tuned `walk_speed` would
  stop being the truth.
- **A SURFACE IS METADATA ON GEOMETRY, INHERITED FROM THE NEAREST TAGGED ANCESTOR.**
  `metadata/surface` on a body or anything above it. A component would be a node per floor tile; a
  group would share one flat namespace with `navmesh_source`, where a typo becomes a second surface
  silently; an ENUM would be a list of surface names in `src/`, which `check_boundary` fails the
  build over. Inheritance is what makes it cheap to author, and the demo's third surface comes from
  it. A step's timbre is DERIVED from the name for the same boundary reason a table is refused: a
  game that authors `sand` hears it without editing `src/`.
- **A FOOTSTEP IS THE ONE CLAIM THE LADDER CANNOT SEE AT ALL, AND THE FILE IS SPLIT ALONG THAT
  LINE.** Not visual, so no capture reads it; not synchronous, so no assertion reaches it; and
  headless the audio driver is `Dummy`, where every `play()` leaks (gotcha 20). So the pure parts
  — the stride accumulator, the surface query and the two timbre functions — are asserted, and the
  raycast, the frame loop and the `play()` are a windowed run with the log quoted. The same split
  `SurfaceWetness` made for drying, and it is said out loud rather than implied.
- **AN ITEM COUNT IS A FLAG THAT IS PUBLISHED DOWNWARD, NOT A BAG THAT IS READ UPWARD.**
  `bag/<carrier_id>/<item id>` in `Flags`, written only by `Inventory._publish`, and it is the
  general answer whenever a lower layer holds something an upper one must observe. `QuestTracker`
  is `systems` and `Inventory` is `gameplay`, so a tracker reading a bag points the wrong way —
  the same violation WP-08 refused over `reward_item`. Publishing inverts it, and the capability is
  identical: `QuestStep` gained NO field, `QuestTracker` gained no knowledge, and `item_count_test`
  FAILS if either file's code names `Inventory`, `ItemDb` or `BagKeys` — nothing else in the suite
  could, because the behaviour would be identical with the layer rule gone. Settled by T3.3 from
  the FIRST of WP-09's two costed designs. Do not "simplify" it by handing the tracker a bag.
- **A DERIVED FLAG IS READABLE, ANNOUNCED, AND NOT SAVED.** `Flags.declare_derived(prefix)`, and
  `_collect_save` skips those keys. That is what makes the count projection legal rather than a
  second copy of the truth: `flags.gd`'s own header forbids storing anything recomputable, and a
  count mirrored from the bag is recomputable by definition. The consequence is a duty rather than
  a freedom — the PUBLISHER must republish whenever the store is wiped under it, which is why
  `Inventory` subscribes to `game_started` (clear) and `game_loaded` (republish, after every
  section, so the answer cannot depend on save-participant order). Anything else that wants to be
  readable-but-derived pays the same price and should say so in its header.
- **A COUNTED CONDITION IS `AT_LEAST` OR `EQUALS`, AND `AT_MOST` DRAWS NO TALLY.** `AT_MOST` is a
  ceiling, so "2 / 3" under *keep it below three* tells the player to gather more of the one thing
  they must not; a `condition_value` of 0 is not a count either, because `AT_LEAST 0` passes with an
  empty bag. `FlagQuery.progress()` answers `(have, need)` with `need == 0` meaning "not a count",
  and `check_content` fails the build on both mistakes rather than letting a journal draw `0 / 0`.
- **THE BAG KEY SHAPE LIVES IN `src/core/state/bag_keys.gd`, AND NOT ON `Inventory`.** Three places
  need it and none may rebuild it: the bag WRITES it, `check_content` PARSES it to validate the item
  id, and the suite asserts on it. The reason it cannot sit beside `Equipment.PREFIX` is a compile
  error, not taste — `check_content` runs under `--script`, where autoload identifiers do not
  resolve, so naming `Inventory.PREFIX` would not compile. Keep that file free of autoloads.
- **ONE FLAG NAMESPACE IS VALIDATED BY `check_content`; THE REST ARE STILL ONLY PRINTED.** WP-08's
  rule stands — a flag can be written from anywhere, so failing on one with no findable writer would
  be wrong most times it fired. `bag/<carrier>/<item id>` is the exception because it has exactly
  ONE writer and half the key is an item id the tool can look up. The CARRIER is deliberately not
  validated: it is an `@export` in a scene the tool does not open, and a game may put a bag on an
  NPC or a stash.
- **A NEW GAME IS A NEW BAG.** `Director.start_new_game()` clears the flags; `Inventory` now clears
  its counts on `game_started` for the same reason. It did not before T3.3, so the previous run's
  items carried into a fresh game — unreachable in practice and invisible to every gate, and found
  only because the count projection cannot tolerate the two disagreeing.
- **A MATERIAL IS SHARED WHEN TWO AREAS WANT THE SAME THING, AND NOT BEFORE.**
  `assets/materials/` holds `StandardMaterial3D` resources more than one area points at, and it
  holds exactly ONE — the wood the two demo areas had each grown a byte-identical inline copy of.
  The other five were deliberately left inline, and the reason is the whole rule: **a tiling rate
  is a property of the surface it is stretched over, not of the substance.** One area tiles stone
  at `(3, 3)` and the other floors it at `(8, 8)` and walls it at `(6, 2)`, so hoisting those gives
  a shared file with a per-area override on every user — the duplication with an extra
  indirection, and a palette rather than a seam. Nothing under `src/` knows the folder exists: this
  is a scene-authoring convention, not a system, so there is no registry, no id and no sixth
  directory scan. A test fails if two areas declare the same material inline, comparing bodies with
  `ExtResource` ids resolved to paths — which is what nobody could do by eye, and why the duplicate
  survived. What makes sharing safe was already true: `SurfaceWetness` DUPLICATES every material
  before darkening it, so rain outdoors cannot leave an interior's floor wet after an area change.
- **THE LOOK IS PER AREA AND THE STRUCTURE IS IN CODE.** The twenty post-stack values on
  `EnvironmentDriver` are `@export`s at exactly the numbers T2.1 shipped; the tonemapper, the fog
  mode, the glow blend mode and `AMBIENT_SOURCE_COLOR` stay in code because they are what the rest
  of the file ASSUMES rather than what an area tunes — `_apply_now` writes `ambient_light_color`
  every frame, which means nothing unless the source is a colour. Per area rather than per project
  because the driver already lives in the area scene and its `Interior` group already varies that
  way. An "environment look" `.tres` was considered and dropped: a `SpriteSheetLayout` is shared
  between nodes in one scene, a post stack is one per area, so the resource would add a class, a
  folder and a wiring step to reach the same numbers. **The four expensive effects are exports
  despite being `false` everywhere, because a value a consuming game cannot reach is not a seam,
  it is an opinion.** The day/night KEYFRAMES table is NOT part of this and no seam is claimed for
  it: that is a curve, not a look setting.
- **A SEAM THAT NOTHING USES HAS NEVER BEEN TRIED, AND FOUR DOCUMENTS CAN AGREE IT IS MISSING WHEN
  IT IS NOT.** `HD2DCameraRig` has carried its framing as `@export`s since it was written and its
  header has said "duplicate it and change the numbers" the whole time; what was missing was an
  AREA setting one. T2.1's leftover list said the seam did not exist and three more documents
  copied that. So an area now authors its own framing — the interior at 36 degrees and 9.5 m
  against the outdoor 27 and 14 — and a test fails if none does. Generalise the lesson rather than
  the fix: **a backlog line about code is worth re-checking against the code before it is worked**,
  and a claim repeated in five documents is repeated, not verified.
- **AN UNDOCUMENTED FORMAT IS SETTLED BY MEASUREMENT, NOT BY STOPPING.** `[importer_defaults]` in
  `project.godot` sets `detect_3d/compress_to = 0`, so a PNG a game drops in imports correctly the
  first time and no re-import can put VRAM block artefacts through pixel art. T2.1 refused to
  hand-author it because the section is absent from `--doctool` and this project checks every name
  against the API dump — the rule was right, the conclusion was not, and gotcha 39 records the
  reversal: non-negotiable #1 says the ENGINE decides, and the engine can be asked. Exactly one
  value is set, because the other three were measured to be Godot's own defaults already and **a
  default nobody needs is a default nobody maintains.**
- **GIT LFS IS REFUSED, NOT DEFERRED, AND THE THIRD REASON IS THE ONE THAT DECIDES IT.** Pointers
  for a 2 KB procedural placeholder are overhead, and enabling them puts the CI checkout on a
  dependency it does not declare — both were already recorded. The one that had not been said is
  that **this template cannot verify the change it would be making**: proving LFS works needs an
  LFS-enabled remote and a CI run against real binaries, and neither exists while art is deferred.
  The refusal lives in `ART_CONTRACT.md` with the three steps to turn it on, and `.gitattributes`
  keeps a pointer rather than restating it.
- **A BACKLOG ITEM MENTIONED IN FIVE PLACES IS TRACKED IN NONE OF THEM.** T3.2's stated deliverable
  was as much that its five items stop appearing in five documents as that four of them got built,
  and the rule that came out of it is about STATE and not about word counts: **the current state of
  anything lives in exactly one document — the one its consumer reads — and every other mention is
  either a historical record that says "closed by <package>" or it is deleted.** A finished thing
  named in a package section, a settled decision and an inventory row is the normal record shape
  and is fine; five documents each describing PENDING work is the shape that rots, because none of
  them is the one that gets corrected. Nothing was removed from the record; T2.1's section still
  says what T2.1 left, because that is still true.
- Six ADRs in `docs/decisions/` cover the layered `src/`, warnings-as-errors, the input map,
  and save-via-callables.

## Verify before claiming anything is done

Since T1.4 these run in CI too — `.github/workflows/ladder.yml`, on every push, pull request and
manual `gh workflow run ladder.yml --ref <branch>`. CI is not a substitute for running them: the
windowed capture is the one rung a GPU-less runner cannot do, and push events on this repo have
lagged by as much as 25 minutes.

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --check-only --script <file>   # type gate
"$G" --headless --import                       # scenes and resources
"$G" --headless --quit-after 30                # must end "0 warnings, 0 errors"
"$G" --headless res://tests/test_runner.tscn --quit-after 400   # 1,947 assertions, exit 1 on fail
"$G" --headless --script tools/check_budgets.gd            # must exit 0
"$G" --headless --script tools/check_content.gd            # must exit 0
"$G" --headless --script tools/check_boundary.gd           # must exit 0 — src/ and tests/ name no demo content, and no orphan CSV row
"$G" --headless --script tools/check_strings.gd            # must exit 0 — no player-facing literal, every *_KEY exists
"$G" --headless --script tools/check_layers.gd             # must exit 0 — core -> content -> systems -> gameplay -> ui
"$G" --headless --script tools/check_signals.gd            # must exit 0 — every declared signal has an emitter
"$G" --resolution 960x540 --quit-after 90 -- --new-game --shot=<path> --shot-frame=70 --time=18:40 --freeze-time
```

## Sixty-eight gotchas that each cost an hour

1. Autoload identifiers (`Log`, `Events`, …) **do not resolve** under `--check-only`. That
   error is expected. Rungs 2 and 3 are the real compile check.
2. `--headless` uses a dummy rasteriser and **shades nothing**. Visual claims need the
   windowed capture. A day/night system once ran, logged correct times, reported no errors and
   lit nothing — because one `@export` was unwired in the scene.
3. Author with 4 spaces, then `unexpand -t 4 --first-only` before saving. Tabs are the project
   style, and mixed indentation is a parse error.
4. The test suite is a SCENE entered positionally, never `--script`. Under `--script` the
   autoload identifiers fail to compile, so no test touching a system can run that way.
5. Do not name an `` after a native member. `Area3D` already has `priority`, so ours
   is `interact_priority`; redefining a native member is a parse error that cascades into
   every subclass as "could not resolve class".
6. `set_anchors_preset()` leaves offsets at zero, giving a zero-size Control whose text spills
   off screen. Use `set_anchors_and_offsets_preset()`.
7. `Container` is a NATIVE Godot class. `class_name Container` is a parse error that cascades
   into every subclass as "could not resolve class". Ours is `ItemContainer`. Check a name
   against the API dump before claiming it.
8. Configure an interactable BEFORE `add_child`. `object_id` is forwarded to `PersistentState`
   in `_enter_tree`, so anything set afterwards is too late and the object silently stops
   persisting. `TestCase.build()` then `attach()` exists to make that ordering explicit.
9. A body spawns at the area **origin** and is placed on its spawn marker a frame later, so
   an `Area3D` sitting near the origin sees it pass through. `TriggerVolume` arms two physics
   frames late for exactly this reason. Anything else that watches for bodies needs the same
   guard.
10. `TestCase.run()` is **synchronous** — the runner calls it, it does not await it. So no
    test can wait on a physics frame, which is why interactions are driven through `attempt()`
    and a climb through `climb_step(delta)` in a bounded loop. A test that needs a real
    physics step belongs in the windowed run instead.
11. **Autoloads are PAUSABLE by default**, so `get_tree().paused` silently stops `Clock`,
    `Weather` and `Audio` alike. Audio has to opt out explicitly or the score cuts out the
    moment a menu opens — and it is the autoload *node* that needs it, not just the
    `AudioStreamPlayer` children, because the cross-fade tweens are created on the node.
    Verified with `can_process()` in `tests/unit/ui_test.gd`, not assumed.
12. **Child order in a `CanvasLayer` is draw order.** `ScreenFade` has to come after every
    SCREEN or the curtain does not cover them. It was the first child until WP-02. Since WP-04
    exactly one node sits after it, `LoadingIndicator`, which has to be readable while the
    curtain is up — that is the only deliberate exception and there should not be a second.
13. **A RUN THAT QUITS MID-LOAD USED TO PRINT `Parse Error` FOR FILES THAT PARSE PERFECTLY, AND
    THAT IS FIXED — but the shape is worth keeping, because it is the only case in this project
    where the engine reported a failure that was not there.** Killing the process while a
    threaded load is in flight tore the loader thread down inside the text parser, which then
    printed `Parse Error` for `courtyard.tscn` and `wood.tres` plus leaked RIDs and leaked
    ObjectDB instances, *after* the run had already reported `0 warnings, 0 errors`. **Gotcha 22
    with the polarity reversed:** not an error a rung cannot see, but a FALSE error poisoning the
    `Parse Error` grep that rung 2 uses as the project's compile check — and its real cost was
    that CI's boot rung had to read only the last line of its log instead of grepping it, so a
    live defect had bought itself a permanently weakened gate. Fixed in WP-14:
    `Director._exit_tree()` drains its own loader thread, because `--doctool` confirms there is
    no `load_threaded_cancel` and `load_threaded_get()` blocks (measured, 118-197ms, paid once
    on the way out). CI's rung 3 now greps the whole log.

    **THIS GOTCHA ALSO USED TO GIVE THE WRONG REASON FOR THE BOOT RUNG'S FRAME COUNT, and that
    part was stale rather than fixed.** It said 120 rather than 30 because "the area load is
    threaded and 30 frames does not finish it". Since WP-12 the boot stops at the MAIN MENU and
    loads no area at all — gotcha 31 — so the boot rung was never racing a load, and 30 frames
    was measured as producing a byte-identical log to 120 (29 lines, same content, both
    `0 warnings, 0 errors`). **The local boot rung is `--quit-after 30`.** CI keeps 300 for the
    reason that does apply: a shared runner is slower, a headless frame costs milliseconds, and
    a rung that quits before the boot finishes would report clean about work it never did.
14. **`x if c else [] as Array[StringName]` is a RUNTIME cast failure.** The empty literal is
    a plain `Array`, the ternary takes its type from it, and the assignment throws every time
    the condition is false. It compiles, the boot run is clean, and the test suite still
    reports every assertion passing — the only trace is a `SCRIPT ERROR` line in the output.
    Declare the typed local, then assign inside an `if`.
15. **No assertion can press a key.** `TestCase.run()` is synchronous, so an input event never
    reaches the frame that would deliver it. An input path is proved by a TEMPORARY probe
    added to `dev_capture.gd`, run windowed with real `InputEventAction`s, read in the log,
    and then removed. WP-03's probe is quoted verbatim in `DEVLOG.md`; copy its shape.
16. **A FREED object compares EQUAL to `null` in Godot 4.** So `if thing != null` does NOT
    fire for a dangling reference, and `a != b` against one reports "unchanged". Only
    `is_instance_valid()` tells the truth. Worse, a freed instance cannot even be PASSED to a
    typed parameter — the argument type check itself fails with "previously freed" — so a
    dangling reference must never cross a call boundary; read the field in place. This kept a
    prompt for an unloaded area on screen through three packages.
17. **Check a name against the API dump before using it, EVERY time — static functions
    included.** `Resource` declares `resource_name` with the getter `get_name`, and a GDScript
    is a Resource, so `DictRead.get_name(...)` compiled and then dispatched to the native
    zero-argument method at runtime. Third time this project has been bitten by a native-name
    collision, after `Area3D.priority` and `class_name Container`. Regenerate with
    `--headless --doctool <dir>` and grep it.
18. **A navmesh bake that finds nothing takes NO TIME and reports SUCCESS.** `bake_navigation_mesh`
    on a region whose geometry mode does not actually reach the terrain produces zero polygons,
    logs nothing, and every NPC then concludes it has already arrived, everywhere. Always report
    `navigation_mesh.get_polygon_count()` and treat zero as an error. Godot's default
    `SOURCE_GEOMETRY_ROOT_NODE_CHILDREN` parses the children of the `NavigationRegion3D` itself,
    which in this project's area layout has none — the terrain is a sibling, so the areas use
    `SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN` with the group `navmesh_source`.
19. **`agent_max_climb` describes an abstraction the character controller does not implement.**
    The bake will bridge a knee-high step; `CharacterBody3D.move_and_slide()` has no step-up at
    all, so the body walks into the riser and stops while the agent reports "not finished"
    forever. Keep the climb limit below anything the body cannot manage. Related: do not ask the
    navigation map anything before it has synchronised — an unsynchronised map answers
    "unreachable" to everything, and acting on that answer strands an agent at the origin.
20. **Under `--headless` the audio driver is `Dummy`, and every `play()` against it LEAKS.**
    The AudioServer releases a stopped playback on the next mix and headless quits before there
    is one, so each `play()` shows up as a leaked ObjectDB instance along with its stream.
    Stopping the player and nulling its stream in `_exit_tree` does NOT help â the server owns
    the playback. Anything that starts a sound gates on `AmbienceBed.is_audible()`, which reads
    `AudioServer.get_driver_name()`: measured as `Dummy` headless, `WASAPI` windowed.
21. **An asynchronous system needs a PERSISTENCE test, not just a delay before you ask it.**
    `NavigationAgent3D` recomputes its path over frames, so the frame after a target moves it
    answers "unreachable" to a question it has not finished thinking about. WP-06 added a delay
    before the first question and it was still wrong â the keeper reported "cannot reach" in
    windowed runs and never in headless ones, because a WANDER activity re-targets every few
    seconds and only real-framerate timing landed inside the window. The answer must now hold
    for thirty consecutive physics frames, and a new target clears the evidence. Anything asked
    of an async subsystem should be treated the same way.
22. **"0 warnings, 0 errors" DOES NOT MEAN THE SCRIPTS COMPILED.** `Log` counts its own
    `Log.warn` and `Log.error` calls; an engine-level `Parse Error` is neither, so a file that
    fails to load prints a `SCRIPT ERROR` on stderr and the boot rung still reports a clean
    session. `dev_capture.gd` was dead for a whole package this way — the WP-13 merge added
    `await _settled()` without the function, and F12, `--shot`, `--time` and `--weather` were all
    broken while every rung stayed green. **Rung 2, `--headless --import`, is the compile check.**
    Grep its output for `SCRIPT ERROR` and `Parse Error` and require zero; do not read only the
    last line of rung 3.
23. **A GATE THAT NEVER FAILS HAS NEVER BEEN TESTED.** Every checker added since T1.2 is proved
    by planting a violation, watching it exit 1, removing it, and watching it exit 0 — both
    quoted in `DEVLOG.md`. This costs two minutes and is the only thing separating a gate from a
    reassuring printout. `tools/check_boundary.gd` also gets it wrong in a way no failure can
    show: it reads text, so a computed id or a name that exists in neither `data/` nor
    `scenes/areas/` passes silently. Its header lists what it cannot see, and that list is part
    of the gate.

24. **A GDScript RUNTIME ERROR ABORTS ONLY THE INNERMOST FRAME, so a crashing test passed for
    the life of the project.** Probed: a null dereference three frames deep printed its
    `SCRIPT ERROR`, and both the calling function and `_ready()` above it ran to completion. So
    the runner sees a case that returned normally, and a completion sentinel at the end of
    `run()` cannot work either — it is reached. T1.3 needed TWO mechanisms, and the second was
    added because the first was measured and found wanting: a declared PLAN catches every crash
    that swallows an assertion, but a crash planted in a leaf helper with nothing asserted after
    it still reported `2/2` and exit 0. `tests/framework/error_watch.gd` — an `OS.add_logger`
    `Logger` counting `ERROR_TYPE_SCRIPT` — is the only thing in the engine that sees that one.
    Related and useful: `get_tree().quit(1)` followed later by `quit(0)` exits 0, last call wins,
    which is why the runner ARMS its exit code to failure on its first line.


25. **GITHUB RUNS EVERY `run:` BLOCK AS `bash -e {0}`, so `set -uo pipefail` inside a step does
    NOT turn errexit off.** T1.4's first red run reported nothing but `Process completed with exit
    code 1`: the step died on the failing `godot` line, before the line that prints WHICH
    assertion failed. The uploaded artefact had the answer and the step did not, which is a gate
    that fails without saying why — half a gate. Any rung that must outlive its own command's
    failure captures the status with `|| status=$?`, which is exempt from errexit, and judges it
    afterwards. Related, and it wasted an hour on its own: **verifying a shell fragment
    interactively with `( ... )` inside an `&&` chain also silently disables `set -e`** — the same
    fragment reported exit 0 on a deliberately failing suite inline and exit 1 as a script file.
    Test a workflow fragment as a FILE, never inline.

26. **`gh`'s run listing lags, and believing it produces a confident wrong diagnosis.**
    `actions/runs` reported `total_count: 0` for four minutes after a push whose run had already
    been created AND completed. On that evidence CI looked disabled, which cost a needless
    visibility change to rule out a private-repo minutes limit — the runs that had already passed
    were pushed while the repo was private. Push-event delivery on this repo ran up to **25
    minutes** behind at times. Check `run_started_at` against the push time before concluding
    anything is broken, and prefer `gh workflow run` for a prompt answer: `workflow_dispatch` is a
    trigger on the ladder precisely because a gate with one way in has a single point of failure.
    A manual run gets its own `concurrency` group keyed on its run id, because a dispatch was
    once cancelled by the very push it was verifying and a cancelled run reports neither pass nor
    fail.

27. **AN EXPORT DROPS AN INSTANCE OVERRIDE THAT HAS NO `[editable]` MARKER, and running from
    source cannot see it.** A hand-authored `.tscn` that sets a property on a node INSIDE an
    instanced scene needs `[editable path="<the instance>"]` at the foot of the file. Without it
    the text loader applies the override happily; the exporter converts `.tscn` to binary `.scn`
    and the conversion silently discards it, so the prefab reverts to its defaults in the shipped
    build ONLY. The demo's NPC lost its `object_id`, its prompt and its conversation exactly this
    way, and every rung, both CI jobs and 930 assertions were green throughout. Stale `index=`
    values look like the culprit and are not — correcting them changed nothing.
    `tools/check_content.gd` gates it now. Related, from the same package:
    **`export_filter="all_resources"` is the only setting that ships directory-scanned content**
    (`"scenes"` ships zero of it), **`include_filter="*.tres"` is the plausible wrong fix** because
    the include filter is for NON-resource files, and **a debug export is required to verify
    content at all**, because the readout is behind `OS.is_debug_build()`. An export template must
    be installed first, and it comes only in a 1.28 GB `.tpz`.


28. **A SPRITE DRAWN FROM THE WRONG CELL STILL LOOKS LIKE A CHARACTER.** This is gotcha 2 in its
    sharpest form: a day/night system that lights nothing is at least obviously wrong on screen,
    but a person drawn from the wrong row is still a person — upright, lit, facing *some*
    direction — so a capture of it cannot be JUDGED, it has to be READ. T2.1's second placeholder
    sheet therefore labels every cell: `column + 1` bright pips down the left edge, `frame + 1`
    along the foot, and a different body tint per animation block. That is what turned
    `frame=19/24` from a number to be taken on trust into a checkable prediction — four left pips,
    two foot pips, orange body, `(1*3 + 1) * 4 + 3 = 19`. Any future visual seam whose failure mode
    is "plausible but wrong" needs the same treatment; a screenshot of something that merely looks
    fine is not evidence.

29. **A `Theme` HAS NO VARIABLES, so a colour put in a type variation is a colour duplicated.**
    Godot's `Theme` stores each item per type, and there is no reference between them — so the
    natural-looking design, where `TitleText` carries both its `font_size` and its `font_color`,
    means the accent colour is written into as many variations as use it and "one Theme edit
    restyles every screen" is false the moment there are two. The split T2.1 settled on: variations
    carry ONLY sizes, and the colours and insets live once each under `UiPalette` / `UiMetrics`
    which the screens read by name. Related, and it is what makes this work at all: the project
    theme set as `gui/theme/custom` resolves from ANY Control in the tree, so a screen never has to
    be handed it — but a theme item that exists in the file and does not resolve from a node is not
    wired, which is the same failure shape as an unwired `@export`, and it is worth one assertion.

30. **`[importer_defaults]` IS UNDOCUMENTED AND ABSENT FROM `--doctool`.** Godot's per-importer
    project defaults are an editor-managed `project.godot` section, so the rule this project runs
    on — check every name against the API dump before using it — cannot be satisfied for it, and
    hand-authoring an undocumented format is exactly the change that looks applied and does
    nothing. T2.1 stopped rather than guess. **ITS CONCLUSION WAS WRONG AND T3.2 REVERSED IT — see
    gotcha 39.** The first half stands: there is still no dump to check. What was missing was that
    a MEASUREMENT is available and is stronger evidence than a dump, which is non-negotiable #1.
    The latent hazard it named is closed: the section now sets `detect_3d/compress_to = 0` and so
    does every committed `.import`, so a re-import can no longer put VRAM block artefacts through
    pixel art. Keep this entry for its general lesson, which is not about textures: **"I cannot
    check this the usual way" is a reason to find another check, not a reason to stop.**

31. **NO ORDINARY RUN EVER ENTERS AN AREA, so most of the ladder is blind to area content.**
    `--headless --quit-after 30` boots to the MAIN MENU and reports `0 warnings, 0 errors`
    without loading anything — it cannot see a wrong `area_id`, an empty navmesh bake, an NPC with
    no schedule or an unlit interior. Neither can a bare `--shot`: the PNG is the title screen,
    which is what the first capture in T2.2 turned out to be. **`--new-game` is what starts a
    game**, `--goto=<area>` travels to a different one, and the area load is threaded so the
    shutter needs `--shot-frame=70` with `--quit-after 90` rather than the old bare 55. This is
    gotcha 22's family, one level up: not a rung that cannot see an error, but a rung reporting
    clean about work it never did. Related and cheap to trip over: `--stand-by=` takes a NODE
    NAME, not an `object_id`, and a propless new area at 18:40 renders near-black, which looks
    exactly like a lighting bug — capture a new area at midday first.

32. **STAGING THAT RUNS BEFORE `--new-game` HAS ITS STATE THROWN AWAY.** `--new-game` CLEARS EVERY
    FLAG, so `--flag=met/x:true` applied during argument parsing is gone by the time the area
    lands — and the run still reports `0 warnings, 0 errors`, because nothing failed. The first
    WP-08 capture was a journal with no quest in it for exactly that reason, and the only trace is
    the ORDER of the log lines: `--flag` before `Quest tracker ready`, and no `started` line after
    it. `--flag` now waits for the area the way `--open-menu` already did. This is gotcha 31 one
    step further in: not a rung blind to an error, and not a rung reporting clean about work it
    never did, but staging that ran before the thing it was staging for. Any future `--` flag that
    poses state a new game resets needs the same wait, and `dev_stage.gd`'s header says so.


33. **`Array[StringName].sort()` DOES NOT SORT ALPHABETICALLY.** It orders by the StringName's
    internal handle, so the result is stable within a run and arbitrary between them. It compiles,
    it looks like a sort, and `Equipment.equipped_ids()` returned two ids in the wrong order with a
    single failing assertion as the only trace. `Inventory.ids()` had already hit this and sorts
    through `String` with a `sort_custom`, which is the only reason this cost a minute rather than
    an hour — a comment saying WHY a line is not the obvious one is worth more than the line.
    Anything sorting `StringName`s goes through `String`.

34. **A UI THAT REDRAWS ONLY ON ITS OWN INPUT IS SILENTLY WRONG THE MOMENT SOMETHING ELSE WRITES.**
    `InventoryScreen` refreshed on `inventory_changed`, so pressing a row to equip redrew correctly
    and equipping from anywhere else did not — and the first WP-09 capture came back showing a held
    lantern drawn as merely carried while the log said `player equipped`. Nothing failed, because
    the screen was still right about the bag. A press is never the only writer: staging equips from
    the command line, `_revalidate` stows on its own, and a save restores. Subscribe to the fact,
    not to the gesture. This is gotcha 2's family in the UI layer, and only a capture sees it.

35. **TWO STAGING FLAGS THAT BOTH WAIT FOR "THE AREA" LEAVE THAT WAIT ON THE SAME FRAME, AND
    RACE.** `--goto` and `--open-menu` each begin with `_wait_for_area()`, so they resume
    together: if the menu opened first, the travel `--goto` was about to request unwound it —
    `ScreenKeys` unwinds the stack on every `area_change_requested` — and the capture came back
    showing nothing, with `0 warnings, 0 errors` and every rung green. This is gotcha 32's family
    one step further out: not staging that ran before the thing it staged for, but two pieces of
    staging that were both correct and were ordered by chance. A LONGER FIXED WAIT ONLY MOVES THE
    RACE. The fix is gotcha 21's shape — `dev_stage._settle_stable(20)` requires twenty
    CONSECUTIVE settled frames and resets its count the moment a transition begins, so it cannot
    be satisfied early no matter which flag resumed first. Any future staging flag that puts
    something on screen uses it, and `dev_stage.gd`'s header says so.

36. **`String.hash()` MIXES ITS LOW BITS WEAKLY, so `hash() % N` CLUSTERS SHORT SIMILAR NAMES.**
    Measured: `"grass"` hashes to 260508453 and `"stone"` to 274826446 — wildly different numbers
    whose last three digits are 453 and 446 — and `"wood"` and `"sand"` differ by 159027 in a
    number of 2.09 billion. WP-09b derives a footstep's timbre from the surface's name, so those
    two surfaces produced brightnesses 0.006 apart and **sounded identical**, with every rung
    green, a `playing=true` in the log and an inequality assertion passing. Adding a second derived
    axis did not help — the salted hashes collided the same way. The fix is an avalanche before the
    modulus (one multiply, two shifts), which moves the pair to 796 and 572. Two lessons, and the
    second is the general one: anything deriving a VALUE from a Godot string hash must mix it
    first, and **a regression assertion about a perceptible difference must demand a MARGIN**,
    because mere inequality is exactly what the broken version passed. Gotcha 2 with a speaker on
    it: a step that plays is not a step that follows.


37. **A BASE-CLASS `static var` IS ONE STORAGE SHARED BY EVERY SUBCLASS.** Probed under 4.7.2 with
    two throwaway subclasses bumping a counter declared on their base: `A.shared=3 B.shared=3
    Base.shared=3`. This is the opposite of the per-class statics most languages give you, and it
    is what made the obvious shape of T3.1 — `ItemDb extends ContentDb`, with `_by_id`, `_loaded`
    and `content_dir` on the base — silently catastrophic: five registries would have shared ONE
    cache and ONE content root, so `Fixtures.activate()` would have pointed all five at a single
    folder and four catalogues would have come back empty. Every accessor would still have been
    typed and the class diagram would still have looked right. The shared part of five static
    classes must therefore be a FUNCTION taking the caller's state, never inherited state. Three
    related facts from the same probe, each of which the design depends on: a `class_name` passed
    as a `Script` works with `is_instance_of()`; `Script.get_global_name()` returns the class name;
    and a `Dictionary[StringName, X]` handed to an untyped `Dictionary` parameter keeps its value
    type and is filled BY REFERENCE — which is the whole mechanism keeping every registry accessor
    typed with one shared scan. Related and cheaper to trip over: **`ResourceLoader` caches by
    path**, so re-saving a different resource over a path already loaded in this run hands the next
    scan the FIRST one. A new file name, not a second write.

38. **A MISSPELLED PROPERTY NAME IN A HAND-AUTHORED `.tres` IS SILENTLY DISCARDED.** Measured under
    4.7.2: `conditio_flag = &"bag/player/item/rose_petal"` in a quest step loaded with **no engine
    error, no warning and no `Invalid` line anywhere** — the resource simply came back with that
    field at its default. This project hand-authors every `.tres`, so it is exactly the slip the
    editor would have made impossible, and it is `[editable]`'s family (gotcha 27): a property the
    loader drops looks identical to a property nobody set. The only thing that saw it was
    `problems()` on the resource itself, and only because a non-ALWAYS test with no flag is a
    declared problem — a misspelt `condition_value` would have become 0 in silence, which is why
    T3.3's content gate refuses a count below one. **Every field a `.tres` sets that MATTERS must be
    reachable by `problems()` or by a checker**, or authoring it is a suggestion.


39. **AN UNDOCUMENTED ENGINE FORMAT CAN BE SETTLED BY MEASUREMENT, AND `[importer_defaults]` WAS.**
    Gotcha 30 stopped T2.1 for a good reason and reached the wrong conclusion, and this project's
    own non-negotiable #1 is why: *nothing is done until the engine has run it* is not merely a
    completion rule, it is an EVIDENCE rule, and it outranks the API dump. Measured under 4.7.2 in
    four steps — a throwaway texture copied into a scratch folder under `res://`, imported with stock
    defaults; the section written into `project.godot`; the generated `.import` DELETED; and
    `--headless --import` run again. It came back carrying `detect_3d/compress_to=0` and
    `mipmaps/generate=true`, against the stock `1` and `false`. So: the section works, the key is
    the **importer's** name (`texture`, not a file extension), the value is a **Dictionary of
    param paths**, it applies to a FRESH import only — an existing `.import` keeps its own params,
    which is why all eight committed ones had to be edited too — and
    `ProjectSettings.get_setting("importer_defaults/texture")` reads it back at runtime as a
    Dictionary (`type=27`), which is what makes it assertable rather than merely written. Two
    things generalise past textures. **A control value is what turns a probe into evidence:** only
    one value mattered, but a second one whose stock default was the OPPOSITE of what was written
    is what proved the section applied at all rather than the value happening to already be right.
    And **the stock defaults were measured, not assumed** — three of the four settings
    `ART_CONTRACT.md` had recommended turned out to be Godot's own defaults, so writing them down
    would have been ceremony that later reads as a decision.

40. **TWO CLASSES CAN EXPORT THE SAME PROPERTY NAME, SO A TEXT SCAN OF A SCENE FILE IS NOT A SCAN
    OF A NODE.** `HD2DCameraRig` and `WeatherVisuals` both export `height_offset`, and they mean
    entirely different things. An assertion that an area authors its own camera framing therefore
    PASSED with the framing deleted, because the courtyard's weather node carries a
    `height_offset = 5.0` line and the scan was looking at whole files. Every rung green, and the
    only reason it was caught is that the gate was proved red before being believed (gotcha 23) —
    which is the entire argument for planting the real violation, since the gate was the thing
    that was broken. Anything reading a `.tscn` as text must resolve the OWNING NODE first: walk
    `[node ...]` blocks, buffer each one, and match on the `script` ExtResource resolved to a path
    — buffering rather than switching on the `script` line as it goes by, because a property
    authored above `script` is legal `.tscn`. This is gotcha 17's family (`Area3D.priority`,
    `class_name Container`, `DictRead.get_name`, `ItemDb.reload`) moved out of GDScript and into
    scene text, and it is the sixth name collision this project has paid for.

41. **A DEFECT CAN BUY ITSELF A WEAKENED GATE, AND THAT COSTS MORE THAN THE DEFECT.** The engine
    printing false `Parse Error` lines on a mid-load shutdown (gotcha 13) was, on its own, cosmetic
    noise after a run had already reported cleanly. Its real price was paid one level up: CI's boot
    rung was written to grep only the LAST LINE of its log, with a comment explaining that a
    whole-log grep "would be a flake generator" — so the project's single most load-bearing check,
    the `Parse Error` grep that gotcha 22 exists to insist on, was switched off on that rung, on
    purpose, correctly, for as long as the defect lived. **Nobody weakens a gate for no reason;
    they weaken it because something real is making it lie.** So a gate carrying a comment that
    explains why it checks less than it could is a defect report in disguise, and the fix is
    upstream of the gate every time. WP-14 fixed the shutdown and switched the grep back on. When
    you find a scope-limiting comment on a check, read it as a lead rather than as settled design.

42. **AN ASSERTION THAT PASSES CAN STILL BE ASSERTING THE WRONG THING, AND ONLY PLANTING FINDS
    OUT.** WP-14's smoke test carried a comment claiming its save/load block asserted the
    save-participant ORDER — the invariant T3.3 established, that a derived count must be
    republished on `game_loaded` because `Flags._apply_save` wipes the store from underneath it.
    Deleting that subscription, which is exactly how the invariant would really be lost, left the
    assertion GREEN: the test's own wipe happened to let `_apply_save` publish for itself, so the
    ordering never came into play. The assertion was true, the comment above it was not, and no
    failure could ever have shown the difference. This is T3.2's framing gate (gotcha 40) in a
    second costume, and the same rule closes both: **plant the real violation even when the
    assertion looks obvious — especially then, because the thing being tested is the test.**

43. **AN ASSERTION THAT SCANS SOURCE FOR A GUARD WILL READ THE GUARD'S OWN DOCUMENTATION BACK TO
    ITSELF, AND WILL BE SATISFIED BY THE WRONG COPY.** WP-14b had to assert that the debug console
    and the performance overlay are unreachable in a release build. `OS.is_debug_build()` is true
    in every context the suite can run in — a test cannot exercise the false branch — so the
    assertable form is a text scan for the guard, the same mechanism `check_boundary.gd` already
    uses for `src/systems/debug/`. **The first version was wrong in two independent ways, and
    planting found both.** One: `screen_keys.gd` EXPLAINS its gate in a `##` comment, so a
    whole-file scan passed while reading its own explanation with the binding deleted — the fix is
    the comment rule every other text tool in this project already applies. Two, and it is the
    sharper half: `perf_overlay.gd` carried the identical fragment `if not OS.is_debug_build():`
    in BOTH `_ready` and `_input`, so deleting the real one left the assertion green on the
    decorative one. **That fix belonged in the CODE, not in the test.** `_input` and `toggle()`
    now ask `_label == null`, which is the same question and a stricter one — a release build
    leaves `_ready` early and never builds the label — so one place decides and the anchor is
    unique. Two rules generalise: **a scan-for-a-guard assertion must name a fragment that appears
    exactly once in its file**, and **a guard written twice is a guard that cannot be asserted**,
    which is a design smell before it is a testing problem. Gotchas 40 and 42's family, third
    costume, and the third time planting has caught the test rather than the code.


44. **A BLOCK THAT GATES ON A BROADER QUESTION THAN IT ASSERTS IS GREEN EVERYWHERE EXCEPT IN A
    CONSUMER'S HANDS.** `smoke_test.gd` asked *"does this checkout have any content?"* and then
    asserted about **areas**. Both extremes are fine — the full demo has areas, a stripped template
    has neither — so every run this project ever made was green. The failure lives only in the gap:
    a real game that authored one item before its first area, which is exactly the window
    `NEW_GAME.md` walks an author through while promising the ladder stays green. It was found by
    PERFORMING `docs/UPGRADING.md` against a real fork, and it could not have been found any other
    way, because a suite cannot run in a state neither of this repository's two checkouts is ever
    in. Two rules generalise. **A block must gate on the same question it asserts** —
    `Fixtures.area_ids()` already existed and is that question; the broader `has_demo_content()`
    was reached for because it was the one that was already being used. And **a template's
    intermediate states are a place tests never look**: the full demo and the stripped template are
    the two states this repo has, and every state a consuming game passes through lies between
    them. Gotchas 40, 42 and 43's family, fourth costume, and the first of them that no plant in
    this repository would have caught — the fork had to exist.

45. **A GATE THAT MATCHES SUBSTRINGS IS GREEN IN BOTH OF THIS REPOSITORY'S STATES AND RED ONLY IN A
    CONSUMER'S HANDS.** `check_boundary.gd` asked whether a line CONTAINS a content id. T4.2
    authored an item called `pear` — nothing exotic — and the gate failed on
    `tests/unit/menus_test.gd`'s *"and Load has appeared under it"*, because **`appeared` contains
    `pear`**. The full demo is green because its own ids happen not to collide; the stripped
    template is green because it has no ids at all; the failure lives only in the gap, and it needs
    an id this repository does not have. Gotcha 44's family, fifth costume, and **the second one
    that no plant here could have caught** — the content had to be authored. Three rules
    generalise. **A text gate that matches an identifier matches it as a WHOLE WORD**, or every
    short id (`pear`/`appeared`, `ore`/`before`, `art`/`start`) is a build failure a consuming game
    cannot fix. **A gate's failure message must not tell the reader whose bug it is** — the gate
    table in `AUTHORING.md` said a `check_boundary` hit "is a bug in the *engine*, not in your
    content", which sent an author to file a bug rather than rename an item. And **an engine test's
    throwaway literals are content ids waiting to happen**: `borrowed["pear"] = 1` was an arbitrary
    dictionary key that became a boundary violation the day a game used the word, so such literals
    come from the reserved `fixture_` namespace, which is immune BY CONSTRUCTION because an id
    sitting after an underscore is not a whole word.

46. **A RULE WRITTEN IN A FILE'S OWN HEADER CAN STILL BE UNFOLLOWED BY A CALL SITE IN THAT SAME
    FILE.** `dev_stage.gd` states gotcha 35's rule — staging that puts something on screen uses
    `_settle_stable`, not `_wait_for_area` alone — and `--stand-by` did not, for six packages.
    `--goto=<new area> --stand-by=<object in it>` therefore resolved the node name in the
    **departure** area, every time, deterministically rather than as a race, so no object in an
    authored area could be photographed at all. Every rung stayed green because the flag is only
    used by hand. Two rules. **A written rule with more than one call site wants an assertion, not
    a paragraph** — gotcha 41's family: a rule nothing checks is a comment. And **an assertion that
    a function contains a call must be scoped to that FUNCTION when the fragment repeats**:
    `_settle_stable(SETTLE_FRAMES)` appears three times in that file, so a whole-file scan is
    satisfied by any one of them and would have stayed green with the broken call site deleted.
    That is gotcha 43's rule met by narrowing the TEXT rather than the fragment, and the plant
    proved it — deleting the one call failed while the other two remained.


47. **A GAME FLAG WITHOUT `--` IS SWALLOWED BY GODOT, AND THE RUN THAT PROVES NOTHING LOOKS
    EXACTLY LIKE THE RUN THAT PASSED.** `--headless --new-game` does not start a new game. Godot
    keeps the argument for itself, `dev_stage.gd` never sees it, the run stops at the main menu
    having done nothing, and it ends `0 warnings, 0 errors` — green, and completely empty.
    Everything after `--` is the GAME's argument list: `"$G" --headless --quit-after 180 --
    --new-game` is the form that works. **`--quit-after` counts FRAMES, not seconds**, and gives
    the identical false green a second way: below about 120 the session ends at the menu before
    the flag has fired, so the same silent nothing appears for a completely different reason.
    `docs/NEW_GAME.md` section 6 asserted the behaviour of an unset first area for two packages
    without giving the command, so the natural guess was the one that verifies nothing. **A
    document that states an output must state the command that produced it**, which is the same
    rule as non-negotiable #1 aimed at prose.

48. **A MISSING PRUNE PREFIX SHIPPED SILENTLY, BECAUSE NO GATE READ `localization/` AT ALL.**
    **CLOSED BY T5.4**, and the closing is at the end of the entry — the diagnosis below is kept
    because it is the reasoning, and because half of it is still true.
    `check_boundary.gd` guards `src/`, `tests/framework/` and `tests/unit/` — the places where a
    demo id would be a LEAK. A demo row in `localization/strings.csv` is not a leak and not an
    error: it is a translation for content that was deleted, so nothing loads it, nothing resolves
    it and nothing complains. `check_strings.gd` anchors at sinks and declarations, so an orphan
    row is invisible to it too. The consequence is that `NEW_GAME.md`'s prune list is the ONLY
    thing standing between a fork and shipping this template's demo strings, and a list is exactly
    the artefact that rots: written at T1.2, it never learned about `quest.` when WP-08 added
    quests, so a fork shipped *"The Keeper's Errand"* and *"three rose petals"* inside its own game
    with all four checkers and 1,539 assertions green. **A checklist item with no gate behind it
    needs an expiry story**, and the story written here — "a grep the document tells the author to
    run" — was not one, because it rested on the author choosing to run it.
    **T5.4 found the expiry story the paragraph above says a tool cannot have, by asking the
    opposite question.** A tool that lists which prefixes are engine does rot; a tool that asks
    whether a ROW NAMES CONTENT THAT EXISTS derives everything and cannot. `check_boundary.gd`
    already computed the demo-name set from `data/` and `scenes/areas/`, so the orphan check was
    forty lines: a `quest.keepers_errand.*` row with no quest resource behind it is now **exit 1**,
    in the template and in every game built on it. Presence is still only REPORTED — 218 rows, 51
    in a content namespace — because the template legitimately ships its own demo rows and a gate
    switched off where it lives is decoration. **The stripped CI job now runs `NEW_GAME.md`'s
    `awk` verbatim and then this gate**, so the prune list is itself checked, by something derived
    from a different place. Two namespaces are still ungated and said so in the header: `object.`
    and `action.` keys are authored freely and match no id, so nothing can derive them.


49. **A SCRIPT THAT DOES NOT PARSE IS NOT `null`, SO THE TEST RUNNER SKIPPED A LISTED CASE IN
    SILENCE FOR THE LIFE OF THE SUITE.** `load()` on a `.gd` file with a parse error hands back a
    `GDScript` that exists, is not null, and cannot be instantiated. `_run_case` checked only for
    null, so it walked into `script.new()` — and **the failure of that call is a runtime error,
    which gotcha 24 already established aborts only the innermost frame.** So `_run_case` itself
    aborted, the `does not extend TestCase` failure two lines below was never reached, the `for`
    loop in `_ready` moved on to the next case, and the suite reported
    `=== 1608 passed, 0 failed, 0 skipped ===` and **exit 0** with an entire case never run.
    Measured, twice: the identical plant after the fix gives exit 1 and names the file. The
    sharpest part is that `tests/framework/error_watch.gd` **had counted the error the whole
    time** — `_no_script_errors` is read per case from inside `_run_case`, after `run()` returns,
    so an error raised on the way IN is tallied by the watch and read by nobody. T1.3 built two
    mechanisms because the first was measurably not enough (gotcha 24); this is the third hole in
    the same wall, and the one neither mechanism was positioned to see. Three rules generalise.
    **A guard that only checks `null` has not checked that a resource is USABLE** — `load()` has
    more than two outcomes, and `can_instantiate()` is the question actually being asked.
    **Gotcha 24's own reasoning applies to the RUNNER, not just to the cases** — the code that
    judges whether a frame aborted is written in the same language and aborts the same way, which
    is why the run-level backstop had to be a separate check rather than a better per-case one.
    And **a mechanism that sees a failure is worth nothing until something asks it**: the watch,
    the plan and the manifest were all correct and all silent here. Found by performing
    `docs/TESTING.md` — whose rule 5 *named* this failure shape in prose, as the thing
    `_manifest_is_complete` was analogous to, while nothing in the runner covered it. **The fifth
    document walked, and the fifth to find a defect; the third of the five where the defect was
    in the TEMPLATE rather than the prose.**


50. **A STAGING FLAG THAT GOES THROUGH A PERSISTED SETTING BREAKS THE NEXT RUN OF SOMETHING ELSE.**
    `--locale=<code>` is routed through `Settings.set_value` on purpose — a flag that set
    `TranslationServer` directly would photograph a path no player can take — and `set_value`
    calls `save()`, because a language choice should survive a relaunch. So one capture at
    `--locale=en_XA` left the setting on disk, and the NEXT suite run failed four assertions in
    `items_test` and `screens_test`: `expected fixture.fixture_stack.name x3, got
    [~~fixture.fixture_stack.name x3~~]`. Four failures, in two files the package had never
    touched, caused by a screenshot taken ten minutes earlier — and the suite had been green
    immediately before, so the obvious reading was that the last edit broke it. **A suite whose
    result depends on the developer's saved preferences is not deterministic**, and the fix is the
    one the runner already applied to time: `test_runner.gd` pins `Clock.paused` because a clock
    that advances mid-assertion makes time assertions flaky, and it now pins the locale for the
    identical reason one step further out. The pin reads `internationalization/locale/fallback`
    from `ProjectSettings` rather than hard-coding English, or a consuming game whose default is
    another language would inherit the flakiness the pin exists to remove. Two rules generalise.
    **Anything global that a dev flag can persist must be pinned by the harness, not trusted to be
    put back** — the flag was correct, the capture was correct, and the failure was still real.
    And **a failure in a file you did not touch is evidence about the ENVIRONMENT, not about your
    change**; the ten minutes spent suspecting the edit were spent because that reflex is backwards.

51. **`update_from_velocity` FROM A PROBE MEASURES NOTHING, AND `run` IS A TOGGLE.** Two facts,
    one probe, and both cost a measurement that looked like data. Driving
    `CharacterVisual.update_from_velocity` directly from `dev_probes.gd` reported the drawn cell
    frozen at 0 through twelve frames at two different speeds — which reads as "the walk cycle is
    broken" and is actually **`PlayerController._physics_process` overwriting the visual from its
    own velocity every physics frame**, that velocity being zero because nothing was pressing
    anything. A visual driven by a controller can only be measured THROUGH the controller: press
    the real action with `Input.action_press` and let the body move. The second fact bit
    immediately afterwards: `run` is a TOGGLE (`run_is_toggle`, polled through
    `is_action_just_pressed`), so `Input.action_press(Actions.RUN)` toggles it rather than holding
    it — the "running" trial covered **0.75m against walking's 2.30m**, having toggled off and
    then walked into the dais, which is a number that looks like a finding and is an artefact
    twice over. `sneak` is a hold and is what a speed comparison should use. Corrected, the
    measurement is clean and matches the formula: `4.04m / 8 cell changes` walking against
    `1.50m / 4` sneaking over 60 frames, against
    `walk_fps 8.0 * clampf(speed / 3.2, 0.35, 2.0)`. **A probe that reads a value someone else
    writes every frame is reading their answer, not yours.**


52. **`--shot-frame` AIMS AT A FRAME NUMBER, AND THE SAME FRAME NUMBER IS A DIFFERENT MOMENT IN
    EVERY RUN.** T5.2 needed three captures of one character in three gaits, and spent an hour
    getting them because a frame is not a point in the game's story. **Measured across runs of the
    identical command: the player was grounded in its area at process frame 17 in one run and at
    frame 115 in another** — the area load is threaded, so everything downstream of it slides by
    a hundred frames. Three separate failure modes came out of that one fact. A capture aimed
    early enough to catch a gait in one run **landed before the area existed in the next**, and a
    PNG of empty sky with a working HUD looks exactly like a rendering bug rather than a mis-timed
    shutter. A capture aimed late enough to be safe caught a character that had **walked clean out
    of the area** — x went 0 to -16.8 by frame 115 at run speed, and the camera followed it into
    nothing. And an oscillation added to keep the character in frame introduced a **one-frame
    window where velocity is zero** between releasing one direction and pressing the other, in
    which the visual correctly reports IDLE — so a walk capture came back showing the idle block
    and the honest reading of it was "the feature does not work". Three rules. **A capture that
    must land on a game STATE needs the shutter driven by that state, not by a frame count** —
    aim at a window, verify from the log which state the run was actually in at that frame, and
    treat the number as a guess to be checked rather than a setting. **Ask the ASSET before
    blaming the renderer:** sampling the generated sheet's pixels settled in one command what four
    captures had left ambiguous, because a PNG on disk has no timing in it. And **a probe that
    starts before the area does measures nothing** — `_gait_parade` skipped the
    `while Director.current_area_id == &""` wait that every other probe in that file opens with,
    and duly reported the player falling from -0.30 to -20.54 with `is_on_floor()` false, which is
    gotcha 9 seen from a probe that arrived too early and reads as "the player falls through the
    world".


53. **THE `.godot` IMPORT CACHE IS GITIGNORED, SO SWITCHING BRANCHES LEAVES THE OTHER BRANCH'S
    ASSETS IMPORTED AND THE SUITE FAILS ON A MISMATCH THAT EXISTS IN NEITHER BRANCH.** Measured
    while recording T5.2's CI run: `git checkout` back to the previous branch, run rung 4, and
    `the default layout fits its sheet — expected 0, got 1`. Both branches were green in CI.
    Nothing was wrong with either. `assets/placeholder/character_placeholder.png` had been
    regenerated at 256x576 on one branch and the checkout correctly restored the 256x192 file — but
    the IMPORTED texture lives in `.godot/`, which is gitignored and therefore not part of what a
    checkout changes, so the layout resource from one branch was being validated against the
    imported texture of the other. **`--headless --import` after the checkout, and it is
    `1653 passed, 0 failed`.** This is the fresh-clone rule (`--headless --import` FIRST, because
    `class_name` globals live in that cache) with a second and less obvious consequence: the cache
    holds IMPORTED ASSETS as well as script globals, so it goes stale on a branch switch and not
    only on a clone. Two rules. **Re-import after any checkout that touches an asset or a
    `.import` file**, and treat a rung-4 failure immediately after a branch switch as a cache
    question before a code question. And **a failure that contradicts a green CI run on the same
    tree is evidence about the local environment**, not about the tree — the same reflex gotcha 50
    asks for, one layer down: there, a leftover setting; here, a leftover import.
54. **A UNIT TEST AT EACH END OF A SEAM PROVES NOTHING ABOUT THE WIRE BETWEEN THEM, AND TWO GREEN
    ASSERTIONS READ AS COVERAGE OF THE WHOLE PATH.** T5.2 shipped `MoveState.CLIMB` as an
    addressable animation block. `traversal_test.gd` asserted a climbing body reports
    `state == CLIMB`; `art_contract_test.gd` asserted `animation_for(CLIMB)` returns the climb
    row. Both passed. **CLIMB never reached the sprite at all** — `_physics_process` returns
    early while a climb owns the body, so the one line that hands the state to the visual was
    unreachable, and `climb_step` touched the visual only after resetting the state to IDLE. The
    exit criterion was ticked, 1,676 assertions were green, and `climb_row` was undrawable. The
    defect is invisible in the demo because the shipped sheet leaves `climb_row` at -1 and the
    fallback draws the walk block, so the first observer would have been the first game to draw
    a climb cycle. **The assertion that catches this class asserts the OUTPUT of the whole path,
    not the state at either end**: decode the block out of `sprite.frame` after driving a real
    climb, which fails with `expected 1, got 0` the moment the wire is cut. Ask of any seam:
    which assertion fails if the middle is deleted? If the answer is none, the middle is
    unverified however many assertions surround it. This is the same lesson as gotcha 22 (`0
    warnings, 0 errors` counts the game's own logging, not compile errors) and gotcha 24 (a
    GDScript runtime error aborts only the innermost frame) in a third place: **a green signal
    that was never wired to the thing it claims to describe.** Found by an audit that swept for
    declared-and-unread values rather than by any gate, because no gate looks for one.
55. **A RULE WITH NO GATE IS A RULE THAT IS ALREADY BEING BROKEN, AND YOU WILL NOT FIND OUT FROM
    A GREEN LADDER.** `ARCHITECTURE.md` has stated `core -> content -> systems -> gameplay -> ui,
    downward only` since Phase 0, gives the test in the next sentence — *could you delete the
    layer above and still compile?* — and nothing had ever run it. T5.4 wrote the four-line
    checker, expecting to confirm a clean tree because the package brief said the tree was clean.
    **First run: 55 upward references, exit 1.** Forty-two were the debug harness, which is the
    same exemption `check_boundary.gd` already grants for the same reason. Thirteen were real:
    `interaction_sensor.gd` sat in `systems/` and was typed on `Interactable`, which is
    `gameplay` — delete `gameplay/` and `systems/` does not compile, the document's own test,
    failed. The file was simply in the wrong layer: its second line says it *"lives as a child of
    the player"*, and a player component is not a game-agnostic service. Moved to
    `src/gameplay/interaction/` and the reference became legal with no exemption. **This is the
    same shape as `const FIRST_AREA := &"courtyard"` sitting in `core` before T1.2 — it passed
    eight verification rungs because no rule forbade it — with the roles reversed: here the rule
    existed and the enforcement did not.** The transferable form: for every invariant a document
    states, ask which command fails when it is violated. If the answer is none, the invariant is
    a wish, and the cost of discovering that grows with the tree. Writing the gate is cheap while
    the tree is nearly clean and expensive once it is not — and you do not know which you have
    until you run it.

56. **A TEXT SEARCH FOR A WIRE CAN STAY GREEN AFTER THE WIRE IS CUT, BECAUSE THE DECLARATION IT
    FINDS IS NOT THE CONNECTION.** T5.5 built `UiAccessibility`, wired it into `game_root.tscn`,
    and — mindful of gotcha 54 — added the assertion that gotcha 54 asks for: not just that the
    class works, but that the running game instances one. It read the `.tscn` as text and
    required the script path and `parent="UILayer"` to both appear. **Then the node was deleted
    as a plant and the suite stayed green: `1782 passed, 0 failed`, byte-identical.** Both halves
    were still in the file — a `[ext_resource]` line SURVIVES the removal of every node that used
    it, and eight other nodes carry that parent — so the assertion was really checking that the
    file still mentioned a script somewhere, which it always would. The fix was to stop reading
    the scene as prose: `PackedScene.get_state()` gives `SceneState`, where a script is a
    PROPERTY of a node and the node either exists or does not, and `get_node_path(i, true)`
    answers `./UILayer`. Replanted: `expected ./UILayer, got ` — exit 1. **The transferable form
    is narrower than gotcha 54 and sharper: an assertion about STRUCTURE must be made against a
    parser, not a substring, because a file's declarations outlive the things that referenced
    them.** And it says something about gotcha 54 itself — writing the wire assertion is not the
    hard part, writing one that can actually fail is. Plant every assertion whose job is to
    catch an absence; the ones that check for a presence tell you they work by passing, and the
    ones that check for an absence never tell you anything at all.

57. **A GENERATOR THAT CLIPS TO THE IMAGE INSTEAD OF TO THE CELL DRAWS INTO THE NEXT CELL, AND
    THE SHEET STILL LOOKS LIKE PEOPLE.** `_plot` in `tools/gen_placeholders.gd` bounds-checks
    the IMAGE, which is correct and useless: a sprite sheet is a grid of independent cells, and
    T5.6's run block overreached its stride by four pixels so the trailing boot's last row
    landed at y=40 — one row inside the cell below, where it drew a stray foot floating above
    the next block's head. Every rung stayed green, because no rung looks at a placeholder's
    pixels, and at a glance the sheet was fine. **The assertion caught it on its first run**:
    `and no cell bleeds into the one below it — expected [], got [8, 9]`. The transferable form
    is that a cell's TOP ROW is the one row nothing legitimately occupies, so it is a free and
    exact test for the whole class — and it costs one assertion for any number of cells.

58. **A SPRITE ANCHORED BY ITS FEET HAS ITS BOTTOM ROWS EATEN BY THE GROUND PLANE, SO ANYTHING
    DRAWN THERE CANNOT BE READ IN A CAPTURE.** `CharacterVisual` lifts the sprite by half its
    cell height so the node origin sits where the collision capsule does, which puts the last
    few rows of every cell right at the ground and behind it in depth. T5.6's frame tally lived
    at `cell.y - 3` and photographed as ONE pip where the decoded frame said three: the tally
    was right, the sheet was right, and the picture was unreadable. Moved to `cell.y - 7`.
    **This is a capture STANDARD failing rather than a drawing failing**, and it is invisible to
    every check that reads the PNG instead of the screen — the assertion on the sheet passed
    throughout. If a placeholder carries information meant to be read off a screenshot, keep it
    clear of the bottom four rows.

59. **READING A SPRITE'S FRAME BEFORE THE POST-DRAW AWAIT MEASURES A DIFFERENT MOMENT FROM THE
    PHOTOGRAPH, AND THE DISAGREEMENT LOOKS LIKE A CONTENT BUG.** `await
    RenderingServer.frame_post_draw` lets a physics step run, so a probe that logs
    `sprite.frame` and then awaits the shutter has produced two honest measurements of two
    different frames. T5.6 spent a while believing its own sheet was wrong because the log said
    cell 2 and the image showed one foot pip. Await first, then read the frame and grab the
    image together — inside the post-draw callback nothing advances, so the number and the
    picture are the same frame by construction. This is the sharp edge of the project's own
    rule that a capture must be READ rather than judged: reading it against the wrong number is
    worse than not reading it.

60. **`Camera3D.unproject_position` ANSWERS IN THE VIEWPORT'S LOGICAL SIZE, NOT IN THE CAPTURED
    IMAGE'S PIXELS.** This project scales content from 1920x1080, so under
    `--resolution 960x540` the viewport still reports a visible rect of `(1920, 1080)` while
    `get_viewport().get_texture().get_image()` returns a 960x540 image. Every unprojected point
    therefore comes back at exactly twice its place in the capture, and T5.6's first five zoom
    crops were photographs of grass with the character just off the edge. Scale by
    `Vector2(shot.get_size()) / camera.get_viewport().get_visible_rect().size` rather than by a
    literal 0.5, or the crop is right at one resolution and silently wrong at every other.

61. **A CONSTANT THAT "SPELLS OUT THE ENGINE'S DEFAULT" IS A SECOND COPY OF A NUMBER YOU DO NOT
    OWN, AND `--headless` CANNOT SEE IT WRONG.** `Settings._apply_shadows` sized the shadow
    atlas to zero to turn shadows off and restored `const POSITIONAL_ATLAS: int = 2048` to turn
    them back on, under a comment calling 2048 the engine's own default. It is 4096 —
    `rendering/lights_and_shadows/positional_shadow/atlas_size` and the directional size both
    default to 4096 in 4.7.2 — so this repository booted every windowed session at half the
    shadow resolution the project authored, measured `boot = 2048` against `boot = 4096`. Two
    things hid it. The OFF half is the half a wrong constant cannot break, and off is the only
    half T5.5 photographed. And `_apply_display()` returns early when
    `DisplayServer.get_name() == "headless"`, so no rung below the windowed capture executes this
    code at all — the suite could not have caught it however many assertions were pointed at the
    setting. Read the authored value back before the first write, the way
    `HD2DCameraRig._authored_dof` does; a preference is a VETO over what the author chose, and a
    veto has to remember what it is vetoing.

62. **AN ASSET CAN BE THE UNWIRED MIDDLE, AND A SYSTEM CAN BE CORRECT, ASSERTED AT BOTH ENDS AND
    INVISIBLE FOR FIVE PHASES.** The facing system quantises a direction into a `GameEnums.Facing`
    (`facing_test`) and a sheet COLUMN (`art_contract_test`), and every one of those assertions
    was green and right. `character_placeholder.png` drew ONE POSE EIGHT TIMES: measured over the
    figure band, facing 4 — the back, 180 degrees from the front — differed from facing 0 by
    **0.7%** of a 1,536-pixel cell, and facings 2 and 3 were **byte-identical**. The alt sheet was
    worse: three of its four columns differed only by the column tally. **The first observer was
    an owner who played the game** and said sideways movement "just slides to the side". This is
    gotcha 54 with the middle made of pixels instead of code, and it is harder to see for one
    reason: no rung reads a placeholder's pixels, and a sheet that looks like a person passes
    every glance a capture gets. The transferable form: for any seam whose two ends are DATA and
    CODE, ask what the data has to CONTAIN for the code's correctness to be observable — and
    assert that, because "the column index is right" and "the column looks different" are two
    claims and only one of them was being made. The floor was picked by measurement rather than
    taste (0.05, against the old sheets' best pair at 0.035 and the new sheets' worst at 0.075),
    which is T5.5's rule for a threshold applied to an image.
63. **A COLOUR YOU WROTE INTO AN IMAGE IS NOT THE COLOUR THAT COMES BACK, TWICE OVER, AND BOTH
    HALVES COST T5.8 A RUN.** On the WRITE side, `Image.FORMAT_RGBA8` quantises: `0.68` is stored
    as `173/255` and reads back as `0.6784`, which is near enough to look identical and far enough
    to fail `Color.is_equal_approx` — so a generator pass that repainted "every SKIN pixel" as hair
    matched nothing and drew five bald heads. Compare a read-back colour with an explicit
    tolerance, never with an epsilon. On the READ side, **the imported texture is not the PNG**:
    `process/fix_alpha_border=true` is on for every texture in this project and rewrites the RGB
    of TRANSPARENT pixels so filtering cannot pull a halo out of them. It works on the whole image
    rather than per cell, so a pip tally bleeds its colour into the transparent margin of the
    cell next door, and a mirror assertion comparing all four channels reported two cells as
    unmirrored **over pixels the sprite discards before it draws them** (`ALPHA_CUT_DISCARD`). Two
    transparent pixels are the same pixel. Any assertion that reads an imported sheet has to say
    which pixels are VISIBLE before it says whether they agree.
64. **A CAMERA THAT TRANSLATES PARALLAXES, SO A RIGID-OFFSET SEARCH UNDER-REPORTS IT — AND THE
    TWO NUMBERS WILL NOT RECONCILE.** T5.7's brute-force offset search is the right tool for
    "did the picture move", and T5.9 used it again on the screen shake. But the focal-plane
    maths says a camera sliding 0.302 m at 14 m and a 27-degree lens should move the image about
    24 px, and the best rigid fit came back at **(+14, −12)**. Neither number is wrong. A camera
    TRANSLATION shifts near geometry further than far geometry, so there is no single offset that
    fits the whole frame, and a least-residual search returns a depth-weighted average of all of
    them. What the search proves is that the scene moved RIGIDLY ENOUGH that one offset drops the
    residual sharply — 0.0513 to 0.0173, a 3.0x fall — and it is that RATIO, plus a control at
    the same offset, that carries the claim. Do not quote the pixel count as a measurement of the
    displacement; the metres in the log are the measurement, and the search is the corroboration.

65. **A SIGNAL THAT ANNOUNCES THE END OF A THING IS EMITTED BEFORE THE FLAG SAYING IT ENDED IS
    CLEARED, AND A GUARD READ ON THE SPOT REFUSES EVERY TIME — SILENTLY, BECAUSE EACH REFUSAL IS
    CORRECT.** `Director._run_transition` emits `area_entered` and clears `_transitioning` **two
    statements later**, which is right: the signal's contract is "the area is in the tree and the
    player is placed", and the transition is not formally over until the curtain has been asked to
    lift. So `Autosave`, connected to `area_entered` and guarded by `is_transitioning()`, would
    have hit its own guard on every single arrival and never once written a file. Nothing would
    be red anywhere: no error, no warning, both ends of the wire correct, the guard behaving
    exactly as specified, and a feature that does nothing at all. It is gotcha 54's family with
    the unwired middle made of ORDERING rather than of a missing connection. The fix is one
    `await get_tree().process_frame` before the guard, and the assertion that pins it emits
    `area_entered` inside a synchronous `run()` — where no frame ever comes — and requires that
    **nothing was written**. Before trusting any guard on a `_entered` / `_finished` / `_changed`
    signal, read the emitter and find out what is still true at the moment it fires.

66. **A FADE AND A CUT READ IDENTICALLY IN A SYNCHRONOUS TEST, AND THE FIX IS TO STEP THE TWEEN
    BY HAND RATHER THAN TO GIVE UP ON THE CLAIM.** `TestCase.run()` is synchronous, so no idle
    frame ever arrives and a tween created inside it never moves at all — which means an
    assertion taken after the call sees the value the fade STARTED from, and an assertion taken
    after a `custom_step` long enough to finish sees the value it was heading for. Neither
    distinguishes a 0.4-second fade from an instant jump, and T5.7 wrote that down as a limit
    assertions could not reach. They can. `SceneTree.get_processed_tweens()` returns the live
    tweens and `Tween.custom_step(delta)` advances one by exactly `delta` — so "the bus has NOT
    moved yet", "half the fade is half the drop" and "the whole fade lands exactly on target" are
    three separate measurements, and a fade rewritten as a cut fails all three (measured, T5.11
    plant 2, exit 1). **Snapshot the tween list BEFORE the call under test and step only what is
    new**: stepping every processed tween would advance a screen fade or a music cross-fade some
    other case owns and is mid-flight. The default transition is linear, which is what makes the
    midpoint assertion exact rather than approximate — a tween authored with an ease would need
    the curve, not the fraction.

67. **A CAMERA STILL CATCHING UP WITH A TELEPORTED PLAYER LOOKS EXACTLY LIKE A SHAKE, AND THE
    FIRST TRACE THIS PROJECT TOOK OF ONE WAS THE WRONG PHENOMENON ENTIRELY.** T5.12's gate probe
    teleported the player, waited twenty frames, sampled the camera as `rest`, opened the gate and
    reported **0.428401 m rising monotonically to 0.428789 and stopping**. Every part of that run
    was green and the number was a real measurement of a real camera movement — of `follow_lag`.
    Exponential smoothing APPROACHES its target and never arrives, so there is no frame count
    after which a rig is "settled"; twenty frames leaves 4 % of the error, and 4 % of a 10 m
    teleport is three times the shake being looked for. **The tell is the SHAPE.** A decaying
    oscillation crosses its rest position repeatedly; an asymptotic approach never crosses it at
    all, and both summarise as "the camera moved by X". The fix is to wait on the DERIVATIVE
    rather than on a frame count — per-frame movement under 10 µm, which took **53 frames** — and
    the general rule is that any measurement taken against a smoothed value needs the smoothing
    proved finished, not assumed finished. Gotcha 52's family with the still moment made of
    convergence rather than of animation frames.

68. **A SCREEN'S NODE NAME IS ITS ENGINE CLASS, NEVER ITS `class_name`, SO `find_child` CANNOT
    FIND ONE.** `find_child("MainMenuScreen")` returned null on a session with the main menu
    plainly on screen: a `UiScreen` is `.new()`d rather than instanced from a `.tscn`, and Godot
    names a scriptless-instantiated node after the ENGINE class the script extends — `Control`
    here — so every screen in the stack shares one unhelpful name. `UiRoot.top()` is the answer
    and the reason the stack is public: a screen's identity is `screen_id` and its position in the
    stack, and its node name is an engine detail that happens to be a string. The same trap waits
    for anything else built with `.new()` — every menu, every dialogue box. Nodes that come from a
    `.tscn` keep their authored name, which is why `find_child("Player")` and
    `find_child("NorthGate")` work in the same file three lines away.

## How work is sliced

**One package, one chat** — see [`docs/WORK_PACKAGES.md`](WORK_PACKAGES.md), which is the
board of every package from here to skeleton-complete — WP-01 to WP-15 plus the T-phases. Each
names the exact files that chat should read, so a session loads a few hundred lines instead of three thousand. The layer rule
(`core -> content -> systems -> gameplay -> ui`, downward only) is what makes that possible: a
package never has to read upward.


**Next package: NOTHING IS BLOCKING, AND THE STRONGEST CANDIDATE IS A QUESTION FOR THE OWNER.**
Candidates D, G, H, I and J are all done (T5.6 to T5.10), and what is left of Phase T5 is a second
idle block — a chooser on top of machinery that already works — and **candidate C, a turn in
place, which is a SEAM decision three rows in a row have declined to make silently.** T5.8 changed
the case for it: a turn in place was not worth animating while every facing drew the same picture,
and now that every facing draws a different figure, it is. **Putting that question to the owner is
itself the next action, and it is cheaper than any package below.** What follows is a real choice,
not a queue:

- **Candidate C — a turn in place, but the seam decision FIRST. Recommended, as a question.**
  `face_direction()` has only test callers, so nothing in this game changes facing while
  stationary. The question is WHO may ask for a turn: the player facing an interaction target, or
  an NPC facing the player in dialogue. `Speaker` is 17 lines and deliberately knows only a
  conversation id, so it is probably `NpcBrain` or `InteractionSensor` — **but that is the owner's
  call and must not be picked silently.**
- **Candidate E — music ducking, or delete it.** `stop_music`, `duck` and `unduck` have no callers
  anywhere. Lowering music under dialogue is the obvious use and `DialogueRunner` is the home; the
  honest alternative is deleting three methods.
- **Candidate F — the `Button` styleboxes.** The theme sets `font_sizes` on nine type variations
  and no `Button/styles/*`, so every menu row draws Godot's default StyleBox — already a declared
  known limitation, invisible against the shipped dark palette and immediately wrong against a
  light one.
- **A `dev_probes.gd` row for the two capture gaps that are now written down twice.** T5.9 wants a
  probe that unlocks the gate, hands over the key and photographs a gate opening; T5.10 wants one
  that boots, autosaves, quits, relaunches and continues into the autosave. Both are the same
  shape — a scripted scenario no assertion can run — and one row could close both.
- **Split `tools/gen_placeholders.gd`**, at 230 of its 250, character sheets against flat textures.
  It has been the next file to split for three rows and no row has touched it.
- **WP-10 crafting**, if a game wants it. Still OPTIONAL, still a genre choice per `TEMPLATE.md`.
- **Nothing at all**, which stays a legitimate answer for a base that has answered every question
  it set out to.

*(This line names ONE package or one honest choice between a few. Earlier revisions accumulated a
stale line per package and two were left stranded here; if you ever find two, the lower one is
history — delete it.)*

The original WP-08 through WP-15 continue after the T1 and T2 phases, several of them re-framed.

## Plan — where this is going

**Phase 1 is complete and Phase 2 is well under way.** The demo loop works end to end: walk a lit
courtyard through a day/night cycle, be prompted, read a sign, throw a lever, take an item,
empty a chest, be refused by a gate that wants a key, open it once you carry the key, cross a
volume that fires once, rest on a bench and watch the light change, climb a trellis to a terrace
and back down, press I at any point to see what you are carrying in a window that stops the
world — then walk north through a door into a lantern-lit hall that has never heard of the sun,
and come back, and ask the garden-keeper who they are and what lies behind the north gate, in a
box that leaves the world running behind it — and that conversation now hands you an errand, which
the lever you already threw and the dais you already crossed advance, and three rose petals out of
the wicker chest settle — the journal counting them `2 / 3` on the way, readable on `J` at any
point — and pick a lantern up, hold it from the satchel with Enter, and pass under an arch
that turned you away a moment earlier with a line its author wrote — and press `M` to see the two
places you know drawn on one map, the hall a grey `???` until you have walked to it and a gold dot
you can press to travel back to once you have — and every one of those walks now sounds different
depending on whether you are crossing grass, the wooden dais or stone. Every one of those changes
survives a save and a
reload, including from the far side of an area that is no longer loaded. All of it is covered
by 1,676 headless assertions.

**Next, and for the first time it is not an ordered queue.** Every blocking row is done: Phase T3
closed with WP-14b, WP-15 was CLOSED by the owner, and T4.1 shipped the version and the upgrade
note. The one criterion left in Phase T4 is a RELEASE TAG, which is the owner's to take.

1. **The rest of the system catalogue is COMPLETE**, and WP-15 is closed — see the board. WP-11
   closed the last row that had no proof at all, and WP-10 is OPTIONAL.
   *(Every T-numbered row is DONE. T3.1 — one scan behind all five catalogues, every accessor still
   typed. T3.3 — an item count is a flag published downward, so a step can require N of an item id
   and the quest system still does not know what an inventory is. T3.2 — the look of an area is
   data: a shared material library, the environment post stack and per-area camera framing, plus
   texture import defaults settled by measurement and Git LFS refused in writing.)*

*(Path actions, NPC schedules, navigation baking, weather visuals, quests, equipment, the world
map, the shared content scan and counted quest steps are all DONE — WP-06, WP-07, WP-08, WP-09, WP-09b, WP-11,
WP-13, T3.1 and T3.3.)*

**Still open, and expensive later:**
- **The export path is PROVEN as of T2.0** — an exported `.exe` reports the same catalogue counts
  and resolved paths the editor does. What remains unproven is a RELEASE export's content, because
  the readout is behind `OS.is_debug_build()`, and every platform other than Windows.
- **The string audit exists as of WP-14 and is deliberately PARTIAL.** `tools/check_strings.gd`
  checks a literal reaching a text SINK and every `*_KEY` const resolving. What it still cannot
  see is written in its own header: a literal reaching a sink through a variable, a sink outside
  `src/*.gd` (a `.tscn` authoring `text = "Play"`), a literal handed to `draw_string()`, and
  whether the key `tr()` got was the RIGHT key. Computed keys (`verb.*`, `refusal.*`) are still
  the enum loop in `items_test.gd`, which is better verification than a scan could be.

## Read next

`CLAUDE.md` (rules, and the doc router table) · `docs/TEMPLATE.md` (why this is not a game) ·
**`docs/AUTHORING.md`** (add an area, an NPC, a conversation, an item, an object, a quest,
equipment, a place on the world map) ·
**`docs/ART_CONTRACT.md`** (what art must satisfy) · **`docs/TESTING.md`** (adding assertions) ·
`docs/ARCHITECTURE.md` (§ The extension surface — what may be subclassed) ·
`docs/NEW_GAME.md` · `docs/SYSTEMS_INVENTORY.md` · `docs/ROADMAP.md` · `docs/DEVLOG.md` ·
`src/core/events/events.gd` (the connection map)
