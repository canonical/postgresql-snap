#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]
  then echo "Need to be root to switch to snap _daemon_ user."
  exit
fi

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)

# Update cluster env's LD PATH
"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- sed -i "s#LD_LIBRARY_PATH='.*'#LD_LIBRARY_PATH='$LD_LIBRARY_PATH'#g" "$SNAP_DATA/etc/postgresql/$PG_MAJOR_VER/$NAME/environment" || true

"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_ctlcluster "$@"
