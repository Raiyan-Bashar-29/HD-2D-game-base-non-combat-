extends TestCase
## Schedules: which block covers which hour, and whether a whereabouts survives a save.
##
## WHAT IS DELIBERATELY NOT HERE: walking. A navmesh needs physics frames and `TestCase.run()`
## is synchronous, so no assertion here can watch an NPC cross a courtyard. That is measured by
## a RUN instead — `--npc-day` in `dev_capture.gd` steps the clock through a whole day and
## reports where each NPC actually ends up, and `--npc-storm=30` measures what a crowd costs.
##
## What IS here is everything decidable without a frame, and the part most likely to rot: the
## hour-to-block lookup, which is pure arithmetic over authored data and has exactly the shape
## that silently returns the wrong answer at 03:00 six months from now.
##
## OWNS: assertions about NpcSchedule, ScheduleEntry, ScheduleDb and persisted whereabouts.
## MUST NOT: assert anything about pathing, movement or navmesh baking.

const KEEPER: StringName = &"schedule/keeper"

var _schedule: NpcSchedule = null


func run() -> void:
	_set_up()
	_the_catalogue_is_sound()
	_every_hour_of_the_day_has_an_owner()
	_the_night_shift_wraps_past_midnight()
	_a_waypoint_is_a_name_not_a_place()
	_whereabouts_survive_a_save()
	_tear_down()


func _set_up() -> void:
	ScheduleDb.reload()
	_schedule = ScheduleDb.schedule(KEEPER)


func _the_catalogue_is_sound() -> void:
	equal("the keeper's schedule exists", ScheduleDb.has(KEEPER), true)
	equal("and the catalogue is clean", ScheduleDb.problems().size(), 0)
	equal("its id matches its filename", _schedule.id, KEEPER)
	equal("it has entries", _schedule.entries.size() > 0, true)
	equal("an invented schedule is null", ScheduleDb.schedule(&"schedule/nobody"), null)
	equal("and reports as absent", ScheduleDb.has(&"schedule/nobody"), false)


## THE HEADLINE. Every hour must resolve to some block, including the hours before the first one
## begins. A gap would mean an NPC with no instructions, which in practice means an NPC standing
## wherever it happened to be when the gap opened.
func _every_hour_of_the_day_has_an_owner() -> void:
	for hour: int in 24:
		var entry: ScheduleEntry = _schedule.entry_for_hour(hour)
		equal("%02d:00 has a block" % hour, entry != null, true)
		if entry != null:
			equal("%02d:00 names a waypoint" % hour, entry.waypoint != &"", true)


## The keeper's day starts at 06:00, so 02:00 belongs to the LAST block of the previous day, not
## to the first block of this one. Getting this backwards puts every NPC at its morning post all
## night, which reads as a game where nobody sleeps.
func _the_night_shift_wraps_past_midnight() -> void:
	var latest: ScheduleEntry = null
	for entry: ScheduleEntry in _schedule.entries:
		if latest == null or entry.from_hour > latest.from_hour:
			latest = entry
	var first: ScheduleEntry = null
	for entry: ScheduleEntry in _schedule.entries:
		if first == null or entry.from_hour < first.from_hour:
			first = entry

	equal("before the day starts, the last block still runs",
		_schedule.entry_for_hour(first.from_hour - 1).waypoint, latest.waypoint)
	equal("and so does midnight", _schedule.entry_for_hour(0).waypoint, latest.waypoint)
	equal("the day's first hour switches over",
		_schedule.entry_for_hour(first.from_hour).waypoint, first.waypoint)
	equal("an hour inside a block belongs to that block",
		_schedule.entry_for_hour(latest.from_hour + 1).waypoint, latest.waypoint)
	# Out-of-range hours are clamped rather than crashing: a caller passing 24 has a bug, but a
	# crash in an NPC's daily update is a worse way to find out about it.
	equal("hour 99 is clamped", _schedule.entry_for_hour(99).waypoint, latest.waypoint)
	equal("and so is -5", _schedule.entry_for_hour(-5).waypoint, latest.waypoint)


## A schedule names waypoints; the AREA owns where they are. Assert that every waypoint the
## keeper's day mentions actually exists in the area the keeper lives in — a name that resolves
## to nothing is an NPC that never leaves, and it is invisible until someone watches for an hour.
func _a_waypoint_is_a_name_not_a_place() -> void:
	var packed: PackedScene = load(Director.area_path(&"courtyard")) as PackedScene
	var area: Node = packed.instantiate()
	var markers: Node = area.get_node_or_null(^"Waypoints")
	equal("the courtyard has a Waypoints node", markers != null, true)
	for entry: ScheduleEntry in _schedule.entries:
		var marker: Node = markers.get_node_or_null(NodePath(String(entry.waypoint)))
		equal("the courtyard has a marker called '%s'" % entry.waypoint, marker != null, true)
		equal("and it is a Node3D", marker is Node3D, true)
	area.free()


## An NPC's whereabouts ride the save machinery that already exists, through PersistentState and
## therefore through Flags. Asserted at the storage level because the walking half needs frames:
## what matters here is that the key is namespaced per area and per object like everything else,
## so two NPCs cannot overwrite each other and a second area cannot overwrite the first.
func _whereabouts_survive_a_save() -> void:
	var first: StringName = &"obj/courtyard/keeper/waypoint"
	var second: StringName = &"obj/lantern_hall/keeper/waypoint"
	Flags.set_flag(first, "bench")
	Flags.set_flag(second, "plinth")
	equal("a whereabouts is stored", Flags.get_string(first), "bench")
	equal("and the same NPC in another area is separate", Flags.get_string(second), "plinth")

	var slot: int = 3
	equal("the save succeeds", SaveSystem.save_to_slot(slot), OK)
	Flags.set_flag(first, "gate_post")
	equal("the value is destroyed before reloading", Flags.get_string(first), "gate_post")
	equal("the load succeeds", SaveSystem.load_from_slot(slot), OK)
	equal("and the whereabouts came back", Flags.get_string(first), "bench")
	equal("both of them", Flags.get_string(second), "plinth")
	SaveSystem.delete_slot(slot)


func _tear_down() -> void:
	Flags.erase_flag(&"obj/courtyard/keeper/waypoint")
	Flags.erase_flag(&"obj/lantern_hall/keeper/waypoint")
	ScheduleDb.reload()
	_schedule = null
