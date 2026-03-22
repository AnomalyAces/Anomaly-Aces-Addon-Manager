@tool
class_name AcePluginInstallAddonsView extends Control

@onready var _addonContainer: VBoxContainer = %Addons


func initalizeInstallView(addons: Array[RemoteRepoObject], config_file: String) -> void:
	AceLog.printLog(["Opening Install View with addons: %s and config: %s" % [addons, config_file]])
	var adddonConfig: ConfigFile = AceFileUtil.Config.load_config(config_file)