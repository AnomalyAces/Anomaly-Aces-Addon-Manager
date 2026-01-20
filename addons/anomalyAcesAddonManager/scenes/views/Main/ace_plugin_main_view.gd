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


	

func getAddons() -> void:
	rrm.getAddonsFromRemoteRepo()


func _on_addon_downloads_completed() -> void:
	AceLog.printLog(["All Addons Downloaded from Remote Repo"], AceLog.LOG_LEVEL.INFO)


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
