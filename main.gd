extends Control

const ADDON_CARD_SCENE = preload("res://addon_card.tscn")

@onready var grid_container = $VBoxContainer/ContentMargins/ScrollContainer/GridContainer
@onready var search_input = $VBoxContainer/Header/HBox/Controls/SearchInput
@onready var addon_count_label = $VBoxContainer/Header/HBox/Controls/AddonCountLabel
@onready var refresh_button = $VBoxContainer/Header/HBox/Controls/RefreshButton

# Cache list of addon details: { name, version, author, description, demos, card_instance }
var addons_list: Array = []

func _ready():
	# Style styling setup or connect signals
	search_input.text_changed.connect(_on_search_changed)
	refresh_button.pressed.connect(scan_addons)
	scan_addons()

func scan_addons():
	# Clear existing cards
	for child in grid_container.get_children():
		child.queue_free()
	addons_list.clear()
	
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
					parse_addon(folder_name, config_path, addon_dir_path)
					
			folder_name = dir.get_next()
			
	# Update UI count
	addon_count_label.text = str(addons_list.size()) + " Addon(s) Detected"
	
	# Render cards
	render_addon_cards()

func parse_addon(folder_name: String, config_path: String, addon_dir_path: String):
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
	
	addons_list.append({
		"folder": folder_name,
		"name": addon_name,
		"version": addon_version,
		"author": addon_author,
		"description": addon_desc,
		"demos": demos,
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
	for item in addons_list:
		var card = ADDON_CARD_SCENE.instantiate()
		grid_container.add_child(card)
		card.set_addon_details(
			item["name"], 
			item["version"], 
			item["author"], 
			item["description"], 
			item["demos"]
		)
		item["card"] = card

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
