# StarrScripts

A curated collection of scripts to optimize and manage various functions related to Starr applications and associated tools.
Occasionally holds random useful scripts as well.
These scripts are designed to enhance functionality, improve management, and automate routine tasks.
All scripts are **Created By: [Bakerboy448](https://github.com/bakerboy448/) unless otherwise noted.**

## Scripts Overview

### Cross-Seed Category Filter for Qbittorrent

-   **Script:** `xseed_qbit_cat_filter.sh`
-   **Description:** Filters cross-seed requests by categories or trackers for execution by Qbittorrent.
-   **Creator:** [zakkarry](https://github.com/zakkarry)
-   **Usage:** Execute the script to filter categories or trackers as needed in Qbittorrent setups.

### Cross-Seed Trigger for Starr Apps

-   **Script:** `xseed.sh`
-   **Description:** Triggers a cross-seed search post-import or post-upgrade in Starr applications.
-   **Creator:** [Bakerboy448](https://github.com/bakerboy448/) with assistance from [zakkarry](https://github.com/zakkarry)
- **Setup**
    1. Copy `.env.sample` to `.env`.
    2. Populate required values under "# Xseed" header.
    3. Docker Users: Mount `.env` and `xseed.sh` to your Starr's `/config` mount.

### Cross-Seed Updater

-   **Script:** `xseed-update.sh`
-   **Description:** Updates the [Cross-Seed](https://github.com/cross-seed/cross-seed) tool to its latest version.

### Duplicate File Manager

-   **Script:** `dupe.sh`
-   **Description:** Executes `jdupes` to find and manage duplicate files in the specified directory.
-   **Setup:**
    1. Copy `.env.sample` to `.env`.
    2. Populate required values under "# Jdupes" header.
    3. Review and adjust script parameters to fit your use case.
-   **Output:** Results are saved to a file as specified in the script.

### Merge Folders Utility

-   **Script:** `merge_folders.py`
-   **Description:** A robust utility designed for merging multiple directories into a single target directory, ensuring that no existing files are overwritten in the process. This script uses a recursive function to efficiently merge content, while providing detailed logging of each step to monitor the creation, movement, and skipping of files and directories.
-   **Features:**
    -   **Recursive Merging:** Seamlessly combines contents of source directories into a target directory.
    -   **Non-destructive:** Preserves existing files by not overwriting them.
    -   **Error Handling:** Captures and logs errors during the merging process, ensuring reliable operations.
    -   **Detailed Logging:** Tracks and logs every file and directory operation, providing clear visibility into the process.
-   **Usage Case:** Ideal for consolidating data in scenarios like organizing media libraries, merging data backups, or simplifying file system structures.
-   **Setup:**
    1. Update `source_dirs` and uncomment the variable
    2. Update `target_dir` and uncomment the variable
    3. Uncomment `atomic_moves` to engage the movement operation
    4. Run the script with `python3 merge_folders.py`

### Notifiarr Branch Builder

-   **Script:** `notifiarr-branch-builder.sh`
-   **Description:** Reinstalls [Notifiarr](https://github.com/Notifiarr/notifiarr) and allows selection of the installation branch, from apt or built from source.
-   **Review:** Validate script parameters to ensure compatibility with your system.

### Plex Image Cleanup Updater

-   **Script:** `pic-update.sh`
-   **Description:** Updates [Plex-Image-Cleanup](https://github.com/meisnate12/Plex-Image-Cleanup) to the latest branch.
-   **Review:** Check that script parameters are suitable for your environment.

### Plex Meta Manager Updater

-   **Script:** `pmm-update.sh`
-   **Description:** Updates [Plex Meta Manager](https://github.com/meisnate12/Plex-Meta-Manager) to the latest branch.
-   **Review:** Confirm script parameters align with your configuration.

### Qbittorrent Management Trigger

-   **Script:** `qbm-qbit.sh`
-   **Description:** Executes [QbitManage](https://github.com/StuffAnThings/qbit_manage) upon download completion in Qbittorrent.
-   **Setup:**
    1. Copy `.env.sample` to `.env`.
    2. Populate required values under "# Qbittorrent Manage" header.

### QbitManage Updater

-   **Script:** `qbm-update.sh`
-   **Description:** Updates [QbitManage](https://github.com/StuffAnThings/qbit_manage) to the latest branch.
-   **Review:** Ensure script parameters match your setup before execution.

### Servarr Bot Merger

-   **Script:** `servarr/servarr_bot_merge.sh`
-   **Description:** Merges the latest changes from the Servarr Wiki Bot Branch into the Prowlarr Indexers Wiki Master.

### ZFS Snapshot Cleanup

-   **Script:** `zfsburn.sh`
-   **Description:** Deletes ZFS autosnapshots older than a specified number of days.
-   **Setup:**
    1. Copy `.env.sample` to `.env`.
    2. Fill in the required values under "# ZFS Destroy" header.

## Contributions

Contributions to improve or expand the scripts collection are welcome. Please refer to the [contribution guidelines](https://github.com/bakerboy448/StarrScripts/blob/main/CONTRIBUTING.md) for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/bakerboy448/StarrScripts/blob/main/LICENSE) file for details.
