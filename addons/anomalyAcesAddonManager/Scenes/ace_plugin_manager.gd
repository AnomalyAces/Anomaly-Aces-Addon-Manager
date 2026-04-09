@tool
class_name AcePluginManager extends Control

@onready var main_view: AcePluginMainView = $Main
@onready var install_addons: AcePluginInstallAddonsView = $InstallAddons


func _ready() -> void:
	if main_view != null:
		main_view.open_install_view.connect(_on_open_install_addons)

func assignEditorInterface(editorInterface: EditorInterface) -> void:
	if main_view != null:
		main_view._editor_interface = editorInterface

	if install_addons != null:
		install_addons._editor_interface = editorInterface


func _on_open_install_addons(addons: Array[RemoteRepoObject], config_file: ConfigFile) -> void:
	AceLog.printLog(["Opening Install Addons View with addons:", addons])
	install_addons.initalizeInstallView(addons, config_file)
	main_view.hide()
	install_addons.show()
