# Major version upgrades

Data written by one PostgreSQL major cannot be read by another, so a plain
`snap refresh` from the `16` track to the `18` track is refused by the snap
and rolled back. To upgrade in place, refresh together with the component
that carries the previous major's server binaries, then run
`postgresql.upgrade`:

```shell
sudo snap refresh postgresql+pg16 --channel 18/stable   # data untouched, service kept stopped
sudo postgresql.upgrade --check                         # optional dry run
sudo postgresql.upgrade                                 # pg_upgrade 16 -> 18, service started
sudo postgresql.psql -U postgres -h /tmp -c 'ANALYZE'   # or vacuumdb --all --analyze-in-stages
sudo snap remove postgresql+pg16                        # old binaries no longer needed
```

Any release since 9.2 upgrades directly to the current major with
[pg_upgrade](https://www.postgresql.org/docs/current/pgupgrade.html), so
there is no need to step through intermediate majors.

What `postgresql.upgrade` does:

* creates the new cluster with the snap defaults, matching the old cluster's
  data checksum setting (PostgreSQL 18 enables checksums by default);
* runs `pg_upgrade` in copy mode as the `_daemon_` user, with the old server
  started from the `pg16` component; pass `--link` to hard-link instead of
  copying (faster, no extra disk, but the old cluster is unusable afterwards);
* gives the new cluster the old cluster's port (the old cluster is moved to
  the port the new one was created on);
* enables and starts the `postgresql` service.

Settings from the old `postgresql.conf` are not carried over: compare
`/var/snap/postgresql/common/etc/postgresql/16/main/postgresql.conf` with the
new one and port what you need. Extensions used by the old cluster must be
available for the new major before upgrading, for example
`snap install postgresql+pg-cron`; `pg_upgrade --check` lists what is missing.
The old cluster stays under `/var/snap/postgresql/common/var/lib/postgresql/16`
until you delete it.

If the refresh happened without the component, PostgreSQL is not started and
`postgresql.upgrade` explains what to install. `snap revert postgresql` returns
to the previous revision at any point before the upgrade has run.
