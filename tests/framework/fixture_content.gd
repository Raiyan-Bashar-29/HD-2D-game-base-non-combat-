class_name FixtureContent
extends RefCounted
## The content a test needs, built in code: items, a conversation, a schedule, a quest, a path
## action.
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
## Three equippable fixtures, and each one exists to make a different rule observable: two in the
## SAME slot (so displacing an occupant is distinguishable from adding a second) and one in
## another slot (so two slots coexisting is distinguishable from one slot being overwritten).
## Every other fixture item has slot NONE, which is what proves an ordinary item is refused.
const HELD_ITEM: StringName = &"item/fixture_held"
const OTHER_HELD_ITEM: StringName = &"item/fixture_held_two"
const WORN_ITEM: StringName = &"item/fixture_worn"
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

const QUEST: StringName = &"quest/fixture_errand"
const QUEST_START_FLAG: StringName = &"fixture/asked"
const QUEST_FIRST_FLAG: StringName = &"fixture/first_done"
const QUEST_SECOND_FLAG: StringName = &"fixture/second_done"
const QUEST_FIRST_STEP: StringName = &"first"
const QUEST_SECOND_STEP: StringName = &"second"

## Two mapped places, and each exists to make a different rule observable: one KNOWN FROM START
## (so a new game with no travel in it still has a map with something on it) and one that is not
## (so discovery is distinguishable from being drawn at all). Neither has a scene behind it,
## which is the point: the map is provable in a checkout with no game in it.
const PLACE_A: StringName = &"fixture_place_a"
const PLACE_B: StringName = &"fixture_place_b"
const PLACE_A_SPAWN: StringName = &"fixture_arrival"

const STANDING_ID: StringName = &"fixture_person"
const SUCCESS_FLAG: StringName = &"fixture/bartered"


## The item fixtures every content-shaped assertion in the suite needs: one unique key item, one
## that stacks to a limit below its category's default, a second material so a sort order has
## something to be an order OF, and three equippable ones. All six go to disk together, so
## `ItemDb.count()` is asked for `items().size()` rather than compared to a number that would
## have to be edited here and there both.
static func items() -> Array[ItemDefinition]:
	var out: Array[ItemDefinition] = []
	out.append(item(UNIQUE_ITEM, GameEnums.ItemCategory.KEY_ITEM, 1))
	out.append(item(STACK_ITEM, GameEnums.ItemCategory.MATERIAL, STACK_LIMIT))
	out.append(item(SPARE_ITEM, GameEnums.ItemCategory.MATERIAL, 99))
	out.append(item(HELD_ITEM, GameEnums.ItemCategory.TOOL, 1, GameEnums.EquipSlot.LIGHT))
	out.append(item(OTHER_HELD_ITEM, GameEnums.ItemCategory.TOOL, 1, GameEnums.EquipSlot.LIGHT))
	out.append(item(WORN_ITEM, GameEnums.ItemCategory.CLOTHING, 1, GameEnums.EquipSlot.GARMENT))
	return out


static func item(id: StringName, category: GameEnums.ItemCategory, max_stack: int,
		equip_slot: GameEnums.EquipSlot = GameEnums.EquipSlot.NONE) -> ItemDefinition:
	var made := ItemDefinition.new()
	made.id = id
	# A name_key that is deliberately NOT in strings.csv. tr() returns the key unchanged, which
	# is what every assertion here compares against, so a fixture cannot pass by translation.
	made.name_key = "fixture.%s.name" % String(id).get_file()
	made.category = category
	made.max_stack = max_stack
	made.equip_slot = equip_slot
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


## A quest whose SHAPE makes every tracker rule observable, and nothing more: a start condition
## that is not ALWAYS (so "not started" is a real state to be in), and TWO steps in order (so
## advancing is distinguishable from completing, which one step cannot show).
##
## The three flags are abstract on purpose. A quest step is a flag condition and nothing else, so
## a fixture quest needs no lever, no trigger volume and no area - which is what makes the quest
## system provable in a checkout with no game in it.
static func quest() -> Quest:
	var made := Quest.new()
	made.id = QUEST
	made.name_key = "fixture.quest.name"
	made.summary_key = "fixture.quest.summary"
	made.condition_flag = QUEST_START_FLAG
	made.condition_test = GameEnums.FlagTest.IS_TRUE
	var steps: Array[QuestStep] = []
	steps.append(quest_step(QUEST_FIRST_STEP, QUEST_FIRST_FLAG))
	steps.append(quest_step(QUEST_SECOND_STEP, QUEST_SECOND_FLAG))
	made.steps = steps
	return made


static func quest_step(step_id: StringName, flag: StringName) -> QuestStep:
	var step := QuestStep.new()
	step.step_id = step_id
	step.summary_key = "fixture.quest.step.%s" % step_id
	step.condition_flag = flag
	step.condition_test = GameEnums.FlagTest.IS_TRUE
	return step


## The two mapped places, in the order `AreaDb.ids()` will sort them, so a case can assert an
## order without restating one here.
static func area_defs() -> Array[AreaDef]:
	var out: Array[AreaDef] = []
	out.append(area_def(PLACE_A, Vector2(0.25, 0.5), true, PLACE_A_SPAWN))
	out.append(area_def(PLACE_B, Vector2(0.75, 0.5), false, &""))
	return out


static func area_def(id: StringName, at: Vector2, known_from_start: bool,
		arrival_spawn: StringName) -> AreaDef:
	var made := AreaDef.new()
	made.id = id
	# Deliberately NOT in strings.csv, for the reason `item()` gives: tr() returns the key
	# unchanged, so a fixture cannot pass by translation.
	made.name_key = "fixture.area.%s" % id
	made.map_position = at
	made.known_from_start = known_from_start
	made.arrival_spawn = arrival_spawn
	return made
