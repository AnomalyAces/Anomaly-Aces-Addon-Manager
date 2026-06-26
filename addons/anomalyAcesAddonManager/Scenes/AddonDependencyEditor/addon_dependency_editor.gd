@tool
extends Control

const DEPENDENCY_ENTRY_SCENE = preload("res://addons/anomalyAcesAddonManager/Scenes/AddonDependencyEditor/DependencyEntry/dependency_entry.tscn")

@onready var back_button: Button = $VBoxContainer/Header/HBox/BackButton
@onready var subtitle_label: Label = $VBoxContainer/Header/HBox/TitleSection/Subtitle
@onready var file_status_label: Label = $VBoxContainer/Header/HBox/Controls/FileStatusLabel
@onready var save_button: Button = $VBoxContainer/Header/HBox/Controls/SaveButton
@onready var run_script_button: Button = $VBoxContainer/Header/HBox/Controls/RunScriptButton
@onready var dep_list_vbox: VBoxContainer = $VBoxContainer/DependencyListScroll/DependencyListVBox/ContentMargin/InnerVBox
@onready var add_entry_button: Button = $VBoxContainer/AddEntryButton
@onready var output_dialog: AcceptDialog = $OutputDialog

var plugin_ref = null
var folder_name: String = ""
var addon_path: String = ""
var addons_json_path: String = ""

func initialize_view(p_ref, extra_data) -> void:
	plugin_ref = p_ref
	if extra_data is Dictionary:
		folder_name = extra_data.get("folder_name", "")
		addon_path = extra_data.get("addon_path", "")
		addons_json_path = addon_path + "/addons.json"

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	run_script_button.pressed.connect(_on_run_script_pressed)
	add_entry_button.pressed.connect(_on_add_entry_pressed)
	
	if Engine.is_editor_hint() and plugin_ref != null:
		var scale = EditorInterface.get_editor_scale()
		_apply_editor_scaling($VBoxContainer/Header, scale)
	
	# Update subtitle with addon folder name
	subtitle_label.text = "Editing: " + (folder_name if folder_name != "" else "Unknown Addon")
	
	# Load existing addons.json if present
	_load_addons_json()

func _load_addons_json() -> void:
	if FileAccess.file_exists(addons_json_path):
		var file = FileAccess.open(addons_json_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_text)
			if parsed is Array:
				file_status_label.text = "✓ Loaded addons.json"
				file_status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3, 1))
				for entry_data in parsed:
					_add_entry_from_data(entry_data)
				return
	
	# No file found — show blank form status
	file_status_label.text = "⚠ No addons.json found"
	file_status_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2, 1))

func _add_entry_from_data(data: Dictionary) -> void:
	var entry = DEPENDENCY_ENTRY_SCENE.instantiate()
	dep_list_vbox.add_child(entry)
	entry.set_data(data)
	entry.remove_requested.connect(func(): entry.queue_free())

func _on_add_entry_pressed() -> void:
	var entry = DEPENDENCY_ENTRY_SCENE.instantiate()
	dep_list_vbox.add_child(entry)
	entry.remove_requested.connect(func(): entry.queue_free())

func _build_json_array() -> Array:
	var result: Array = []
	for child in dep_list_vbox.get_children():
		if child.has_method("get_data"):
			result.append(child.get_data())
	return result

func _on_save_pressed() -> void:
	var data = _build_json_array()
	var json_text = JSON.stringify(data, "\t")
	
	# Ensure the directory exists (it should, since the addon is installed)
	var dir_path = ProjectSettings.globalize_path(addon_path)
	if not DirAccess.dir_exists_absolute(addon_path):
		DirAccess.make_dir_recursive_absolute(addon_path)
	
	var file = FileAccess.open(addons_json_path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		file_status_label.text = "✓ Saved addons.json"
		file_status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3, 1))
	else:
		file_status_label.text = "✗ Save failed!"
		file_status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))

func _on_run_script_pressed() -> void:
	# Save first so the script picks up latest changes
	_on_save_pressed()
	
	var project_root = ProjectSettings.globalize_path("res://")
	var script_path = project_root + "addons/anomalyAcesAddonManager/manage_addons"
	var output: Array = []
	
	# Try to run via bash (Git Bash / WSL on Windows, native bash on Linux/Mac)
	var exit_code = OS.execute("bash", [script_path, "update"], output, true)
	
	var output_text = "\n".join(output)
	
	if exit_code == 0:
		_show_output_dialog("✓ manage_addons update completed successfully", output_text, true)
	else:
		# Fallback: bash not found or script error — show copyable command
		var fallback_msg = "Could not run script automatically (exit code %d).\n\nRun this command manually from the project root:\n" % exit_code
		var cmd = "bash ./addons/anomalyAcesAddonManager/manage_addons update"
		_show_output_dialog("⚠ Script execution failed — copy command below", fallback_msg + output_text, false, cmd)

func _show_output_dialog(title: String, body: String, success: bool, copy_cmd: String = "") -> void:
	output_dialog.title = title
	var output_edit: TextEdit = output_dialog.get_node_or_null("VBox/OutputText")
	var copy_btn: Button = output_dialog.get_node_or_null("VBox/CopyButton")
	
	if output_edit:
		output_edit.text = body
	
	if copy_btn:
		copy_btn.visible = copy_cmd != ""
		if copy_cmd != "":
			# Disconnect any previous connections before reconnecting
			if copy_btn.pressed.is_connected(_dummy_copy):
				copy_btn.pressed.disconnect(_dummy_copy)
			copy_btn.pressed.connect(func(): DisplayServer.clipboard_set(copy_cmd))
	
	output_dialog.popup_centered(Vector2(600, 400))

func _dummy_copy() -> void:
	pass

func _on_back_pressed() -> void:
	if plugin_ref:
		plugin_ref.switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn")

func _apply_editor_scaling(node: Node, scale: float) -> void:
	if scale == 1.0:
		return
	if node is Control:
		if node == back_button or node == save_button or node == run_script_button:
			var soft_scale = 1.0 + (scale - 1.0) * 0.4
			node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if node.custom_minimum_size != Vector2.ZERO:
				node.custom_minimum_size = node.custom_minimum_size * soft_scale
		else:
			if node.custom_minimum_size != Vector2.ZERO:
				node.custom_minimum_size = node.custom_minimum_size * scale
		
		if node.has_theme_font_size_override("font_size"):
			var current_size = node.get_theme_font_size("font_size")
			node.add_theme_font_size_override("font_size", int(round(current_size * scale)))
		
		for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			if node.has_theme_constant_override(margin):
				var val = node.get_theme_constant(margin)
				node.add_theme_constant_override(margin, int(round(val * scale)))
		
		for sep in ["separation", "h_separation", "v_separation"]:
			if node.has_theme_constant_override(sep):
				var val = node.get_theme_constant(sep)
				node.add_theme_constant_override(sep, int(round(val * scale)))
	
	for child in node.get_children():
		_apply_editor_scaling(child, scale)
