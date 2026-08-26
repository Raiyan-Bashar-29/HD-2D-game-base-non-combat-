extends Node
## The global signal registry. Autoload `Events`.
##
## THIS FILE IS THE CONNECTION MAP. Every cross-system conversation in the game is declared
## here, in one place, with typed parameters. Reading this file tells you how the game is
## wired without opening anything else.
##
## WHEN TO USE THE BUS, AND WHEN NOT TO. Apply in five seconds:
##   Direct call   - you own the thing and it is right there. Always prefer this.
##   Node signal   - a parent needs to hear from its own child. Local and traceable.
##   THIS BUS      - a system needs to announce that a fact about the world changed, to
##                   unknown and unrelated listeners, and must not know who cares.
##   Never the bus - for asking a question, getting a value back, or anything where you need
##                   to know the receiver acted. Signals are announcements, not calls.
##
## THE BUS'S OWN FAILURE MODE, stated honestly: flow gets hard to trace, because the emit
## site and the listen site are far apart. Three rules keep that survivable.
##   1. Every signal is declared HERE, with typed parameters. Never emitted ad hoc.
##   2. Past tense for facts that already happened. The _requested suffix for asks.
##   3. Exactly ONE system emits any given signal, and the comment says which. If two
##      systems emit the same signal, the signal is modelled wrong.
##
## OWNS: nothing at all. No state, no logic, deliberately. That is what stops it becoming
## the god object that a singleton called "GameManager" always eventually becomes.

# ---------------------------------------------------------------------------------------
# Application flow. Emitted by Director and SaveSystem.
# ---------------------------------------------------------------------------------------

## A brand-new game began. Fired after flags are cleared, before the first area loads.
signal game_started()
## A save was restored. Listeners should re-read any state they cache.
signal game_loaded(slot: int)
## A save finished writing successfully.
signal game_saved(slot: int)
## Returning to the main menu. Gameplay systems should tear down.
signal game_ending()

# ---------------------------------------------------------------------------------------
# Areas and world. Emitted by Director.
# ---------------------------------------------------------------------------------------

## Someone asked to travel. Director is the only listener; it validates, then performs it.
signal area_change_requested(area_id: StringName, spawn_id: StringName)
## Transition began. UI should cover the screen. The old area is still alive at this point.
signal area_unloading(area_id: StringName)
## How far the threaded load of an area has got, 0.0 to 1.0. Emitted every frame while a load
## is in flight, so a loading indicator can show progress without polling ResourceLoader
## itself - which would mean a second place that knows the path template.
signal area_load_progress(area_id: StringName, ratio: float)
## The new area is in the tree and the player is placed. Safe to query world contents.
signal area_entered(area_id: StringName)

# ---------------------------------------------------------------------------------------
# The player character. Emitted by the player's own components.
# ---------------------------------------------------------------------------------------

## The player entered the scene tree. Systems needing a reference should grab it here.
signal player_spawned(player: Node3D)
## The player is leaving the tree. Drop any cached reference; it is about to be invalid.
signal player_despawned()
## Movement state changed. Used by animation, audio and the HUD.
signal player_state_changed(state: GameEnums.MoveState)

# ---------------------------------------------------------------------------------------
# Interaction. Emitted by the interaction sensor on the player.
# ---------------------------------------------------------------------------------------

## The best interaction target changed, or became null. The prompt UI listens to this.
signal interact_target_changed(target: Node3D, verb: GameEnums.InteractVerb, label_key: String)
## An interaction actually began. It may be instant, or held over several seconds.
signal interaction_started(target: Node3D)
## An interaction completed normally.
signal interaction_finished(target: Node3D)
## An interaction was rejected, with a reason the UI can explain to the player. `args` fills
## placeholders the same way notify_requested does - MISSING_ITEM is useless to a player
## without naming the item.
signal interaction_refused(target: Node3D, reason: GameEnums.RefusalReason, args: Dictionary)

# ---------------------------------------------------------------------------------------
# Items and inventory. Emitted by the inventory component.
# ---------------------------------------------------------------------------------------

## An item entered the inventory. `count` is how many were added, not the new total.
signal item_gained(item_id: StringName, count: int)
## An item left the inventory, for any reason.
signal item_lost(item_id: StringName, count: int)
## An item was consumed or activated by the player.
signal item_used(item_id: StringName)
## Something about the inventory changed. The UI redraws on this and ignores the specifics.
signal inventory_changed()

# ---------------------------------------------------------------------------------------
# World state. Emitted by Flags, and by trigger volumes in the world.
# ---------------------------------------------------------------------------------------

## A plot or world flag changed value. Quests, doors and dialogue conditions listen.
signal flag_changed(flag: StringName, value: Variant)

## A trigger volume fired. Emitted by TriggerVolume and nothing else. `who` is the body that
## entered. Carried on the bus rather than left as a local node signal because the whole point
## of a trigger is that the thing it affects is somewhere else and does not know it exists.
signal trigger_fired(trigger_id: StringName, who: Node3D)

# ---------------------------------------------------------------------------------------
# Time and weather. Emitted by Clock and Weather.
# ---------------------------------------------------------------------------------------

## Fired once per in-game minute. Cheap listeners only. This is frequent.
signal minute_passed(day: int, hour: int, minute: int)
## Fired on the hour. NPC schedules key off this.
signal hour_passed(day: int, hour: int)
## A new in-game day began.
signal day_passed(day: int)
## The time-of-day band changed. Lighting and ambience cross-fade on this.
signal day_phase_changed(phase: GameEnums.DayPhase)
## Weather has begun changing. `seconds` is how long the blend will take.
signal weather_changing(to: GameEnums.WeatherKind, seconds: float)
## Weather finished blending and is now stable.
signal weather_changed(kind: GameEnums.WeatherKind)

# ---------------------------------------------------------------------------------------
# Dialogue and narrative. Emitted by the dialogue system.
# ---------------------------------------------------------------------------------------

## Someone asked to talk. The UI layer listens and opens the box; the asker does not know a
## box exists. Same shape as area_change_requested: gameplay names an id, ui does the work.
signal dialogue_requested(talk_id: StringName)
## A conversation started. Gameplay input should yield to the dialogue UI.
signal dialogue_started(speaker_id: StringName)
## A conversation ended and control returns to the player.
signal dialogue_finished(speaker_id: StringName)

# ---------------------------------------------------------------------------------------
# Quests. Emitted by the quest system.
# ---------------------------------------------------------------------------------------

signal quest_started(quest_id: StringName)
signal quest_advanced(quest_id: StringName, step: StringName)
signal quest_completed(quest_id: StringName)

# ---------------------------------------------------------------------------------------
# UI requests. Anyone may emit these; the UI layer is the only listener.
# ---------------------------------------------------------------------------------------

## Show a transient toast. `key` is a localization key, never raw player-facing text.
## `args` fills placeholders in the translated string: {"count": 3, "item": "Apple"} against
## "Picked up {count} {item}". Pass an empty Dictionary when there is nothing to substitute.
## Without this a toast could not name a thing or a count, which is what almost every real
## notification in an exploration game does.
signal notify_requested(key: String, seconds: float, args: Dictionary)
## Fade the screen. Director uses this for transitions, and cutscenes may too.
signal screen_fade_requested(to_black: bool, seconds: float)
## Show the main menu. Emitted by GameRoot on boot - which is why the game no longer starts in
## an area - and by the pause menu's "main menu" row. A `_requested` ask has many askers by
## design; it is the FACTS on this bus that have exactly one emitter each.
signal main_menu_requested()
## Close the game. The menus ask; `GameRoot` is the only thing that performs it, so there is
## still one shutdown path and an autosave policy will only ever need adding in one place.
signal quit_requested()
## A screen opened or closed and the world's relationship to input changed. Emitted by UiRoot
## and by nothing else - it is the single announcement that replaces one input-lock boolean
## per screen. Input readers take or release their own `ui` token on it; the prompt hides on
## it. Carried on the bus because UiRoot must not know the player's components exist.
signal ui_mode_changed(mode: GameEnums.UiMode)

# ---------------------------------------------------------------------------------------
# Settings and debug.
# ---------------------------------------------------------------------------------------

## A user setting changed at runtime, so systems can re-read it. Emitted by Settings.
signal setting_changed(section: String, key: String, value: Variant)
## A developer console command was entered. Debug tooling only.
signal debug_command(command: String, args: PackedStringArray)
