@tool
extends PanelContainer

signal plugin_toggled(plugin_path: String, enabled: bool)
signal run_demo_requested(demo_path: String)

@onready var title_label = $VBox/Header/Title
@onready var version_label = $VBox/Header/Version
@onready var author_label = $VBox/Author
@onready var desc_label = $VBox/Description
@onready var demos_list = $VBox/DemosSection/DemosList
@onready var no_demos_label = $VBox/DemosSection/NoDemosLabel
@onready var status_toggle = $VBox/StatusContainer/StatusToggle

var plugin_path: String = ""

func _apply_editor_scaling(node: Node, scale: float):
	if scale == 1.0:
		return
	if node is Control:
		if node.custom_minimum_size != Vector2.ZERO:
			node.custom_minimum_size = node.custom_minimum_size * scale
		
		# Scale font size overrides or defaults
		var font_size_key = "font_size"
		if node.has_theme_font_size_override(font_size_key):
			var current_size = node.get_theme_font_size(font_size_key)
			node.add_theme_font_size_override(font_size_key, int(round(current_size * scale)))
		elif node is Label or node is Button or node is LineEdit or node is CheckButton:
			var current_size = node.get_theme_font_size(font_size_key)
			node.add_theme_font_size_override(font_size_key, int(round(current_size * scale)))
			
		# Scale margin theme overrides
		for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			if node.has_theme_constant_override(margin):
				var val = node.get_theme_constant(margin)
				node.add_theme_constant_override(margin, int(round(val * scale)))
				
		# Scale separation theme overrides
		if node.has_theme_constant_override("separation"):
			var val = node.get_theme_constant("separation")
			node.add_theme_constant_override("separation", int(round(val * scale)))
			
	for child in node.get_children():
		_apply_editor_scaling(child, scale)

func set_addon_details(addon_name: String, version: String, author: String, description: String, demos: Array, is_enabled: bool, p_path: String, scale: float = 1.0):
	title_label.text = addon_name
	
	if version.begins_with("v") or version.begins_with("V"):
		version_label.text = version
	else:
		version_label.text = "v" + version
		
	author_label.text = "by " + author if author != "" else "Author: Unknown"
	desc_label.text = description if description != "" else "No description provided."
	
	# Configure status toggle
	plugin_path = p_path
	status_toggle.set_pressed_no_signal(is_enabled)
	_update_status_text(is_enabled)
	
	# Connect the signal if not already connected
	if not status_toggle.toggled.is_connected(_on_status_toggled):
		status_toggle.toggled.connect(_on_status_toggled)
	
	# Clear existing demos
	for child in demos_list.get_children():
		child.queue_free()
		
	if demos.size() > 0:
		no_demos_label.visible = false
		for demo_path in demos:
			var btn = Button.new()
			# Extract filename from path
			var filename = demo_path.get_file()
			btn.text = "▶ Run " + filename
			btn.tooltip_text = demo_path
			
			# Store demo_path in a local variable for the lambda closure
			var target_scene = demo_path
			btn.pressed.connect(func():
				run_demo_requested.emit(target_scene)
			)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			demos_list.add_child(btn)
	else:
		no_demos_label.visible = true
		
	if scale != 1.0:
		_apply_editor_scaling(self, scale)

func _update_status_text(enabled: bool):
	var color = Color(0.3, 0.8, 0.3) if enabled else Color(0.6, 0.6, 0.6)
	status_toggle.text = "Enabled" if enabled else "Disabled"
	status_toggle.add_theme_color_override("font_color", color)
	status_toggle.add_theme_color_override("font_pressed_color", color)
	status_toggle.add_theme_color_override("font_hover_color", color)
	status_toggle.add_theme_color_override("font_hover_pressed_color", color)
	status_toggle.add_theme_color_override("font_focus_color", color)

func _on_status_toggled(button_pressed: bool):
	_update_status_text(button_pressed)
	plugin_toggled.emit(plugin_path, button_pressed)

