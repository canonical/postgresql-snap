#!/bin/bash

NAME=$1
ACTION=$2

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)

# Update cluster env's LD PATH
"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- sed -i "s#LD_LIBRARY_PATH='.*'#LD_LIBRARY_PATH='$LD_LIBRARY_PATH'#g" "$SNAP_DATA/etc/postgresql/$PG_MAJOR_VER/$NAME/environment"

"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_ctlcluster --skip-systemctl-redirect --foreground "$PG_MAJOR_VER" "$NAME" "$ACTION"
