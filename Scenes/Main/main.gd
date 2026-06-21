@tool
extends Control

const ADDON_CARD_SCENE = preload("res://Scenes/AddonCard/addon_card.tscn")

@onready var grid_container = $VBoxContainer/ContentMargins/ScrollContainer/GridContainer
@onready var search_input = $VBoxContainer/Header/HBox/Controls/SearchInput
@onready var addon_count_label = $VBoxContainer/Header/HBox/Controls/AddonCountLabel
@onready var refresh_button = $VBoxContainer/Header/HBox/Controls/RefreshButton
@onready var scroll_container = $VBoxContainer/ContentMargins/ScrollContainer

# Cache list of addon details: { name, version, author, description, demos, card_instance }
var addons_list: Array = []
var plugin_ref = null

func initialize_view(p_ref, extra_data):
	plugin_ref = p_ref

func _ready():
	if Engine.is_editor_hint() and plugin_ref != null:
		var scale = EditorInterface.get_editor_scale()
		_apply_editor_scaling(self, scale)
		
	# Style styling setup or connect signals
	search_input.text_changed.connect(_on_search_changed)
	refresh_button.pressed.connect(scan_addons)
	
	scroll_container.resized.connect(_on_scroll_container_resized)
	_on_scroll_container_resized()
	
	scan_addons()

func _apply_editor_scaling(node: Node, scale: float):
	if node is Control:
		var size_scale = scale
		if node == search_input or node == refresh_button:
			size_scale = 1.0 + (scale - 1.0) * 0.4
			node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
		if node.custom_minimum_size != Vector2.ZERO:
			node.custom_minimum_size = node.custom_minimum_size * size_scale
		
		# Scale font size overrides or defaults
		var font_size_key = "font_size"
		if node == search_input or node == refresh_button:
			node.add_theme_font_size_override(font_size_key, int(round(15 * scale)))
		elif node.has_theme_font_size_override(font_size_key):
			var current_size = node.get_theme_font_size(font_size_key)
			node.add_theme_font_size_override(font_size_key, int(round(current_size * scale)))
		elif node is Label or node is Button or node is LineEdit:
			var current_size = node.get_theme_font_size(font_size_key)
			node.add_theme_font_size_override(font_size_key, int(round(current_size * scale)))
			
		# Scale margin theme overrides
		for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			if node.has_theme_constant_override(margin):
				var val = node.get_theme_constant(margin)
				node.add_theme_constant_override(margin, int(round(val * scale)))
				
		# Scale separation theme overrides
		for sep in ["separation", "h_separation", "v_separation"]:
			if node.has_theme_constant_override(sep):
				var val = node.get_theme_constant(sep)
				node.add_theme_constant_override(sep, int(round(val * scale)))
			
	for child in node.get_children():
		_apply_editor_scaling(child, scale)

func _on_scroll_container_resized():
	var scale = EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	var card_min_width = 350.0 * scale
	var h_sep = 20.0 * scale
	var available_width = scroll_container.size.x
	
	# Account for vertical scrollbar
	available_width -= 20.0 * scale
	
	if available_width > 0:
		var cols = int((available_width + h_sep) / (card_min_width + h_sep))
		grid_container.columns = max(1, cols)

func scan_addons():
	# Clear existing cards
	for child in grid_container.get_children():
		child.queue_free()
	addons_list.clear()
	
	var enabled_plugins = get_enabled_plugins()
	
	var addons_path = "res://addons"
	if not DirAccess.dir_exists_absolute(addons_path):
		DirAccess.make_dir_absolute(addons_path)
	
	var dir = DirAccess.open(addons_path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				var addon_dir_path = addons_path + "/" + folder_name
				var config_path = addon_dir_path + "/plugin.cfg"
				
				if FileAccess.file_exists(config_path):
					parse_addon(folder_name, config_path, addon_dir_path, enabled_plugins)
					
			folder_name = dir.get_next()
			
	# Update UI count
	addon_count_label.text = str(addons_list.size()) + " Addon(s) Detected"
	
	# Render cards
	render_addon_cards()

func parse_addon(folder_name: String, config_path: String, addon_dir_path: String, enabled_plugins: PackedStringArray):
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	var addon_name = folder_name
	var addon_version = "0.0.0"
	var addon_author = "Unknown"
	var addon_desc = ""
	
	if err == OK:
		addon_name = config.get_value("plugin", "name", folder_name)
		addon_version = config.get_value("plugin", "version", "0.0.0")
		addon_author = config.get_value("plugin", "author", "Unknown")
		addon_desc = config.get_value("plugin", "description", "")
		
	# Search recursively for demo scenes
	var demos = find_demo_scenes(addon_dir_path)
	
	var plugin_path = "res://addons/" + folder_name + "/plugin.cfg"
	var is_enabled = plugin_path in enabled_plugins
	
	addons_list.append({
		"folder": folder_name,
		"name": addon_name,
		"version": addon_version,
		"author": addon_author,
		"description": addon_desc,
		"demos": demos,
		"is_enabled": is_enabled,
		"plugin_path": plugin_path,
		"card": null
	})

func find_demo_scenes(path: String) -> Array:
	var list = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					list.append_array(find_demo_scenes(path + "/" + file_name))
			else:
				var lower_name = file_name.to_lower()
				if file_name.ends_with(".tscn") and (
					lower_name.contains("demo") or 
					lower_name.contains("example") or 
					lower_name.contains("test") or 
					lower_name.contains("preview")
				):
					list.append(path + "/" + file_name)
			file_name = dir.get_next()
	return list

func render_addon_cards():
	var scale = EditorInterface.get_editor_scale() if (Engine.is_editor_hint() and plugin_ref != null) else 1.0
	for item in addons_list:
		var card = ADDON_CARD_SCENE.instantiate()
		grid_container.add_child(card)
		card.set_addon_details(
			item["name"], 
			item["version"], 
			item["author"], 
			item["description"], 
			item["demos"],
			item["is_enabled"],
			item["plugin_path"],
			scale
		)
		card.plugin_toggled.connect(_on_plugin_toggled)
		card.run_demo_requested.connect(_on_run_demo_requested)
		item["card"] = card

func _on_run_demo_requested(demo_path: String):
	if Engine.is_editor_hint() and plugin_ref != null:
		plugin_ref.switch_to_view("res://Scenes/DemoPreviewer/demo_previewer.tscn", demo_path)
	else:
		AddonPreviewerOverlay.target_demo_scene = demo_path
		get_tree().change_scene_to_file("res://Scenes/DemoPreviewer/demo_previewer.tscn")

func get_enabled_plugins() -> PackedStringArray:
	if Engine.is_editor_hint():
		var enabled_list = PackedStringArray()
		var addons_path = "res://addons"
		var dir = DirAccess.open(addons_path)
		if dir:
			dir.list_dir_begin()
			var folder_name = dir.get_next()
			while folder_name != "":
				if dir.current_is_dir() and not folder_name.begins_with("."):
					if EditorInterface.is_plugin_enabled(folder_name):
						enabled_list.append("res://addons/" + folder_name + "/plugin.cfg")
				folder_name = dir.get_next()
		return enabled_list
	else:
		if not FileAccess.file_exists("res://project.godot"):
			return PackedStringArray()
		var config = ConfigFile.new()
		var err = config.load("res://project.godot")
		if err == OK:
			return config.get_value("editor_plugins", "enabled", PackedStringArray())
		return PackedStringArray()

func _on_plugin_toggled(plugin_path: String, enabled: bool):
	var folder_name = plugin_path.get_slice("/", 3)
	
	if Engine.is_editor_hint():
		EditorInterface.set_plugin_enabled(folder_name, enabled)
		print("Toggled plugin via EditorInterface: ", folder_name, " -> ", enabled)
	else:
		var config = ConfigFile.new()
		var err = config.load("res://project.godot")
		if err == OK:
			var plugins = config.get_value("editor_plugins", "enabled", PackedStringArray())
			var plugin_list = Array(plugins)
			var has_plugin = plugin_path in plugin_list
			
			if enabled and not has_plugin:
				plugin_list.append(plugin_path)
			elif not enabled and has_plugin:
				plugin_list.erase(plugin_path)
				
			var new_plugins = PackedStringArray(plugin_list)
			config.set_value("editor_plugins", "enabled", new_plugins)
			config.save("res://project.godot")
			
			# Also update ProjectSettings memory so Godot runtime is aware and save settings
			ProjectSettings.set_setting("editor_plugins/enabled", new_plugins)
			ProjectSettings.save()

func _on_search_changed(new_text: String):
	var filter = new_text.strip_edges().to_lower()
	for item in addons_list:
		var card = item["card"]
		if card:
			if filter == "":
				card.visible = true
			else:
				var match_found = (
					item["name"].to_lower().contains(filter) or
					item["description"].to_lower().contains(filter) or
					item["author"].to_lower().contains(filter) or
					item["folder"].to_lower().contains(filter)
				)
				card.visible = match_found
