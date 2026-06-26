@tool
class_name AcePluginManager extends Control

@onready var main_view: AcePluginMainView = $Main
@onready var install_addons: AcePluginInstallAddonsView = $InstallAddons
@onready var github_pat: AcePluginGithubPATView = $GithubPat


func _ready() -> void:
	if main_view != null:
		main_view.open_install_view.connect(_on_open_install_addons)
		main_view.open_github_pat_view.connect(_on_open_github_pat)

	if install_addons != null:
		install_addons.back_to_main_view.connect(_on_close_install_addons)
		install_addons.install_completed.connect(_on_install_completed)
	
	if github_pat != null:
		github_pat.back_to_main_view.connect(_on_close_github_pat)

func assignEditorInterface(editorInterface: EditorInterface) -> void:
	var scale = editorInterface.get_editor_scale()
	if main_view != null:
		main_view._editor_interface = editorInterface
		main_view.initialize_scaling(scale)

	if install_addons != null:
		install_addons._editor_interface = editorInterface
		install_addons.initialize_scaling(scale)

	if github_pat != null:
		github_pat._editor_interface = editorInterface
		github_pat.initialize_scaling(scale)


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
	main_view.updateAddons()

func _on_open_github_pat() -> void:
	github_pat.initialize()
	main_view.hide()
	github_pat.show()

func _on_close_github_pat() -> void:
	main_view.show()
	github_pat.hide()
