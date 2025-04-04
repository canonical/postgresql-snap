#!/bin/bash

NAME=$1

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)
PGCONF="$SNAP_DATA/etc/postgresql/$PG_MAJOR_VER/$NAME"
PGDATA="$SNAP_COMMON/pgsql/data/$PG_MAJOR_VER/$NAME"

echo "Starting cluster $PG_MAJOR_VER/$NAME"
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- "$SNAP/usr/lib/postgresql/$PG_MAJOR_VER/bin/postgres" -k /tmp -D "$PGDATA" -c config_file="$PGCONF/postgresql.conf" -c hba_file="$PGCONF/pg_hba.conf" -c ident_file="$PGCONF/pg_ident.conf"
