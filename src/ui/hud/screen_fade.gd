extends ColorRect
## The black rectangle that area transitions hide behind.
##
## Listens for Events.screen_fade_requested and nothing else. Director asks for a fade
## without knowing this node exists, which is exactly the case the event bus is for: the
## sender does not care who performs it, and a cutscene can later ask for the same fade.
##
## Starts fully black so the very first frame of a fresh boot is not a flash of an
## unlit, unpopulated world.
##
## OWNS: the fade rectangle and its tween.
## MUST NOT: know why the screen is fading, or who asked. It performs one visual effect.

const START_OPAQUE: bool = true

var _tween: Tween = null


func _ready() -> void:
	# Never intercept clicks. A full-screen rectangle that eats input is a bug that takes
	# an hour to find.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep fading even when the game is paused, so a pause during a transition does not
	# leave the screen stuck black.
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.0, 0.0, 0.0, 1.0 if START_OPAQUE else 0.0)
	Events.screen_fade_requested.connect(_on_fade_requested)


func _on_fade_requested(to_black: bool, seconds: float) -> void:
	var target: float = 1.0 if to_black else 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if seconds <= 0.0:
		color.a = target
		return
	_tween = create_tween()
	_tween.tween_property(self, "color:a", target, seconds)
