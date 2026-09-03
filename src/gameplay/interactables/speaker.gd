class_name Speaker
extends Interactable
## Something you can talk to. A plaque, a parrot, or eventually an NPC.
##
## IT NAMES A CONVERSATION ID AND NOTHING ELSE, exactly as `AreaDoor` names an area id. It does
## not know what is said, what the conversation changes, or that a dialogue box exists. That
## keeps the fiftieth speaker in the game a `.tscn` override and a `.tres` file with no code at
## all, which is the same test `ItemDb` and `DialogueDb` are built to pass.
##
## WHY IT GOES THROUGH THE BUS. `Speaker` is in the gameplay layer and the dialogue box is in
## the ui layer, and dependencies here point downward only: gameplay must not name a screen.
## So it emits `Events.dialogue_requested` and stops, exactly as `AreaDoor` emits
## `area_change_requested` rather than loading an area itself. `ScreenKeys` listens, because it
## is already the one place a thing becomes a screen.
##
## NO "ALREADY TALKING" REFUSAL, deliberately. It cannot happen: `InteractionSensor` takes its
## own `&"dialogue"` token on `Events.dialogue_started`, so while a conversation is open the
## sensor is suspended and this object cannot be attempted at all. A guard here would be a
## second answer to a question WP-02 already answered once.
##
## OWNS: which conversation it offers, and refusing when it has none.
## MUST NOT: read dialogue data beyond checking that its id resolves, read or write a flag,
## open a screen, or know what a dialogue box contains.

## The conversation to open. Must match data/dialogue/<name>.tres, whose id is `talk/<name>`.
@export var conversation_id: StringName = &""


func _ready() -> void:
	verb = GameEnums.InteractVerb.TALK
	super()
	if conversation_id == &"":
		Log.error("dialogue", "%s names no conversation and will refuse every attempt" % name)
	elif not DialogueDb.has(conversation_id):
		# Loud at load, not at use. A speaker whose conversation was renamed must not look like
		# scenery until a player walks the length of the map to try it.
		Log.error("dialogue", "%s offers '%s', which does not exist" % [name, conversation_id])


## STORY_GATED when there is nothing to say: a refusal with a message rather than a silent
## no-op, on the same reasoning that makes a locked gate keep offering its prompt.
func refusal(_who: Node3D) -> GameEnums.RefusalReason:
	if conversation_id == &"" or not DialogueDb.has(conversation_id):
		return GameEnums.RefusalReason.STORY_GATED
	return GameEnums.RefusalReason.NONE


func perform(_who: Node3D) -> void:
	Log.info("dialogue", "%s asks for '%s'" % [name, conversation_id])
	Events.dialogue_requested.emit(conversation_id)
