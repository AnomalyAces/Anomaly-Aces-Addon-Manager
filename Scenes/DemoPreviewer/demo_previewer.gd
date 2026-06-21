extends Control

@onready var back_button: Button = $VBoxContainer/Header/HBox/BackButton
@onready var path_label: Label = $VBoxContainer/Header/HBox/PathLabel
@onready var sub_viewport: SubViewport = $VBoxContainer/ViewportContainer/SubViewport

func _ready() -> void:
	# Connect the back button pressed signal
	back_button.pressed.connect(_on_back_pressed)
	
	# Retrieve target demo path from autoload state
	var target_scene = AddonPreviewerOverlay.target_demo_scene
	if target_scene == "":
		push_error("No target demo scene specified. Returning to main menu.")
		get_tree().change_scene_to_file("res://Scenes/Main/main.tscn")
		return
		
	path_label.text = "Previewing: " + target_scene
	
	# Load and instantiate the scene inside the SubViewport
	var scene_res = load(target_scene)
	if scene_res:
		var scene_instance = scene_res.instantiate()
		sub_viewport.add_child(scene_instance)
		
		# If the instance is a Control, ensure it fills the SubViewport if anchors are set
		if scene_instance is Control:
			scene_instance.anchors_preset = Control.PRESET_FULL_RECT
	else:
		push_error("Failed to load demo scene: " + target_scene)
		path_label.text = "Error: Failed to load " + target_scene
		path_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))

func _on_back_pressed() -> void:
	# Clear the target demo scene path
	AddonPreviewerOverlay.target_demo_scene = ""
	# Go back to main scene
	get_tree().change_scene_to_file("res://Scenes/Main/main.tscn")
