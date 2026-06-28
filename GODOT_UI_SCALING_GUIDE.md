# Godot 4 High-DPI UI Scaling Guide

This guide details a production-ready scaling architecture for custom UI controls and editor plugins in Godot 4. It covers resolution detection, layout constraints, theme override APIs, and implementation blueprints to achieve crisp, consistent, and responsive scaling across high-res and multi-monitor setups.

---

## 1. Core Scaling Challenges in Godot 4

When building custom UI panels or editor plugins, standard containers (like `VBoxContainer` or `GridContainer`) will flow and resize. However, **explicit properties** do not scale automatically:
* **Custom Minimum Sizes** (`custom_minimum_size`) defined on nodes remain fixed in absolute pixels.
* **Theme Font Size Overrides** remain at their absolute values (e.g., `14px` on a `1080p` display is readable, but microscopic on a `4K` display).
* **Theme Margin and Separation Overrides** remain unscaled, making layout spacing feel collapsed on high-resolution screens.
* **Vector Icons (SVG)** are rasterized at their default import sizes (usually `16x16`), appearing tiny and blurry on high-DPI viewports.

To achieve clean layouts, you must scale these properties dynamically at runtime.

---

## 2. The "@tool" Serialization Trap

If your custom panel or plugin runs in `@tool` mode (running inside the Godot editor workspace itself):
> [!CAUTION]
> If you apply scaling layout overrides inside a script's `_ready()` callback, those modifications change the active scene tree. If you save the scene in the editor, Godot will **serialize the scaled properties back into the `.tscn` file on disk**, permanently mutating your design source file.

### Best Practice Rule
Always guard your scaling logic. Only trigger layout transformations if the view is initialized inside the running plugin wrapper:
```gdscript
var plugin_ref = null

func initialize_view(p_ref, _extra_data) -> void:
    plugin_ref = p_ref

func _ready() -> void:
    # Scale only when running in the active plugin tab context.
    # When editing the scene in the editor, plugin_ref is null, leaving the .tscn clean.
    if Engine.is_editor_hint() and plugin_ref != null:
        var scale = AddonManagerUtil.get_applied_scale()
        AddonManagerUtil.apply_editor_scaling(self, scale)
```

---

## 3. Official Godot Theme Overrides API

In Godot 4, you **cannot** safely retrieve theme overrides via raw property paths (e.g., `node.get("theme_override_font_sizes/font_size")` returns `null` because overrides are managed internally by the engine).

### Best Practice Rule
Use the official `Control` methods to safely check, query, and set overrides:
```gdscript
# Fonts
if node.has_theme_font_size_override(key):
    var current_size = node.get_theme_font_size(key)
    node.add_theme_font_size_override(key, int(round(current_size * scale)))

# Spacing Constants
if node.has_theme_constant_override(key):
    var val = node.get_theme_constant(key)
    node.add_theme_constant_override(key, int(round(val * scale)))
```

---

## 4. Multi-Monitor DPI Scale Estimation

Estimating screen scale using a hardcoded monitor index is error-prone on Windows because Godot's window screen mapping can shift. 
* **Safe Solution**: Query `DisplayServer.window_get_current_screen()` to find the active monitor index and pass it to `screen_get_size()` and `screen_get_scale()`. This handles multi-monitor workspaces correctly when the primary monitor has different bounds than the active editor screen.
* **OS-Scale & Multi-Monitor Sizing**: Normalise the reported size into physical bounds based on thresholds:
  ```gdscript
  var current_screen = DisplayServer.window_get_current_screen()
  var screen_size = DisplayServer.screen_get_size(current_screen)
  var os_scale = DisplayServer.screen_get_scale(current_screen)
  var physical_width = float(screen_size.x)
  if os_scale > 1.0:
      if physical_width < 1920.0:
          physical_width = physical_width * os_scale
      elif physical_width > 3840.0:
          physical_width = physical_width / os_scale
  ```

---

## 5. Destruction Auto-Save Guard

If your UI utilizes editable text fields (`LineEdit`) with `focus_exited` signals connected to auto-save functions:
> [!IMPORTANT]
> When the view is reloaded or destroyed, Godot removes the active nodes from the tree. If an input field had focus, it fires a **destruction-induced `focus_exited` event**. Without a guard, this event will execute and save stale or default text properties back to your configuration, overwriting your runtime settings.

Always add guard checks at the start of your `focus_exited` callbacks:
```gdscript
line_edit.focus_exited.connect(func():
    if line_edit.is_queued_for_deletion() or not line_edit.is_inside_tree():
        return
    apply_scale.call(line_edit.text)
)
```

---

## 6. Sizing Constraints & SVG Icons

* **LineEdit Vertical Expansion**: By default, text inputs expand to fill their parent container heights. To prevent vertical bloating when headers scale, center them:
  ```gdscript
  node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  ```
* **SVG Icon Scaling**: SVG icons must be programmatically re-rasterized at scaled dimensions to remain sharp:
  ```gdscript
  static func scale_svg_icon(svg: Texture2D, target_size: int) -> Texture2D:
      if svg:
          var img = svg.get_image()
          if img:
              img.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
              return ImageTexture.create_from_image(img)
      return svg
  ```

---

## 7. Scaling Utility Blueprint (Copy & Paste)

Create a static helper class (`AddonManagerUtil.gd`) to encapsulate your scaling system:

```gdscript
@tool
class_name UIUtility

# 1. Estimate DPI Scale
static func get_estimated_scale() -> float:
    var current_screen = DisplayServer.window_get_current_screen()
    var screen_size = DisplayServer.screen_get_size(current_screen)
    var os_scale = DisplayServer.screen_get_scale(current_screen)
    if os_scale <= 0:
        os_scale = 1.0
        
    var physical_width = float(screen_size.x)
    if os_scale > 1.0:
        if physical_width < 1920.0:
            # Godot returned logical size. Multiply to get physical.
            physical_width = physical_width * os_scale
        elif physical_width > 3840.0:
            # Godot returned double-scaled size. Divide to get physical.
            physical_width = physical_width / os_scale
        
    var ratio = physical_width / 1920.0
    return max(1.0, round(ratio * 4.0) / 4.0)

# 2. Scale SVG Icons
static func scale_svg_icon(svg: Texture2D, target_size: int) -> Texture2D:
    if svg:
        var img = svg.get_image()
        if img:
            img.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
            return ImageTexture.create_from_image(img)
    return svg

# 3. Recursive Editor scaling
static func apply_editor_scaling(node: Node, scale: float) -> void:
    if scale == 1.0 or node == null:
        return
        
    if node is Control:
        # Check if node is inside a "Header" layout
        var is_in_header = false
        var parent = node
        while parent != null:
            if parent.name == "Header":
                is_in_header = true
                break
            parent = parent.get_parent()
            
        var custom_scaled = false
        # Header button and input form element overrides
        if is_in_header and (node is Button or node is LineEdit):
            if node is LineEdit:
                node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            if node is Button:
                node.flat = true
                
            var base_min = node.custom_minimum_size
            if base_min != Vector2.ZERO:
                var new_h = base_min.y + 12 # +12px height expansion
                var new_w = base_min.x
                if abs(base_min.x - base_min.y) < 2:
                    new_w = base_min.x + 12 # Square button
                else:
                    new_w = base_min.x + 50 # Standard button width pad
                node.custom_minimum_size = Vector2(new_w, new_h) * scale
                
            node.add_theme_font_size_override("font_size", int(round(26 * scale))) # Base 26px font
            custom_scaled = true
            
        if not custom_scaled:
            if node.custom_minimum_size != Vector2.ZERO:
                node.custom_minimum_size = node.custom_minimum_size * scale
                
            # Scale explicit font overrides
            var font_keys = ["font_size", "normal_font_size", "bold_font_size", "bold_italics_font_size", "italics_font_size", "mono_font_size"]
            for key in font_keys:
                if node.has_theme_font_size_override(key):
                    var current_size = node.get_theme_font_size(key)
                    node.add_theme_font_size_override(key, int(round(current_size * scale)))
                    
        # Scale margin, separation, and other constant overrides
        var constant_keys = [
            "margin_left", "margin_top", "margin_right", "margin_bottom",
            "separation", "h_separation", "v_separation", "icon_max_width"
        ]
        for key in constant_keys:
            if node.has_theme_constant_override(key):
                var val = node.get_theme_constant(key)
                node.add_theme_constant_override(key, int(round(val * scale)))
                
    for child in node.get_children():
        apply_editor_scaling(child, scale)
```
