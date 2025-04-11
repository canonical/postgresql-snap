#!/bin/bash
set -e
if [ "${EUID}" != "0" ]; then
  echo "Error: run it as root (to utilize snap user _daemon_)." >&2
  exit 1
fi

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)

"$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- "$SNAP/usr/lib/postgresql/$PG_MAJOR_VER/bin/pg_ctl" "$@"
