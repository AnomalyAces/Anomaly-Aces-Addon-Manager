# Ace Addon Manager Standalone Installation Guide

If you only have the `anomalyAcesAddonManager` folder, you must run the bootstrapper command *before* enabling the plugin in your Godot Project Settings. 

Because this manager depends on its companion plugins (`anomalyAcesLog`, `anomalyAcesTable`, `anomalyAcesUtil`, and `log`), enabling it prematurely will lead to Godot script compilation and resource load errors.

---

### Step 1: Copy the Addon Folder
Ensure the `anomalyAcesAddonManager` folder is placed inside your Godot project's `addons/` directory:
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
   *This command will download the ZIP archives for the 4 dependencies directly from GitHub, extract the required addon folders, and install them into your `addons/` directory.*

### Step 3: Enable the Plugin in Godot
1. Open your project in the **Godot Editor**.
2. Go to **Project -> Project Settings -> Plugins**.
3. Locate **Ace Addon Manager** and check the **Enable** checkbox.
4. The **"Addon Manager"** main screen tab will now appear at the top-center of your editor.
