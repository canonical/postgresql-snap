#!/bin/bash

# For security measures, applications should not be run as sudo.
export LOCPATH="${SNAP}"/usr/lib/locale
export PGDATA=${SNAP_COMMON}/pgsql/data

"${SNAP}/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- "${SNAP}/usr/lib/postgresql/14/bin/postgres" -k /tmp -D "${PGDATA}"
