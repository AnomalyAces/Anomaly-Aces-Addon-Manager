@tool
class_name AcePluginManager extends Control

@onready var main_view: AcePluginMainView = $Main
@onready var install_addons: AcePluginInstallAddonsView = $InstallAddons

func assignEditorInterface(editorInterface: EditorInterface) -> void:
	if main_view != null:
		main_view._editor_interface = editorInterface

	if install_addons != null:
		install_addons._editor_interface = editorInterface


