class_name DevCommands
extends RefCounted
## The four development verbs — travel, forge a flag, set the clock, fill the bag — in ONE
## implementation, so the command line and the in-game console are the same command.
##
## WHY THIS FILE EXISTS AND WHY IT IS NOT A SECOND PARSER
## `--goto=`, `--flag=`, `--time=` and `--give=` have been parsed and proved since WP-08, split
## across `dev_stage.gd` and `dev_capture.gd`. WP-14b's console is a UI over that vocabulary, and
## writing the four bodies again inside a screen would give the project two answers to "what does
## `give` do" that drift the first time one of them is fixed. So the bodies moved here and the
## two argument parsers now CALL them: what you type in the console is exactly what you pass on
## the command line, argument for argument, and there is one place where each verb happens.
##
## EACH VERB RETURNS ITS OWN REPORT rather than logging. A staging flag wants that line in the
## log; a console wants it on the screen. Returning the sentence lets both have it, and keeps
## this file free of an opinion about where a developer is reading.
##
## THE REPORTS ARE NOT LOCALIZED, DELIBERATELY. They are a developer readout — echoes of what was
## typed and the values that came back — not prose a player will ever see, and `strings.csv` is
## the file a consuming game translates and prunes. The screen's own chrome IS localized, which
## is the line this package draws: chrome is text, output is data. See
## `src/ui/screens/debug_console_screen.gd`.
##
## OWNS: what `goto`, `flag`, `time` and `give` do, and the one-line report each returns.
## MUST NOT: wait for a frame, read the command line, draw anything, or be depended upon by
## gameplay. Deleting this file must break only the harness and the console.

const GOTO: StringName = &"goto"
const FLAG: StringName = &"flag"
const TIME: StringName = &"time"
const GIVE: StringName = &"give"

## The vocabulary, in the order the console offers it. A caller listing the verbs reads this
## rather than repeating the four names, so a fifth verb is one edit.
const VERBS: Array[StringName] = [GOTO, FLAG, TIME, GIVE]


## Run one typed line: a verb, a space, and the SAME argument the matching `--verb=` takes.
## An empty line is not an error — a developer pressing enter on nothing has asked for nothing.
static func run(line: String) -> String:
	var trimmed: String = line.strip_edges()
	if trimmed == "":
		return ""
	var space: int = trimmed.find(" ")
	var verb: StringName = StringName(trimmed if space < 0 else trimmed.substr(0, space))
	var argument: String = "" if space < 0 else trimmed.substr(space + 1).strip_edges()
	if verb == GOTO:
		return travel_to(argument)
	if verb == FLAG:
		return set_flag(argument)
	if verb == TIME:
		return set_time(argument)
	if verb == GIVE:
		return give(argument)
	return "no such command '%s'. %s" % [verb, usage()]


## The one-line help, derived from VERBS so it cannot fall out of step with what `run` answers.
static func usage() -> String:
	var parts: PackedStringArray = []
	for verb: StringName in VERBS:
		parts.append(String(verb))
	return "commands: %s" % " ".join(parts)


## Ask to travel. The SAME bus signal an `AreaDoor` emits, so `Director` still owns every
## transition — a console that moved the player itself would be a second travel path.
static func travel_to(area_id: String) -> String:
	if area_id == "":
		return "goto needs an area id"
	Events.area_change_requested.emit(StringName(area_id), &"")
	return "goto requested '%s'" % area_id


## Forge a plot flag. `true` and `false` are spelled; anything else is read as an integer, which
## covers the counter flags AT_LEAST and AT_MOST test. Deliberately the raw store and not a
## system: this is the development harness, and a flag is exactly what a harness should forge.
static func set_flag(value: String) -> String:
	var at: int = value.rfind(":")
	if at <= 0:
		return "flag expects <key>:<value>, got '%s'" % value
	var flag: StringName = StringName(value.substr(0, at))
	var raw: String = value.substr(at + 1)
	var parsed: Variant = raw.to_int()
	if raw == "true" or raw == "false":
		parsed = raw == "true"
	Flags.set_flag(flag, parsed)
	return "flag %s = %s" % [flag, str(parsed)]


## Move the clock. Through `Clock.set_time`, which is the one route a time change takes — see
## the settled decision "a time skip is one event".
static func set_time(value: String) -> String:
	var parts: PackedStringArray = value.split(":")
	if parts.size() != 2:
		return "time expects HH:MM, got '%s'" % value
	Clock.set_time(Clock.day, parts[0].to_int(), parts[1].to_int())
	return "time is now %02d:%02d on day %d" % [Clock.hour, Clock.minute, Clock.day]


## Put items in the player's bag through the real `Inventory.add`, so what a capture shows is
## what the game would have produced. Refuses rather than crashes with no player in the tree,
## which is the state the suite and a boot-to-menu run are both in.
static func give(list: String) -> String:
	var bag: Inventory = Inventory.of(Director.player)
	if bag == null:
		return "give found no inventory on the player"
	var report: PackedStringArray = []
	for entry: String in list.split(",", false):
		var parts: PackedStringArray = entry.split(":")
		var count: int = parts[1].to_int() if parts.size() > 1 else 1
		var added: bool = bag.add(StringName(parts[0]), maxi(1, count))
		report.append("%s x%d: %s" % [parts[0], count, str(added)])
	if report.is_empty():
		return "give needs an item id"
	return "give %s" % " ".join(report)
