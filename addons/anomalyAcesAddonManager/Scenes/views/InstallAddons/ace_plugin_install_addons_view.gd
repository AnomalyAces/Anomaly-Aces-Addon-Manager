@tool
class_name AcePluginInstallAddonsView extends Control

@onready var installTablePlugin: AceTablePlugin = %InstallTablePlugin
@onready var loadingView: LoadingView = %LoadingView

##Signals
signal install_completed(addons: Array, config_file: String)

var rrm: GitHubManager

var _editor_interface: EditorInterface
var _addon_install_table: _AceTable
var _addon_config: ConfigFile

func _ready() -> void:
	rrm = GitHubManager.new(self, _editor_interface)

	rrm.addons_installed.connect(_on_addons_installed)


func initalizeInstallView(addons: Array[RemoteRepoObject], config_file: ConfigFile) -> void:
	AceLog.printLog(["Opening Install View with addons: ", addons])
	_addon_config = config_file

	_createAddonInstallTable(addons, _addon_config)



func _on_addons_installed(addons: Array[RemoteRepoObject]) -> void:
	AceLog.printLog(["Addons Installation Completed: %s" % addons])
	install_completed.emit(	addons, _addon_config)
	


func _createAddonInstallTable(addons: Array[RemoteRepoObject], configFile: ConfigFile) -> void:

	var addonColDef: AceTableColumnDef = AceTableColumnDef.new()
	addonColDef.columnId = "repo"
	addonColDef.columnName = "Add-on"
	addonColDef.columnType = AceTableConstants.ColumnType.LABEL
	addonColDef.columnSort = true
	addonColDef.columnAlign = AceTableConstants.Align.CENTER
	addonColDef.columnImageSize = Vector2i(64,64)
	addonColDef.columnImage = "res://addons/anomalyAcesAddonManager/Icons/Package.svg"
	addonColDef.columnTextType = AceTableConstants.TextType.COMBO

	var installedVersionColDef: AceTableColumnDef = AceTableColumnDef.new()
	installedVersionColDef.columnId = "installed_version"
	installedVersionColDef.columnName = "Installed Version"
	installedVersionColDef.columnType = AceTableConstants.ColumnType.LABEL
	installedVersionColDef.columnSort = true
	installedVersionColDef.columnAlign = AceTableConstants.Align.CENTER
	installedVersionColDef.columnTextType = AceTableConstants.TextType.TEXT

	var latestVersionColDef: AceTableColumnDef = AceTableColumnDef.new()
	latestVersionColDef.columnId = "latest_version"
	latestVersionColDef.columnName = "Latest Version"
	latestVersionColDef.columnType = AceTableConstants.ColumnType.LABEL
	latestVersionColDef.columnSort = true
	latestVersionColDef.columnAlign = AceTableConstants.Align.CENTER
	latestVersionColDef.columnTextType = AceTableConstants.TextType.TEXT

	var tableData: Array[Dictionary] = _normalize_table_data(_createInstallAddonsTableData(addons, configFile))

	var colDefs: Array[AceTableColumnDef] = [addonColDef, installedVersionColDef, latestVersionColDef]

	AceLog.printLog(["Loading Add-on Table data via AceTableManager"])
	installTablePlugin.printConfig()
	_addon_install_table = AceTableManager.createTable(installTablePlugin, colDefs, tableData)
	# _addon_install_table.row_selected.connect(_on_addon_table_selection)
	AceLog.printLog(["Done Loading Add-on Table data via AceTableManager"])

	pass


func _createInstallAddonsTableData(addons: Array[RemoteRepoObject], configFile: ConfigFile) -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for addon in addons:
		var addon_dict: Dictionary = {
			"repo": addon.repo,
			"installed_version": addon.version if addon.isRelease else addon.branch,
			"latest_version": configFile.get_value(addon.repo, "version") if addon.isRelease else configFile.get_value(addon.repo, "last_commit_date")
		}
		data.append(addon_dict)
		data.append_array(_createInstallAddonsTableData(addon.dependencies, configFile))
	return data

func _normalize_table_data(table_data: Array[Dictionary]) -> Array[Dictionary]:
	# This function can be used to normalize or preprocess the data before feeding it to the table
	# For example, you could flatten nested data structures, format certain fields, etc.
	var normalized_data: Array[Dictionary] = []
	var normalized_dict: Dictionary = {}
	for dict in table_data:
		var dict_key = "|".join([dict["repo"], dict["installed_version"], dict["latest_version"]])
		if not normalized_dict.has(dict_key):
			normalized_dict[dict_key] = dict
	

	normalized_data.assign(normalized_dict.values())

	return normalized_data
