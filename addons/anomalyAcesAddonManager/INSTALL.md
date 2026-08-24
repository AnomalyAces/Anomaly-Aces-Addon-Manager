# Ace Addon Manager Standalone Installation Guide

If you copy only the `anomalyAcesAddonManager` folder directly into an existing Godot project:

1. **Automatic Error Suppression**: The folder ships with temporary `.gdignore` files inside the `Scripts/` and `Scenes/` subdirectories. This tells Godot to ignore those script/scene directories on startup, suppressing compilation or class-not-found errors before your dependencies are ready, while keeping `INSTALL.md` and basic metadata visible.
2. **Recursive Resolution**: The bootstrapper parses the manager's `addons.json` and recursively downloads and resolves the entire dependency tree (including `anomalyAcesLog`, `anomalyAcesTable`, `anomalyAcesUtil`, and sub-dependencies like `log`) directly from GitHub.
3. **Activation**: Running the bootstrap command automatically deletes the `.gdignore` files so Godot can safely scan, compile, and register the plugin.

---

### Step 1: Copy the Addon Folder
Place the `anomalyAcesAddonManager` folder inside your Godot project's `addons/` directory:
```
your-godot-project/
├── addons/
│   └── anomalyAcesAddonManager/
└── project.godot
```

### Step 2: Run the Bootstrapper CLI Command
1. Open a Bash-compatible terminal (Git Bash on Windows, WSL, Linux, or macOS terminal) and navigate to your Godot project's root folder.
2. Run the bootstrap command:
   ```bash
   ./addons/anomalyAcesAddonManager/manage_addons bootstrap
   ```
   *This command will dynamically download and resolve all dependencies listed in the addons.json files directly from GitHub, install them under `addons/`, and remove the temporary `.gdignore` files.*

### Step 3: Enable the Plugin in Godot
1. Open your project in the **Godot Editor**.
2. Go to **Project -> Project Settings -> Plugins**.
3. Locate **Ace Addon Manager** (which is now visible and compiled cleanly) and check the **Enable** checkbox.
4. The **"Addon Manager"** main screen tab will now appear at the top-center of your editor.

---

### Tracking and Managing Custom Dependencies

If you have custom addons or asset libraries inside your project, you can add an `addons.json` file to their folder so that their dependencies are automatically tracked and installed by the bootstrapper:

1. **Via the Editor UI**: Open the Addon Manager dashboard, click **"Edit Dependencies"** on the addon card, configure your dependency list, and click **"Save addons.json"**.
2. **Via Manual File Creation**: Create a file named `addons.json` in the root of the addon folder (e.g., `res://addons/my_custom_addon/addons.json`) and configure its dependencies in standard JSON format:
   ```json
   [
     {
       "repo": "Anomaly-Aces-Util",
       "subfolder": "addons/anomalyAcesUtil",
       "owner": "anomalyaces",
       "branch": "master",
       "isRelease": false,
       "version": "1.0",
       "dependencies": []
     }
   ]
   ```

The CLI bootstrapper (`manage_addons bootstrap`) scans all folders under `addons/` recursively for `addons.json` files, meaning any dependencies defined this way will be automatically resolved and installed during a bootstrap or update.
