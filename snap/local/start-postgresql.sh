#!/bin/bash

# For security measures, applications should not be run as sudo.
export LOCPATH="${SNAP}"/usr/lib/locale
export PGDATA=${SNAP_COMMON}/pgsql/data
PGMAJORVER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)

"${SNAP}/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- "${SNAP}/usr/lib/postgresql/${PGMAJORVER}/bin/postgres" -k /tmp -D "${PGDATA}"
