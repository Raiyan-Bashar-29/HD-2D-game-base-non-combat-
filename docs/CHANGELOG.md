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
