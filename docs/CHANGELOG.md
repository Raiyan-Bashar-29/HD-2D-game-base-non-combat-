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
## 5.2.0

*2026-09-09 — the save store becomes redirectable, so the suite stops writing into the
developer's own save directory. One `const` became a `var`; the rest is tests.*

**A consuming game does: nothing.** `SaveSystem.SAVE_DIR` is gone, but nothing outside
`save_system.gd` ever referenced it — the search that preceded this change found six uses and all
six were in that file. If your game DID reference it, the replacement is `SaveSystem.save_dir`
and the shipped default is `SaveSystem.DEFAULT_SAVE_DIR`; that is the only rename in this
release, which is why it is a MINOR rather than a MAJOR.

**What was wrong.** `tests/framework/fixtures.gd` repoints five content roots under
`user://test_fixtures` so a run reads fixture content instead of the game's. The save store was
the sixth root and the only one left out, because its directory was a `const`. So
`save_recovery_test.gd` — which exists to write MALFORMED save files — and `core_test.gd`'s round
trip both wrote real slots into whatever `user://saves` resolves to on the machine running the
suite. Both delete what they write, which is not the same as never having written it: a case that
crashes between the write and the delete leaves the file behind, and the slot numbers the suite
picks are slot numbers a player may have filled.

**What a game gains, and it is why this is public rather than test-only.** `save_dir` is settable
at runtime and creates the directory when assigned, so a portable build that wants its saves
beside its executable is now one assignment rather than a fork of `save_system.gd`. A test-only
backdoor was the alternative and is the thing `fixtures.gd`'s own header refuses to add.

**New: `tests/framework/save_fixture.gd`**, with `activate()` / `deactivate()` / `is_active()` on
`Fixtures`' shape, emptying the scratch directory on the way in as well as out. `test_runner.gd`
calls `SaveFixture.deactivate()` after every case unconditionally, for the reason the existing
`Fixtures.deactivate()` call states: a case that crashed part way through would otherwise hand
the next one a redirected store.

**And `tests/unit/save_dir_test.gd` is new**, 18 assertions split by QUESTION from the two cases
either side of it — `core_test.gd` asks *does a good save survive*, `save_recovery_test.gd` asks
*what happens to a bad one*, and this asks *which directory did it go in*. A fork that changed
where saves live will go red here; that is the case doing its job.

---
## 5.1.0

*2026-09-09 — the sensor's SELECTION rule gets the scene-level test it has been asking for in
writing since WP-02, and that test found a defect in the tie-break on its first run.*

**A consuming game does: nothing, unless it has two interactables that overlap EXACTLY, in
which case which one gets the prompt may change — for the better.** `InteractionSensor` breaks
a scoring tie by node name, and `_select()` compared `a.name < b.name`. `Node.name` is a
`StringName`, and `<` on two of those compares their **interned addresses, not their text**, so
ties were ordered by whichever name the engine happened to intern first — script and scene load
order. Measured both ways in one run: for the same pair of names, the `StringName` comparison
said `Z_later < A_earlier` and the `String` comparison said the opposite. The fix is one cast,
`String(a.name) < String(b.name)`.

**What that changes for a game.** The documented rule now actually holds: naming two
overlapping objects `sign_a` and `sign_b` chooses between them, which it did not before. If your
game had two objects at an exact tie and relied on the old winner, it may swap — but it could not
have relied on it, because the old winner depended on intern order and could differ between a
fresh boot and the same objects reached another way. Nothing outside an exact tie is affected:
priority, then proximity, then facing all rank as they always did.

**`InteractionSensor` gained one public method, `cycle()`.** It is the Tab override extracted
from `_handle_input` so it can be called without a keypress, and it returns false when there is
only one candidate. A subclass that overrode nothing is unaffected. It exists because the suite
is synchronous and provably cannot press a key: `Input.parse_input_event` is buffered until a
main-loop flush that never comes mid-run, and `Input.action_press` does land but then leaves the
action reading `is_action_just_pressed() == true` for the whole run, which would cycle every
other case's sensor. The key binding itself is still proved windowed by `dev_stage.gd --cycle`.

**And `tests/unit/selection_test.gd` is new**, 24 assertions on the ranking, the candidate set,
the cycle and the two prefabs — `Readable` and `Speaker` — that `AUTHORING.md` tells you to place
and which nothing had asserted at all. If your fork changed the ranking, it may go red on merge;
that is the case doing its job. 2,148 → 2,173 — the extra assertion beyond the file's own 24 is
`record_shape_test.gd` computing its plan from what it finds, and it now finds one more package on
the board.

**If you are merging from `4.3.1` or earlier, read the `5.0.0` entry below as well** — this is a
MINOR, but it sits on top of a MAJOR whose one obligation still stands: add the `DevScreens` node
to `game_root.tscn`.

---
## 5.0.0

*2026-09-09 — `src/systems/debug/dev_stage.gd` was at 248 of its 250 allowed code lines, so the
five staging flags that push a SCREEN moved into a new sixth debug file, `dev_screens.gd`. No
behaviour changed; the same invocations produce the same logs, byte for byte.*

**A consuming game does ONE thing: add the `DevScreens` node to `game_root.tscn`.** That is the
whole obligation, and it is a MAJOR rather than a MINOR because skipping it does not cost you a
new feature — it silently REMOVES five flags you may already be using. `--open-inventory`,
`--talk=`, `--talk-advance=`, `--open-menu=` and `--console=` are parsed by the new node and by
nothing else, so without it every one of them is read by no `_parse_arguments` at all: no error,
no warning, and a capture that comes back looking like a game that was never asked to do
anything. Compare version 3.1.0, which added a debug file whose absence merely meant going
without something new.

The one-line replacement, immediately after the existing `DevStage` node:

```
[node name="DevScreens" type="Node" parent="."]
script = ExtResource("22_screens")
```

with its resource line beside the others in the header, and `load_steps` incremented by one:

```
[ext_resource type="Script" path="res://src/systems/debug/dev_screens.gd" id="22_screens"]
```

**The order matters and is not cosmetic.** `DevScreens` must sit AFTER `DevStage`, because these
flags draw over what that file poses — `--give` fills the bag that `--open-inventory` photographs.
Node order is `_ready` order, so putting it earlier lets a screen resume a frame before the state
it is meant to show. If your `game_root.tscn` has diverged and the merge conflicts, that is the
only constraint to preserve.

**If you subclassed or called into `dev_stage.gd`, five private methods are no longer there:**
`_open_inventory`, `_talk`, `_reveal_done`, `_console` and `_open_menu`, along with the
`_talk_advance` field. They are unchanged in `dev_screens.gd`. Nothing public moved, and
`SETTLE_FRAMES` still exists in both files.

**Everything else is internal.** `dev_stage.gd` is 248 → 175 code lines and `dev_screens.gd` is
102, so both have room again; `_parse_arguments` fell from 32 of its 40-line function budget to
22. `tests/unit/dev_tools_test.gd` gained a gate worth knowing about if you maintain your own
debug flags: **no two debug nodes may dispatch the same flag**, with `--new-game` the one stated
exception, because the failure mode of a split like this one is leaving the branch behind in both
parsers and dispatching twice. 2,143 → 2,148.

---

## 4.3.1

*2026-09-08 — twelve places where the record disagreed with the repository, and two gates so the
two structural ones cannot recur. **No production code changed**: this release is documentation
and tests.*

**A consuming game does: nothing.** No field, method, signal, scene or setting changed, and no
file a game wrote is affected. Everything here is either a document this base ships or a test
case that reads one.

**What was wrong.** `CONTEXT.md` — the file `CLAUDE.md` orders every session to read first — was
stating template version `2.4.0` two majors after the fact, still called `1.1.0` untagged, still
listed branch protection as unbuilt after T5.16 turned it on, and still carried a **"THE NEXT
PACKAGE"** paragraph describing work T5.2 had already shipped. `ARCHITECTURE.md` was 348
assertions behind and pointed at "rung 9" for a capture that is rung 12. `SYSTEMS_INVENTORY.md`
had T5.15's `Row styles` row stranded at line 1 ABOVE the document's own title, which was the
row's only copy — so the system was missing from its table. T5.17 had shipped with no row on the
board at all.

**What now stops two of them coming back.** `tests/unit/record_shape_test.gd` is new and owns
STRUCTURE, which is the part of a document that is not prose: every document must open with its
own title, and every package the log records must have a row on the board. `version_test.gd`
gained a third fact — a **bold** semver in `CONTEXT.md` is a claim about the current version and
must equal `project.godot`'s. **A fork that keeps this base's `docs/` gains all three checks, and
one that REWRITES those documents is fine** — every case is computed from what the scan finds
rather than from a list of expected files. **A fork that DELETES `docs/` outright will see
`record_shape_test.gd` go red on its "the log records packages to check" precondition**, which is
the same thing `docs_test.gd` and `doc_counts_test.gd` have always done in that situation: delete
the three cases together, or keep the documents. The precondition is deliberate — a doc gate that
silently passes because it found nothing to check is worse than no gate.

**What is deliberately NOT gated, and why.** The assertion count and the public-method count both
drifted too, and both were corrected by hand. Neither got a gate: a case cannot know the suite's
own final total while the suite is still running, and re-deriving the method count would duplicate
`check_methods.gd`'s scan inside a test. T5.17's *"nothing gates a prose claim"* stands for
sentences; structure and a bold version are the exceptions, and the counts need a checker rung
rather than a case.

---
## 4.3.0

*2026-09-07 — the save loader's refusals are asserted, and its migration path is documented as
structurally unreachable. **No production code changed**: `save_system.gd` is byte-identical.*

**A consuming game does: nothing, and should read one line.** The base gained a test case, which
is a gain a game may ignore — except in one situation worth naming. **If your fork modified
`SaveSystem`, `tests/unit/save_recovery_test.gd` may go red on merge.** That is the case doing
its job rather than a defect in your game: it asserts that a corrupt envelope is refused while a
corrupt SECTION is skipped, and a fork that made either one behave like the other has changed how
much of a player's save survives a bad file.

**What was unasserted.** `core_test.gd` owns the round trip and covered exactly one refusal — an
empty slot. Nothing in the suite had ever written a MALFORMED save file, so six branches were
carried by review alone: a file that is not JSON, a missing `version` field, a save from a newer
build, a non-Dictionary section, a section predating per-section versioning, and a section absent
altogether. All six are now asserted, and two were proved by planting a reversion.

**The migration mechanism is unreachable, and that is arithmetic.** `_migrate` is called only when
`version != SCHEMA_VERSION`, and it refuses `<= 0` and `> SCHEMA_VERSION`. At `SCHEMA_VERSION == 1`
no integer is all three of not-one, above-zero and at-most-one — so its success path, including its
`"Migrated save from v%d to v%d"` line, cannot be entered by any file. This is not a bug: there
genuinely are no migrations at v1, and the comment telling a future author where to add one is
correct. What was wrong was `SYSTEMS_INVENTORY.md` describing migration as DONE, which read as
"exercised" when it meant "written". That row now says so.

**And it expires by itself.** The new case pins `SCHEMA_VERSION` to 1. Ship a v2 schema and the
suite fails with *"SCHEMA_VERSION is still 1, so _migrate has no reachable success path"* — which
is the reminder to write the migration test at the moment one first becomes possible, rather than
a note in a document nobody rereads.

---

## 4.2.1

*2026-09-07 — a quest whose start condition is written by another quest's completion did not
reliably start. Whether it did depended on the order the content directory happened to be
scanned in, and nothing in the ladder could see it.*

**A consuming game does: nothing, and gains a guarantee it did not have.** No field, method or
signal changed, and no file a game wrote is affected. A game that authored a chain of quests was
already relying on this working; on the unlucky scan order it silently was not.

**The defect.** `QuestTracker.evaluate()` guards against re-entrancy, because a listener on
`Events.quest_completed` legitimately writes flags — beginning the next chapter is the case the
guard's own comment names. It guarded by RETURNING, which discards the re-derivation the new flag
asked for. That is only harmless if the pass already running still reaches the newly-startable
quest, and whether it does depends on where that quest sits in `QuestDb.all()` — insertion order
from `ContentScan`, which does not sort. So a chapter that begins when the previous one ends
started or did not start according to filenames.

**The fix.** A re-entrant call now sets a pending bit and the outer pass drains it, re-deriving
until nothing more moves. The pass bound is DERIVED from `QuestDb.count()` rather than picked, so
it cannot go stale as a game authors its sixtieth quest, and exceeding it logs an error rather
than hanging.

**Why no rung caught it, which is the part worth reading.** The demo has one quest, so it cannot
chain; and `quests_test.gd` states in its own header that it drives `evaluate()` and
`Flags.set_flag` directly *"rather than through the signal chain a running game uses"* — which is
correct for asking what a step means, and is exactly why it could not reach the guard, since a
re-entrant call can only arrive on `flag_changed`. `tests/unit/quest_chain_test.gd` is the case
that goes through the signal, and it asserts BOTH scan orders, because the benign one passed
while the defect was live and a case that tested only that would have looked like proof.

---


## 4.2.0

*2026-09-06 — the `Button` styleboxes, declared as a known limitation since T2.2 and left for
six packages. Every menu row, and every reply in a conversation, now draws all five of its
states from the palette instead of falling through to the engine's fallback StyleBox.*

**A consuming game does: nothing, unless it wants to.** Nothing was removed or renamed, no
export changed, and no method a game calls has a different signature. **A game that authored
its own `MenuRow/styles/normal` keeps it untouched** — `UiRowStyles` skips any variation that
already declares a `normal` box. **A game that replaced `ui_theme.tres` with a palette that has
no `surface` entry keeps exactly the behaviour it had at 4.1.0**, and gets one `WARN` line at
boot saying so. The one merge conflict to expect is `scenes/boot/game_root.tscn`, which gains a
`UiRowStyles` node under `UILayer`.

### What is new

| | |
|---|---|
| `UiPalette/colors/surface` | The face of a pressable row at rest, and the only colour the five states are derived from. The first palette entry that needed a SURFACE rather than a mark on one |
| `UiMetrics/constants/row_padding` | Side inset between a row's border and its text |
| `UiMetrics/constants/focus_border` | Width of the ring round the focused row |
| `src/ui/root/ui_row_styles.gd` | Derives `normal`, `hover`, `pressed`, `disabled` and `focus` — plus the `_mirrored` and `hover_pressed` spellings — and writes them into the project theme at boot. `UiAccessibility`'s sibling: that one owns the theme's font SIZES, this one owns its Button styles |
| `ui.menu.continue_autosave` | The main menu's Continue row said "Continue — Slot 7" when the latest save was the autosave. It says "Continue — Autosave" |

### Why nothing here is a colour this base picked

The four previous packages that opened this file and closed it again all gave the same reason: a
stylebox has to be *designed*, and the only palette to design against is the placeholder one, so
populating them would ship a decision as a default. **Nothing in `ui_row_styles.gd` designs a
colour. It designs the relationship between the five states**, and takes every colour from the
palette:

- `hover` is `surface` moved **toward `text`** — which lightens a dark row and darkens a light
  one, from the same expression. That is what makes the fix survive a palette this base does not
  ship, and it is the half of the defect ("immediately wrong against a light one") that a
  hard-coded lighten would not have touched.
- `pressed` moves toward `accent`, because a press is an act and wants a hue rather than a shade.
- `disabled` keeps the hue and drops the alpha, so a refused row is the same row faded.
- `focus` draws **no centre at all**, only an `accent` ring, so it composes with whichever of the
  other four is underneath rather than hiding it.

**To restyle: change `UiPalette/colors/surface` and the four other palette entries. Nothing
else.** To opt out entirely: delete the `UiRowStyles` node from `game_root.tscn`.

### If you are upgrading and you replaced the theme

Add one line to your palette and you get the whole set:

```
UiPalette/colors/surface = Color(<the face of a row at rest>)
```

Without it the row styles are skipped and your menus look exactly as they did at 4.1.0. This is
deliberate: there is nothing to derive from, and inventing a surface would be the base picking
a colour for you after all.

---

## 4.1.0

*2026-09-06 — a turn in place. `Events.turn_requested` is a new signal, and with it
`CharacterVisual.face_direction()` — correct, asserted and reached only from `tests/` since the
day it was written — finally has an occasion. The player turns towards what the prompt is
offering; the person you talk to turns towards you.*

**A consuming game does: nothing. Every character it already has gains the behaviour, and any
character it does not want turning simply never has a request addressed to it.** No export
changed, no scene changed, no method was removed or renamed, and nothing a game wrote has to
move. This is the MINOR case exactly.

### What is new

| | |
|---|---|
| `Events.turn_requested(character: Node3D, towards: Vector3)` | Ask a character to face a world point without moving it. Many askers by design, on `camera_shake_requested`'s shape |
| `CharacterVisual` | Listens, and answers only when the request names the character it draws — itself, or any ancestor of itself |
| `InteractionSensor` | Asks for the player, when a target is selected **while standing still**, or when the player comes to rest with one selected |
| `Speaker` | Asks for the character it hangs under, if there is one, towards whoever spoke. A speaker on a plaque asks for nothing |

### Two things worth knowing before you build on it

**A turn does not need undoing, and there is no hold flag anywhere.**
`update_from_velocity` re-aims only while the character is actually moving, so a turn given to
somebody standing simply persists until they walk — which is why an NPC is still looking at the
player when the dialogue box closes, at the cost of no listener at all. A turn given to a
character who is *moving* is overwritten on the next physics frame, and that is not a defect to
work around; it is why `InteractionSensor` asks only while the player is still.

**Your own askers need no new seam.** An NPC that notices the player, walks over and stops them —
the case neither shipped asker covers — emits the same signal and needs nothing added here. That
is the reason the seam was drawn at the bus rather than inside either call site.

### Also

`src/systems/debug/dev_gait_shots.gd` gained a `--turn-shots=<dir>` pass, which photographs a
character before and after a turn and reports the fraction of the crop's pixels that differ,
against a same-gap control shot with no turn asked for. Debug surface only; deleting that file
still does not break the game.

---

## 4.0.0

*2026-09-06 — the seventh checker, `tools/check_methods.gd`: a public method under `src/` that
nothing anywhere calls now fails the build. It found twelve on its first run, and two of them are
deleted in this version, which is what makes this a MAJOR bump rather than a PATCH for a tool.*

**A consuming game does: nothing, unless it called one of the two deleted methods — and then it
is a one-line edit each. After that, run rung 11 on your own tree and expect it to say
something.** The gate is asked of every public method under `src/`, and your `src/` is bigger
than this one.

### The two methods that are gone, and what to write instead

| Removed | Write instead | Why it went |
|---|---|---|
| `DialogueNode.has_choices()` | `not node.choices.is_empty()` | Two lines of alias over the expression both real readers already write — `DialogueRunner` and `DialogueScreen` each call `available_choices().is_empty()` and never went through it. `stop_music()`'s shape exactly, and the same verdict |
| `ItemDefinition.is_equippable()` | `Equipment.slot_of(item_id) != GameEnums.EquipSlot.NONE` | Its doc block claimed "an `Equipment` component and a UI row both ask this"; neither ever did. `Equipment.can_equip()` compares against NONE through `slot_of()`, which is strictly better, because `slot_of()` also answers NONE for an id with no definition at all |

**Neither had a caller anywhere in the repository — not in `src/`, not in the suite, not in the
tools.** If your game calls one, the replacement above is exact and behaviour is unchanged.

### The gate itself

**Rung 11, `godot --headless --script tools/check_methods.gd`, and it is in CI as its own step.**
It fails when a public method declared at column 0 under `src/` — 314 of them here — has its name
written nowhere else in the repository, on any non-comment line, in `.gd`, `.tscn` or `.tres`.

**The exemption is the phrase `NO CALLER` in the method's own `##` block**, which is
`check_signals.gd`'s `NO EMITTER` with the subject changed, and **a stale exemption fails too**: a
method that carries the phrase and has a caller is a violation in the other direction. Nine
methods carry it in this version and each one states its reason in the same breath — a log level
you can select but this template never writes at, the untyped `Flags` hatch for a type the typed
accessors cannot cover, three `PersistentState` fetchers kept as a complete typed family, a
`Readable`'s persisted read flag that a quest condition asks, and a `Footsteps` pair that a dust
puff would read.

**What it does NOT fail on, deliberately: a method reached only from `tests/` or `tools/`.** There
are 86 of those, and "has a caller in the suite" is genuinely not "has a caller in the game" — but
a template declares accessors for a consuming game to call and this repository never will, so
failing there would be answered with a fake caller. The count is printed on every run instead.

**It under-reports and cannot over-report.** A local variable or another class's method sharing a
name keeps a dead method looking alive; 37 names are declared in more than one file and are
treated as one. A green run is therefore not a proof that everything public is live. **A red run
is always real.**

**One precondition, checked rather than assumed:** no line in the repository both dispatches
(`call(`, `callv(`, `call_deferred(`, `Callable(`, `has_method(`) and builds a string. A name
assembled at runtime is the one form this gate cannot see, so if you introduce one, rung 11 fails
loudly instead of quietly reporting a green it cannot back. **If your game dispatches that way,
that is where you will meet this tool first** — either name the method in full at the call site,
or accept that the gate stops covering it and say so.

**Nothing else under `src/` changed** except one line in `NpcBrain.activity_name()`, which now
reads its own `current_activity()` accessor instead of the private field beside it. Same value,
one fewer place that knows how the enum is stored.

---

## 3.1.0

*2026-09-06 — a fifth debug file, `dev_scenario_shots.gd`, and the node in `game_root.tscn` that
lets it read the command line. Two features that had never been photographed happening in a real
session now have been: a screen shake fired by opening a gate, and an autosave written by
arriving somewhere and read back by pressing Continue in a fresh process.*

**A consuming game does: take the new `DevScenarioShots` node when it merges `game_root.tscn`.**
That is the whole obligation, and it is the only file outside `src/systems/debug/` that this
version touches. If your `game_root.tscn` has diverged and the merge conflicts, the node is three
lines and the file's other nineteen are unchanged:

```
[node name="DevScenarioShots" type="Node" parent="."]
script = ExtResource("20_scenario")
```

**Nothing under `src/` outside the debug directory changed, so nothing you wrote is affected.**
This is a MINOR bump rather than a PATCH for one reason: a node in a shared scene is something
you have to take, and a version that says PATCH is promising you do not.

**What you gained**, all of it gated on `OS.is_debug_build()` and absent from a release export:

| Flag | Does |
|---|---|
| `--gate-shot=<dir>` | throws a demo lever, opens the demo gate, and photographs the shake, writing `gate_closed.png` / `gate_shake.png` / `gate_open.png` and the camera's distance from rest in metres on every frame |
| `--autosave-write` | poses a state, travels, and lets `Events.area_entered` write the autosave |
| `--autosave-continue=<dir>` | in a FRESH process: boots to the main menu, photographs it, presses the real Continue row, and photographs where the game came back |

**`--gate-shot` names demo content and is meant to.** `src/systems/debug/` is the one directory
exempt from the boundary rule, and a fork that deletes the courtyard will find the flag logs
`found no node called 'GateLever'` and stops. Point it at your own lever and gate — two string
constants in the file — or delete the flag. `--autosave-write` names an area id for the same
reason and takes the same edit.

**Two assertions came with it and neither is about the debug surface's own behaviour.**
`Gate.perform()` is now asserted to ask for exactly the amplitude its author wrote and for
`Gate.SHAKE_SECONDS`, and to ask for NOTHING when `open_shake` is left at its default zero —
which T5.9 had left to a code read. And every script under `src/systems/debug/` that reads
`OS.get_cmdline_user_args()` is now asserted to have a node in `game_root.tscn`, because a debug
file with no node is not a broken tool but an absent one, and nothing anywhere goes red.

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
