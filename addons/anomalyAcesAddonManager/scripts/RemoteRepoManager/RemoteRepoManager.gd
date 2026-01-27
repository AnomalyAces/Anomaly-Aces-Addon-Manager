@abstract
class_name RemoteRepoManager extends Object

##Settings root
const SETTINGS_ROOT: String = "aceAddonManager"

## If true this plugin will automatically download addons from remote repos when Godot starts
const AUTO_DOWNLOAD_ADDONS: String = "settings/auto_download_addons"
## Check for updates. If true this plugin will check for updates and notify the user when they are available
const CHECK_FOR_UPDATES: String = "settings/check_for_updates"
## Github Personal Access Token for increasing rate 
const GITHUB_PERSONAL_ACCESS_TOKEN: String = "settings/github_personal_access_token"

## Addons json file
const ADDON_FILE: String = "addons.json"

## Addons directory. should be res://addons
const ADDON_DIR: String = "res://addons"


#Signals
signal conflicts_found(conflicting_addons: Array[RemoteRepoConflict])

var  SETTINGS_CONFIGURATION : Dictionary[String, AceSettingConfig] = {
	AUTO_DOWNLOAD_ADDONS: AceSettingConfig.new(AUTO_DOWNLOAD_ADDONS, TYPE_BOOL, true, PROPERTY_USAGE_CHECKABLE),
	CHECK_FOR_UPDATES: AceSettingConfig.new(CHECK_FOR_UPDATES, TYPE_BOOL, true, PROPERTY_USAGE_CHECKABLE),
	GITHUB_PERSONAL_ACCESS_TOKEN: AceSettingConfig.new(GITHUB_PERSONAL_ACCESS_TOKEN, TYPE_STRING, "", PROPERTY_HINT_PASSWORD)
}

var settings: AceSettings
var parent_node: Node



func _init(parent: Node) -> void:
	parent_node = parent
	settings = AceSettings.new()
	settings.initialize_settings(SETTINGS_CONFIGURATION, SETTINGS_ROOT)
	settings.prepare()


func isAutoDownloadEnabled() -> bool:
	return settings.get_setting(AUTO_DOWNLOAD_ADDONS, false)

func isCheckForUpdatesEnabled() -> bool:
	return settings.get_setting(CHECK_FOR_UPDATES, false)

func getGithubPersonalAccessToken() -> String:
	return settings.get_setting(GITHUB_PERSONAL_ACCESS_TOKEN, "")

func _parseAddonFiles() -> Array[RemoteRepoObject]:
	AceLog.printLog(["Parsing Addon Files...."])
	var rroList: Array[RemoteRepoObject] = []
	rroList = _getAddonFiles()
	
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
				AceLog.printLog(["Successfully deserialized addon file: " , file_path])
				var rro_sub_arr: Array[RemoteRepoObject] = []
				rro_sub_arr.assign(addonResp.data)
				_assign_addon_files(rro_sub_arr, file_path)
				rroList.append_array(rro_sub_arr)
			else:
				AceLog.printLog(["Error deserializing addon file at %s. Error Code: %s" % [file_path, addonResp.error]], AceLog.LOG_LEVEL.ERROR)

	return rroList



func _assign_addon_files(addons: Array[RemoteRepoObject], addon_file: String) -> void:
	for addon in addons:
		addon.metadata.addon_file = addon_file
		for dependency in addon.dependencies:
			dependency.metadata.addon_file = addon_file

func _checkForConflicts(addons: Array[RemoteRepoObject]) -> Array[RemoteRepoConflict]:
	var unique_addons: Dictionary[String, RemoteRepoObject] = {}
	var conflicts: Array[RemoteRepoConflict] = []
	
	for addon in addons:
		#Check addon itself
		if unique_addons.has(addon.repo):
			var addon_conflict: RemoteRepoConflict = RemoteRepoConflict.new()
			addon_conflict.initializeConflict(addon, unique_addons[addon.repo])
			if addon_conflict.isConflicting():
				AceLog.printLog(["Conflict detected for addon repo: %s" % addon.repo], AceLog.LOG_LEVEL.WARN)
				conflicts.append(addon_conflict)
		else:
			unique_addons[addon.repo] = addon
		
		#check dependencies
		if addon.dependencies.size() > 0:
			for dependency in addon.dependencies:
				if unique_addons.has(dependency.repo):
					var dependency_conflict: RemoteRepoConflict = RemoteRepoConflict.new()
					dependency_conflict.initializeConflict(dependency, unique_addons[dependency.repo], addon)
					if dependency_conflict.isConflicting():
						AceLog.printLog(["Conflict detected for addon dependency: %s required by addon: %s" % [dependency, addon.repo]], AceLog.LOG_LEVEL.WARN)
						conflicts.append(dependency_conflict)
				else:
					unique_addons[dependency.repo] = dependency
	

	return conflicts


@abstract func getAddonsFromRemoteRepo()
