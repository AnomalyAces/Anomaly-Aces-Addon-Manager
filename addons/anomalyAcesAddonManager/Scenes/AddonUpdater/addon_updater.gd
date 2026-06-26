@tool
extends Control

const ACE_PLUGIN_MANAGER_SCENE = "res://addons/anomalyAcesAddonManager/Scenes/AddonUpdater/AcePluginManager.tscn"

@onready var back_button = $VBoxContainer/Header/HBox/BackButton
@onready var refresh_button = $VBoxContainer/Header/HBox/Controls/RefreshButton
@onready var manager_container = $VBoxContainer/ManagerContainer

var plugin_ref = null
var plugin_manager = null

func initialize_view(p_ref, _extra_data) -> void:
	plugin_ref = p_ref

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	
	if Engine.is_editor_hint() and plugin_ref != null:
		# Apply scaling to the header region only
		var scale = EditorInterface.get_editor_scale()
		_apply_editor_scaling($VBoxContainer/Header, scale)
		
		# Instantiate the migrated AcePluginManager at runtime
		var scene_res = load(ACE_PLUGIN_MANAGER_SCENE)
		if scene_res:
			plugin_manager = scene_res.instantiate()
			plugin_manager.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			plugin_manager.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			# Pass editor interface before adding to tree
			if plugin_manager.has_method("assignEditorInterface"):
				plugin_manager.assignEditorInterface(EditorInterface)
			
			manager_container.add_child(plugin_manager)
			
			# Trigger the initial addon load
			_on_refresh_pressed()

# Recursive editor scaling — same pattern as main.gd and addon_card.gd
func _apply_editor_scaling(node: Node, scale: float) -> void:
	if scale == 1.0:
		return
	if node is Control:
		if node == back_button or node == refresh_button:
			# Softer scale for compact header buttons
			var soft_scale = 1.0 + (scale - 1.0) * 0.4
			node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if node.custom_minimum_size != Vector2.ZERO:
				node.custom_minimum_size = node.custom_minimum_size * soft_scale
		else:
			if node.custom_minimum_size != Vector2.ZERO:
				node.custom_minimum_size = node.custom_minimum_size * scale
		
		# Scale explicit font size overrides directly from properties to bypass scene tree lookup gotchas
		var font_keys = ["font_size", "normal_font_size", "bold_font_size", "bold_italics_font_size", "italics_font_size", "mono_font_size"]
		for key in font_keys:
			var override_font_size = node.get("theme_override_font_sizes/" + key)
			if override_font_size != null and override_font_size is int and override_font_size > 0:
				node.add_theme_font_size_override(key, int(round(override_font_size * scale)))
		
		# Scale margin overrides
		for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			var override_val = node.get("theme_override_constants/" + margin)
			if override_val != null and override_val is int:
				node.add_theme_constant_override(margin, int(round(override_val * scale)))
		
		# Scale separation overrides
		for sep in ["separation", "h_separation", "v_separation"]:
			var override_val = node.get("theme_override_constants/" + sep)
			if override_val != null and override_val is int:
				node.add_theme_constant_override(sep, int(round(override_val * scale)))
	
	for child in node.get_children():
		_apply_editor_scaling(child, scale)

func _on_back_pressed() -> void:
	if plugin_ref:
		plugin_ref.switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn")

func _on_refresh_pressed() -> void:
	if plugin_manager and plugin_manager.has_method("getAddons"):
		plugin_manager.getAddons()
	elif plugin_manager and "main_view" in plugin_manager and plugin_manager.main_view != null:
		plugin_manager.main_view.getAddons()
