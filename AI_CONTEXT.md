# AI Context & Developer Guide

This file provides context for AI coding assistants (and developers) working on the **Anomaly Aces Addon Manager** project. It outlines the project structure, design decisions, CLI commands, and rules for managing addon submodules and links.

---

## Project Overview
The Anomaly Aces Addon Manager is a Godot 4.7 testing sandbox designed to preview, run, and develop Godot addons in isolation or in tandem.
Instead of copying addon folders into the project, addons are registered as **git submodules** under `submodules/` and linked dynamically into the standard `addons/` directory.

The editor plugin exposes a **single unified tab** called **"Ace Addon Manager"** which contains three navigable sections:
1. **Addon Previewer** (default landing page) — scan, toggle, and demo-run registered addons
2. **Addon Updater** — fetch, check, and install updates for addons via GitHub
3. **Addon Dependency Editor** — create/edit per-addon `addons.json` dependency files and invoke `manage_addons` (located at `addons/anomalyAcesAddonManager/manage_addons`)

---

## Directory Structure
* **`submodules/`**: *(Currently empty — `anomalyAcesAddonManager` has been migrated into the main project.)* Contains raw cloned git submodules of addons.
  * Contains a `.gdignore` file to prevent Godot from scanning and importing files inside this folder, avoiding resource duplication conflicts.
* **`addons/`**: Contains Windows directory junctions or Unix symlinks pointing to active plugins inside `submodules/`. This is where Godot scans for addons.
* **`addons/anomalyAcesAddonManager/`**: The unified native editor plugin integration directory.
  * **`plugin.cfg`**: Declares the "Ace Addon Manager" plugin (v2.0).
  * **`anomalyAcesAddonManager.gd`**: The plugin bootstrap script that registers the single **"Ace Addon Manager"** main screen tab. Exposes `switch_to_view(scene_path, extra_data)` to navigate between sub-sections. Preloads the SVG icon (`AceAddonManager.svg`).
  * **`AceAddonManager.svg`**: The plugin icon (original manager icon).
  * **`addon_previewer_overlay.gd`**: Autoloaded helper that overlays a floating **← Back to Dashboard** button on all scenes except the dashboard itself when running in standalone mode.
  * **`Fonts/`**: Migrated fonts (Chakra_Petch, Teko, TitleFont.tres).
  * **`Icons/`**: Migrated UI icon assets.
  * **`Templates/`**: Migration templates like `addons_template.json`.
  * **`Scripts/`**: Migrated backend scripts for managing updates and PAT configuration.
    * `AddonManagerUtil/AddonManagerUtil.gd`
    * `GitHubManager/GitHubManager.gd`
    * `RemoteRepoManager/RemoteRepoManager.gd`
  * **`Scenes/`**: Dedicated subfolder containing the application visual components and layouts:
    * **`AddonPreviewer/`**: Addon Previewer dashboard (`main.tscn` / `main.gd`). Dynamically scans `res://addons/` for `plugin.cfg` files, excluding `anomalyAcesAddonManager` itself. Contains the **"Addon Updater →"** nav button that calls `plugin_ref.switch_to_view()`.
    * **`AddonCard/`**: Render card component (`addon_card.tscn` / `addon_card.gd`) showing details, status toggle, list of detected demos, and an **"⚙ Edit Dependencies"** button.
    * **`DemoPreviewer/`**: The standalone demo player container (`demo_previewer.tscn` / `demo_previewer.gd`).
    * **`AddonUpdater/`**: Host scene (`addon_updater.tscn` / `addon_updater.gd`) that wraps the migrated `AcePluginManager` at runtime. Provides matching dark-theme header with Back and Refresh buttons, and applies DPI scaling.
    * **`AddonDependencyEditor/`**: Dependency editor (`addon_dependency_editor.tscn` / `addon_dependency_editor.gd`) that reads/writes per-addon `addons.json` files and can invoke the `manage_addons` Bash script.
      * **`DependencyEntry/`**: Reusable form row (`dependency_entry.tscn` / `dependency_entry.gd`) for a single addon dependency, with nested sub-dependency support.
* **`project.godot`**: Godot 4.7 project settings. The only enabled plugin entry is `res://addons/anomalyAcesAddonManager/plugin.cfg`.
* **`addons/anomalyAcesAddonManager/manage_addons`**: A Bash CLI helper script.
* **`.vscode/settings.json`**: Configures VS Code workspace settings to exclude `submodules/` from global searches and filesystem watching.

---

## Plugin Navigation Model
All sub-sections are rendered inside a single `MarginContainer` wrapper in `anomalyAcesAddonManager.gd`. Navigation works via:
```gdscript
plugin_ref.switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonUpdater/addon_updater.tscn")
plugin_ref.switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonDependencyEditor/addon_dependency_editor.tscn", { "folder_name": "myAddon", "addon_path": "res://addons/myAddon" })
```
Every sub-scene implements `initialize_view(plugin_ref, extra_data)` to receive its context before `_ready()` fires.

---

## Editor Plugin & Dashboard Integration
* **Ace Addon Manager Tab**: Single tab exposing all functionality.
  * **Addon Previewer** (default): Card grid with search, rescan, toggle, demo runner, and dependency editor entry points.
  * **Addon Updater**: Migrated `AcePluginManager` — GitHub-fetched addon list, update check, install flow, conflict detection, GitHub PAT management.
  * **Addon Dependency Editor**: Per-addon `addons.json` editor. Writes to `res://addons/{folder}/addons.json`. Invokes `manage_addons update` (at `addons/anomalyAcesAddonManager/manage_addons`) via `OS.execute("bash", ...)` with a fallback copy-to-clipboard dialog.

---

## High-DPI Scaling & Layout Adjustments
To support responsive UI scaling in the editor plugin at any display scale and resolution, the project implements a robust dynamic scaling utility defined in [AddonManagerUtil.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/addons/anomalyAcesAddonManager/Scripts/AddonManagerUtil/AddonManagerUtil.gd):

### 1. The Serialization Gotcha (Crucial!)
Because dashboard scripts are marked with `@tool`, their `_ready()` functions run inside the Godot Editor workspace tree when editing them. If layout modifications are applied automatically on `_ready()`, they will modify the editor's active scene and get **serialized back to the `.tscn` file** when saving the scene.
* **Rule**: Only trigger layout and font scaling if `plugin_ref` is NOT `null`. When scenes are opened for editing in the editor, `plugin_ref` is `null`, ensuring properties remain at their clean, unscaled base values.
* **Addon Cards**: Since addon cards are instantiated dynamically via code, they are scaled dynamically when `set_addon_details(..., scale)` is called by the parent main screen script.

### 2. Resolution-Based Scale Estimation
- The default estimated scale is calculated strictly based on the physical screen resolution width and the OS display scale factor:
  * If the reported physical width is greater than standard 4K (`3840px`), we know it is a double-scaled layout size returned by Godot and divide it by the OS scale factor (`DisplayServer.screen_get_scale()`) to get the true physical width.
  * If the reported width is less than or equal to `3840px`, we use it directly as the true physical width.
- This ensures that a `3456px` display width always calculates to `1.75` (175%) estimated scale factor, regardless of scaling quirks or monitor setups.
- Multi-monitor queries should call `DisplayServer.screen_get_size()` and `DisplayServer.screen_get_scale()` with no arguments (defaulting to `-1`) to dynamically target the active display.

### 3. Destruction Auto-Save Guard (LineEdit focus_exited)
- When a text-input box (like the custom scale `LineEdit` in the header) has focus, it triggers a `focus_exited` signal when the view is destroyed or reloaded.
- To prevent destruction-induced `focus_exited` signals from saving stale text values back to `addon_manager_settings.json` (locking the scale factor to an old value), the callback must check `is_queued_for_deletion()` and `is_inside_tree()`:
  ```gdscript
  line_edit.focus_exited.connect(func():
      if line_edit.is_queued_for_deletion() or not line_edit.is_inside_tree():
          return
      apply_scale.call(line_edit.text)
  )
  ```

### 4. Official Godot Theme Overrides API
- In Godot 4, you **MUST** use the official Control theme override methods to scale layout attributes at runtime. Querying using raw property paths like `node.get("theme_override_font_sizes/font_size")` returns `null` because theme overrides are managed internally by the Control class.
- Use the following APIs to safely get and scale properties:
  * **Fonts**: `node.has_theme_font_size_override(key)` and `node.get_theme_font_size(key)`
  * **Constants**: `node.has_theme_constant_override(key)` and `node.get_theme_constant(key)`
  * Apply scaled values using `node.add_theme_font_size_override(key, value)` and `node.add_theme_constant_override(key, value)`.

### 5. Header Sizing and Form Element Constraining (+12px Expansion)
- **Flat Header Style**: All header buttons (Rescan, Ignore List, Manager Dependencies, Updater, Back) are flat buttons (`flat = true` in their `.tscn` files).
- **Dimension Expansion (+12px)**: During `apply_editor_scaling()`, if a control is inside a `"Header"` node hierarchy and is a form element (e.g. `Button` or `LineEdit`), its base `custom_minimum_size` width/height and its base font size (`font_size = 26px`) are increased by `12px` before applying the scaling factor.
- **Icon Sizing (+12px)**: Header SVG icons (Rescan, Gear, Back) are scaled to a base size of `28px` (original `16px` + `12px`) before scale multiplier is applied.
- **LineEdit Constraint**: To prevent search input fields and other text entries from expanding vertically inside headers when the container grows, they must be constrained to the vertical center:
  ```gdscript
  node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  ```

### 6. Custom Scaling Control Settings
- The manual scale selector in the Addon Updater header uses an editable text field (`LineEdit`) that reads/writes to `user://addon_manager_settings.json`. 
- It parses input strings robustly (e.g. `120%`, `120`, `1.2`, `1.2x`). Values `>= 10.0` are interpreted as percentages, while values `< 10.0` are treated as direct multipliers. 
- Custom scale is clamped between `0.5` (50%) and `4.0` (400%). Changing the scale saves it to settings and reloads the current view dynamically.

### 7. Table Theme Duplication & Scaling
* `AceTablePlugin` tables rely on shared `Theme` resources. If you duplicate the theme via `theme.duplicate(true)`, scaling the values inside the duplicate and assigning it back scales font sizes and margins correctly in-memory without mutating or saving modified resources back to disk.

---

## Addon Dependency Editor: `addons.json` Format
Each `addons.json` lives next to the addon's `plugin.cfg`. It defines remote dependencies for the `manage_addons` / `anomalyAcesAddonManager` update system:

```json
[
  {
    "owner": "anomalyaces",
    "repo": "Anomaly-Aces-Log",
    "isRelease": false,
    "version": "1.0",
    "branch": "master",
    "subfolder": "addons/anomalyAcesLog",
    "dependencies": []
  }
]
```

### Apply Changes Flow
1. Save the `addons.json` file.
2. Call `OS.execute("bash", [project_root + "addons/anomalyAcesAddonManager/manage_addons", "update"], output, true)`.
3. Display a dialog with stdout/stderr output.
4. On failure (bash not found or non-zero exit): show a fallback dialog with the command pre-filled in a copyable field.

---

## Demo Running Process Flow
Due to engine limitations, standard game scenes lack `@tool` execution and project-wide autoload singletons when instantiated directly in the editor tab (causing them to render statically or crash).
To run demos correctly, the plugin uses a process-level execution flow:
1. When clicking **"▶ Run"** in the editor plugin tab, `main.gd` writes the target path to a temporary file (`res://.preview_target.txt`) and launches the demo previewer as a separate process via `EditorInterface.play_custom_scene("res://addons/anomalyAcesAddonManager/Scenes/DemoPreviewer/demo_previewer.tscn")`.
2. The spawned player process loads `demo_previewer.tscn`, reads the target path from the file, and runs the demo scene with all game scripts, inputs, physics, and autoloads active.
3. Inside `demo_previewer.gd`, the **"← Back to Dashboard"** button checks if `AddonPreviewerOverlay.target_demo_scene == ""` (indicating it was launched in custom preview mode from the editor plugin). If so, it calls `get_tree().quit()`, closing the temporary window and returning focus cleanly back to the editor. In standalone mode (F5), it transitions back to the dashboard scene.

---

## CLI Helper Command (`ace-am`)
The `manage_addons` script is typically aliased globally as `ace-am` using:
```bash
./addons/anomalyAcesAddonManager/manage_addons setup
source ~/.bashrc # or source ~/.zshrc
```

### Core CLI Commands:
* **Add an Addon**: `ace-am add <git_repo_url> <addon_name>`
* **Remove an Addon**: `ace-am remove <addon_name>`
* **Commit Addon Changes**: `ace-am commit <addon_name> "<commit_message>"`
* **List Addons**: `ace-am list`
* **Update Addons**: `ace-am update`

---

## Linking Rules & Priority (Crucial for AI Agents)
The project uses a global **two-pass link resolution** in `manage_addons` (located at `addons/anomalyAcesAddonManager/manage_addons`) to handle naming collisions when a submodule contains nested snapshot dependencies.

### 1. Candidate Detection
For each submodule under `submodules/NAME`:
* **If `submodules/NAME/addons/` exists**: Every direct subdirectory inside is selected as a candidate (e.g. including utility folders and library folders without `plugin.cfg` files, such as `anomalyAcesLog` and `anomalyAcesUtil`).
* **If it does not exist**: The script searches for `plugin.cfg` files and selects their parent directories.
* **If no `plugin.cfg` is found anywhere**: The submodule root `submodules/NAME` is linked directly.

### 2. Classification (Primary vs. Secondary)
* **Primary / Main Addon**:
  - Any candidate folder whose name matches the submodule repository name (normalizing casing, hyphens, and underscores).
  - If a submodule only contains exactly one candidate folder, it is automatically treated as the Primary addon.
* **Secondary / Snapshot Dependency**:
  - All other candidate folders nested inside a submodule (e.g. `submodules/Anomaly-Aces-Addon-Manager/addons/anomalyAcesTable` where the folder name does not match the submodule name) are treated as Secondary.

### 3. Global Link Resolution Flow (`link_all_addons`)
Whenever addons are added, removed, or updated:
1. **Clear Links (`clear_submodule_links`)**: Active links in `addons/` pointing inside `submodules/` are unlinked.
   * *Gotcha*: To safely resolve target paths of both valid and broken links (e.g. when a submodule folder was deleted), the script uses `readlink`. It falls back to physical `pwd -P` resolution.
2. **Pass 1 (Primary Links)**: Create directory junctions/symlinks for all Primary addons. These will overwrite any collisions.
3. **Pass 2 (Secondary Links)**: Iterate through all Secondary (snapshot) addons. Create links for them **only if** the target link name does not already exist under `addons/`.

### 4. Windows Junction Execution Rules
Because Git Bash on Windows has path translation quirks when calling `cmd.exe /c`, the following environment settings and syntax must be used:
* **Creation**: `MSYS_NO_PATHCONV=1 cmd.exe /c mklink /j "$win_link" "$win_target"`
* **Removal**: `MSYS_NO_PATHCONV=1 cmd.exe /c rmdir "$win_link"`
* **No Outer Quotes**: Do not put outer quotes around the command string (e.g. avoid `cmd.exe /c "mklink ..."`), as it causes CMD to launch in interactive mode and hang.

---

## Submodule Duplication Check
To prevent checking out the exact same Git repository under different names, `cmd_add` queries `.gitmodules` using `git config` for the requested URL.
* If the URL (ignoring trailing `.git` and trailing slashes) is already registered, the script outputs a warning, triggers link validation to ensure all junctions are correct, and exits cleanly without creating a redundant submodule directory or registration entry.
