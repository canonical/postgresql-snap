# Extension snaps

Examples of PostgreSQL extensions shipped as *separate* snaps that plug into
the `postgresql` snap through the content interface, as an alternative to
[snap components](../docs/extensions.md). Each directory is its own snapcraft
project:

```shell
cd extensions/postgresql-pg-cron
snapcraft pack
sudo snap install ./postgresql-pg-cron_*.snap --dangerous
sudo snap connect postgresql:extensions postgresql-pg-cron:extensions
sudo snap restart postgresql.postgresql
```

The spread test `spread/tests/extension_snap_pg_cron` expects the packed
snap next to its `snap/` directory.
