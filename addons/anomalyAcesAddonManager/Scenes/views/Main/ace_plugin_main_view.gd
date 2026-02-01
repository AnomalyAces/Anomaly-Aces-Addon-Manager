@tool
class_name AcePluginMainView extends Control

# @onready var container: VBoxContainer = $VBoxContainer

@onready var tablePlugin: AceTable = $PanelContainer/VBoxContainer/AceTable

var rrm: GitHubManager

var _table: _AceTable

func _ready() -> void:
	rrm = GitHubManager.new(self)
	_createTable()
	# for i in randi_range(1,3):
	# 	_add_addonInfo()
	# rrm.getAddonsFromRemoteRepo()
	rrm.addons_downloaded.connect(_on_addon_downloads_completed)
	rrm.conflicts_found.connect(_on_conflicts_found)


	

func getAddons() -> void:
	rrm.getAddonsFromRemoteRepo()

##### Signal Callbacks #####
func _on_addon_downloads_completed(addons: Array[RemoteRepoObject]) -> void:
	AceLog.printLog(["All Addons Downloaded from Remote Repo", JSON.parse_string(AceSerialize.serialize_array(addons))], AceLog.LOG_LEVEL.INFO)

func _on_conflicts_found(conflicting_addons: Array[RemoteRepoConflict]) -> void:
	AceLog.printLog(["Conflicting addons found:", JSON.parse_string(AceSerialize.serialize_array(conflicting_addons))], AceLog.LOG_LEVEL.INFO)

#############################

func _createConflictTable(conflics: Array[RemoteRepoConflict]) -> void:
	# 
	# columns: Addon, Conflict Addon, Conflict Type, Addon File, Conflict File
	#
	var selectColDef: AceTableColumnDef = AceTableColumnDef.new()
	selectColDef.columnId = "selected"
	selectColDef.columnName = ""
	selectColDef.columnType = AceTableConstants.ColumnType.SELECTION
	selectColDef.columnAlign = AceTableConstants.Align.CENTER
	selectColDef.columnImageSize = Vector2i(64,64)
	selectColDef.columnHasSelectAll = true

	var addonColDef: AceTableColumnDef = AceTableColumnDef.new()
	addonColDef.columnId = "addon"
	addonColDef.columnName = "Add-on"
	addonColDef.columnType = AceTableConstants.ColumnType.LABEL
	addonColDef.columnSort = true
	addonColDef.columnAlign = AceTableConstants.Align.CENTER
	addonColDef.columnImageSize = Vector2i(64,64)
	addonColDef.columnTextType = AceTableConstants.TextType.COMBO

	var conflictAddonColDef: AceTableColumnDef = AceTableColumnDef.new()
	conflictAddonColDef.columnId = "conflict_addon"
	conflictAddonColDef.columnName = "Conflict Add-on"
	conflictAddonColDef.columnType = AceTableConstants.ColumnType.LABEL
	conflictAddonColDef.columnSort = true
	conflictAddonColDef.columnAlign = AceTableConstants.Align.CENTER
	conflictAddonColDef.columnImageSize = Vector2i(64,64)
	conflictAddonColDef.columnTextType = AceTableConstants.TextType.COMBO

	var conflictTypeColDef: AceTableColumnDef = AceTableColumnDef.new()
	conflictTypeColDef.columnId = "conflict_type"
	conflictTypeColDef.columnName = "Conflict Type"
	conflictTypeColDef.columnType = AceTableConstants.ColumnType.LABEL
	conflictTypeColDef.columnSort = true
	conflictTypeColDef.columnAlign = AceTableConstants.Align.CENTER
	conflictTypeColDef.columnImageSize = Vector2i(64,64)
	conflictTypeColDef.columnTextType = AceTableConstants.TextType.TEXT

	var addonFileColDef: AceTableColumnDef = AceTableColumnDef.new()
	addonFileColDef.columnId = "addon_file"
	addonFileColDef.columnName = "Add-on File"
	addonFileColDef.columnType = AceTableConstants.ColumnType.LABEL
	addonFileColDef.columnSort = false


	pass

func _createConflictTableData(conflics: Array[RemoteRepoConflict]) -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for conflict in conflics:
		var conflict_dict: Dictionary = {
			"selected": false,
			"addon": conflict.addon.repo,
			"conflict_addon": conflict.conflicting_addon.repo,
			"conflict_type": "Release Conflict" if conflict.releaseConflict else ("Version Conflict" if conflict.versionConflict else ("Branch Conflict" if conflict.branchConflict else "N/A")),
			# Is data for a text link. Needs to be an object with "text" and "link" keys
			"addon_file": _createTextLinkObject(conflict.addon.metadata.addon_file),
			# Is data for a text link. Needs to be an object with "text" and "link" keys
			"conflicting_file": _createTextLinkObject(conflict.conflicting_addon.metadata.addon_file)
		}
		data.append(conflict_dict)
	return data


func _createAddonTable() -> void:
	# 
	# columns: selected, name, version/branch, dependencies, status, updates
	#
	var selectColDef: AceTableColumnDef = AceTableColumnDef.new()
	selectColDef.columnId = "selected"
	selectColDef.columnName = ""
	selectColDef.columnType = AceTableConstants.ColumnType.SELECTION
	selectColDef.columnAlign = AceTableConstants.Align.CENTER
	selectColDef.columnImageSize = Vector2i(64,64)
	selectColDef.columnHasSelectAll = true
	pass

func _createTable():
	
	var textRect = TextureRect.new()
	textRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	textRect.size_flags_horizontal = SIZE_EXPAND_FILL
	textRect.set_texture(load("res://icon.svg"))

	var selectColDef: AceTableColumnDef = AceTableColumnDef.new()
	selectColDef.columnId = "selected"
	selectColDef.columnName = ""
	selectColDef.columnType = AceTableConstants.ColumnType.SELECTION
	selectColDef.columnAlign = AceTableConstants.Align.CENTER
	selectColDef.columnImageSize = Vector2i(64,64)
	selectColDef.columnHasSelectAll = true

	var fooColDef: AceTableColumnDef = AceTableColumnDef.new()
	fooColDef.columnId = "foo"
	fooColDef.columnName = "Foo"
	fooColDef.columnSort = true
	fooColDef.columnType = AceTableConstants.ColumnType.LABEL
	fooColDef.columnAlign = AceTableConstants.Align.CENTER

	var barColDef: AceTableColumnDef = AceTableColumnDef.new()
	barColDef.columnId = "bar"
	barColDef.columnName = "Bar"
	barColDef.columnSort = true
	barColDef.columnType = AceTableConstants.ColumnType.BUTTON
	barColDef.columnAlign = AceTableConstants.Align.CENTER
	barColDef.columnImage = "res://icon.svg"
	barColDef.columnImageAlign = AceTableConstants.ImageAlign.LEFT
	barColDef.columnButtonIconUpdateWithState = false
	barColDef.columnImageSize = Vector2i(64,64)
	barColDef.columnCallable = _button_pressed

	var foobarColDef: AceTableColumnDef = AceTableColumnDef.new()
	foobarColDef.columnId = "foobar"
	foobarColDef.columnName = "FooBar"
	foobarColDef.columnType = AceTableConstants.ColumnType.TEXTURE_RECT
	foobarColDef.columnAlign = AceTableConstants.Align.CENTER
	foobarColDef.columnImageSize = Vector2i(64,64)
	# foobarColDef.columnNode = textRect

	var colDefs: Array[AceTableColumnDef] = [selectColDef, fooColDef, barColDef, foobarColDef]
	
	var data: Array[Dictionary] = [
		{
			"selected":false,
			"foo":"12",
			"bar":"Press Me",
			"foobar": "res://icon.svg"
		},
		{
			"selected":false,
			"foo":"15",
			"bar":"Old Me",
			"foobar": "res://icon.svg"
		},
		{
			"selected":false,
			"foo":"10",
			"bar":"Press Me",
			"foobar": "res://icon.svg"
		},
		{
			"selected":false,
			"foo":"17",
			"bar":"New Me",
			"foobar": "res://icon.svg"
		}
	]
	AceLog.printLog(["Loading Table data via AceTableManager"])
	tablePlugin.printConfig()
	_table = AceTableManager.createTable(tablePlugin, colDefs, data)
	AceLog.printLog(["Done Loading  Table data via AceTableManager"])
	

func _button_pressed(colDef: AceTableColumnDef, dt: Dictionary):
	AceLog.printLog(["data from Button from column %s: %s" % [colDef.columnName,dt]], AceLog.LOG_LEVEL.INFO)

func _createTextLinkObject(filePath: String) -> Dictionary:

	var file_name: String = filePath.get_file()
	var parent_dir: String = filePath.get_base_dir().get_file()

	return {
		"text": "%s/%s" % [parent_dir, file_name],
		"link": filePath
	}