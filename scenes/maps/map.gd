extends Node2D
# Base Map scene. To make a new level, create a scene inheriting this one and
# use the tilemap to design it (Terrains draw navigation-ready paths), then
# tweak the spawner, objective, camera, etc.
#
# Mobile input model: a single finger drag pans the camera; a tap (press and
# release without dragging) on empty ground dismisses any open turret actions.
# Turret slots handle their own taps via Area2D input_event and mark the event
# handled, so a tap that lands on a slot never reaches this handler.


const STARTING_MONEY := 5000
const TAP_THRESHOLD := 16.0  # screen px before a press counts as a drag
const INITIAL_ZOOM := 1.0

@onready var objective := $Objective as Objective
@onready var spawner := $Spawner as Spawner
@onready var camera := $Camera2D as Camera2D
@onready var tilemap := $TileMap as TileMap

var _pressing := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _last_pos := Vector2.ZERO
## Live touch points by finger index (screen space) and pinch bookkeeping.
## Pinch needs the raw touch stream: the mouse-emulation path only ever sees
## one pointer, so a two-finger spread has to be tracked here.
var _touches := {}
var _pinching := false
var _pinch_dist := 0.0


func _ready() -> void:
	randomize()
	# initialize money
	Global.money = STARTING_MONEY
	# initialize camera limits from the tilemap
	var map_limits := tilemap.get_used_rect()
	var cell_size := tilemap.tile_set.tile_size
	camera.limit_left = int(map_limits.position.x) * cell_size.x
	camera.limit_top = int(map_limits.position.y) * cell_size.y
	camera.limit_right = int(map_limits.end.x) * cell_size.x
	camera.limit_bottom = int(map_limits.end.y) * cell_size.y
	# center the battlefield and start at a touch-friendly zoom
	camera.zoom = Vector2(INITIAL_ZOOM, INITIAL_ZOOM)
	camera.target_zoom = INITIAL_ZOOM
	camera.center_on(Vector2(
			(camera.limit_left + camera.limit_right) / 2.0,
			(camera.limit_top + camera.limit_bottom) / 2.0))
	# connect signals
	spawner.countdown_started.connect(Callable(camera.hud, "_on_spawner_countdown_started"))
	spawner.wave_started.connect(Callable(camera.hud, "_on_spawner_wave_started"))
	spawner.enemies_defeated.connect(Callable(camera.hud, "_on_spawner_enemies_defeated"))
	objective.health_changed.connect(Callable(camera.hud, "_on_objective_health_changed"))
	objective.destroyed.connect(Callable(camera.hud, "_on_objective_destroyed"))
	# initialize HUD parameters
	(camera.hud as Hud).initialize(objective.health)
	# start spawning enemies
	spawner.initialize(objective.global_position, map_limits, cell_size)


func _unhandled_input(event: InputEvent) -> void:
	# Raw touch tracking first: two fingers = pinch zoom. While pinching the
	# emulated-mouse pan/tap path is suppressed so a pinch never pans.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_track_touch(event)
		return
	if _pinching:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_pressing = true
					_dragging = false
					_press_pos = event.position
					_last_pos = event.position
				MOUSE_BUTTON_WHEEL_UP:
					camera.zoom_in()
				MOUSE_BUTTON_WHEEL_DOWN:
					camera.zoom_out()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# a tap on empty ground (slots mark their own taps handled)
			if _pressing and not _dragging and Global.turret_actions:
				Global.turret_actions.hide()
			_pressing = false
			_dragging = false
	elif event is InputEventMouseMotion and _pressing:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if not _dragging and \
					_press_pos.distance_to(event.position) > TAP_THRESHOLD:
				_dragging = true
			if _dragging:
				camera.pan(event.position - _last_pos)
			_last_pos = event.position


func _pinch_distance() -> float:
	var pts: Array = _touches.values()
	if pts.size() < 2:
		return 0.0
	return (pts[0] as Vector2).distance_to(pts[1] as Vector2)


## Track the raw touch stream and drive pinch zoom.
## Two fingers down -> pinch mode; the distance ratio between frames becomes
## the zoom factor, so the world moves with the fingers. Releasing every
## finger leaves pinch mode and hands control back to pan/tap.
func _track_touch(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_touches[touch.index] = touch.position
			if _touches.size() >= 2:
				_pinching = true
				_pressing = false
				_dragging = false
				_pinch_dist = _pinch_distance()
		else:
			_touches.erase(touch.index)
			if _touches.is_empty():
				_pinching = false
				_pinch_dist = 0.0
		return
	var drag := event as InputEventScreenDrag
	if drag == null or not _touches.has(drag.index):
		return
	_touches[drag.index] = drag.position
	if _pinching and _touches.size() >= 2:
		var d := _pinch_distance()
		if _pinch_dist > 1.0 and d > 1.0:
			camera.zoom_by(d / _pinch_dist)
		_pinch_dist = d


func _notification(what: int) -> void:
	# Android hardware back button toggles the pause menu (unless game over).
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not Global.is_gameover:
		var pause = camera.hud.get_node_or_null("UI/Pause")
		if pause:
			pause._enable(not get_tree().paused)
