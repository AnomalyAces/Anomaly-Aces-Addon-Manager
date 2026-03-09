@tool
class_name AcePluginManager extends Control

@onready var main_view: AcePluginMainView = $Main


func assignEditorInterface(editorInterface: EditorInterface) -> void:
	main_view._editor_interface = editorInterface


