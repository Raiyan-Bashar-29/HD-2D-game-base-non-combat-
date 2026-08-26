# This is a template, not a game

**Read this before `ROADMAP.md` or `WORK_PACKAGES.md`.** It reframes both, and several older
lines in the other documents were written before it and have not all been corrected yet.

## The reframing, in the owner's words

> We're not making the entire game, rather the **formula** that we'll use in many games — kinda
> like how we use formulas to solve a problem. The game is our problem, which can vary. The
> formulas stay constant and we mix-match/use based on what we need. That's the base of the
> game, or the barebones **skeleton**.

So: **the product is the systems and the seams between them.** The courtyard, the garden-keeper
and the rose key are not the product. They are the *proof that a system works*, and they are
deletable.

This was decided on 2026-08-26, after WP-07. Everything built before it is still correct — the
architecture was already formula-shaped — but the *planning documents* were not, and are being
corrected package by package.

## What this changes

| Before | Now |
|---|---|
| "a skeleton with a home for every system **the finished game** will need" | there is no *the* game; there are many |
| Exit criteria: "the player can rest **on the bench**" | "a `RestPoint` skips the clock and the environment re-samples" |
| Phase 3 "thirty minutes that represent the finished game" | out of scope — that is a *consuming game's* phase |
| **Depth before breadth** — "no second region until the first is genuinely good" | **RETRACTED.** Breadth of systems, one shallow proof each. See below. |
| Success = a good game | Success = a second, different game can be started without editing `src/` |

### The retraction of "depth before breadth"

`ROADMAP.md` used to state, as doctrine and as "the single lesson from eleven shallow regions":

> Depth before breadth. No second region until the first one is genuinely good.

**That rule is retracted with the same weight the no-combat retraction has.** It is the correct
rule for one game and the wrong rule for a formula library, and it directly contradicted
`WORK_PACKAGES.md`'s own definition of the skeleton — *"every system has a working minimal
implementation plus one piece of placeholder content proving it."*

Left in place it would keep steering packages toward deepening the courtyard. If you find
yourself about to add polish to demo content, that is the retracted rule winning an argument it
should not be in.

**The replacement:** breadth of systems, one shallow proof each.

## Engine vs demo — the boundary

### The rule

> **No file under `src/` may name demo content.**

Not an area id, not an item id, not a conversation id, not an NPC id. This rule exists because
`src/core/boot/game_root.gd` once carried `const FIRST_AREA := &"courtyard"` — engine code in the
layer that is supposed to know nothing about the game — and it passed eight verification rungs, a
budget checker, a content checker, 900 assertions and an adversarial review, **because no rule
forbade it.**

That is the failure mode this project exists to prevent: not wasted effort, but an unguarded
boundary that accumulates silently.

### What is what

| Path | Kind | On starting a new game |
|---|---|---|
| `src/` | **Engine.** All of it. | Keep. Never edit to start a game. |
| `scenes/objects/`, `scenes/characters/`, `scenes/boot/` | **Engine.** Reusable prefabs. | Keep. |
| `tools/`, `tests/framework/` | **Engine.** | Keep. |
| `data/**` | **Demo.** Every `.tres`. | Delete, and author your own in the same folders. |
| `scenes/areas/**` | **Demo.** | Delete, and author your own. |
| `localization/strings.csv` | **Mixed.** `verb.*`, `refusal.*`, `ui.*`, `time.phase.*`, `item.category.*` are engine; `object.*`, `item.*`, `talk.*`, `action.*`, `area.*` are demo. | Prune the demo half. |
| `tests/unit/` | **Mixed, and currently welded to the demo.** | See the known gap below. |

`data/` and `scenes/areas/` being demo is not a coupling — they are the **content roots a game
fills**, and the registries scanning them is a convention the template defines. A new game puts
its own items in `data/items/` and its own areas in `scenes/areas/`.

### Known gaps in the boundary, as of 2026-08-26

These are planned, not accepted:

1. **`game_root.gd` names the demo's first area**, and `log.gd` bakes the string `Gulistan` into
   the boot banner and the log filename — both in `core`.
2. **Nothing enforces the rule.** `check_content.gd` has no such gate yet.
3. **The test suite is welded to the demo.** Roughly a third of the assertions assert facts about
   demo content rather than about systems, so deleting `data/` today would delete rung 4 of the
   verification ladder. A fixture layer is planned.
4. **The debug nodes ship in release builds** — no `OS.is_debug_build()` guard on their argument
   parsing.

## Optional modules

"Mix-match based on what we need" implies some systems are opt-in. `SYSTEMS_INVENTORY.md` will
grow an **OPTIONAL** status for these. Crafting is the clearest case: it is a genre choice, not a
requirement of every game built on this base.

## The one constraint nobody has scoped

**There is no combat, and as a *template* rule that forecloses combat for every game built on this
base.** That was decided for one game. It is recorded here because it is now a much larger
commitment than it was, and nobody has said so out loud.

The same class of question applies to a few other decisions made for one game's constraints and
now imposed on all of them — most notably "a conversation is not saved". They may well be the
right defaults. What is missing is the distinction between a **template default** and a **game
choice**, which no document currently draws.

## Read next

`docs/ROADMAP.md` for the phases · `docs/WORK_PACKAGES.md` for the board · `docs/CONTEXT.md` for
where things stand right now.
