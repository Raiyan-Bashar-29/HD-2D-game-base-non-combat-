extends Node
## Area loading and transitions. Autoload `Director`.
##
## WHY IT EXISTS
## Changing area is the single most failure-prone operation in an exploration game: it has to
## unload a live scene, load another off the main thread, place the player on the right spot,
## restore world state, and hide all of it behind a fade. Done ad hoc from a door script it
## goes wrong in a dozen ways, the worst being two doors firing at once and leaving two areas
## in the tree. One owner, one guarded path.
##
## OWNS: which area is loaded, the transition sequence, the world root, and the reference to
## the current player.
## MUST NOT: know what is inside an area, or contain per-area special cases. If an area needs
## something special on entry, that belongs in the area's own script.
##
## HOW TO TRAVEL, from anywhere:
##     Events.area_change_requested.emit(&"orchard", &"south_gate")
## Nothing calls change_area() directly except this file, so every transition is logged in
## one place and the guard cannot be bypassed.

const AREA_PATH_TEMPLATE: String = "res://scenes/areas/%s/%s.tscn"
const FADE_OUT: float = 0.35
const FADE_IN: float = 0.45

## The area currently in the tree. Empty before the first load.
var current_area_id: StringName = &""
## The live player node, or null between areas. Set from the player_spawned signal rather
## than by searching the tree, so there is never a stale path to chase.
var player: Node3D = null

var _world_root: Node3D = null
var _current_area: Node3D = null
var _transitioning: bool = false
## Set when loading a save, so the player lands where they were rather than at a spawn point.
var _position_override: Variant = null


func _ready() -> void:
	Events.area_change_requested.connect(_on_area_change_requested)
	Events.player_spawned.connect(_on_player_spawned)
	Events.player_despawned.connect(_on_player_despawned)
	SaveSystem.register(&"world", _collect_save, _apply_save)


## The persistent node that areas are parented under. The game root calls this once on boot.
func attach_world_root(node: Node3D) -> void:
	_world_root = node
	Log.info("world", "World root attached: %s" % node.name)


func has_world_root() -> bool:
	return _world_root != null and is_instance_valid(_world_root)


func area_path(area_id: StringName) -> String:
	return AREA_PATH_TEMPLATE % [area_id, area_id]


func area_exists(area_id: StringName) -> bool:
	return ResourceLoader.exists(area_path(area_id))


func is_transitioning() -> bool:
	return _transitioning


## Reload the area in place. Useful for debugging and after editing an area scene.
func reload_current_area() -> void:
	if current_area_id != &"":
		_begin_transition(current_area_id, &"")


func _on_area_change_requested(area_id: StringName, spawn_id: StringName) -> void:
	_begin_transition(area_id, spawn_id)


## The guard. Every rejection is logged, because a silently ignored door is maddening to debug.
func _begin_transition(area_id: StringName, spawn_id: StringName) -> void:
	if _transitioning:
		Log.warn("world", "Ignoring travel to '%s': already moving to '%s'" % [area_id, current_area_id])
		return
	if not has_world_root():
		Log.error("world", "Cannot load '%s': no world root attached" % area_id)
		return
	if not area_exists(area_id):
		Log.error("world", "Area '%s' has no scene at %s" % [area_id, area_path(area_id)])
		return
	_transitioning = true
	_run_transition(area_id, spawn_id)


func _run_transition(area_id: StringName, spawn_id: StringName) -> void:
	var from: StringName = current_area_id
	Log.info("world", "Transition %s -> %s (spawn '%s')" % [
		from if from != &"" else &"(none)", area_id, spawn_id,
	])

	if from != &"":
		Events.screen_fade_requested.emit(true, FADE_OUT)
		await get_tree().create_timer(FADE_OUT).timeout
		Events.area_unloading.emit(from)
		_free_current_area()

	var scene: PackedScene = await _load_area_scene(area_id)
	if scene == null:
		_transitioning = false
		Events.screen_fade_requested.emit(false, FADE_IN)
		return

	var instance: Node = scene.instantiate()
	var area: Node3D = instance as Node3D
	if area == null:
		Log.error("world", "Area '%s' root is %s, expected Node3D" % [area_id, instance.get_class()])
		instance.free()
		_transitioning = false
		return

	_current_area = area
	current_area_id = area_id
	_world_root.add_child(area)

	# The area is in the tree and its _ready has run, so its spawn markers exist.
	_place_player(area, spawn_id)

	Events.area_entered.emit(area_id)
	Events.screen_fade_requested.emit(false, FADE_IN)
	_transitioning = false
	Log.info("world", "Entered '%s'" % area_id)


## Threaded load so a large area does not freeze the frame behind the fade.
func _load_area_scene(area_id: StringName) -> PackedScene:
	var path: String = area_path(area_id)
	var request: Error = ResourceLoader.load_threaded_request(path)
	if request != OK:
		Log.error("world", "Load request for %s failed: %s" % [path, error_string(request)])
		return null

	while true:
		var progress: Array = []
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path, progress)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				return ResourceLoader.load_threaded_get(path) as PackedScene
			ResourceLoader.THREAD_LOAD_FAILED:
				Log.error("world", "Load of %s failed" % path)
				return null
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				Log.error("world", "%s is not a loadable resource" % path)
				return null
		await get_tree().process_frame
	return null


func _free_current_area() -> void:
	if _current_area != null and is_instance_valid(_current_area):
		_current_area.queue_free()
	_current_area = null
	current_area_id = &""


## Put the player on the named spawn marker. Falls back rather than failing, because being
## dropped at the origin is recoverable and being stuck on a black screen is not.
func _place_player(area: Node3D, spawn_id: StringName) -> void:
	if player == null or not is_instance_valid(player):
		return

	if _position_override is Vector3:
		player.global_position = _position_override
		_position_override = null
		return

	var marker: Node3D = _find_spawn(area, spawn_id)
	if marker == null:
		Log.warn("world", "No spawn '%s' in '%s' — using area origin" % [spawn_id, area.name])
		player.global_position = area.global_position
		return
	player.global_position = marker.global_position
	player.global_rotation = marker.global_rotation


func _find_spawn(area: Node3D, spawn_id: StringName) -> Node3D:
	var spawns: Node = area.get_node_or_null(^"Spawns")
	if spawns == null:
		return null
	if spawn_id != &"":
		var named: Node = spawns.get_node_or_null(NodePath(String(spawn_id)))
		var as_marker: Node3D = named as Node3D
		if as_marker != null:
			return as_marker
	for child: Node in spawns.get_children():
		var fallback: Node3D = child as Node3D
		if fallback != null:
			return fallback
	return null


func _on_player_spawned(spawned: Node3D) -> void:
	player = spawned


func _on_player_despawned() -> void:
	player = null


func _collect_save() -> Dictionary:
	var data: Dictionary = {"area": String(current_area_id)}
	if player != null and is_instance_valid(player):
		data["player_position"] = DictRead.put_vector3(player.global_position)
		data["player_yaw"] = player.global_rotation.y
	return data


func _apply_save(data: Dictionary) -> void:
	var area_id: StringName = DictRead.get_name(data, "area", &"")
	if area_id == &"":
		Log.warn("world", "Save has no area to return to")
		return
	if data.has("player_position"):
		_position_override = DictRead.get_vector3(data, "player_position")
	Events.area_change_requested.emit(area_id, &"")
