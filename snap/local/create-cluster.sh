#!/bin/bash

NAME=$1

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)

"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_createcluster -u _daemon_ -g root --start-conf=manual "$PG_MAJOR_VER" "$NAME"

# Inject LD_LIBRARY_PATH in the env file
echo "LD_LIBRARY_PATH='$LD_LIBRARY_PATH'" | "$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- tee -a  "$SNAP_DATA/etc/postgresql/$PG_MAJOR_VER/$NAME/environment"
