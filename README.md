# StarrScripts

A curated collection of scripts to optimize and manage various functions related to Starr applications and associated tools.
Occasionally holds random useful scripts as well.
These scripts are designed to enhance functionality, improve management, and automate routine tasks.
All scripts are **Created By: [Bakerboy448](https://github.com/bakerboy448/) unless otherwise noted.**

**Warning**: Do not edit files on Windows that will be executed on Linux without ensuring the line-endings are set to `LF`.
This means that `CRLF` cannot be used in .sh scripts. Bash scripts will not execute properly and you will receive an
error.

## Scripts Overview

### qui Cross-Seed Trigger for Starr Apps

-   **Script:** `qui-xseed.sh`
-   **Description:** Triggers a [qui](https://github.com/qui-lern/qui) data-based cross-seed search when Radarr or Sonarr completes an import. The script creates a dir-scan entry in qui, triggers a scan, polls for completion, then cleans up.
-   **Creator:** [Bakerboy448](https://github.com/bakerboy448/)
-   **Requirements:**
    -   [qui](https://github.com/qui-lern/qui) with API access enabled
    -   Radarr/Sonarr with Custom Script connect support
-   **Instructions:**
    1. Copy `.env.sample` to `.env` and configure the `QUI_*` variables.
    2. Docker Users: Mount `.env` and `qui-xseed.sh` to your Starr's `/config` mount.
    3. In Radarr: `Settings` -> `Connect` -> `Custom Script` -> select "On Import" and "On Upgrade".
    4. In Sonarr: `Settings` -> `Connect` -> `Custom Script` -> select "On Import Complete".
    5. Test and Save.
-   **Configuration (`.env`):**
    -   `QUI_HOST` - qui hostname (default: `localhost`)
    -   `QUI_PORT` - qui API port (default: `7476`)
    -   `QUI_APIKEY` - qui API key
    -   `QUI_TARGET_INSTANCE_ID` - qui instance ID (default: `1`)
    -   `QUI_QBIT_PATH_PREFIX` - optional path prefix for qBittorrent
    -   `QUI_TAGS` - optional comma-separated tags
    -   `TORRENT_CLIENTS` - comma-separated torrent client names (default: `qBittorrent`)
    -   `USENET_CLIENTS` - comma-separated usenet client names (default: `SABnzbd`)
    -   `LOG_FILE` - log file path (default: `./qui_xseed.log`)
-   **Notes:**
    -   Only errors are written to stderr (which starr apps capture). All other logging goes to the log file only, to avoid noisy notifications.
    -   The script is idempotent — duplicate download IDs are skipped via the ID log file.
    -   Replaces the legacy `xseed.sh` (removed in v4.0.0) which used the cross-seed API directly.

### Duplicate File Manager

-   **Script:** `dupe.sh`
-   **Description:** Executes `jdupes` to find and manage duplicate files in the specified directory.
-   **Instructions:**
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
-   **Instructions:**
    1. Update `source_dirs` and uncomment the variable
    2. Update `target_dir` and uncomment the variable
    3. Uncomment `atomic_moves` to engage the movement operation
    4. Run the script with `python3 merge_folders.py`

### Plex Image Cleanup Updater

-   **Script:** `pic-update.sh`
-   **Description:** Updates [Plex-Image-Cleanup](https://github.com/meisnate12/Plex-Image-Cleanup) to the latest branch.
-   **Review:** Check that script parameters are suitable for your environment.

### Plex Meta Manager Updater

-   **Script:** `pmm-update.sh`
-   **Description:** Updates [Plex Meta Manager](https://github.com/meisnate12/Plex-Meta-Manager) to the latest branch.
-   **Review:** Confirm script parameters align with your configuration.

### QbitManage API Trigger

-   **Script:** `qbm-api-trigger.sh`
-   **Description:** Triggers [QbitManage](https://github.com/StuffAnThings/qbit_manage) commands via Web API for specific torrent hashes.
-   **Requirements:**
    -   QbitManage v4.5+ with Web API enabled (`QBT_WEB_SERVER=true`)
    -   QbitManage container accessible via HTTP
-   **Instructions:**
    1. Configure QbitManage Web API in your docker-compose.yml
    2. In qBittorrent, navigate to `Options` -> `Downloads` -> `Run external program on torrent completion`
    3. Add command: `/path/to/qbm-api-trigger.sh %I`
    4. The `%I` variable passes the torrent hash to trigger commands like `tag_update`, `share_limits`, `rem_unregistered`, and `recheck`
-   **Notes:**
    -   Script sends POST request to `http://127.0.0.1:4269/api/run-command` by default
    -   Modify `API_URL` and `COMMANDS` variables in script to customize behavior
    -   All execution details logged to `run_qbit_manage_commands.log`

### QbitManage Updater

-   **Script:** `qbm-update.sh`
-   **Description:** Updates [QbitManage](https://github.com/StuffAnThings/qbit_manage) to the latest branch.
-   **Review:** Ensure script parameters match your setup before execution.

### Servarr Bot Merger

-   **Script:** `servarr/servarr_bot_merge.sh`
-   **Description:** Merges the latest changes from the Servarr Wiki Bot Branch into the Prowlarr Indexers Wiki Master.

### Backup Config

-   **Script:** `backup_config.sh`
-   **Description:** Backs up configuration directories to a compressed archive.

### Fail2ban Config Dump

-   **Script:** `f2b-dump.sh`
-   **Description:** Dumps Fail2ban configuration details to a temporary file for review.

### Omegabrr Updater

-   **Script:** `omegabrr_upgrade.sh`
-   **Description:** Upgrades [Omegabrr](https://github.com/autobrr/omegabrr) to the latest version.

### Radarr Duplicate Finder

-   **Script:** `radarr_dupefinder.sh`
-   **Description:** Finds duplicate files in Radarr library directories.

### Sonarr Duplicate Finder

-   **Script:** `sonarr_dupefinder.sh`
-   **Description:** Finds duplicate files in Sonarr library directories.

### ZFS Snapshot Cleanup

-   **Script:** `zfsburn.sh`
-   **Description:** Deletes ZFS autosnapshots older than a specified number of days.
-   **Instructions:**
    1. Copy `.env.sample` to `.env`.
    2. Fill in the required values under "# ZFS Destroy" header.

## Contributions

Contributions to improve or expand the scripts collection are welcome. Please refer to the [contribution guidelines](https://github.com/baker-scripts/StarrScripts/blob/main/CONTRIBUTING.md) for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/baker-scripts/StarrScripts/blob/main/LICENSE) file for details.
