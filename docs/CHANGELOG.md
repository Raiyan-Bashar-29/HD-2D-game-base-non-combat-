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
