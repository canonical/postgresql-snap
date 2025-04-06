#!/bin/bash

NAME=$1

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)

# "$SNAP/ctl-cluster.sh" main start
"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_ctlcluster --skip-systemctl-redirect --foreground "$PG_MAJOR_VER" "$NAME" start
