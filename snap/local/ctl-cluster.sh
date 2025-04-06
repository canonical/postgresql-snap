#!/bin/bash

NAME=$1
ACTION=$2

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)

"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_ctlcluster --skip-systemctl-redirect --foreground "$PG_MAJOR_VER" "$NAME" "$ACTION"
