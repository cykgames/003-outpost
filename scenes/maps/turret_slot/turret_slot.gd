extends Area2D
# Interactive base for deployed turrets. Tap an empty slot to open the build
# popup, or tap a built turret to toggle its actions (repair/replace/remove).
# When a turret is destroyed the underlying slot remains.
#
# Tap detection: a press followed by a release without dragging counts as a
# tap. Dragging (to pan the camera) cancels the pending tap so panning never
# accidentally builds or selects a turret. The tap marks the input handled so
# the map does not also treat it as an "empty ground" tap.


var turret: Turret  # turret assigned to this slot

var _tap_pending := false
var _tap_pos := Vector2.ZERO
const TAP_THRESHOLD := 16.0

@onready var projectile_container := $ProjectileContainer as Node
@onready var turret_popup := $UI/TurretPopup as CanvasLayer
@onready var turret_actions := $UI/TurretActions as VBoxContainer


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_tap_pending = true
			_tap_pos = event.position
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _tap_pending:
				_tap_pending = false
				_handle_tap()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _tap_pending:
		if _tap_pos.distance_to(event.position) > TAP_THRESHOLD:
			_tap_pending = false


func _handle_tap() -> void:
	if is_instance_valid(turret):
		turret_actions.visible = not turret_actions.visible
	else:
		turret_popup.show()


func _on_turret_replace_requested() -> void:
	turret_actions.hide()
	turret.remove()
	turret_popup.show()


func _on_turret_repair_requested() -> void:
	if turret.repair():
		turret_actions.hide()
	else:
		var repair_btn := get_node("TurretActions/Repair") as Button
		if is_instance_valid(repair_btn):
			var tween := create_tween().set_trans(Tween.TRANS_BACK).\
					set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(repair_btn, "modulate", Color("fff"), 0.25).\
					from(Color("ff383f"))


func _on_turret_remove_requested() -> void:
	turret_actions.hide()
	turret.remove()


func _on_turret_popup_turret_requested(type: String) -> void:
	# load turret into scene and disable input
	turret = load(Scenes.get_turret_path(type)).instantiate()
	add_child(turret, true)
	turret.shooter.projectile_instanced.connect(_on_turret_projectile_instanced)
	# connect turret signal to restore input detection on turret disabled
	turret.turret_disabled.connect(_on_turret_disabled)


func _on_turret_projectile_instanced(projectile: Projectile) -> void:
	projectile_container.add_child(projectile, true)


func _on_turret_disabled() -> void:
	turret_actions.hide()
	turret = null  # necessary because turret is still on exploding animation


func _on_turret_popup_visibility_changed() -> void:
	if turret_popup.visible:
		turret_actions.hide()


func _on_turret_actions_visibility_changed() -> void:
	if turret_actions.visible:
		turret_popup.hide()
		Global.turret_actions = turret_actions
	else:
		Global.turret_actions = null
