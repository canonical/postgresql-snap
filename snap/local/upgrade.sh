#!/bin/bash
# postgresql.upgrade: migrate the data of the previous PostgreSQL major to
# this snap's major in place with pg_upgrade, using the old server binaries
# shipped in the postgresql+pg<old> component.
#
#   sudo snap refresh postgresql+pg16 --channel 18/stable   # post-refresh hook keeps the service down
#   sudo postgresql.upgrade [--check] [--link] [pg_upgrade options...]
#
# The new cluster is created with the snap defaults (create-cluster.sh); port
# settings from the old postgresql.conf are not carried over. The old cluster
# is left in place until you delete it.
set -euo pipefail

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
}
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac
if [ "${EUID}" != "0" ]; then
  echo "Error: run it as root (to utilize snap user _daemon_)." >&2
  exit 1
fi

NEW="${SNAP_VERSION%%.*}"
DATA="$SNAP_COMMON/var/lib/postgresql"
AS_DAEMON=("$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root --)

# Exactly one cluster of another major must exist.
OLD=""
for d in "$DATA"/*/main; do
  [ -d "$d" ] || continue
  v="$(basename "$(dirname "$d")")"
  [ "$v" = "$NEW" ] && continue
  if [ -n "$OLD" ]; then
    echo "ERROR: several old clusters found under $DATA ($OLD, $v); remove the ones not to migrate." >&2
    exit 1
  fi
  OLD="$v"
done
if [ -z "$OLD" ]; then
  echo "ERROR: no cluster of another PostgreSQL major found under $DATA; nothing to upgrade." >&2
  exit 1
fi

COMP="$(dirname "$SNAP")/components/$SNAP_REVISION/pg$OLD"
OLDBIN="$COMP/usr/lib/postgresql/$OLD/bin"
NEWBIN="$SNAP/usr/lib/postgresql/$NEW/bin"
if [ ! -x "$OLDBIN/pg_ctl" ]; then
  echo "ERROR: PostgreSQL $OLD binaries not found: install the component first:" >&2
  echo "  sudo snap install postgresql+pg$OLD" >&2
  exit 1
fi

if [ ! -d "$DATA/$NEW/main" ]; then
  echo "Creating the PostgreSQL $NEW cluster..."
  INITDB_ARGS=()
  # pg_upgrade requires the same data checksum setting on both sides
  # (PostgreSQL 18 enables checksums by default, older initdb did not).
  if "${AS_DAEMON[@]}" "$OLDBIN/pg_controldata" -D "$DATA/$OLD/main" \
      | grep -q "^Data page checksum version: *0$"; then
    INITDB_ARGS+=(--no-data-checksums)
  fi
  "$SNAP/create-cluster.sh" "$NEW" main -- "${INITDB_ARGS[@]}"
fi

echo "Running pg_upgrade $OLD -> $NEW..."
# Old binaries need their own ICU/libxml2 (different sonames, no clash).
# Both clusters were created by the snap with superuser "postgres".
# pg_upgrade puts its sockets in the working directory and its logs in the
# new data directory. The old server's shared_preload_libraries are cleared:
# its extension libraries are not shipped; the new cluster keeps its config.
cd /tmp
"${AS_DAEMON[@]}" env LD_LIBRARY_PATH="$COMP/libs:${LD_LIBRARY_PATH:-}" \
  "$NEWBIN/pg_upgrade" \
    --username postgres \
    --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
    --old-datadir "/etc/postgresql/$OLD/main" \
    --new-datadir "/etc/postgresql/$NEW/main" \
    --old-options "-c shared_preload_libraries=''" \
    "$@"

case " $* " in
  *" --check "*|*" -c "*) exit 0 ;;
esac

# pg_createcluster gave the new cluster the next free port because the old
# one still owns its port in its config: swap them, like pg_upgradecluster.
OLDPORT="$("${AS_DAEMON[@]}" pg_conftool "$OLD" main show port | sed 's/.*= *//')"
NEWPORT="$("${AS_DAEMON[@]}" pg_conftool "$NEW" main show port | sed 's/.*= *//')"
if [ "$OLDPORT" != "$NEWPORT" ]; then
  echo "Moving PostgreSQL $NEW to port $OLDPORT (the old cluster gets $NEWPORT)..."
  "${AS_DAEMON[@]}" pg_conftool "$OLD" main set port "$NEWPORT"
  "${AS_DAEMON[@]}" pg_conftool "$NEW" main set port "$OLDPORT"
fi

echo "Starting PostgreSQL $NEW..."
if ! snapctl start --enable postgresql.postgresql 2>/dev/null; then
  echo "Run: sudo snap start --enable postgresql.postgresql"
fi
echo "Upgrade complete. Next steps:"
echo "  sudo postgresql.vacuumdb -U postgres -h /tmp --all --analyze-in-stages --missing-stats-only"
echo "  sudo snap remove postgresql+pg$OLD                       # old binaries are no longer needed"
echo "  The PostgreSQL $OLD cluster is kept under $DATA/$OLD until you delete it."
