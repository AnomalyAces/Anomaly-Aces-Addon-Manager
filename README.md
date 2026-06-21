# Anomaly Aces Addon Previewer

A Godot 4.7 testing sandbox designed to preview, run, and develop Godot addons in isolation or in tandem.

This project integrates addons as **git submodules** inside the `submodules/` directory. It features a Bash command-line helper to manage submodules easily and a built-in dashboard UI that dynamically scans for addons and launches their demos from the `addons/` directory using symlinks/junctions.

---

## Command Line Helper (`ap`)

A bash script `manage_addons` is provided at the root of the project. To install it as a global command/alias (`ap`) on your PC:

1. Open your Bash terminal (Git Bash, WSL, Linux, or macOS terminal).
2. Run the setup command:
   ```bash
   ./manage_addons setup
   ```
3. Restart your terminal or reload your config:
   ```bash
   source ~/.bashrc
   # Or source ~/.bash_profile depending on your OS/setup
   ```

Now you can run the `ap` command from anywhere inside the project!

### CLI Commands

* **Add an Addon**:
  ```bash
  ap add <git_repo_url> <addon_name>
  ```
  Example: `ap add https://github.com/someuser/godot-logger-plugin.git logger`
  *This downloads the addon to `submodules/logger`, detects its layout, and creates a directory junction/symlink at `addons/logger`.*

* **Remove an Addon**:
  ```bash
  ap remove <addon_name>
  ```
  Example: `ap remove logger`
  *This cleanly removes the junction/symlink under `addons/logger`, the submodule entries, and the git cache.*

* **List Active Addons**:
  ```bash
  ap list
  ```
  *Lists all installed addon submodules along with their current git commit hashes.*

* **Update Addons**:
  ```bash
  ap update
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
2. Verify they show up in the Addon Previewer UI.
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

* [submodules/](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/submodules): Directory where actual addon git submodules are placed.
* [addons/](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/addons): Directory containing dynamic junctions/links to the active submodules (used by Godot).
* [project.godot](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/project.godot): Minimal Godot 4.7 project configurations.
* [main.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/main.tscn) / [main.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/main.gd): Sleek Godot 4.7 dashboard UI that lists addons, handles live-filtering/search, and launches demos.
* [addon_card.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/addon_card.tscn) / [addon_card.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/addon_card.gd): Addon list item visual card representation.
* [addon_previewer_overlay.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/addon_previewer_overlay.gd): Auto-loaded script creating a floating "← Back to Dashboard" button when playing addon demo scenes.
* [manage_addons](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/manage_addons) (Bash CLI helper): Command interface to add/remove/list/update submodules.
