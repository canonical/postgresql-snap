#!/bin/bash

NAME=$1

PG_MAJOR_VER=$(echo "$SNAP_VERSION" | cut -d "." -f 1)
PGCONF="$SNAP_DATA/etc/postgresql/$PG_MAJOR_VER/$NAME"
PGDATA="$SNAP_COMMON/pgsql/data/$PG_MAJOR_VER/$NAME"


"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- mkdir -p "$PGDATA/"
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- mkdir -p "$PGCONF/"

"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- chown -R 584788:root "$PGDATA"
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- chown -R 584788:root "$PGCONF"

# Based on /usr/bin/pg_createcluster
# TODO add auth-local
echo "Creating new PostgreSQL cluster $PG_MAJOR_VER/$NAME ...";
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- "$SNAP/usr/lib/postgresql/$PG_MAJOR_VER/bin/initdb" -U postgres -D "$PGDATA" --auth-host scram-sha-256 --no-instructions
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- mv "$PGDATA/postgresql.conf" "$PGCONF"
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- chmod 644 "$PGCONF/postgresql.conf"
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- mv "$PGDATA/pg_hba.conf" "$PGCONF"
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- chmod 640 "$PGCONF/pg_hba.conf"
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- mv "$PGDATA/pg_ident.conf" "$PGCONF"
"$SNAP/usr/bin/setpriv" --clear-groups --reuid snap_daemon --regid snap_daemon -- chmod 640 "$PGCONF/pg_ident.conf"

