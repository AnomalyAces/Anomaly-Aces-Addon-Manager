@tool
class_name AcePluginInstallAddonsView extends Control

@onready var installTablePlugin: AceTablePlugin = %InstallTablePlugin
@onready var loadingView: LoadingView = %LoadingView
@onready var backButton: Button = %Back

##Signals
signal install_completed(addons: Array, config_file: ConfigFile)
signal back_to_main_view()

var rrm: GitHubManager

var _editor_interface: EditorInterface
var _addon_install_table: _AceTable
var _addon_config: ConfigFile

var _addons: Array[RemoteRepoObject] = []
var _editor_scale: float = 1.0

func _ready() -> void:
	if _editor_scale != 1.0:
		_scale_table_themes(installTablePlugin, _editor_scale)
	rrm = GitHubManager.new(self, _editor_interface)

	rrm.addons_installed.connect(_on_addons_installed)


func initalizeInstallView(addons: Array[RemoteRepoObject], config_file: ConfigFile) -> void:
	AceLog.printLog(["Opening Install View with addons: ", addons])
	_addons = addons
	_addon_config = config_file
	if _addon_install_table != null:
		var tableData: Array[Dictionary] = _normalize_table_data(_createInstallAddonsTableData(_addons, _addon_config))
		AceTableManager.setTableData(_addon_install_table, tableData)
	else:
		_createAddonInstallTable(_addons, _addon_config)


func _on_back_pressed() -> void:
	back_to_main_view.emit()

func _on_install_button_pressed() -> void:
	loadingView.show()
	loadingView.playAnimation()
	installTablePlugin.hide()
	rrm.installAddonsFromRemoteRepo(_addons) # Replace with function body.

func _on_addons_installed(addons: Array[RemoteRepoObject]) -> void:
	AceLog.printLog(["Addons Installation Completed:", addons])
	loadingView.hide()
	installTablePlugin.show()
	AddonManagerUtil.enable_addons() # Ensure newly installed addons are enabled in the editor.
	install_completed.emit(	addons, _addon_config)
	


func _createAddonInstallTable(addons: Array[RemoteRepoObject], configFile: ConfigFile) -> void:

	var addonColDef: AceTableColumnDef = AceTableColumnDef.new()
	addonColDef.columnId = "repo"
	addonColDef.columnName = "Add-on"
	addonColDef.columnType = AceTableConstants.ColumnType.LABEL
	addonColDef.columnSort = true
	addonColDef.columnAlign = AceTableConstants.Align.CENTER
	addonColDef.columnImageSize = Vector2i(48 * _editor_scale, 48 * _editor_scale)
	addonColDef.columnImage = "res://addons/aceAddonManager/Icons/Package.svg"
	addonColDef.columnTextType = AceTableConstants.TextType.COMBO

	var installedVersionColDef: AceTableColumnDef = AceTableColumnDef.new()
	installedVersionColDef.columnId = "installed_version"
	installedVersionColDef.columnName = "Installed Version"
	installedVersionColDef.columnType = AceTableConstants.ColumnType.LABEL
	installedVersionColDef.columnSort = true
	installedVersionColDef.columnAlign = AceTableConstants.Align.CENTER
	installedVersionColDef.columnTextType = AceTableConstants.TextType.TEXT

	var installCommitDateColDef: AceTableColumnDef = AceTableColumnDef.new()
	installCommitDateColDef.columnId = "install_commit_date"
	installCommitDateColDef.columnName = "Install Commit Date"
	installCommitDateColDef.columnType = AceTableConstants.ColumnType.LABEL
	installCommitDateColDef.columnSort = true
	installCommitDateColDef.columnAlign = AceTableConstants.Align.CENTER
	installCommitDateColDef.columnTextType = AceTableConstants.TextType.TEXT

	var latestVersionColDef: AceTableColumnDef = AceTableColumnDef.new()
	latestVersionColDef.columnId = "latest_version"
	latestVersionColDef.columnName = "Latest Version"
	latestVersionColDef.columnType = AceTableConstants.ColumnType.LABEL
	latestVersionColDef.columnSort = true
	latestVersionColDef.columnAlign = AceTableConstants.Align.CENTER
	latestVersionColDef.columnTextType = AceTableConstants.TextType.TEXT

	var statusColDef: AceTableColumnDef = AceTableColumnDef.new()
	statusColDef.columnId = "status"
	statusColDef.columnName = "Status"
	statusColDef.columnType = AceTableConstants.ColumnType.LABEL
	statusColDef.columnSort = true
	statusColDef.columnAlign = AceTableConstants.Align.CENTER
	statusColDef.columnTextType = AceTableConstants.TextType.LINK
	statusColDef.columnCallable = _handle_update

	var tableData: Array[Dictionary] = _normalize_table_data(_createInstallAddonsTableData(addons, configFile))

	var colDefs: Array[AceTableColumnDef] = [addonColDef, installedVersionColDef, installCommitDateColDef, latestVersionColDef, statusColDef]

	AceLog.printLog(["Loading Add-on Table data via AceTableManager"])
	installTablePlugin.printConfig()
	_addon_install_table = AceTableManager.createTable(installTablePlugin, colDefs, tableData)
	_apply_editor_scaling(installTablePlugin, _editor_scale)
	# _addon_install_table.row_selected.connect(_on_addon_table_selection)
	AceLog.printLog(["Done Loading Add-on Table data via AceTableManager"])

	pass


func _createInstallAddonsTableData(addons: Array[RemoteRepoObject], configFile: ConfigFile) -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for addon in addons:
		var addon_dict: Dictionary = {
			"repo": addon.repo,
			"installed_version": addon.version if addon.isRelease else addon.branch,
			"install_commit_date": "N/A" if addon.isRelease else configFile.get_value(addon.repo, "last_commit_date", "N/A"),
			"latest_version": addon.version if addon.isRelease else addon.metadata.branch_last_commit_date,
			"status": rrm.createTextLinkObjectForUpdate(addon),
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

func _handle_update(link: String) -> void:
	AceLog.printLog(["Update link pressed: %s" % link], AceLog.LOG_LEVEL.INFO)

func initialize_scaling(scale: float) -> void:
	_editor_scale = scale
	_apply_editor_scaling(self, scale)

func _scale_table_themes(table_plugin: Control, scale: float) -> void:
	if scale == 1.0 or table_plugin == null:
		return
	if table_plugin.header_theme:
		table_plugin.header_theme = _scale_theme(table_plugin.header_theme, scale)
	if table_plugin.header_cell_theme:
		table_plugin.header_cell_theme = _scale_theme(table_plugin.header_cell_theme, scale)
	if table_plugin.row_theme:
		table_plugin.row_theme = _scale_theme(table_plugin.row_theme, scale)
	if table_plugin.row_cell_theme:
		table_plugin.row_cell_theme = _scale_theme(table_plugin.row_cell_theme, scale)

func _scale_theme(theme: Theme, scale: float) -> Theme:
	var dup = theme.duplicate(true)
	for type in dup.get_type_list():
		for name in dup.get_font_size_list(type):
			var val = dup.get_font_size(name, type)
			dup.set_font_size(name, type, int(round(val * scale)))
		for name in dup.get_constant_list(type):
			var val = dup.get_constant(name, type)
			dup.set_constant(name, type, int(round(val * scale)))
	return dup

func _apply_editor_scaling(node: Node, scale: float) -> void:
	if scale == 1.0:
		return
	if node is Control:
		if node.custom_minimum_size != Vector2.ZERO:
			node.custom_minimum_size = node.custom_minimum_size * scale
		
		# Scale explicit font size overrides directly from properties to bypass scene tree lookup gotchas
		var font_keys = ["font_size", "normal_font_size", "bold_font_size", "bold_italics_font_size", "italics_font_size", "mono_font_size"]
		for key in font_keys:
			var override_font_size = node.get("theme_override_font_sizes/" + key)
			if override_font_size != null and override_font_size is int and override_font_size > 0:
				node.add_theme_font_size_override(key, int(round(override_font_size * scale)))
		
		# Scale margin overrides
		for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
			var override_val = node.get("theme_override_constants/" + margin)
			if override_val != null and override_val is int:
				node.add_theme_constant_override(margin, int(round(override_val * scale)))
		
		# Scale separation overrides
		for sep in ["separation", "h_separation", "v_separation"]:
			var override_val = node.get("theme_override_constants/" + sep)
			if override_val != null and override_val is int:
				node.add_theme_constant_override(sep, int(round(override_val * scale)))
	
	for child in node.get_children():
		_apply_editor_scaling(child, scale)

