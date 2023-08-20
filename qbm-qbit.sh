#!/bin/bash
LOCK=/var/lock/qbm-qbit.lock
PATH_QBM=/opt/QbitManage
remove_lock() {
    rm -f "$LOCK"
}
another_instance() {
    echo "There is another instance running, exiting"
    exit 1
}
lockfile -r 0 -l 3600 "$LOCK" || another_instance
trap remove_lock EXIT
sleep 60
# -cs = cross-seed
# -re = recheck
# -cu = cat-update
# -tu = tag-update
# -ru = remove unregistered
# Do not remove orphaned torrents as imports may be in-progress
"$PATH_QBM"/qbit-venv/bin/python "$PATH_QBM"/qbit_manage.py -cs -re -cu -tu -ru -r --config-file /data/media/.config/QbitMngr/config.yml
