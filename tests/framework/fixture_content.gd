class_name FixtureContent
extends RefCounted
## The content a test needs, built in code: items, a conversation, a schedule, a path action.
##
## WHY THIS EXISTS
## A test asserting `item/rose_key` is testing the demo, not the item system. Before T1.3 about
## a third of the suite named demo content, so deleting `data/` and `scenes/areas/` - which
## `docs/NEW_GAME.md` tells a consuming game to do on day one - deleted rung 4 of the
## verification ladder. Everything here is deliberately ABSTRACT: `fixture/unique`, not a key
## to a rose garden. If a name in this file ever describes a place, that is the demo growing
## back.
##
## WHY THE SHAPES ARE WHAT THEY ARE
## Each builder reproduces the STRUCTURE the systems under test need, and nothing else. The
## conversation is the clearest case: it has a first-meeting node and an acquaintance node in
## authored order (so the entry-point condition has something to choose between), a branch node
## with exactly three choices (so hiding one can be observed), a node that leads onward and one
## that terminates. That is not a story - it is the smallest graph on which the runner's rules
## are all observable.
##
## OWNS: constructing content resources. MUST NOT: write files, touch a registry, or assert
## anything. `fixtures.gd` owns where content lives; this file owns what it is.

const UNIQUE_ITEM: StringName = &"item/fixture_unique"
const STACK_ITEM: StringName = &"item/fixture_stack"
const SPARE_ITEM: StringName = &"item/fixture_spare"
const STACK_LIMIT: int = 20

const TALK: StringName = &"talk/fixture_speaker"
const MET_FLAG: StringName = &"fixture/met"
const TALLY_FLAG: StringName = &"fixture/talks"
const FIRST_NODE: StringName = &"greet_first"
const AGAIN_NODE: StringName = &"greet_again"
const MENU_NODE: StringName = &"menu"
const ONWARD_NODE: StringName = &"onward"
const FINAL_NODE: StringName = &"final"

const SCHEDULE: StringName = &"schedule/fixture_walker"
const MORNING_WAYPOINT: StringName = &"fixture_post_a"
const EVENING_WAYPOINT: StringName = &"fixture_post_b"
const MORNING_HOUR: int = 6
const EVENING_HOUR: int = 18

const STANDING_ID: StringName = &"fixture_person"
const SUCCESS_FLAG: StringName = &"fixture/bartered"


## The three items every content-shaped assertion in the suite needs: one unique key item, one
## that stacks to a limit below its category's default, and a second material so a sort order
## has something to be an order OF.
static func items() -> Array[ItemDefinition]:
	var out: Array[ItemDefinition] = []
	out.append(item(UNIQUE_ITEM, GameEnums.ItemCategory.KEY_ITEM, 1))
	out.append(item(STACK_ITEM, GameEnums.ItemCategory.MATERIAL, STACK_LIMIT))
	out.append(item(SPARE_ITEM, GameEnums.ItemCategory.MATERIAL, 99))
	return out


static func item(id: StringName, category: GameEnums.ItemCategory, max_stack: int) -> ItemDefinition:
	var made := ItemDefinition.new()
	made.id = id
	# A name_key that is deliberately NOT in strings.csv. tr() returns the key unchanged, which
	# is what every assertion here compares against, so a fixture cannot pass by translation.
	made.name_key = "fixture.%s.name" % String(id).get_file()
	made.category = category
	made.max_stack = max_stack
	return made


## A conversation whose graph exercises every rule the runner has: fall-through entry, an effect
## on arrival, a three-way branch, a link onward, and a terminal node.
static func conversation() -> Conversation:
	var talk := Conversation.new()
	talk.id = TALK
	var nodes: Array[DialogueNode] = []
	nodes.append(_greeting(FIRST_NODE, GameEnums.FlagTest.IS_FALSE, GameEnums.FlagWrite.SET_TRUE))
	nodes.append(_greeting(AGAIN_NODE, GameEnums.FlagTest.IS_TRUE, GameEnums.FlagWrite.ADD))
	nodes.append(_menu())
	nodes.append(_plain(ONWARD_NODE, MENU_NODE))
	nodes.append(_plain(FINAL_NODE, &""))
	talk.nodes = nodes
	return talk


static func _greeting(node_id: StringName, test: GameEnums.FlagTest,
		write: GameEnums.FlagWrite) -> DialogueNode:
	var node := DialogueNode.new()
	node.node_id = node_id
	node.text_key = "fixture.line.%s" % node_id
	node.next_node = MENU_NODE
	node.condition_flag = MET_FLAG
	node.condition_test = test
	node.effect_flag = MET_FLAG if write == GameEnums.FlagWrite.SET_TRUE else TALLY_FLAG
	node.effect_write = write
	node.effect_value = 1
	return node


## Exactly three choices, in this order, because the runner's index rules are only observable
## with a first one to hide, a later one that leads somewhere, and a last one that ends it.
static func _menu() -> DialogueNode:
	var node := DialogueNode.new()
	node.node_id = MENU_NODE
	node.text_key = "fixture.line.menu"
	var choices: Array[DialogueChoice] = []
	choices.append(_choice(ONWARD_NODE))
	choices.append(_choice(FINAL_NODE))
	choices.append(_choice(&""))
	node.choices = choices
	return node


static func _choice(target: StringName) -> DialogueChoice:
	var choice := DialogueChoice.new()
	choice.target_node = target
	choice.text_key = "fixture.choice.%s" % (target if target != &"" else &"leave")
	return choice


static func _plain(node_id: StringName, next_node: StringName) -> DialogueNode:
	var node := DialogueNode.new()
	node.node_id = node_id
	node.text_key = "fixture.line.%s" % node_id
	node.next_node = next_node
	return node


## Two blocks, so the wrap past midnight has a previous day's block to wrap INTO.
static func schedule() -> NpcSchedule:
	var made := NpcSchedule.new()
	made.id = SCHEDULE
	var entries: Array[ScheduleEntry] = []
	entries.append(_entry(MORNING_HOUR, MORNING_WAYPOINT, GameEnums.NpcActivity.STAND))
	entries.append(_entry(EVENING_HOUR, EVENING_WAYPOINT, GameEnums.NpcActivity.STAND))
	made.entries = entries
	return made


static func _entry(from_hour: int, waypoint: StringName,
		activity: GameEnums.NpcActivity) -> ScheduleEntry:
	var entry := ScheduleEntry.new()
	entry.from_hour = from_hour
	entry.waypoint = waypoint
	entry.activity = activity
	return entry


## An action that can genuinely refuse, fail AND succeed - the three outcomes path_actions_test
## walks in one go. success_standing above required_standing is what keeps the failure branch
## reachable; equal values would make it a lock with extra steps.
static func path_action() -> PathAction:
	var action := PathAction.new()
	action.verb = GameEnums.InteractVerb.BARTER
	action.label_key = "fixture.action.label"
	action.required_standing = 1
	action.success_standing = 3
	action.standing_on_success = 1
	action.standing_on_failure = -1
	action.once = true
	action.success_flag = SUCCESS_FLAG
	action.success_key = "fixture.action.success"
	action.failure_key = "fixture.action.failure"
	action.refusal_key = "fixture.action.refusal"
	return action
