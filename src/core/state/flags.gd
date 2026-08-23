extends Node
## World and plot state. Autoload `Flags`.
##
## WHY A FLAG STORE AT ALL
## Narrative state spreads if you let it: a door remembers whether it is unlocked, an NPC
## remembers whether you spoke, a quest remembers a step, and soon the same truth lives in
## four places and they disagree. One store, one truth, one save section.
##
## WHAT BELONGS HERE: facts the plot cares about, and that must survive a reload.
##     story/chapter                   int    how far the main plot has progressed
##     met/gardener                    bool   has the player spoken to this NPC
##     area/orchard/gate_unlocked      bool   world change the player made
##     count/lanterns_lit              int    a running tally
##
## WHAT DOES NOT BELONG HERE: anything recomputable, anything per-frame, positions,
## velocities, UI state, or a cache. If it can be derived, derive it.
##
## NAMING: lowercase, slash-separated, most general part first, so `story/`, `met/` and
## `area/<id>/` group naturally when sorted or dumped in the debug console.
##
## OWNS: the flag dictionary and its save section.
## MUST NOT: interpret any flag. It never knows what `story/chapter` means.

var _values: Dictionary[StringName, Variant] = {}


func _ready() -> void:
	SaveSystem.register(&"flags", _collect_save, _apply_save)


## Set a flag and announce it. Setting a flag to the value it already has is silent, so
## listeners are never woken for a non-change.
func set_flag(flag: StringName, value: Variant) -> void:
	if _values.has(flag) and _values[flag] == value:
		return
	_values[flag] = value
	Log.debug("flags", "%s = %s" % [flag, str(value)])
	Events.flag_changed.emit(flag, value)


func get_flag(flag: StringName, default: Variant = null) -> Variant:
	return _values.get(flag, default)


func has_flag(flag: StringName) -> bool:
	return _values.has(flag)


## Typed accessors. Use these rather than get_flag, so a wrong type is caught here instead
## of surfacing as a strange bug three systems away.
func get_bool(flag: StringName, default: bool = false) -> bool:
	var value: Variant = _values.get(flag, default)
	if value is bool:
		return value
	Log.warn("flags", "%s is %s, expected bool" % [flag, type_string(typeof(value))])
	return default


func get_int(flag: StringName, default: int = 0) -> int:
	var value: Variant = _values.get(flag, default)
	if value is int or value is float:
		return roundi(value as float)
	Log.warn("flags", "%s is %s, expected int" % [flag, type_string(typeof(value))])
	return default


func get_string(flag: StringName, default: String = "") -> String:
	var value: Variant = _values.get(flag, default)
	if value is String:
		return value
	Log.warn("flags", "%s is %s, expected String" % [flag, type_string(typeof(value))])
	return default


## Add to a counter flag, creating it at zero if absent. Returns the new total.
func advance(flag: StringName, amount: int = 1) -> int:
	var total: int = get_int(flag, 0) + amount
	set_flag(flag, total)
	return total


func erase_flag(flag: StringName) -> void:
	if _values.erase(flag):
		Events.flag_changed.emit(flag, null)


## Wipe everything. Used when starting a new game, and by tests between cases.
func clear_all() -> void:
	var count: int = _values.size()
	_values.clear()
	Log.info("flags", "Cleared %d flags" % count)


## Every flag whose name starts with `prefix`. Useful for area teardown and debug dumps.
func with_prefix(prefix: String) -> Dictionary[StringName, Variant]:
	var found: Dictionary[StringName, Variant] = {}
	for flag: StringName in _values:
		if String(flag).begins_with(prefix):
			found[flag] = _values[flag]
	return found


func count() -> int:
	return _values.size()


func _collect_save() -> Dictionary:
	# StringName keys become strings in JSON, and come back as strings. _apply_save converts.
	var out: Dictionary = {}
	for flag: StringName in _values:
		out[String(flag)] = _values[flag]
	return out


func _apply_save(data: Dictionary) -> void:
	_values.clear()
	for key: String in data:
		_values[StringName(key)] = data[key]
	Log.info("flags", "Restored %d flags" % _values.size())
