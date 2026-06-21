extends PanelContainer

@onready var title_label = $VBox/Header/Title
@onready var version_label = $VBox/Header/Version
@onready var author_label = $VBox/Author
@onready var desc_label = $VBox/Description
@onready var demos_list = $VBox/DemosSection/DemosList
@onready var no_demos_label = $VBox/DemosSection/NoDemosLabel

func set_addon_details(addon_name: String, version: String, author: String, description: String, demos: Array):
    title_label.text = addon_name
    version_label.text = "v" + version
    author_label.text = "by " + author if author != "" else "Author: Unknown"
    desc_label.text = description if description != "" else "No description provided."
    
    # Clear existing demos
    for child in demos_list.get_children():
        child.queue_free()
        
    if demos.size() > 0:
        no_demos_label.visible = false
        for demo_path in demos:
            var btn = Button.new()
            # Extract filename from path
            var filename = demo_path.get_file()
            btn.text = "▶ Run " + filename
            btn.tooltip_text = demo_path
            # Store demo_path in a local variable for the lambda closure
            var target_scene = demo_path
            btn.pressed.connect(func():
                AddonPreviewerOverlay.target_demo_scene = target_scene
                get_tree().change_scene_to_file("res://Scenes/DemoPreviewer/demo_previewer.tscn")
            )
            btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
            demos_list.add_child(btn)
    else:
        no_demos_label.visible = true
