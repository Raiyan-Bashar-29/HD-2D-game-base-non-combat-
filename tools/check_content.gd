extends SceneTree
## Content gate: the checks that catch a broken item, a duplicate object id, or a localization
## key that will render on screen as its own name.
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
	var raw: PackedStringArray = ResourceLoader.list_directory(ItemDb.ITEM_DIR)
	print("  list_directory(%s) -> %s" % [ItemDb.ITEM_DIR, str(raw)])
	print("  resolved paths        -> %s" % str(ItemDb.resource_paths(ItemDb.ITEM_DIR)))


func _check_items() -> void:
	ItemDb.reload()
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
		if path == ItemDb.ITEM_DIR:
			continue
		for file_name: String in DirAccess.get_files_at(path):
			if not file_name.ends_with(".tres"):
				continue
			var resource: Resource = ResourceLoader.load("%s/%s" % [path, file_name])
			if resource is ItemDefinition:
				_fail("%s/%s is an ItemDefinition outside %s" % [path, file_name, ItemDb.ITEM_DIR])


func _check_scenes() -> void:
	var scenes: Array[String] = []
	for directory: String in SCENE_DIRS:
		_collect_scenes(directory, scenes)
	print("  scenes scanned: %d" % scenes.size())
	for path: String in scenes:
		_check_scene(path)


func _collect_scenes(directory: String, into: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(directory):
		_collect_scenes("%s/%s" % [directory, sub], into)
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(".tscn"):
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
	DialogueDb.reload()
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
