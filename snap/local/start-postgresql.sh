#!/bin/bash

# For security measures, applications should not be run as sudo.
export LOCPATH="$SNAP"/usr/lib/locale
export PGDATA=${SNAP_COMMON}/pgsql/data
PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)
export CLUSTERCONF="$SNAP_DATA/etc/postgresql/$PG_MAJOR_VER/main"

"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- "$SNAP/usr/lib/postgresql/$PG_MAJOR_VER/bin/postgres" -k /tmp -D "$PGDATA" -c config_file="$CLUSTERCONF/postgresql.conf" -c hba_file="$CLUSTERCONF/pg_hba.conf" -c ident_file="$CLUSTERCONF/pg_ident.conf"
