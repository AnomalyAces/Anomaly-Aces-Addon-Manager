@abstract
class_name RemoteRepoManager extends Object

##Settings root
const SETTINGS_ROOT: String = "aceAddonManager"
## Check for updates. If true this plugin will check for updates and notify the user when they are available
const CHECK_FOR_UPDATES: String = "settings/check_for_updates"

## Addons json file
const ADDON_FILE: String = "addons.json"

## Addons directory. should be res://addons
const ADDON_DIR: String = "res://addons"

var  SETTINGS_CONFIGURATION : Dictionary[String, AceSettingConfig] = {
	CHECK_FOR_UPDATES: AceSettingConfig.new(CHECK_FOR_UPDATES, TYPE_BOOL, true, PROPERTY_USAGE_CHECKABLE)
}

var settings: AceSettings

var http: HTTPRequest


func _init(req:HTTPRequest) -> void:
	http = req
	settings = AceSettings.new()
	settings.initialize_settings(SETTINGS_CONFIGURATION, SETTINGS_ROOT)
	settings.prepare()

func _parseAddonFiles() -> Array[RemoteRepoObject]:
	AceLog.printLog(["Parsing Addon Files...."])
	var rroList: Array[RemoteRepoObject] = []

	if settings.get_setting(CHECK_FOR_UPDATES, false):
		rroList = _getAddonFiles()
	else:
		AceLog.printLog(["Ace Addon Manager Setting: %s is not enabled in the project settings. Parsing addon files skipped" % CHECK_FOR_UPDATES], AceLog.LOG_LEVEL.WARN)


	return rroList


func _getAddonFiles() -> Array[RemoteRepoObject]:
	var addon_paths = []
	var rroList: Array[RemoteRepoObject] = []
	
	# Get a list of subdirectories within the 'addons' folder
	var dir_access = DirAccess.open(ADDON_DIR)
	if dir_access:
		dir_access.list_dir_begin()
		var dir_name = dir_access.get_next()
		while dir_name != "":
			if dir_access.current_is_dir():
				addon_paths.append(ADDON_DIR + "/" + dir_name)
			dir_name = dir_access.get_next()
		dir_access.list_dir_end()
	
	# Iterate through each addon's root directory and check for the file
	for path in addon_paths:
		var file_path = path + "/" + ADDON_FILE
		if FileAccess.file_exists(file_path):
			AceLog.printLog(["Found file '" + ADDON_FILE + "' at: " + file_path])
			var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
			var content: String = file.get_as_text()
			file.close()
			var addonResp:AceDeserializeResult = AceSerialize.deserialize(content, RemoteRepoObject)

			if addonResp.error == Error.OK:
				AceLog.printLog(["Successfully deserialized addon file", addonResp.data])
				var rro_sub_arr: Array[RemoteRepoObject] = []
				rro_sub_arr.assign(addonResp.data)
				rroList.append_array(rro_sub_arr)
			else:
				AceLog.printLog(["Error deserializing addon file at %s. Error Code: %s" % [file_path, addonResp.error]], AceLog.LOG_LEVEL.ERROR)

	return rroList





@abstract func getAddonsFromRemoteRepo()
