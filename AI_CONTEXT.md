# AI Context & Developer Guide

This file provides context for AI coding assistants (and developers) working on the **Anomaly Aces Addon Previewer** project. It outlines the project structure, design decisions, CLI commands, and rules for managing addon submodules and links.

---

## Project Overview
The Anomaly Aces Addon Previewer is a Godot 4.7 testing sandbox designed to preview, run, and develop Godot addons in isolation or in tandem.
Instead of copying addon folders into the project, addons are registered as **git submodules** under `submodules/` and linked dynamically into the standard `addons/` directory.

---

## Directory Structure
* **`submodules/`**: Contains the raw cloned git submodules of the addons.
  * Contains a `.gdignore` file to prevent Godot from scanning and importing files inside this folder, avoiding resource duplication conflicts.
* **`addons/`**: Contains Windows directory junctions or Unix symlinks pointing to the active plugins inside `submodules/`. This is where Godot scans for addons.
* **`addons/aceAddonPreviewer/`**: The native editor plugin integration directory.
  * **`plugin.cfg`**: Declares the "Ace Addon Previewer" plugin.
  * **`aceAddonPreviewer.gd`**: The plugin bootstrap script that adds the **Ace Previewer** main screen tab. Dynamically downscales the SVG icon (`AceAddonPreviewer.svg`) using Lanczos filtering to match native editor scales (`16 * scale`).
* **`Scenes/`**: Dedicated subfolder containing the application visual components and layouts:
  * **`Scenes/Main/`**: Main dashboard view (`main.tscn` / `main.gd`). It dynamically scans `res://addons/` for `plugin.cfg` files. It also references the unified SVG icon file `AceAddonPreviewer.svg`.
  * **`Scenes/AddonCard/`**: Render card component (`addon_card.tscn` / `addon_card.gd`) showing details, run button, and live status toggle.
  * **`Scenes/DemoPreviewer/`**: The standalone demo player container (`demo_previewer.tscn` / `demo_previewer.gd`).
* **`project.godot`**: Godot 4.7 project settings.
* **`addon_previewer_overlay.gd`**: Autoloaded helper that overlays a floating **← Back to Dashboard** button on all scenes except the dashboard itself when running in standalone mode.
* **`manage_addons`**: A Bash CLI helper script.
* **`.vscode/settings.json`**: Configures VS Code workspace settings to exclude `submodules/` from global searches and filesystem watching.

---

## Editor Plugin & Dashboard Integration
The dashboard and the addon manager are fully integrated inside the Godot Editor as native Main Screen tabs:
* **Ace Previewer Tab**: Exposes the addon testing dashboard.
  * **Instant Addon Toggling**: When running in the editor, toggling the status switch on an addon card calls `EditorInterface.set_plugin_enabled()` directly. This instantly activates or deactivates the addon in the editor workspace tree without needing an editor restart.
  * **Standalone Fallback**: When the dashboard is run as a standalone game, toggling an addon card updates and saves the settings in `project.godot` and ProjectSettings memory directly.
* **Ace Manager Tab**: Exposes the **Ace Addon Manager** layout inside the editor, replacing the legacy window popup. It dynamically fetches installed addons on tab click and supports complete viewport sizing.

---

## High-DPI Scaling & Theme Gotchas
To support responsive UI scaling in the editor plugin at any display scale, the dashboard implements dynamic scaling via `EditorInterface.get_editor_scale()`:

### 1. The Serialization Gotcha (Crucial!)
Because dashboard scripts are marked with `@tool`, their `_ready()` functions run inside the Godot Editor workspace tree when editing them. If layout modifications are applied automatically on `_ready()`, they will modify the editor's tree and get **serialized back to the `.tscn` file** when saving the scene.
* **Rule**: Only trigger layout and font scaling if `plugin_ref` is NOT `null`. When scenes are opened for editing in the editor, `plugin_ref` is `null`, ensuring properties remain at their clean, unscaled base values.
* **Addon Cards**: Since addon cards are instantiated dynamically via code, they are scaled dynamically when `set_addon_details(..., scale)` is called by the parent main screen script.

### 2. Differentiated Font Scaling
Dynamically instantiated controls (like the demo run buttons) inherit standard editor theme settings which are already scaled by the Godot Editor.
* **Rule**: To prevent double-scaling default fonts, `_apply_editor_scaling` must **only** scale font sizes that have an explicit override set in the scene (by checking `node.has_theme_font_size_override("font_size")`).

---

## Demo Running Process Flow
Due to engine limitations, standard game scenes lack `@tool` execution and project-wide autoload singletons when instantiated directly in the editor tab (causing them to render statically or crash).
To run demos correctly, the plugin uses a process-level execution flow:
1. When clicking **"▶ Run"** in the editor plugin tab, `main.gd` writes the target path to a temporary file (`res://.preview_target.txt`) and launches the demo previewer as a separate process via `EditorInterface.play_custom_scene("res://Scenes/DemoPreviewer/demo_previewer.tscn")`.
2. The spawned player process loads `demo_previewer.tscn`, reads the target path from the file, and runs the demo scene with all game scripts, inputs, physics, and autoloads active.
3. Inside `demo_previewer.gd`, the **"← Back to Dashboard"** button checks if `AddonPreviewerOverlay.target_demo_scene == ""` (indicating it was launched in custom preview mode from the editor plugin). If so, it calls `get_tree().quit()`, closing the temporary window and returning focus cleanly back to the editor. In standalone mode (F5), it transitions back to the dashboard scene.

---

## CLI Helper Command (`ap`)
The `manage_addons` script is typically aliased globally as `ap` using:
```bash
./manage_addons setup
source ~/.bashrc # or source ~/.zshrc
```

### Core CLI Commands:
* **Add an Addon**: `ap add <git_repo_url> <addon_name>`
* **Remove an Addon**: `ap remove <addon_name>`
* **Commit Addon Changes**: `ap commit <addon_name> "<commit_message>"`
* **List Addons**: `ap list`
* **Update Addons**: `ap update`

---

## Linking Rules & Priority (Crucial for AI Agents)
The project uses a global **two-pass link resolution** in `manage_addons` to handle naming collisions when a submodule contains nested snapshot dependencies.

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
