# Anomaly Aces Addon Manager

A Godot 4.7 testing sandbox designed to preview, run, and develop Godot addons in isolation or in tandem.

This project integrates addons as **git submodules** inside the `submodules/` directory. It features a built-in dashboard UI that dynamically scans for addons and launches their demos from the `addons/` directory using symlinks/junctions, and a Bash command-line helper to manage submodules easily.

---

## How to Use the UI

The **Addon Manager** is a custom Godot editor interface that allows you to manage and test addons directly inside the Godot Editor.

### 1. Opening the UI
- Open the project in the **Godot Editor**.
- Go to **Project -> Project Settings -> Plugins** and ensure the **Ace Addon Manager** plugin is checked/enabled.
- Once enabled, a new **"Addon Manager"** main screen tab will appear at the top-center of the editor (alongside 2D, 3D, Script, and AssetLib).
- *Alternatively*, you can run the standalone scene [main.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn) directly to run the manager as a game window.

### 2. Main Dashboard Features
- **Search & Live Filtering**: Use the search bar at the top-right to instantly search through your active addons by name, developer, description, or folder.
- **Enable/Disable Addons**: Toggle the checkbox on any addon card to instantly enable or disable it within the project.
- **Available Demos**: View a list of detected demo, test, and example scenes for each addon. Click any demo button to launch it. A floating overlay button "← Back to Manager" will appear to return you to the dashboard when finished.
- **Manage Dependencies**: Click the **⚙ Edit Dependencies** button on any card to view and manage required dependencies inside the local `addons.json`.
- **Ignore List**: Click the **Ignore List** button in the header to hide specific subfolders. You can check the toggle to safely remove their directory junction/symlink from `res://addons/` as well.

### 3. Addon Updater View
Click the **Addon Updater** button in the top-right header to switch to the updater view:
- **Check for Updates**: Scans remote repositories to identify updates and potential version conflicts.
- **GitHub Personal Access Token**: Click this button to securely add or verify your GitHub PAT, preventing API rate-limiting issues when downloading remote releases.
- **Install Updates**: Select the updates you wish to retrieve and click **Install** to dynamically download, extract, and configure them.

---

## Command Line Helper (`ace-am`)

A bash script `manage_addons` is provided in the `addons/anomalyAcesAddonManager/` directory. To install it as a global command/alias (`ace-am`) on your PC:

1. Open your Bash terminal (Git Bash, WSL, Linux, or macOS terminal).
2. Run the setup command:
   ```bash
   ./addons/anomalyAcesAddonManager/manage_addons setup
   ```
3. Restart your terminal or reload your config:
   ```bash
   source ~/.bashrc
   # Or source ~/.bash_profile depending on your OS/setup
   ```

Now you can run the `ace-am` command from anywhere inside the project!

> **SSH Required** — All git operations use SSH authentication. Before using `ace-am`, make sure you have an SSH key configured for GitHub (or your git host). HTTPS URLs are not accepted. See [GitHub's SSH guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) if you need to set one up.

### CLI Commands

* **Add an Addon**:
  ```bash
  ace-am add <ssh_git_url> <addon_name>
  ```
  Example: `ace-am add git@github.com:someuser/godot-logger-plugin.git logger`
  *This downloads the addon to `submodules/logger`, detects its layout, and creates a directory junction/symlink at `addons/logger`. Only SSH URLs are accepted — HTTPS will be rejected with an error showing the correct SSH equivalent.*

* **Remove an Addon**:
  ```bash
  ace-am remove <addon_name>
  ```
  Example: `ace-am remove logger`
  *This cleanly removes the junction/symlink under `addons/logger`, the submodule entries, and the git cache.*

* **List Active Addons**:
  ```bash
  ace-am list
  ```
  *Lists all installed addon submodules along with their current git commit hashes.*

* **Commit & Push Changes in a Submodule**:
  ```bash
  ace-am commit <addon_name> "<commit message>"
  ```
  Example: `ace-am commit logger "Add demo scene for previewing features"`
  *Stages all changes inside `submodules/<addon_name>`, commits with the given message, and pushes to the addon's upstream remote. Use this to contribute changes back to the addon's own repository without manually `cd`-ing into it.*

* **Update Addons**:
  ```bash
  ace-am update
  ```
  *Fetches and checks out the latest remote commits for all installed addon submodules, and verifies linking.*

---

## Creating and Contributing Demos

The dashboard scan is dynamic:
1. It reads `plugin.cfg` inside each directory under `addons/`.
2. It recursively scans the addon's directory for scene files (`.tscn`) containing `demo`, `test`, `example`, or `preview` in their names.
3. It renders a card on the dashboard list, automatically listing buttons to run these scenes.

### Contributing Demos Back to Original Addons
Because submodules are independent git repositories nested in this project under `submodules/`:
1. Create your demo scenes directly inside the addon's folder (e.g. `submodules/logger/demo/demo_logger.tscn`).
2. Verify they show up in the Addon Manager UI.
3. Open a terminal and `cd` into the addon's directory:
   ```bash
   cd submodules/logger
   ```
4. Commit and push your changes directly to the addon's original remote repository:
   ```bash
   git add .
   git commit -m "Add demo scene for previewing features"
   git push origin main
   ```
   *This ensures any testing work or demo scene improvements are contributed back upstream for others to use.*

---

## Project Structure

* [submodules/](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/submodules): Directory where actual addon git submodules are placed. Contains a `.gdignore` so Godot skips indexing these source repos directly.
* [addons/](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/addons): Directory containing dynamic junctions/symlinks to the active submodules (used by Godot).
* [project.godot](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/project.godot): Minimal Godot 4.7 project configuration.
* [Scenes/Main/main.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/Scenes/Main/main.tscn) / [main.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/Scenes/Main/main.gd): Dashboard UI that lists addons, handles live-filtering/search, and launches demo scenes.
* [Scenes/AddonCard/addon_card.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/Scenes/AddonCard/addon_card.tscn) / [addon_card.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/Scenes/AddonCard/addon_card.gd): Visual card component representing each addon in the dashboard list.
* [Scenes/DemoPreviewer/demo_previewer.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/Scenes/DemoPreviewer/demo_previewer.tscn) / [demo_previewer.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/Scenes/DemoPreviewer/demo_previewer.gd): Launches addon demo scenes as a full game process via `EditorInterface.play_custom_scene()` with a "← Back to Manager" overlay button.
* [addon_previewer_overlay.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/addon_previewer_overlay.gd): Auto-loaded script that creates a floating "← Back to Manager" button when a demo scene is running as a game process.
* [manage_addons](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Manager/addons/anomalyAcesAddonManager/manage_addons) (Bash CLI helper): Command interface to add, remove, commit, list, and update submodules. Install with `./addons/anomalyAcesAddonManager/manage_addons setup` to use the `ace-am` shorthand.
