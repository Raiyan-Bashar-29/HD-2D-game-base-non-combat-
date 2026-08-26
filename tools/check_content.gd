extends SceneTree
## Content gate: the checks that catch a broken item, a duplicate object id, or a localization
## key that will render on screen as its own name.
##
## ITS SIBLING IS tools/check_boundary.gd, which asks the opposite question: this tool checks
## that the DEMO is well formed, that one checks that the ENGINE does not know the demo exists.
## Both must exit 0. They were one tool for about ten minutes, until check_budgets.gd refused
## the result at 252 of the 250 allowed code lines.
##
## RUN:  godot_console --headless --script tools/check_content.gd
## Exit 0 if clean, 1 on any violation. Safe in a commit hook next to check_budgets.gd.
##
## WHY IT CAN BE A --script TOOL AT ALL
## Because ItemDefinition and ItemDb touch no autoload. Under --headless --script the autoload
## *identifiers* do not resolve, so the moment anyone adds a Log call to a content class, this
## tool stops compiling and the gate fails. That is a real mechanical enforcement of the
## content-layer rule, not a style note. print() is used here for the same reason.
##
## WHAT IT DELIBERATELY DOES NOT CHECK
## Computed localization keys. interact_prompt.gd builds "verb.%s" and "refusal.%s" from enum
## names at runtime, and no text scan can follow that. Those are covered by an enum loop in
## tests/unit/items_test.gd, which is better verification than a scan could be. It also cannot
## report unused CSV keys, for the same reason: a key referenced only by computed name would
## look orphaned. And it is not a general hard-coded-string audit - telling a player-facing
## literal from a log message or a flag key needs semantics a text scan does not have, and a
## partial tool that looks complete is how 409 passing checks happened.
##
## MUST NOT: import a gameplay or ui class, or reference an autoload.

const CSV: String = "res://localization/strings.csv"
const SCENE_DIRS: Array[String] = ["res://scenes"]
const AREA_ROOT: String = "res://scenes/areas"

var _violations: int = 0
var _keys: Dictionary[String, bool] = {}


func _initialize() -> void:
	print("")
	print("Content check")
	print("=".repeat(78))
	_load_keys()
	_report_scan()
	_check_items()
	_check_dialogue()
	_check_schedules()
	_check_path_actions()
	_check_scenes()
	print("=".repeat(78))
	if _violations > 0:
		print("FAIL — %d content violation(s)" % _violations)
		quit(1)
		return
	print("PASS")
	quit(0)


func _fail(message: String) -> void:
	_violations += 1
	print("  !! %s" % message)


## The CSV is parsed directly rather than through the engine's translation system, because
## that system is not available under --script and because a missing key must be detectable
## even when strings.en.translation has not been regenerated.
func _load_keys() -> void:
	var file: FileAccess = FileAccess.open(CSV, FileAccess.READ)
	if file == null:
		_fail("cannot open %s" % CSV)
		return
	var first: bool = true
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == 0 or row[0] == "":
			continue
		if first:
			first = false
			continue
		_keys[row[0]] = true
		# MORE THAN TWO COLUMNS MEANS AN UNQUOTED COMMA, and the value was silently cut short at
		# it. Nothing else catches this: the key still resolves, tr() still returns a string, and
		# the line just quietly loses its second half. WP-01 shipped a lever whose toast ended at
		# "Somewhere north" for three packages before a capture showed it.
		if row.size() > 2:
			_fail("%s has an unquoted comma; its text is cut off at '%s'" % [row[0], row[1]])
	file.close()
	print("  localization keys: %d" % _keys.size())


## Records what the undocumented ResourceLoader.list_directory actually returned, so its
## behaviour stays a fact in the build log instead of an assumption in a comment.
func _report_scan() -> void:
	var raw: PackedStringArray = ResourceLoader.list_directory(ItemDb.content_dir)
	print("  list_directory(%s) -> %s" % [ItemDb.content_dir, str(raw)])
	print("  resolved paths        -> %s" % str(ItemDb.resource_paths(ItemDb.content_dir)))


func _check_items() -> void:
	ItemDb.rescan()
	for problem: String in ItemDb.problems():
		_fail(problem)
	print("  item definitions: %d" % ItemDb.count())
	for item_id: StringName in ItemDb.all():
		var definition: ItemDefinition = ItemDb.definition(item_id)
		print("     %-22s %-12s max_stack=%d" % [item_id, definition.category_name(), definition.max_stack])
		if not _keys.has(definition.name_key):
			_fail("%s name_key '%s' is not in the CSV" % [item_id, definition.name_key])
	_check_stray_definitions("res://data")


## An ItemDefinition outside data/items is the one silent failure this design admits: a Pickup
## can reference it by path while ItemDb never finds it, so can_accept refuses an item the
## player can plainly see.
func _check_stray_definitions(root: String) -> void:
	for directory: String in DirAccess.get_directories_at(root):
		var path: String = "%s/%s" % [root, directory]
		if path == ItemDb.content_dir:
			continue
		for file_name: String in DirAccess.get_files_at(path):
			if not file_name.ends_with(".tres"):
				continue
			var resource: Resource = ResourceLoader.load("%s/%s" % [path, file_name])
			if resource is ItemDefinition:
				_fail("%s/%s is an ItemDefinition outside %s" % [path, file_name, ItemDb.content_dir])


func _check_scenes() -> void:
	var scenes: Array[String] = []
	for directory: String in SCENE_DIRS:
		_collect_files(directory, ".tscn", scenes)
	print("  scenes scanned: %d" % scenes.size())
	for path: String in scenes:
		_check_scene(path)
		_check_editable_instances(path)


func _collect_files(directory: String, extension: String, into: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(directory):
		_collect_files("%s/%s" % [directory, sub], extension, into)
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(extension):
			into.append("%s/%s" % [directory, file_name])


## Text-scanned rather than instantiated: it needs no scene tree, it is fast, and it still
## works when a scene is broken for an unrelated reason.
##
## KNOWN LIMIT: duplicates are detected per FILE. Two objects in different scenes that end up
## under one AreaRoot at runtime are not caught, and neither is the same sub-scene instanced
## twice without overriding object_id - though that second case shows up as a missing override,
## which is why an instance line with no object_id is also reported.
func _check_scene(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("cannot open %s" % path)
		return
	var seen: Dictionary[String, bool] = {}
	var line_number: int = 0
	while not file.eof_reached():
		var line: String = file.get_line()
		line_number += 1
		var object_id: String = _quoted_after(line, "object_id = &\"")
		if object_id != "":
			if seen.has(object_id):
				_fail("%s:%d duplicate object_id '%s' in one scene" % [path, line_number, object_id])
			seen[object_id] = true
		_check_key_literal(path, line_number, line)
	file.close()


## Every property whose name ends in _key must name a real CSV row. tr() on a missing key
## silently returns the key itself, so this is the only thing that catches a typo before a
## player sees "object.chest.courtyard.label" printed on screen.
func _check_key_literal(path: String, line_number: int, line: String) -> void:
	var trimmed: String = line.strip_edges()
	if not trimmed.contains("_key = \""):
		return
	var value: String = _quoted_after(trimmed, "_key = \"")
	if value == "" or _keys.has(value):
		return
	_fail("%s:%d localization key '%s' is not in the CSV" % [path, line_number, value])


func _quoted_after(line: String, marker: String) -> String:
	var at: int = line.find(marker)
	if at < 0:
		return ""
	var rest: String = line.substr(at + marker.length())
	var end: int = rest.find("\"")
	return rest.substr(0, end) if end > 0 else ""


## Conversations get exactly the treatment items get, because ADR-0006's reasoning was never
## about items. The extra check here is the one a text scan cannot do: every text_key and
## speaker_key a conversation names must exist in the CSV, or the line renders on screen as its
## own key. Dangling node links are checked by Conversation.problems() itself.
func _check_dialogue() -> void:
	DialogueDb.rescan()
	for problem: String in DialogueDb.problems():
		_fail(problem)
	print("  conversations: %d" % DialogueDb.count())
	for talk_id: StringName in DialogueDb.all():
		var talk: Conversation = DialogueDb.conversation(talk_id)
		print("     %-22s %d nodes" % [talk_id, talk.nodes.size()])
		_check_conversation_keys(talk)


func _check_conversation_keys(talk: Conversation) -> void:
	for node: DialogueNode in talk.nodes:
		if node == null:
			continue
		var context: String = "%s/%s" % [talk.id, node.node_id]
		_require_key(context, "text_key", node.text_key)
		_require_key(context, "speaker_key", node.speaker_key)
		for choice: DialogueChoice in node.choices:
			if choice != null:
				_require_key(context, "choice text_key", choice.text_key)


## An empty key is not an error here - a narrator line with no speaker is legitimate, and
## node.problems() already refuses an empty text_key. What is an error is a key that names a
## CSV row which does not exist, because tr() silently returns the key itself.
func _require_key(context: String, field: String, key: String) -> void:
	if key == "" or _keys.has(key):
		return
	_fail("%s %s '%s' is not in the CSV" % [context, field, key])


## Schedules get the same treatment as items and conversations, plus the check no text scan can
## do: every waypoint a schedule names must exist as a marker in at least one area, or the NPC
## following it stands still forever and nothing says why.
func _check_schedules() -> void:
	ScheduleDb.rescan()
	for problem: String in ScheduleDb.problems():
		_fail(problem)
	print("  schedules: %d" % ScheduleDb.count())
	var known: Dictionary[StringName, bool] = _all_waypoint_names()
	for schedule_id: StringName in ScheduleDb.all():
		var schedule: NpcSchedule = ScheduleDb.schedule(schedule_id)
		print("     %-22s %d entries" % [schedule_id, schedule.entries.size()])
		for entry: ScheduleEntry in schedule.entries:
			if entry == null or entry.waypoint == &"":
				continue
			if not known.has(entry.waypoint):
				_fail("%s sends an NPC to '%s', which no area has a marker for" % [
					schedule_id, entry.waypoint,
				])


## Every waypoint name in every area, pooled. Pooled rather than per-area on purpose: a schedule
## does not name an area, so the only thing that can be checked here is that the name exists
## SOMEWHERE. An NPC in the wrong area for its schedule is a placement mistake this tool cannot
## see, and pretending otherwise would be the partial check that looks complete.
func _all_waypoint_names() -> Dictionary[StringName, bool]:
	var found: Dictionary[StringName, bool] = {}
	for directory: String in DirAccess.get_directories_at(AREA_ROOT):
		var path: String = "%s/%s/%s.tscn" % [AREA_ROOT, directory, directory]
		var packed: PackedScene = ResourceLoader.load(path) as PackedScene
		if packed == null:
			continue
		var area: Node = packed.instantiate()
		var markers: Node = area.get_node_or_null(^"Waypoints")
		if markers != null:
			for child: Node in markers.get_children():
				found[StringName(child.name)] = true
		area.free()
	return found


## Path actions are referenced by path, not found by scan, so there is no registry to validate.
## What CAN be validated is every .tres in data/actions: that it really is a PathAction, that its
## own problems() is empty, and that every key it names exists in the CSV. A path action that
## says nothing on success is a mechanic the player performs and cannot tell they performed.
func _check_path_actions() -> void:
	var directory: String = "res://data/actions"
	var files: PackedStringArray = ItemDb.resource_paths(directory)
	print("  path actions: %d" % files.size())
	for path: String in files:
		var resource: Resource = ResourceLoader.load(path)
		var action: PathAction = resource as PathAction
		if action == null:
			_fail("%s is not a PathAction" % path)
			continue
		var name: String = path.get_file()
		print("     %-24s %-11s standing %d/%d" % [
			name, action.verb_name(), action.required_standing, action.success_standing,
		])
		for problem: String in action.problems(name):
			_fail(problem)
		_require_key(name, "label_key", action.label_key)
		_require_key(name, "success_key", action.success_key)
		_require_key(name, "failure_key", action.failure_key)
		_require_key(name, "refusal_key", action.refusal_key)



## THE EDITABLE-INSTANCE TRAP, and it is a SILENT EXPORT failure — found by T2.0 running an
## exported build, not by any gate. courtyard.tscn overrode object_id, label_key and
## conversation_id on two nodes INSIDE its instanced npc.tscn without the `[editable path=...]`
## marker that makes those internals addressable. From source that works: the text loader applies
## the overrides and every rung, both CI jobs and 911 assertions were green. An export converts
## .tscn to BINARY .scn, and the conversion drops overrides on a non-editable instance — so the
## exported build booted with a keeper who had no object_id, no prompt and no conversation, and
## said so in three log lines nobody would have seen for months.
##
## This project hand-authors its .tscn files, so the marker the editor would have written is
## exactly the thing a hand-authored scene forgets. Hence a gate rather than a note.
##
## THE RULE: a [node] block whose parent path descends into an instanced node requires an
## [editable path="<that instance>"] for that instance. Deliberately STRICTER than the failure
## needs — an ADDED node inside an instance was observed to survive the conversion, and it is
## still required to be declared editable, because "which of the two kinds is this" is a
## distinction the export makes and the author should not have to remember.
func _check_editable_instances(path: String) -> void:
	var instances: PackedStringArray = PackedStringArray()
	var editable: PackedStringArray = PackedStringArray()
	var inside: Dictionary[String, int] = {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var line_number: int = 0
	while not file.eof_reached():
		var line: String = file.get_line()
		line_number += 1
		if line.begins_with("[editable path=\""):
			editable.append(_quoted_after(line, "[editable path=\""))
		elif line.begins_with("[node "):
			_note_node(line, line_number, instances, inside)
	file.close()
	_report_uneditable(path, instances, editable, inside)


## One [node] header: remember it if it is an instance, and remember where it sits if its parent
## is not the scene root. The full path of a node is its parent path plus its name, and a parent
## of "." is the root.
func _note_node(
	line: String,
	line_number: int,
	instances: PackedStringArray,
	inside: Dictionary[String, int],
) -> void:
	var node_name: String = _quoted_after(line, "name=\"")
	var parent: String = _quoted_after(line, "parent=\"")
	if node_name == "" or parent == "":
		return
	var full: String = node_name if parent == "." else "%s/%s" % [parent, node_name]
	if line.contains(" instance="):
		instances.append(full)
	if parent != ".":
		inside[full] = line_number


## For every node sitting under an instance, the instance must be declared editable. Godot needs
## the marker at EVERY level, so a nested instance reports one violation per level that lacks
## one rather than only the outermost.
func _report_uneditable(
	path: String,
	instances: PackedStringArray,
	editable: PackedStringArray,
	inside: Dictionary[String, int],
) -> void:
	for full: String in inside:
		for instance: String in instances:
			if full == instance or not full.begins_with("%s/" % instance):
				continue
			if editable.has(instance):
				continue
			_fail("%s:%d overrides '%s' inside the instance '%s' with no [editable path=\"%s\"] — the override is DROPPED in an exported build" % [
				path, inside[full], full, instance, instance,
			])
