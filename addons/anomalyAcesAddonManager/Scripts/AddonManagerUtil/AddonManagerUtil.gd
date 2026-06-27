@tool
class_name AddonManagerUtil extends Object

static func get_github_pat() -> GithubPATInfo:
    var pat_info: GithubPATInfo = GithubPATInfo.new()
    if AceFileUtil.File.file_exists(AcePluginGithubPATView.GITHUB_PAT_FILE_PATH):
        var file: FileAccess = AceFileUtil.File.create_file(AcePluginGithubPATView.GITHUB_PAT_FILE_PATH, FileAccess.READ)

        if file == null:
            AceLog.printLog(["File is empty. Returning null"], AceLog.LOG_LEVEL.ERROR)
            return null

        var content: String = file.get_as_text()
        file.close()

        var pat_res: AceDeserializeResult = AceSerialize.deserialize(content, GithubPATInfo)

        if pat_res.error != OK:
            AceLog.printLog(["Failed to deserialize PAT info from file. Error code: ", pat_res.error], AceLog.LOG_LEVEL.ERROR)
            return pat_info
        
        pat_info = pat_res.data

        if pat_info != null:
            AceLog.printLog(["Loaded Personal Access Token from file. Expiration Date: ", pat_info.expiration_date], AceLog.LOG_LEVEL.INFO)
            return pat_info
        else:
            AceLog.printLog(["Failed to deserialize Personal Access Token info from file."], AceLog.LOG_LEVEL.ERROR)
            return GithubPATInfo.new()
    else:
        AceFileUtil.File.create_file(AcePluginGithubPATView.GITHUB_PAT_FILE_PATH, FileAccess.WRITE) # Create an empty file if it doesn't exist.
        AceLog.printLog(["No existing Personal Access Token found. Please enter a token and click 'Check Token'."], AceLog.LOG_LEVEL.INFO)
        return pat_info


static func enable_addons() -> void:
    var addons_path = "res://addons/"
    var dir = DirAccess.open(addons_path)

    if dir:
        dir.list_dir_begin()
        var folder_name = dir.get_next()
        
        while folder_name != "":
            # 1. Ensure it is a directory and not a hidden file system path
            if dir.current_is_dir() and not folder_name.begins_with("."):
                # 2. Check if the directory actually contains a 'plugin.cfg' file
                var cfg_path = folder_name.path_join("plugin.cfg")
                if dir.file_exists(cfg_path):
                    # 3. Only enable it if it isn't active already
                    if not EditorInterface.is_plugin_enabled(folder_name):
                        EditorInterface.set_plugin_enabled(folder_name, true)
                        print("Plugin enabled successfully: ", folder_name)
                    else:
                        print("Plugin already active: ", folder_name)
                else:
                    # Safely skip asset/utility folders that are not formal editor plugins
                    print("Skipped (No plugin.cfg found): ", folder_name)
                    
            folder_name = dir.get_next()
        print("All found addons processed successfully!")
    else:
        print("An error occurred trying to access the res://addons/ path.")

const SETTINGS_FILE_PATH = "user://addon_manager_settings.json"

static func get_settings() -> Dictionary:
    var settings = {}
    if FileAccess.file_exists(SETTINGS_FILE_PATH):
        var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            file.close()
            var parsed = JSON.parse_string(content)
            if parsed is Dictionary:
                settings = parsed
    return settings

static func save_settings(settings: Dictionary) -> void:
    var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(settings, "\t"))
        file.close()

static func get_estimated_scale() -> float:
    if Engine.is_editor_hint():
        return EditorInterface.get_editor_scale()
    
    var screen = DisplayServer.window_get_current_screen()
    var screen_scale = DisplayServer.screen_get_scale(screen)
    if screen_scale > 1.0:
        return screen_scale
        
    var dpi = DisplayServer.screen_get_dpi(screen)
    if dpi > 0:
        var raw_scale = dpi / 96.0
        if raw_scale > 1.1:
            return max(1.0, round(raw_scale * 4.0) / 4.0)
            
    return 1.0

static func get_applied_scale() -> float:
    var settings = AddonManagerUtil.get_settings()
    if settings.has("scale"):
        var custom_scale = settings.get("scale")
        if custom_scale is float or custom_scale is int:
            return float(custom_scale)
    return 1.0

static func set_applied_scale(scale: float) -> void:
    var settings = AddonManagerUtil.get_settings()
    settings["scale"] = scale
    AddonManagerUtil.save_settings(settings)

static func add_scale_ui_to_header(controls_container: HBoxContainer, plugin_instance: Control) -> void:
    if controls_container == null:
        return
        
    if controls_container.has_node("ScaleContainer"):
        return
        
    var container = HBoxContainer.new()
    container.name = "ScaleContainer"
    container.alignment = BoxContainer.ALIGNMENT_CENTER
    container.add_theme_constant_override("separation", 6)
    
    var label = Label.new()
    label.name = "ScaleLabel"
    label.text = "Scale:"
    
    var line_edit = LineEdit.new()
    line_edit.name = "ScaleLineEdit"
    
    var current_scale = AddonManagerUtil.get_applied_scale()
    line_edit.text = "%d%%" % int(current_scale * 100)
    line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
    
    line_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    # Do not scale elements inside the header, but make LineEdit custom_minimum_size match RefreshButton height
    line_edit.add_theme_font_size_override("font_size", 13)
    line_edit.custom_minimum_size = Vector2(80, 28)
    label.add_theme_font_size_override("font_size", 13)
    label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1))
    
    container.add_child(label)
    container.add_child(line_edit)
    
    controls_container.add_child(container)
    controls_container.move_child(container, 0)
    
    var apply_scale = func(new_text: String):
        var clean_text = ""
        var has_dot = false
        for i in range(new_text.length()):
            var c = new_text[i]
            if (c >= "0" and c <= "9"):
                clean_text += c
            elif c == "." and not has_dot:
                clean_text += c
                has_dot = true
                
        if clean_text.is_empty():
            line_edit.text = "%d%%" % int(AddonManagerUtil.get_applied_scale() * 100)
            return
            
        var val = float(clean_text)
        var scale_val = val
        if val >= 10.0:
            scale_val = val / 100.0
            
        scale_val = clamp(scale_val, 0.5, 4.0)
        
        # Prevent redundant reloading
        if abs(AddonManagerUtil.get_applied_scale() - scale_val) < 0.005:
            # Format text back to clean representation
            line_edit.text = "%d%%" % int(scale_val * 100)
            return
            
        AddonManagerUtil.set_applied_scale(scale_val)
        
        var main_plugin = plugin_instance.get("plugin_ref")
        if main_plugin and main_plugin.has_method("reload_current_view"):
            main_plugin.call("reload_current_view")
        elif main_plugin and main_plugin.has_method("switch_to_view"):
            main_plugin.call("switch_to_view", "res://addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn")
            
    line_edit.text_submitted.connect(func(new_text: String):
        apply_scale.call(new_text)
    )
    
    line_edit.focus_exited.connect(func():
        apply_scale.call(line_edit.text)
    )


static func apply_editor_scaling(node: Node, scale: float) -> void:
    if scale == 1.0 or node == null:
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
        
        # Scale margin, separation, and other constant overrides
        var constant_keys = [
            "margin_left", "margin_top", "margin_right", "margin_bottom",
            "separation", "h_separation", "v_separation",
            "icon_max_width"
        ]
        for key in constant_keys:
            var override_val = node.get("theme_override_constants/" + key)
            if override_val != null and override_val is int:
                node.add_theme_constant_override(key, int(round(override_val * scale)))
        
        # Scale table themes if the node is an AceTablePlugin
        if node is AceTablePlugin:
            _scale_table_themes(node, scale)
    
    for child in node.get_children():
        apply_editor_scaling(child, scale)


static func _scale_table_themes(table_plugin: Control, scale: float) -> void:
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


static func _scale_theme(theme: Theme, scale: float) -> Theme:
    var dup = theme.duplicate(true)
    for type in dup.get_type_list():
        for name in dup.get_font_size_list(type):
            var val = dup.get_font_size(name, type)
            dup.set_font_size(name, type, int(round(val * scale)))
        for name in dup.get_constant_list(type):
            var val = dup.get_constant(name, type)
            dup.set_constant(name, type, int(round(val * scale)))
    return dup
