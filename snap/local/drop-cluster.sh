#!/bin/bash
set -e

if [ "${EUID}" != "0" ]; then
  echo "Error: run it as root (to utilize snap user _daemon_)." >&2
  exit 1
fi

"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- pg_dropcluster "$@"
