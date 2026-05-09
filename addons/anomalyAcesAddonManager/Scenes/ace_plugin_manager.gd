@tool
class_name AcePluginManager extends Control

@onready var main_view: AcePluginMainView = $Main
@onready var install_addons: AcePluginInstallAddonsView = $InstallAddons


func _ready() -> void:
	if main_view != null:
		main_view.open_install_view.connect(_on_open_install_addons)

	if install_addons != null:
		install_addons.back_to_main_view.connect(_on_close_install_addons)
		install_addons.install_completed.connect(_on_install_completed)

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

func _on_close_install_addons() -> void:
	install_addons.hide()
	main_view.show()

func _on_install_completed(addons: Array, config_file: ConfigFile) -> void:
	AceLog.printLog(["Addons Installed:", addons])
	install_addons.hide()
	main_view.show()
	main_view.getAddons()
