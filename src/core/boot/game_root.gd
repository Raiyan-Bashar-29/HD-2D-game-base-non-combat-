extends Node
## The persistent root of a running game. Autoloads aside, this is the only node that lives
## for the whole session. Areas come and go underneath it.
##
## MUST NOT contain game logic. HARD BUDGET: 60 CODE LINES. READ THIS BEFORE ADDING ANYTHING.
## The previous project's equivalent file reached 3,983 lines, because a root node is the
## most convenient place to put anything and every feature took the convenience. This file
## may only do four things: build the tree, hand the world root to Director, put the player
## in it, and shut down cleanly. If you are about to add game logic here, it belongs in a
## system under src/systems or a component under src/gameplay. There is no exception that
## has ever turned out to be worth it.
##
## TREE
##     GameRoot                this script
##     |- WorldRoot            Node3D. The player and the current area live here.
##     |- UILayer              CanvasLayer above the world. Child order IS draw order:
##        |- InteractPrompt    gameplay UI, so a screen covers it
##        |- NotificationToast
##        |- UiRoot            the screen stack. Screens land here, over the HUD.
##        |- ScreenFade        last, so the curtain covers the screens too
##
## WHY THE PLAYER IS HERE AND NOT IN THE AREA
## The player outlives any single area. Instantiating them per-area would mean rebuilding
## their inventory and state on every doorway, and would make "walk out and back in" a
## state-loss bug. They are spawned once, and Director repositions them on each transition.

const PLAYER_SCENE: String = "res://scenes/characters/player.tscn"
## The area loaded on a fresh boot. When the main menu exists, it will choose instead.
const FIRST_AREA: StringName = &"courtyard"
const FIRST_SPAWN: StringName = &"default"

@onready var world_root: Node3D = $WorldRoot
@onready var ui_layer: CanvasLayer = $UILayer


func _ready() -> void:
	# Handle the window's close button ourselves so a quit can be made safe later.
	get_tree().set_auto_accept_quit(false)

	Director.attach_world_root(world_root)
	_spawn_player()
	Log.info("boot", "Game root ready")

	if Director.area_exists(FIRST_AREA):
		Events.area_change_requested.emit(FIRST_AREA, FIRST_SPAWN)
	else:
		# Once an area exists this is a real failure, not an early-development state. Fade in
		# regardless: ScreenFade starts opaque and only Director lifts it, so returning here
		# without fading leaves the player staring at black with no recovery.
		Log.error("boot", "First area '%s' not found at %s — world is empty" % [FIRST_AREA, Director.area_path(FIRST_AREA)])
		Events.screen_fade_requested.emit(false, 0.4)


## Spawned before the first area is requested, so Director already holds the reference and
## can place them on the correct spawn marker as soon as the area is in the tree.
func _spawn_player() -> void:
	var packed: PackedScene = load(PLAYER_SCENE) as PackedScene
	if packed == null:
		Log.error("boot", "Player scene missing or invalid at %s" % PLAYER_SCENE)
		return
	world_root.add_child(packed.instantiate())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown()


func _shutdown() -> void:
	Log.info("boot", "Shutdown requested")
	Events.game_ending.emit()
	# Autosave on quit goes here once there is a save slot policy. Deliberately not yet:
	# writing a save before the save format is settled would create migration debt on day one.
	get_tree().quit()
