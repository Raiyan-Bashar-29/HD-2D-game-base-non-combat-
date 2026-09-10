extends TestCase
## AN AUTHORED CONDITION CAN ASK WHAT TIME IT IS.
##
## Before T5.31 it could not, and the gap was structural rather than a missing feature: `Clock`
## emitted four signals and never called `Flags.set_flag`, while `FlagQuery` — the ONE evaluator
## `DialogueNode` and `QuestStep` both go through — reads `Flags` and nothing else. So the shop
## hours `clock.gd`'s own header names as a reason a clock is foundational were inexpressible in
## authored content, and so was every other question about the hour, the day, the phase or the
## weather. The projection is the fix; this file is the proof that the projection is ASKABLE,
## which is a different claim from "a flag was written".
##
## SO EVERY ASSERTION HERE GOES THROUGH `FlagQuery.passes`, NOT THROUGH `Flags.get_int`. Reading
## the flag back directly would prove the write happened and say nothing about whether authored
## content can use it — and that distinction is exactly what a String-valued flag would have got
## wrong, silently: `passes` returns FALSE for every test in the closed set against a String, so
## a published phase NAME would have looked correct in a dump and answered nothing.
##
## BOTH PATHS, BECAUSE THEY ARE SEPARATE CODE. A natural minute goes through `_tick_minute`; a
## sleep, a cutscene, a debug command and a loaded save all go through `set_time`. Two publish
## sites means a fix to one is not a fix to the other, and the plant for this row removes only
## the `set_time` call — a normal tick still passes and half the ways a game moves time stop
## answering. The ordering pair is the sharp end of it: the flag must be current INSIDE
## `hour_passed`, on both paths, which is `bag_mirror_test.gd`'s invariant one system over.
##
## OWNS: that a `FlagQuery` condition on `time/hour` flips on the right minute on both publish
##   paths; that the flag is current when a time signal arrives; that exactly one phase flag and
##   one weather-kind flag exist at a time; and that all of them are declared derived.
## MUST NOT: assert how a phase band is chosen, what any signal carries, how a clock is saved, or
##   anything about weather blending — `world_test.gd` and `core_test.gd` own those.

## Shop hours, which is the case the header of `clock.gd` names and could not express.
const OPENS: int = 9
const CLOSES: int = 17
## Returned when the flag is not there at all, which is what an erased phase leaves.
const ABSENT: int = -1

var _hour_inside_signal: int = ABSENT
var _signals_seen: int = 0


func run() -> void:
	plan(27)
	_the_keys_are_derived()
	_a_condition_flips_on_the_right_minute()
	_and_on_the_set_time_path_too()
	_the_flag_is_current_when_the_signal_fires()
	_exactly_one_phase_is_true()
	_and_exactly_one_weather_kind()
	_restore()


## Published, announced and readable — and out of the save file. `flags.gd` says `is_derived` is
## public for precisely this assertion, so that a test states the fact rather than inferring it
## from a row missing from a file.
func _the_keys_are_derived() -> void:
	equal("the hour is derived, so it is never saved",
		Flags.is_derived(Clock.FLAG_HOUR), true)
	equal("so is the day", Flags.is_derived(Clock.FLAG_DAY), true)
	equal("so is a phase flag",
		Flags.is_derived(Clock.phase_flag(GameEnums.DayPhase.DAWN)), true)
	equal("so is a weather kind",
		Flags.is_derived(Weather.kind_flag(GameEnums.WeatherKind.CLEAR)), true)


## THE GATE, on the natural path. `advance_minutes` is what a passing minute does, one
## `_tick_minute` at a time, so the flip is observed at the minute it happens rather than
## somewhere inside a jump.
func _a_condition_flips_on_the_right_minute() -> void:
	Clock.set_time(1, OPENS - 1, 58)
	equal("the shop is shut two minutes before opening", _is_open(), false)
	Clock.advance_minutes(1)
	equal("and still shut one minute before", _is_open(), false)
	Clock.advance_minutes(1)
	equal("it opens on the hour", _is_open(), true)

	# The other half of the pair, and the reason an hour is published as an ORDERED int: a
	# closing time is `AT_MOST`, and it only means anything if the comparison does.
	Clock.set_time(1, CLOSES, 59)
	equal("still open in the last minute of the last hour", _is_open(), true)
	Clock.advance_minutes(1)
	equal("and shut when that hour rolls", _is_open(), false)


## THE SAME GATE ACROSS `set_time`, which is a different function with a different publish call.
## This is the pair the plant separates.
func _and_on_the_set_time_path_too() -> void:
	Clock.set_time(1, OPENS - 1, 59)
	equal("a jump to one minute before opening leaves it shut", _is_open(), false)
	Clock.set_time(1, OPENS, 0)
	equal("a jump onto the hour opens it", _is_open(), true)
	Clock.set_time(1, CLOSES + 1, 0)
	equal("and a jump past closing shuts it", _is_open(), false)
	# A day is published on the same path, and a condition on it is how a game gates anything
	# that may only happen once the world has been running a while.
	equal("the day is askable too",
		FlagQuery.passes(Clock.FLAG_DAY, GameEnums.FlagTest.AT_LEAST, 1), true)


## THE ORDERING INVARIANT. A flag published AFTER the signal would be a projection that is always
## one event stale, and the only trace would be an authored condition that fires an hour late.
## Asserted on both paths for the same reason the gate is: they are two call sites.
func _the_flag_is_current_when_the_signal_fires() -> void:
	# The setup jump happens BEFORE the connection, because `set_time` emits `hour_passed` itself
	# and a tally that counted the arrangement would be measuring this file rather than the clock.
	Clock.set_time(1, 10, 59)
	Events.hour_passed.connect(_on_hour_passed)
	_hour_inside_signal = ABSENT
	Clock.advance_minutes(1)
	equal("hour_passed fired on the tick", _signals_seen, 1)
	equal("and the flag already read the NEW hour inside it", _hour_inside_signal, 11)

	_hour_inside_signal = ABSENT
	Clock.set_time(1, 14, 0)
	equal("hour_passed fired on the jump", _signals_seen, 2)
	equal("and the flag was current inside that one too", _hour_inside_signal, 14)

	Events.hour_passed.disconnect(_on_hour_passed)


## ONE ROW, NOT SEVEN, AND THE OLD ONE GONE. A phase flag left true is the defect worth guarding:
## an authored dawn-only line would fire at every hour after the first dawn, and nothing would
## look wrong. `IS_FALSE` against the erased row is how authored content sees that, which is why
## it is asked through `passes` rather than by counting.
func _exactly_one_phase_is_true() -> void:
	Clock.set_time(1, 6, 0)
	equal("it is dawn", _phase_holds(GameEnums.DayPhase.DAWN), true)
	equal("and only dawn has a row", Flags.with_prefix(Clock.PHASE_PREFIX).size(), 1)

	Clock.set_time(1, 12, 0)
	equal("midday arrives", _phase_holds(GameEnums.DayPhase.MIDDAY), true)
	equal("dawn is over as far as a condition is concerned",
		FlagQuery.passes(Clock.phase_flag(GameEnums.DayPhase.DAWN),
			GameEnums.FlagTest.IS_FALSE, 0), true)
	equal("and there is still one row", Flags.with_prefix(Clock.PHASE_PREFIX).size(), 1)

	# NO ORDINAL WAS PUBLISHED, and this is the assertion that keeps it that way. `time/phase`
	# holding a `GameEnums.DayPhase` number would be correct only by accident of enum order, and
	# an ordering comparison on it is meaningless regardless — `phase_for_hour` runs 6,0,1,2,3,4,5
	# across a day, so DEEP_NIGHT is the highest ordinal and the earliest hours.
	equal("and no ordinal flag exists to be compared by accident",
		Flags.has_flag(StringName(Clock.PHASE_PREFIX.trim_suffix("/"))), false)


## The same shape one system over, so the two namespaces cannot drift apart in how they answer.
func _and_exactly_one_weather_kind() -> void:
	Weather.force(GameEnums.WeatherKind.RAIN)
	equal("a quest step can require rain", _weather_holds(GameEnums.WeatherKind.RAIN), true)
	equal("and one kind has a row", Flags.with_prefix(Weather.KIND_PREFIX).size(), 1)
	Weather.force(GameEnums.WeatherKind.CLEAR)
	equal("and the rain is over when it clears",
		FlagQuery.passes(Weather.kind_flag(GameEnums.WeatherKind.RAIN),
			GameEnums.FlagTest.IS_FALSE, 0), true)


## Asked the way an author asks it: two conditions on one ordered int.
func _is_open() -> bool:
	return (FlagQuery.passes(Clock.FLAG_HOUR, GameEnums.FlagTest.AT_LEAST, OPENS)
		and FlagQuery.passes(Clock.FLAG_HOUR, GameEnums.FlagTest.AT_MOST, CLOSES))


func _phase_holds(of_phase: GameEnums.DayPhase) -> bool:
	return FlagQuery.passes(Clock.phase_flag(of_phase), GameEnums.FlagTest.IS_TRUE, 0)


func _weather_holds(kind: GameEnums.WeatherKind) -> bool:
	return FlagQuery.passes(Weather.kind_flag(kind), GameEnums.FlagTest.IS_TRUE, 0)


func _on_hour_passed(_day: int, _hour: int) -> void:
	_signals_seen += 1
	_hour_inside_signal = Flags.get_int(Clock.FLAG_HOUR, ABSENT)


## The clock is an autoload every other case shares, so this one puts it back where the suite
## found it rather than leaving a case downstream at 14:00. The weather needs nothing: the last
## thing asserted above forced it back to CLEAR, which is where it starts.
func _restore() -> void:
	Clock.set_time(1, 6, 0)
	equal("the clock is back where the suite started it", Clock.minutes_today(), 6 * 60)
