extends Control


@onready var menu_panel := $PanelContainer as PanelContainer
@onready var how_to_play := $HowToPlay as Panel


func _ready() -> void:
	# Upstream HowToPlay shows desktop mouse instructions; on touch devices
	# swap them for the mobile control scheme (drag pan, button zoom, pause).
	if DisplayServer.is_touchscreen_available():
		$HowToPlay/Sections/Controls/Description/MouseImg.hide()
		$HowToPlay/Sections/Controls/Description/Labels/Select.text = "Tap: select / build"
		$HowToPlay/Sections/Controls/Description/Labels/MoveCamera.text = "Drag: move camera"
		$HowToPlay/Sections/Controls/Description/Labels/Zoom.text = "+ / - buttons: zoom"
		$HowToPlay/Sections/Controls/Description/Labels/Esc.text = "II or back: pause"


func _on_start_pressed() -> void:
	Scenes.change_scene(Scenes.MAP_TEMPLATE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_how_to_play_pressed() -> void:
	how_to_play.show()
	menu_panel.hide()


func _on_back_pressed() -> void:
	how_to_play.hide()
	menu_panel.show()
