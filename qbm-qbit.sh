#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    source ".env"
fi

# Use environment variables with descriptive default values
LOCK=${QBIT_MANAGE_LOCK_FILE_PATH:-/var/lock/qbm-qbit.lock}
PATH_QBM=${QBIT_MANAGE_PATH:-/opt/qbit-manage}
VENV_PATH=${QBIT_MANAGE_VENV_PATH:-/opt/qbit-manage/.venv}
CONFIG_PATH=${QBIT_MANAGE_CONFIG_PATH:-/opt/qbit-manage/config.yml}
QBIT_OPTIONS=${QBIT_MANAGE_OPTIONS:-"-cs -re -cu -tu -ru -sl -r"}

# Function to remove the lock file
remove_lock() {
    rm -f "$LOCK"
}

# Function to handle detection of another running instance
another_instance() {
    echo "There is another instance running, exiting."
    exit 1
}

# Acquire a lock to prevent concurrent execution, with a timeout and lease time
lockfile -r 0 -l 3600 "$LOCK" || another_instance

# Ensure the lock is removed when the script exits
trap remove_lock EXIT

# Pause the script to wait for any pending operations (demonstrative purpose)
sleep 600

# Execute qbit_manage with configurable options
"$VENV_PATH"/bin/python "$PATH_QBM"/qbit_manage.py "$QBIT_OPTIONS" --config-file "$CONFIG_PATH"
