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
