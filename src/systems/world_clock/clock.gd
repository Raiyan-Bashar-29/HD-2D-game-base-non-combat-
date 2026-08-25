extends Node
## The world clock. Autoload `Clock`.
##
## WHY A CLOCK IS FOUNDATIONAL
## Time is an input to lighting, NPC schedules, ambience, shop hours, weather odds and some
## interactions. If each of those keeps its own notion of "night", they drift apart. One clock
## emits the truth and everything else listens.
##
## OWNS: the current day, hour and minute; the rate time passes; the time-of-day phase.
## MUST NOT: change lighting, move an NPC, or play a sound. It reports time passing. What
## that means is the listener's business. This is the boundary that keeps a day/night system
## from quietly turning into the place where all world logic lives.
##
## RATE: at the default 1.0 seconds per in-game minute, a full 24-hour day takes 24 real
## minutes. That is deliberately brisk, so a play session sees several dawns.

const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const MINUTES_PER_DAY: int = MINUTES_PER_HOUR * HOURS_PER_DAY

## Real seconds per in-game minute. Set to 0 to freeze time without pausing the game.
@export var seconds_per_minute: float = 1.0

var day: int = 1
var hour: int = 6
var minute: int = 0
var paused: bool = false

var _accumulator: float = 0.0
var _phase: GameEnums.DayPhase = GameEnums.DayPhase.DAWN


func _ready() -> void:
	_phase = phase_for_hour(hour)
	SaveSystem.register(&"clock", _collect_save, _apply_save)
	Log.info("clock", "Started at day %d, %02d:%02d (%s)" % [day, hour, minute, phase_name()])


func _process(delta: float) -> void:
	if paused or seconds_per_minute <= 0.0:
		return
	_accumulator += delta
	while _accumulator >= seconds_per_minute:
		_accumulator -= seconds_per_minute
		_tick_minute()


## Total in-game minutes elapsed today. Useful for interpolating anything continuous.
func minutes_today() -> int:
	return hour * MINUTES_PER_HOUR + minute


## Progress through the day as 0.0 at midnight to 1.0 at the next midnight.
## This is what a lighting gradient should sample.
func day_fraction() -> float:
	return float(minutes_today()) / float(MINUTES_PER_DAY)


func phase() -> GameEnums.DayPhase:
	return _phase


func phase_name() -> String:
	return GameEnums.DayPhase.keys()[_phase]


## Which band an hour falls into. Kept as a pure function so lighting and schedules can ask
## about a future hour, not only the present one.
func phase_for_hour(of_hour: int) -> GameEnums.DayPhase:
	if of_hour < 5:
		return GameEnums.DayPhase.DEEP_NIGHT
	if of_hour < 7:
		return GameEnums.DayPhase.DAWN
	if of_hour < 11:
		return GameEnums.DayPhase.MORNING
	if of_hour < 14:
		return GameEnums.DayPhase.MIDDAY
	if of_hour < 17:
		return GameEnums.DayPhase.AFTERNOON
	if of_hour < 20:
		return GameEnums.DayPhase.DUSK
	return GameEnums.DayPhase.NIGHT


## True between dusk and dawn. Convenience for the many things that just want "is it dark".
func is_night() -> bool:
	return _phase == GameEnums.DayPhase.NIGHT or _phase == GameEnums.DayPhase.DEEP_NIGHT


## Jump to a specific time. Used by sleeping, cutscenes, debug tools and save loading.
## Emits the same signals a natural passage would, so listeners need no special case.
func set_time(to_day: int, to_hour: int, to_minute: int = 0) -> void:
	var previous_day: int = day
	var previous_hour: int = hour
	day = maxi(1, to_day)
	hour = clampi(to_hour, 0, HOURS_PER_DAY - 1)
	minute = clampi(to_minute, 0, MINUTES_PER_HOUR - 1)
	_accumulator = 0.0
	Events.minute_passed.emit(day, hour, minute)
	if hour != previous_hour:
		Events.hour_passed.emit(day, hour)
	if day != previous_day:
		Events.day_passed.emit(day)
	_update_phase()
	Log.info("clock", "Time set to day %d, %02d:%02d" % [day, hour, minute])


## Push time forward. Sleeping until morning is advance_minutes of whatever the gap is.
func advance_minutes(count: int) -> void:
	if count <= 0:
		return
	for _i: int in count:
		_tick_minute()


## Minutes from now until the next occurrence of an hour. Used by "sleep until dawn".
func minutes_until_hour(target_hour: int) -> int:
	var target: int = clampi(target_hour, 0, HOURS_PER_DAY - 1) * MINUTES_PER_HOUR
	var now: int = minutes_today()
	if target <= now:
		target += MINUTES_PER_DAY
	return target - now


func _tick_minute() -> void:
	minute += 1
	var rolled_hour: bool = false
	var rolled_day: bool = false

	if minute >= MINUTES_PER_HOUR:
		minute = 0
		hour += 1
		rolled_hour = true
	if hour >= HOURS_PER_DAY:
		hour = 0
		day += 1
		rolled_day = true

	Events.minute_passed.emit(day, hour, minute)
	if rolled_hour:
		Events.hour_passed.emit(day, hour)
		_update_phase()
	if rolled_day:
		Events.day_passed.emit(day)
		Log.info("clock", "Day %d began" % day)


func _update_phase() -> void:
	var next: GameEnums.DayPhase = phase_for_hour(hour)
	if next == _phase:
		return
	_phase = next
	Log.debug("clock", "Phase -> %s at %02d:%02d" % [phase_name(), hour, minute])
	Events.day_phase_changed.emit(_phase)


func _collect_save() -> Dictionary:
	return {"day": day, "hour": hour, "minute": minute}


func _apply_save(data: Dictionary, _from_version: int) -> void:
	set_time(
		DictRead.get_int(data, "day", 1),
		DictRead.get_int(data, "hour", 6),
		DictRead.get_int(data, "minute", 0),
	)
