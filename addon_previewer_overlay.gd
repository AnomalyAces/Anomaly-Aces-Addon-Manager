extends Node

var overlay: CanvasLayer
var button: Button

func _ready():
	# Make sure this runs always, even when the scene tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create overlay UI
	overlay = CanvasLayer.new()
	overlay.layer = 100 # Keep on top of other elements
	add_child(overlay)
	
	# Create a nice semi-transparent glassmorphic back button container
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 16)
	
	# Custom flat panel style for overlay
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.25, 0.3, 0.8)
	
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	
	button = Button.new()
	button.text = "← Back to Dashboard"
	button.pressed.connect(_on_button_pressed)
	
	# Set flat styling on the button inside the panel
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.25, 0.6, 1.0)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.content_margin_left = 12
	btn_style.content_margin_top = 6
	btn_style.content_margin_right = 12
	btn_style.content_margin_bottom = 6
	
	button.add_theme_stylebox_override("normal", btn_style)
	panel.add_child(button)

func _process(_delta):
	var curr_scene = get_tree().current_scene
	if curr_scene:
		var is_main = curr_scene.scene_file_path == "res://main.tscn" or curr_scene.name == "Main"
		overlay.visible = not is_main

func _on_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
