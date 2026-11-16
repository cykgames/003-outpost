extends Camera2D
# Mobile-friendly camera. The Map scene drives panning (single-finger drag)
# and zoom (on-screen HUD buttons or the mouse wheel); this node only smooths
# the zoom transition and exposes pan/zoom helpers. Taps are reserved for
# turret placement and are handled by the map / turret slots, not here.


@export var min_zoom: float = 0.25
@export var max_zoom: float = 1.5
@export var zoom_rate: float = 16.0
@export var zoom_delta: float = 0.1

var target_zoom: float = 0.9

@onready var hud := $Hud as Hud


func _ready() -> void:
	target_zoom = zoom.x
	if hud:
		hud.bind_camera(self)


func _physics_process(delta: float) -> void:
	zoom.x = lerp(zoom.x, target_zoom, zoom_rate * delta)
	zoom.y = lerp(zoom.y, target_zoom, zoom_rate * delta)
	# disable physics process once the zoom has reached its target
	set_physics_process(not is_equal_approx(zoom.x, target_zoom))


# Pan by a screen-space delta (1:1 finger tracking at any zoom level).
func pan(screen_delta: Vector2) -> void:
	position -= screen_delta / zoom


func zoom_in() -> void:
	target_zoom = min(target_zoom + zoom_delta, max_zoom)
	set_physics_process(true)


func zoom_out() -> void:
	target_zoom = max(target_zoom - zoom_delta, min_zoom)
	set_physics_process(true)


## Multiplies the target zoom by [param factor] (pinch gesture), clamped to
## [min_zoom, max_zoom]. Added for the touch build: the HUD +/- buttons are
## coarse, a pinch is how players actually frame the battlefield.
func zoom_by(factor: float) -> void:
	if factor <= 0.0 or is_nan(factor):
		return
	target_zoom = clampf(target_zoom * factor, min_zoom, max_zoom)
	set_physics_process(true)


func center_on(world_pos: Vector2) -> void:
	position = world_pos
