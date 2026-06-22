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

> **SSH Required** — All git operations use SSH authentication. Before using `ap`, make sure you have an SSH key configured for GitHub (or your git host). HTTPS URLs are not accepted. See [GitHub's SSH guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) if you need to set one up.

### CLI Commands

* **Add an Addon**:
  ```bash
  ap add <ssh_git_url> <addon_name>
  ```
  Example: `ap add git@github.com:someuser/godot-logger-plugin.git logger`
  *This downloads the addon to `submodules/logger`, detects its layout, and creates a directory junction/symlink at `addons/logger`. Only SSH URLs are accepted — HTTPS will be rejected with an error showing the correct SSH equivalent.*

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

* **Commit & Push Changes in a Submodule**:
  ```bash
  ap commit <addon_name> "<commit message>"
  ```
  Example: `ap commit logger "Add demo scene for previewing features"`
  *Stages all changes inside `submodules/<addon_name>`, commits with the given message, and pushes to the addon's upstream remote. Use this to contribute changes back to the addon's own repository without manually `cd`-ing into it.*

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

* [submodules/](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/submodules): Directory where actual addon git submodules are placed. Contains a `.gdignore` so Godot skips indexing these source repos directly.
* [addons/](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/addons): Directory containing dynamic junctions/symlinks to the active submodules (used by Godot).
* [project.godot](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/project.godot): Minimal Godot 4.7 project configuration.
* [Scenes/Main/main.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/Scenes/Main/main.tscn) / [main.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/Scenes/Main/main.gd): Dashboard UI that lists addons, handles live-filtering/search, and launches demo scenes.
* [Scenes/AddonCard/addon_card.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/Scenes/AddonCard/addon_card.tscn) / [addon_card.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/Scenes/AddonCard/addon_card.gd): Visual card component representing each addon in the dashboard list.
* [Scenes/DemoPreviewer/demo_previewer.tscn](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/Scenes/DemoPreviewer/demo_previewer.tscn) / [demo_previewer.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/Scenes/DemoPreviewer/demo_previewer.gd): Launches addon demo scenes as a full game process via `EditorInterface.play_custom_scene()` with a "← Back to Previewer" overlay button.
* [addon_previewer_overlay.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/addon_previewer_overlay.gd): Auto-loaded script that creates a floating "← Back to Previewer" button when a demo scene is running as a game process.
* [manage_addons](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Addon-Previewer/manage_addons) (Bash CLI helper): Command interface to add, remove, commit, list, and update submodules. Install with `./manage_addons setup` to use the `ap` shorthand.
