#!/bin/bash
set -e

# pg_lsclusters is a Perl script: run as root, Perl's getpw* builtins read
# /etc/shadow via getspnam() and PgCommon probes _daemon_-owned cluster
# paths, flooding the kernel log with AppArmor denials (issue #190).
# Drop to _daemon_ like the other cluster tools; run directly otherwise.
if [ "${EUID}" = "0" ]; then
  exec "$SNAP/usr/bin/setpriv" --clear-groups --reuid _daemon_ --regid root -- \
    pg_lsclusters "$@"
fi

exec pg_lsclusters "$@"
