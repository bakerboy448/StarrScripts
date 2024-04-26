#!/bin/bash

# Check if lockfile command exists
if ! command -v lockfile &>/dev/null; then
    echo "Error: lockfile command not found. Please install the procmail package." >&2
    exit 1
fi

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    source ".env"
fi

# Use environment variables with descriptive default values
QBQBM_LOCK=${QBIT_MANAGE_LOCK_FILE_PATH:-/var/lock/qbm-qbit.lock}
QBQBM_PATH_QBM=${QBIT_MANAGE_PATH:-/opt/qbit-manage}
QBQBM_VENV_PATH=${QBIT_MANAGE_VENV_PATH:-/opt/qbit-manage/.venv}
QBQBM_CONFIG_PATH=${QBIT_MANAGE_CONFIG_PATH:-/opt/qbit-manage/config.yml}
QBQBM_QBIT_OPTIONS=${QBIT_MANAGE_OPTIONS:-"-cs -re -cu -tu -ru -sl -r"}
QBQBM_SLEEP_TIME=600
QBQBM_LOCK_TIME=3600

# Function to remove the lock file
remove_lock() {
    rm -f "$LOCK"
}

# Function to handle detection of another running instance
another_instance() {
    echo "There is another instance running, exiting."
    exit 1
}

echo "Acquiring Lock"
# Acquire a lock to prevent concurrent execution, with a timeout and lease time
lockfile -r 0 -l "$QBQBM_SLEEP_TIME" "$QBQBM_LOCK" || another_instance

# Ensure the lock is removed when the script exits
trap remove_lock EXIT

echo "sleeping for $QBQBM_SLEEP_TIME"
# Pause the script to wait for any pending operations (i.e. Starr Imports)

sleep $QBQBM_SLEEP_TIME

# Execute qbit_manage with configurable options
echo "Executing Command"
"$VENV_PATH"/bin/python "$PATH_QBM"/qbit_manage.py "$QBIT_OPTIONS" --config-file "$CONFIG_PATH"
