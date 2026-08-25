class_name GameEnums
extends RefCounted
## Shared vocabulary. Enums that more than one system needs to name the same way.
##
## WHY: if Clock says night as the string "night" and the lighting system checks for
## "Night", nothing errors. It just silently never matches. Enums make that a parse error.
##
## RULE: an enum belongs here only if two or more systems use it. Anything used by exactly
## one system stays private inside that system's own script.

## Time-of-day bands. Lighting, NPC schedules and ambience all key off these.
enum DayPhase { DAWN, MORNING, MIDDAY, AFTERNOON, DUSK, NIGHT, DEEP_NIGHT }

## Weather states. Drives environment, particles, ambience and some interactions.
enum WeatherKind { CLEAR, CLOUDY, OVERCAST, RAIN, STORM, FOG, SNOW, WIND }

## What the player character is currently doing. The controller owns transitions;
## every other system only reads it.
enum MoveState { IDLE, WALK, RUN, SNEAK, JUMP, FALL, CLIMB, SWIM, BUSY, LOCKED }

## Eight-way facing for billboarded sprites. SOUTH is first because a sprite facing the
## camera is the default resting pose, and the one that placeholder art always has.
enum Facing { SOUTH, SOUTH_EAST, EAST, NORTH_EAST, NORTH, NORTH_WEST, WEST, SOUTH_WEST }

## Item taxonomy. Note the absence of weapons and armour: this game has no combat.
enum ItemCategory { TOOL, CONSUMABLE, KEY_ITEM, QUEST, MATERIAL, CLOTHING, DOCUMENT, TREASURE }

## The verb shown on the interaction prompt. Purely presentational. The interactable
## itself decides what actually happens.
enum InteractVerb { LOOK, TAKE, OPEN, CLOSE, USE, TALK, READ, SIT, CLIMB, ENTER, HARVEST, LIGHT }

## Why an interaction was refused, so the UI can say something useful instead of nothing.
enum RefusalReason { NONE, LOCKED, MISSING_ITEM, MISSING_SKILL, WRONG_TIME, ALREADY_DONE, HANDS_FULL, STORY_GATED, NOT_GROUNDED }

## What the UI is doing to the world right now. UiRoot owns the transitions; the player's
## input readers and the prompt only listen. OVERLAY and MODAL differ in exactly one way and
## it is not cosmetic: an OVERLAY suspends the player's input while the world keeps ticking
## (a conversation happens in real time), a MODAL stops the world as well.
enum UiMode { GAMEPLAY, OVERLAY, MODAL }
