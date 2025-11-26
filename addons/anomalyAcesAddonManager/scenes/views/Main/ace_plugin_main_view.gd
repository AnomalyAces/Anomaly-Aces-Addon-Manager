@tool
class_name AcePluginMainView extends Control

# @onready var container: VBoxContainer = $VBoxContainer

@onready var tablePlugin: AceTable = $PanelContainer/VBoxContainer/AceTable

var rrm: RemoteRepoManager

func _ready() -> void:
	rrm = GitHubManager.new(self)
	_createTable()
	# for i in randi_range(1,3):
	# 	_add_addonInfo()
	rrm.getAddonsFromRemoteRepo()

	

func getAddons() -> void:
	rrm.getAddonsFromRemoteRepo()


func _add_addonInfo():
	var addonInfoScene: PackedScene = load("res://addons/anomalyAcesAddonManager/scenes/addonInfo/AddonInfo.tscn")
	var addonInfoSceneInstance: HBoxContainer = addonInfoScene.instantiate()
	# container.add_child(addonInfoSceneInstance)

func _createTable():
	
	var textRect = TextureRect.new()
	textRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	textRect.size_flags_horizontal = SIZE_EXPAND_FILL
	textRect.set_texture(load("res://icon.svg"))

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
	barColDef.columnImageSize = Vector2i(64,64)
	barColDef.columnCallable = button_pressed

	var foobarColDef: AceTableColumnDef = AceTableColumnDef.new()
	foobarColDef.columnId = "foobar"
	foobarColDef.columnName = "FooBar"
	foobarColDef.columnType = AceTableConstants.ColumnType.TEXTURE_RECT
	foobarColDef.columnAlign = AceTableConstants.Align.CENTER
	foobarColDef.columnNode = textRect

	var colDefs: Array[AceTableColumnDef] = [fooColDef, barColDef, foobarColDef]
	
	var data: Array[Dictionary] = [
		{
			"foo":"12",
			"bar":"Press Me",
			"foobar": "res://icon.svg"
		},
		{
			"foo":"15",
			"bar":"Old Me",
			"foobar": "res://icon.svg"
		},
		{
			"foo":"10",
			"bar":"Press Me",
			"foobar": "res://icon.svg"
		},
		{
			"foo":"17",
			"bar":"New Me",
			"foobar": "res://icon.svg"
		}
	]
	AceLog.printLog(["Loading Table data via AceTableManager"])
	tablePlugin.printConfig()
	AceTableManager.createTable(tablePlugin, colDefs, data)
	AceLog.printLog(["Done Loading  Table data via AceTableManager"])
	

func button_pressed(colDef: AceTableColumnDef, dt: Dictionary):
	AceLog.printLog(["data from Button: %s" % [dt]])
