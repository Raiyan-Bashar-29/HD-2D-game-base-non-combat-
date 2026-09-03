class_name NpcSchedule
extends ContentEntry
## Where one NPC is at every hour of the day, as authored data.
##
## THE ID IS THE FILE NAME, exactly as for items and conversations: `data/schedules/keeper.tres`
## must declare `id = &"schedule/keeper"`. Third content type, third time the same rule, and it
## is the same rule for the same reason - a copy-paste slip becomes a named startup failure
## rather than an NPC that silently never goes anywhere.
##
## ENTRIES ARE SORTED ON LOOKUP, NOT ON LOAD. Authored order is whatever the writer found
## convenient; `entry_for_hour` does not care, because it picks the entry with the greatest
## `from_hour` not exceeding the hour asked for, and falls back to the LAST entry of the day
## when the hour is earlier than every block. That fallback is what makes a night shift work:
## an NPC whose day starts at 06:00 is, at 02:00, still doing whatever it was doing at 22:00.
##
## OWNS: the immutable schedule of one NPC, and validating its own shape.
## MUST NOT: know which NPC uses it, move anything, or touch an autoload.

## `id` is inherited from `ContentEntry`; for this catalogue it is `schedule/` plus this file name.
## In any order. Each runs until the next begins; the last wraps around midnight.
@export var entries: Array[ScheduleEntry] = []


## Which block covers this hour. Null only when there are no entries at all.
func entry_for_hour(hour: int) -> ScheduleEntry:
	var wanted: int = clampi(hour, 0, 23)
	var best: ScheduleEntry = null
	var latest: ScheduleEntry = null
	for entry: ScheduleEntry in entries:
		if entry == null:
			continue
		if latest == null or entry.from_hour > latest.from_hour:
			latest = entry
		if entry.from_hour <= wanted and (best == null or entry.from_hour > best.from_hour):
			best = entry
	# Before the first block of the day, the previous day's last block is still running.
	return best if best != null else latest


func problems() -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	if id == &"":
		found.append("%s has no id" % resource_path)
	if entries.is_empty():
		found.append("%s (%s) has no entries" % [resource_path, id])
	var hours: Dictionary[int, bool] = {}
	for entry: ScheduleEntry in entries:
		if entry == null:
			found.append("%s has an empty entry slot" % id)
			continue
		if hours.has(entry.from_hour):
			# Two blocks claiming one hour is not a crash, but it IS ambiguous, and which one
			# wins depends on array order - exactly the kind of thing that reads as random.
			found.append("%s has two entries starting at %02d:00" % [id, entry.from_hour])
		hours[entry.from_hour] = true
		found.append_array(entry.problems(String(id)))
	return found
