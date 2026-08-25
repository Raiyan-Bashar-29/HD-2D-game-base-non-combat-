class_name EnvironmentDriver
extends Node
## Turns the world clock and the weather into real lighting. This is where "time of day"
## stops being a number and starts being something you can see.
##
## OWNS: the WorldEnvironment's values, the sun and moon transforms, and the HD-2D post
## stack (glow, tonemap, fog).
## MUST NOT: decide what time it is, or what the weather is. It reads Clock and Weather and
## renders their consequences. That separation is why time can be fast-forwarded by a bed,
## or forced by a cutscene, without touching this file.
##
## WHY IT INTERPOLATES EVERY FRAME rather than on the hour: stepping light values once a
## minute is visible as a flicker. Continuous interpolation across a keyframe table costs a
## handful of lerps per frame and looks like an actual sunrise.
##
## THE HD-2D POST STACK, applied once at startup:
##   AgX tonemapping        - rolls off highlights gently, so a bright sky keeps colour
##                            instead of clipping to white. This is a large part of why
##                            modern HD-2D looks filmic rather than flat.
##   Generous glow          - the signature bloom. Threshold kept low so lanterns and
##                            bright sky bleed, but not so low that everything hazes.
##   Volumetric fog         - gives godrays and depth between layers of scenery, which is
##                            what separates foreground, midground and background.
##   No SSAO, no SDFGI      - both are expensive and largely wasted on billboarded sprites
##                            and simple geometry. Revisit only if the look demands it.

## A single point in the day. `t` is Clock.day_fraction(): 0.0 and 1.0 are midnight.
const KEYFRAMES: Array[Dictionary] = [
	{
		"t": 0.00, "sun": Color(0.36, 0.44, 0.68), "sun_e": 0.06,
		"amb": Color(0.12, 0.16, 0.28), "amb_e": 0.25,
		"fog": Color(0.10, 0.13, 0.22), "fog_d": 0.012,
	},
	{
		"t": 0.21, "sun": Color(0.56, 0.46, 0.58), "sun_e": 0.18,
		"amb": Color(0.22, 0.22, 0.34), "amb_e": 0.34,
		"fog": Color(0.22, 0.20, 0.28), "fog_d": 0.020,
	},
	{
		"t": 0.27, "sun": Color(1.00, 0.62, 0.38), "sun_e": 1.10,
		"amb": Color(0.45, 0.38, 0.42), "amb_e": 0.55,
		"fog": Color(0.62, 0.45, 0.42), "fog_d": 0.028,
	},
	{
		"t": 0.36, "sun": Color(1.00, 0.88, 0.72), "sun_e": 1.50,
		"amb": Color(0.55, 0.58, 0.62), "amb_e": 0.60,
		"fog": Color(0.58, 0.62, 0.68), "fog_d": 0.013,
	},
	{
		"t": 0.50, "sun": Color(1.00, 0.97, 0.90), "sun_e": 1.90,
		"amb": Color(0.62, 0.66, 0.72), "amb_e": 0.70,
		"fog": Color(0.62, 0.70, 0.80), "fog_d": 0.008,
	},
	{
		"t": 0.66, "sun": Color(1.00, 0.90, 0.74), "sun_e": 1.60,
		"amb": Color(0.58, 0.58, 0.60), "amb_e": 0.62,
		"fog": Color(0.62, 0.62, 0.68), "fog_d": 0.012,
	},
	{
		"t": 0.76, "sun": Color(1.00, 0.52, 0.30), "sun_e": 1.00,
		"amb": Color(0.42, 0.34, 0.40), "amb_e": 0.50,
		"fog": Color(0.58, 0.38, 0.36), "fog_d": 0.030,
	},
	{
		"t": 0.84, "sun": Color(0.56, 0.42, 0.62), "sun_e": 0.26,
		"amb": Color(0.24, 0.24, 0.38), "amb_e": 0.35,
		"fog": Color(0.26, 0.24, 0.34), "fog_d": 0.022,
	},
]

## Peak sun elevation at noon. Lower than 90 so shadows always have some length, which
## reads better in a fixed-camera game than a sun directly overhead.
const MAX_ELEVATION: float = 68.0
## How much heavy weather suppresses direct sun and lifts fog.
const WEATHER_SUN_DAMPING: float = 0.75
const WEATHER_FOG_GAIN: float = 4.0

@export var world_environment: WorldEnvironment = null
@export var sun: DirectionalLight3D = null
## Optional. If present it takes over lighting once the sun is below the horizon.
@export var moon: DirectionalLight3D = null
## Set false for interiors, which should not follow the outdoor sun.
@export var follow_clock: bool = true

var _environment: Environment = null


func _ready() -> void:
	_discover_siblings()
	if world_environment == null:
		Log.error("world", "EnvironmentDriver has no WorldEnvironment — lighting will not update")
		return

	_environment = world_environment.environment
	if _environment == null:
		_environment = Environment.new()
		world_environment.environment = _environment
	_build_post_stack()
	_apply_now()
	Log.info("world", "Environment driver ready (follow_clock=%s)" % str(follow_clock))


func _process(_delta: float) -> void:
	if follow_clock and _environment != null:
		_apply_now()


## The one-time HD-2D look configuration.
func _build_post_stack() -> void:
	_environment.background_mode = Environment.BG_SKY
	if _environment.sky == null:
		var sky := Sky.new()
		sky.sky_material = ProceduralSkyMaterial.new()
		_environment.sky = sky

	_environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	_environment.tonemap_exposure = 1.0

	_environment.glow_enabled = true
	_environment.glow_intensity = 0.9
	_environment.glow_strength = 1.1
	_environment.glow_bloom = 0.15
	_environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.glow_hdr_threshold = 0.92
	_environment.glow_hdr_scale = 2.0

	_environment.fog_enabled = true
	_environment.fog_mode = Environment.FOG_MODE_DEPTH
	_environment.fog_depth_begin = 30.0
	_environment.fog_depth_end = 160.0
	_environment.fog_sky_affect = 0.35

	_environment.volumetric_fog_enabled = true
	_environment.volumetric_fog_density = 0.005
	_environment.volumetric_fog_length = 96.0
	_environment.volumetric_fog_gi_inject = 0.0
	_environment.volumetric_fog_anisotropy = 0.3

	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR

	# Deliberately off. See the header note.
	_environment.ssao_enabled = false
	_environment.sdfgi_enabled = false
	_environment.ssil_enabled = false
	_environment.ssr_enabled = false


func _apply_now() -> void:
	var t: float = Clock.day_fraction()
	var frame: Dictionary = _sample(t)
	var wetness: float = Weather.intensity()

	var sun_energy: float = DictRead.get_float(frame, "sun_e") * (1.0 - wetness * WEATHER_SUN_DAMPING)
	var elevation: float = sin((t - 0.25) * TAU) * MAX_ELEVATION
	var azimuth: float = t * 360.0 - 90.0

	if sun != null:
		sun.light_color = DictRead.get_color(frame, "sun")
		sun.light_energy = maxf(0.0, sun_energy)
		sun.rotation_degrees = Vector3(-elevation, azimuth, 0.0)
		# Hide the sun entirely below the horizon so it cannot light the scene from beneath.
		sun.visible = elevation > -2.0

	if moon != null:
		moon.visible = elevation <= -2.0
		moon.rotation_degrees = Vector3(-(-elevation), azimuth + 180.0, 0.0)

	_environment.ambient_light_color = DictRead.get_color(frame, "amb")
	_environment.ambient_light_energy = DictRead.get_float(frame, "amb_e")

	var fog_colour: Color = DictRead.get_color(frame, "fog")
	_environment.fog_light_color = fog_colour
	_environment.fog_density = DictRead.get_float(frame, "fog_d") * (1.0 + wetness * WEATHER_FOG_GAIN)
	_environment.volumetric_fog_albedo = fog_colour

	var sky_material: ProceduralSkyMaterial = _environment.sky.sky_material as ProceduralSkyMaterial
	if sky_material != null:
		sky_material.sky_top_color = fog_colour.darkened(0.35)
		sky_material.sky_horizon_color = fog_colour.lightened(0.15)
		sky_material.ground_horizon_color = fog_colour.lightened(0.05)
		sky_material.ground_bottom_color = fog_colour.darkened(0.5)


## Blend between the two keyframes surrounding `t`, wrapping around midnight.
func _sample(t: float) -> Dictionary:
	var wrapped: float = fposmod(t, 1.0)
	var count: int = KEYFRAMES.size()
	var next_index: int = 0
	for i: int in count:
		if DictRead.get_float(KEYFRAMES[i], "t") > wrapped:
			next_index = i
			break
	var previous_index: int = posmod(next_index - 1, count)

	var previous: Dictionary = KEYFRAMES[previous_index]
	var upcoming: Dictionary = KEYFRAMES[next_index]
	var from_t: float = DictRead.get_float(previous, "t")
	var to_t: float = DictRead.get_float(upcoming, "t")
	# Crossing midnight means the span wraps past 1.0.
	if to_t <= from_t:
		to_t += 1.0
		if wrapped < from_t:
			wrapped += 1.0
	var span: float = maxf(0.0001, to_t - from_t)
	var mix: float = clampf((wrapped - from_t) / span, 0.0, 1.0)

	return {
		"sun": DictRead.get_color(previous, "sun").lerp(DictRead.get_color(upcoming, "sun"), mix),
		"sun_e": lerpf(DictRead.get_float(previous, "sun_e"), DictRead.get_float(upcoming, "sun_e"), mix),
		"amb": DictRead.get_color(previous, "amb").lerp(DictRead.get_color(upcoming, "amb"), mix),
		"amb_e": lerpf(DictRead.get_float(previous, "amb_e"), DictRead.get_float(upcoming, "amb_e"), mix),
		"fog": DictRead.get_color(previous, "fog").lerp(DictRead.get_color(upcoming, "fog"), mix),
		"fog_d": lerpf(DictRead.get_float(previous, "fog_d"), DictRead.get_float(upcoming, "fog_d"), mix),
	}


## Find the WorldEnvironment, sun and moon among our siblings when they were not wired in
## the scene. A forgotten @export used to leave the sun frozen at its default energy, which
## looks like "the day/night cycle does not work" and wastes an afternoon. Now it is found
## automatically, and says so.
func _discover_siblings() -> void:
	var host: Node = get_parent()
	if host == null:
		return
	if world_environment == null:
		world_environment = host.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
		if world_environment != null:
			Log.warn("world", "WorldEnvironment was not wired in the scene; found by name instead")
	if sun == null:
		sun = host.get_node_or_null(^"Sun") as DirectionalLight3D
		if sun == null:
			Log.warn("world", "No sun found: the day/night cycle will not light this area")
		else:
			Log.warn("world", "Sun was not wired in the scene; found by name instead")
	if moon == null:
		moon = host.get_node_or_null(^"Moon") as DirectionalLight3D
