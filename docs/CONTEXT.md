# Context — read this first, it takes one minute

A state snapshot for a new session. `CLAUDE.md` has the *rules*; this file has the *situation*.
Keep it short. When it drifts from reality, fix it in the same commit as the change.

**Last updated:** 2026-08-26 · WP-02 complete · branch `claude/intelligent-wilbur-ae8141`
**Note:** this branch fast-forwarded WP-01 in from `claude/trusting-curran-04a4f9`, which was
never merged to `main`. Merge order is WP-01 then WP-02, or just merge this branch.
**Remote:** https://github.com/Raiyan-Bashar-29/HD-2D-game-base-non-combat-

## What this is

HD-2D semi-open-world **exploration and narrative** game. Godot 4.7.2, GDScript.
Visual reference: Octopath Traveler I/II/0, The Adventures of Elliot.

**No combat.** Explicitly retracted by the owner — not an oversight. **Art is deferred**;
everything runs on procedural placeholders. The goal is a *base prototype*: a skeleton with a
home for every system the finished game will need, so later work is content and data, not new
architecture.

## Where it stands

Phase 0 complete, Phase 1 nearly done. 53 files, 3,879 code lines, 12 scenes, 1 area, 3 items.
Boots headless with **0 warnings, 0 errors**.

**Works, and verified by running it:** logging with rotation · signal registry (`events.gd`) ·
input actions · settings · save/load with atomic writes and versioning · plot flags · area
director with a re-entrancy guard and threaded loading · world clock · weather state · audio
buses · HD-2D camera rig with tilt-shift DOF · billboarded lit shadow-casting 8-way character ·
camera-relative walk/run/sneak · day/night lighting · screen fade · dev screenshot capture ·
placeholder art generator · line-budget checker · headless test suite (294 assertions) ·
interaction sensor with ranking and Tab-cycling · Interactable contract · localized prompt and
toasts · readable signs · levers · gates gated by flag or by a carried key · per-object
persistence (ADR-0005) · typed item definitions found by directory scan (ADR-0006) · an
inventory component with a capacity seam · pickups · take-all chests · a content validator ·
trigger volumes that fire on entry · a rest point that skips hours · authored climb points ·
a screen stack with real pause semantics · a token input lock.

**Not built:** NPCs · dialogue · quests · any REAL screen (the stack exists and a stub proves
it; the HUD and the inventory screen are WP-03) · hard-coded-string audit · weather visuals ·
item instances (durability) · equipment · keyboard focus inside a screen.

## Known defects

**Fixed 2026-08-26, both found by running the engine, neither visible in the source:**

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
- 17 of the 23 settings have no consumer yet. They are declared so the settings screen has
  something to bind to, not because anything reads them.

## Decisions already made — do not re-litigate

- **GDScript, not C#.** The installed engine is the standard build; .NET is not available.
- **Warnings are errors.** `var x = 5` does not parse. Read untyped data via `DictRead`, never
  `int(value)` on a `Variant`.
- **Input actions live in code** (`src/systems/input/actions.gd`), so the editor's Input Map
  panel looks empty. Intentional — ADR-0003.
- **Ten autoloads, no `GameManager`.** Adding one requires an ADR.
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
- **Pause is per node, not global.** `get_tree().paused` is set by UiRoot, but each node
  decides for itself in its own `_ready()`. The full table is the header of
  `src/ui/root/ui_root.gd`. Clock and Weather stop; Audio, Director, ScreenFade,
  NotificationToast and DevCapture do not.
- Four ADRs in `docs/decisions/` cover the layered `src/`, warnings-as-errors, the input map,
  and save-via-callables.

## Verify before claiming anything is done

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --check-only --script <file>   # type gate
"$G" --headless --import                       # scenes and resources
"$G" --headless --quit-after 120               # must end "0 warnings, 0 errors"
"$G" --headless res://tests/test_runner.tscn --quit-after 150   # 294 assertions, exit 1 on fail
"$G" --headless --script tools/check_budgets.gd            # must exit 0
"$G" --headless --script tools/check_content.gd            # must exit 0
"$G" --resolution 960x540 --quit-after 55 -- --shot=<path> --time=18:40 --freeze-time
```

## Thirteen gotchas that each cost an hour

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
12. **Child order in a `CanvasLayer` is draw order.** `ScreenFade` has to be the LAST child of
    `UILayer` or the curtain does not cover the screens. It was the first child until WP-02.
13. **Use `--quit-after 120` for the boot rung, not 30.** The area load is threaded, and 30
    frames does not reliably finish it on a cold cache — quitting mid-load aborts the loader
    thread and prints spurious `Parse Error` lines for `courtyard.tscn` plus leaked RIDs,
    *after* the run has already reported `0 warnings, 0 errors`. Pre-existing and reproducible
    at any commit; the real fix is for `Director` to cancel its load on shutdown (WP-14).

## How work is sliced

**One package, one chat** — see [`docs/WORK_PACKAGES.md`](WORK_PACKAGES.md), which is the
board of fifteen packages from here to skeleton-complete. Each names the exact files that chat
should read, so a session loads a few hundred lines instead of three thousand. The layer rule
(`core -> content -> systems -> gameplay -> ui`, downward only) is what makes that possible: a
package never has to read upward.

**Next package: WP-03, HUD and inventory screen.**

## Plan — where this is going

**Phase 1 is nearly complete.** The demo loop works end to end: walk a lit courtyard through a
day/night cycle, be prompted, read a sign, throw a lever, take an item, empty a chest, be
refused by a gate that wants a key, open it once you carry the key, cross a volume that fires
once, rest on a bench and watch the light change, climb a trellis to a terrace and back down —
and every one of those changes survives a save and reload. All of it is covered by 294
headless assertions.

**Next, in this order.** The order matters and is not arbitrary:

1. **The HUD and the inventory screen.** The stack, the pause semantics and the token input
   lock landed in WP-02, so a screen is now a `UiScreen` subclass with content in it and
   nothing else — no new pause, no new boolean, no new signal. Keyboard and controller focus
   inside a screen is unbuilt and belongs with the first screen that has something to focus.
2. **A second area and a real transition.** The transition code is written, guarded and logged
   but has never actually swapped two areas, because only one exists. Trigger volumes are now
   the entry mechanism it was waiting for.

**Then Phase 2:** dialogue, NPC schedules, navigation baking, weather visuals.

**Still open, and expensive later:**
- **Sprite sheet layout is hardcoded.** `CharacterVisual` has `FACING_COUNT = 8` and
  `FRAME_COUNT = 4` as constants; a different sheet needs a code edit. Should be a resource.
- **The export path is unproven.** Items are found by scanning a directory, which is verified
  in the editor and headless only. There is no export preset yet, and it must export *all*
  resources or the item catalogue ships empty. See ADR-0006.
- **No hard-coded-string audit.** Computed keys (`verb.*`, `refusal.*`) are covered by an enum
  loop in the test suite, but literal player-facing text in code is still caught only by review.

## Read next

`CLAUDE.md` (rules) · `docs/ARCHITECTURE.md` · `docs/SYSTEMS_INVENTORY.md` ·
`docs/ROADMAP.md` · `docs/DEVLOG.md` · `src/core/events/events.gd` (the connection map)
