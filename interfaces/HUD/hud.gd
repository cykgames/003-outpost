class_name Hud
extends CanvasLayer


@onready var healthbar := $Info/PanelContainer/Rows/Health/HealthBar as TextureProgressBar
@onready var money_label := $Info/PanelContainer/Rows/Money/Label as Label
@onready var gameover := $UI/GameOver as GameOver
@onready var pause := $UI/Pause as PanelContainer
@onready var wave_label := $Info/WaveLabel as Label
@onready var nextwave_panel := $Info/NextWave as PanelContainer
@onready var countdown_label := $Info/NextWave/Rows/Countdown as Label
@onready var nextwave_timer := $Info/NextWave/Timer as Timer

var _camera: Camera2D


func _ready() -> void:
	_build_touch_buttons()


# Called by the parent Camera2D once it is ready.
func bind_camera(cam: Camera2D) -> void:
	_camera = cam


# On-screen controls for touch devices: zoom +/- (bottom-right) and a pause
# button (top-left). Built in code so they adapt to any screen size. The layer
# is inserted at the bottom so the GameOver/Pause panels render above it.
func _build_touch_buttons() -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	move_child(layer, 0)

	var zoom_box := VBoxContainer.new()
	zoom_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	zoom_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	zoom_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	zoom_box.position = Vector2(-24, -24)
	zoom_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(zoom_box)

	var zoom_in_btn := Button.new()
	zoom_in_btn.text = "+"
	zoom_in_btn.custom_minimum_size = Vector2(80, 80)
	zoom_in_btn.pressed.connect(func() -> void:
		if _camera:
			_camera.zoom_in())
	zoom_box.add_child(zoom_in_btn)

	var zoom_out_btn := Button.new()
	zoom_out_btn.text = "-"
	zoom_out_btn.custom_minimum_size = Vector2(80, 80)
	zoom_out_btn.pressed.connect(func() -> void:
		if _camera:
			_camera.zoom_out())
	zoom_box.add_child(zoom_out_btn)

	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.custom_minimum_size = Vector2(72, 72)
	pause_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	pause_btn.position = Vector2(12, 80)
	pause_btn.pressed.connect(_on_pause_button_pressed)
	layer.add_child(pause_btn)


func _on_pause_button_pressed() -> void:
	if not Global.is_gameover and pause:
		pause._enable(not get_tree().paused)


func _process(_delta: float) -> void:
	money_label.text = str(Global.money)
	if not nextwave_timer.is_stopped():
		countdown_label.text = str(int(nextwave_timer.time_left) + 1)


# Needed to set the healthbar's initial values
func initialize(max_health) -> void:
	healthbar.max_value = max_health
	healthbar.value = healthbar.max_value


# Used to update the objective's health
func _on_objective_health_changed(cur_health: int) -> void:
	healthbar.value = cur_health


func _on_objective_destroyed() -> void:
	gameover.enable(true)


func _on_spawner_countdown_started(seconds: float) -> void:
	nextwave_panel.show()
	nextwave_timer.start(seconds)


func _on_timer_timeout() -> void:
	nextwave_panel.hide()


# Here just in case a different gameover screen will be used in case of victory
func _on_spawner_enemies_defeated() -> void:
	gameover.enable(true)


func _on_spawner_wave_started(current_wave: int) -> void:
	wave_label.text = "Wave: %d" % current_wave
