class_name ScheduleEntry
extends Resource
## One block of an NPC's day: from this hour, be at that waypoint, doing this.
##
## A WAYPOINT MUST BE SOMEWHERE THE BODY CAN WALK, WHICH IS NOT THE SAME AS SOMEWHERE THE
## NAVMESH COVERS. A NavigationMesh bakes `agent_max_climb` into the walkable surface, so it
## will happily bridge a knee-high step - but `CharacterBody3D.move_and_slide()` has no step-up
## at all, so the body walks into the riser and stops while the agent insists it has not
## arrived. This game has no jumping and authored vertical movement (ClimbPoint), so the climb
## limit is kept BELOW anything the body cannot manage and waypoints sit on the ground.
##
## IT NAMES A WAYPOINT, NOT A POSITION. A schedule that stored coordinates would be authored
## against one area's geometry and silently wrong the moment a bench moved, and it could not be
## reused by a second NPC or a second area at all. A name is resolved against the area's
## `Waypoints/` node at runtime, so moving the marker moves everyone who goes there.
##
## THERE IS NO `until_hour`, deliberately. An entry runs until the next one begins, and the last
## entry wraps to the first, so a day is always completely covered and two entries cannot
## disagree about who owns 14:00. The cost is that a gap in the day cannot be expressed - which
## is correct, because an NPC is always somewhere.
##
## OWNS: one block of one schedule.
## MUST NOT: know which NPC uses it, resolve its own waypoint, or touch an autoload -
## tools/check_content.gd loads this class under `--headless --script`, where autoload
## identifiers do not resolve, so one Log call here would break the build gate.

## The hour this block begins, 0 to 23. It runs until the next entry's hour.
@export_range(0, 23, 1) var from_hour: int = 0
## Name of a Marker3D under the area's `Waypoints/` node.
@export var waypoint: StringName = &""
## What to do on arrival.
@export var activity: GameEnums.NpcActivity = GameEnums.NpcActivity.STAND


func activity_name() -> String:
	var names: Array = GameEnums.NpcActivity.keys()
	var raw: String = names[activity]
	return raw


func problems(context: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	if waypoint == &"":
		found.append("%s has an entry at %02d:00 with no waypoint" % [context, from_hour])
	return found
