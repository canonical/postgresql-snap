#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]
  then echo "Need to be root to switch to snap _daemon_ user."
  exit
fi

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)
NAME=$2

if [ "$PG_MAJOR_VER" -ne "$1" ]
  then echo "Cannot create $1 cluster on $PG_MAJOR_VER snap."
  exit
fi

# TODO figure out local-auth
"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_createcluster -u _daemon_ -g root --start-conf=manual "$PG_MAJOR_VER" "$NAME" -- --auth-local=trust --auth-host=scram-sha-256 -U postgres

# Inject LD_LIBRARY_PATH in the env file
echo "LD_LIBRARY_PATH='$LD_LIBRARY_PATH'" | "$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- tee -a  "$SNAP_COMMON/etc/postgresql/$PG_MAJOR_VER/$NAME/environment"

echo "The cluster can be started with: 'postgresql.ctlcluster --skip-systemctl-redirect --foreground $PG_MAJOR_VER $NAME start'"
