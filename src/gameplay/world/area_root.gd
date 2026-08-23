class_name AreaRoot
extends Node3D
## The root of every area scene. One per area, and the contract Director loads against.
##
## WHY EVERY AREA HAS THE SAME ROOT SCRIPT
## Areas differ in content, not in shape. Giving them one root type means Director never
## needs a per-area special case, an area can be validated automatically, and adding the
## fiftieth area requires no code at all. The moment an area needs bespoke behaviour, it
## gets a child node with its own script — the root stays generic.
##
## REQUIRED CHILD STRUCTURE (the validator checks this):
##     AreaRoot
##     |- Environment/         WorldEnvironment, sun, moon, EnvironmentDriver
##     |- Terrain/             ground and building geometry, static collision
##     |- Props/               non-interactive scenery
##     |- Interactables/       anything the player can act on
##     |- Actors/              NPCs
##     |- Spawns/              Marker3D per entry point, named to match travel requests
##     |- Triggers/            Area3D volumes: transitions, plot triggers, audio zones
##     |- Camera/              the HD2DCameraRig for this area
##
## OWNS: the area's identity, its weather rules, and its audio beds.
## MUST NOT: contain gameplay logic. It announces itself and configures ambience.

## Must match the folder and file name: scenes/areas/<id>/<id>.tscn
@export var area_id: StringName = &""
## Localization key for the name shown on screen when entering. Never raw text.
@export var display_name_key: String = ""

@export_group("Weather")
## Which kinds may occur here. Empty means anything.
@export var allowed_weather: Array[GameEnums.WeatherKind] = []
## Interiors and caves: weather keeps running but is not visible or felt.
@export var sheltered: bool = false
## Forced on entry, for a story beat that needs a specific sky.
@export var force_weather_on_entry: bool = false
@export var forced_weather: GameEnums.WeatherKind = GameEnums.WeatherKind.CLEAR

@export_group("Audio")
@export var music: AudioStream = null
@export var ambience: AudioStream = null

@export_group("Save")
## Flags for this area are namespaced under this prefix, so an area's world state can be
## found, dumped or cleared as a group.
@export var flag_prefix: String = ""


func _ready() -> void:
	if area_id == &"":
		Log.error("area", "%s has no area_id set — Director cannot match spawns to it" % name)

	Weather.sheltered = sheltered
	Weather.set_allowed(allowed_weather)
	if force_weather_on_entry:
		Weather.force(forced_weather)

	Audio.play_music(music)
	Audio.play_ambience(ambience)

	Log.info("area", "Area '%s' ready (%d spawns, %d interactables)" % [
		area_id, _count_in(^"Spawns"), _count_in(^"Interactables"),
	])


## Namespace for this area's flags. Use it so two areas cannot collide on a flag name:
##     Flags.set_flag(area.flag_key("gate_open"), true)
func flag_key(local_name: String) -> StringName:
	var prefix: String = flag_prefix if flag_prefix != "" else "area/%s" % area_id
	return StringName("%s/%s" % [prefix, local_name])


func _count_in(group: NodePath) -> int:
	var node: Node = get_node_or_null(group)
	return node.get_child_count() if node != null else 0
