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
		# Add manual scaling control UI to header controls
		var controls = $VBoxContainer/Header/HBox/Controls
		AddonManagerUtil.add_scale_ui_to_header(controls, self)
		
		# Instantiate the migrated AcePluginManager at runtime
		var scene_res = load(ACE_PLUGIN_MANAGER_SCENE)
		if scene_res:
			plugin_manager = scene_res.instantiate()
			plugin_manager.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			plugin_manager.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			manager_container.add_child(plugin_manager)
			
			# Pass editor interface and apply scale after adding to tree (so @onready child nodes are initialized)
			if plugin_manager.has_method("assignEditorInterface"):
				plugin_manager.assignEditorInterface(EditorInterface)
			
			# Trigger the initial addon load
			_on_refresh_pressed()



func _on_back_pressed() -> void:
	if plugin_ref:
		plugin_ref.switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn")

func _on_refresh_pressed() -> void:
	if plugin_manager and plugin_manager.has_method("getAddons"):
		plugin_manager.getAddons()
	elif plugin_manager and "main_view" in plugin_manager and plugin_manager.main_view != null:
		plugin_manager.main_view.getAddons()
