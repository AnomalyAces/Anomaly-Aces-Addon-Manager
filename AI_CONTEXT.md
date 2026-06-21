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
* **`project.godot`**: Godot 4.7 project settings.
* **`main.tscn` / `main.gd`**: The dashboard scene. It dynamically scans `res://addons/` for `plugin.cfg` files and recursively searches for scenes containing `demo`, `test`, `example`, or `preview` in their names to render cards.
* **`addon_card.tscn` / `addon_card.gd`**: Render card component for detected addons and their demos.
* **`addon_previewer_overlay.gd`**: Autoloaded helper that overlays a floating **← Back to Dashboard** button on all scenes except the dashboard itself, allowing seamless demo testing.
* **`manage_addons`**: A Bash CLI helper script.
* **`.vscode/settings.json`**: Configures VS Code workspace settings to exclude `submodules/` from global searches and filesystem watching (`files.watcherExclude`), keeping the folder visible in the explorer sidebar while preventing duplicate class parsing diagnostics.

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
  * Any candidate folder whose name matches the submodule repository name (normalizing casing, hyphens, and underscores).
  * If a submodule only contains exactly one candidate folder, it is automatically treated as the Primary addon.
* **Secondary / Snapshot Dependency**:
  * All other candidate folders nested inside a submodule (e.g. `submodules/Anomaly-Aces-Addon-Manager/addons/anomalyAcesTable` where the folder name does not match the submodule name) are treated as Secondary.

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
