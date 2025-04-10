#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]
  then echo "Need to be root to switch to snap _daemon_ user."
  exit
fi

"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_renamecluster "$@"
