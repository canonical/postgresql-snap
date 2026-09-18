# Extensions

## Quick start

Lifecycle:
```shell
sudo snap install postgresql+pg-cron+pgvector          # snap plus two components

sudo snap install postgresql+pg-cron+pgvector+pgaudit+pg-stat-statements+pg-trgm # all at once

sudo snap install postgresql+pg-trgm                   # add one to an existing install
sudo snap restart postgresql.postgresql                # enable newly added pg-trgm components

snap components postgresql                             # list all available components
snap component postgresql+pg-cron                      # describe a particular snap component

sudo snap remove postgresql+pg-cron+pgvector           # drop two, keep the snap with one extention
sudo snap restart postgresql.postgresql                # disable removed pg-cron+pgvector components

sudo snap remove postgresql                            # removes the snap and all its components
```

Status:
```shell
> snap list postgresql
Name        Version  Rev  Tracking   Publisher   Notes
postgresql  18.6     272  18/edge/…  canonical✓  components[3/5]

> snap components postgresql
Component                      Status     Type
postgresql+pg-trgm             installed  standard
postgresql+pg-cron             installed  standard
postgresql+pg-stat-statements  available  standard
postgresql+pgaudit             installed  standard
postgresql+pgvector            available  standard

> snap component postgresql+pg-cron
component: postgresql+pg-cron
type: standard
summary: pg_cron extension for PostgreSQL 18
description: |
  Run periodic jobs in PostgreSQL. Requires a daemon restart after
install/remove (adds itself to shared_preload_libraries).
```

Test command to check extentions availablility+usability:
```shell
postgresql.psql -U postgres -h /tmp -v ON_ERROR_STOP=1 <<'EOF'
  DO $$
  DECLARE
    t record;
    dir text;
  BEGIN
    FOR t IN SELECT * FROM (VALUES
        ('pg_cron',            'pg-cron',            'SELECT cron.unschedule(cron.schedule(''ping'', ''* * * * *'', ''SELECT 1''))'),
        ('pg_stat_statements', 'pg-stat-statements', 'SELECT count(*) FROM pg_stat_statements'),
        ('pg_trgm',            'pg-trgm',            'SELECT similarity(''snap'', ''snap'')'),
        ('vector',             'pgvector',           'SELECT ''[1,2,3]''::vector <-> ''[1,2,4]''::vector'),
        ('pgaudit',            'pgaudit',            'SELECT current_setting(''pgaudit.log'')')
      ) AS v(ext, comp, probe)
    LOOP
      dir := substring(current_setting('extension_control_path') FROM '[^:]*/' || t.comp || '/share');
      IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = t.ext) THEN
        EXECUTE format('CREATE EXTENSION IF NOT EXISTS %I', t.ext);
        EXECUTE t.probe;
        RAISE NOTICE '% ok', t.ext;
      ELSIF dir IS NULL THEN
        RAISE NOTICE '% skipped: component not installed, or PostgreSQL not restarted since installing it', t.ext;
      ELSIF pg_stat_file(dir || '/extension', true) IS NULL THEN
        RAISE NOTICE '% skipped: component removed, restart PostgreSQL to unload it', t.ext;
      ELSE
        RAISE EXCEPTION '% is in extension_control_path but not available: snap component broken?', t.ext;
      END IF;
    END LOOP;
  END
  $$;
EOF
```

PostgreSQL check example:
```shell
NOTICE:  extension "pg_cron" already exists, skipping
NOTICE:  pg_cron ok
NOTICE:  pg_stat_statements skipped: component not installed, or PostgreSQL not restarted since installing it
NOTICE:  extension "pg_trgm" already exists, skipping
NOTICE:  pg_trgm ok
NOTICE:  extension "vector" already exists, skipping
NOTICE:  vector ok
NOTICE:  pgaudit skipped: component not installed, or PostgreSQL not restarted since installing it
```

## Scope

Optional PostgreSQL extensions are shipped as
[snap components](https://snapcraft.io/docs/components): small add-on packages
that install next to the `postgresql` snap without duplicating PostgreSQL itself.
They are built from the same Ubuntu archive as the snap, so the binaries always
match the PostgreSQL version in the snap.

| Component | Extension | Notes |
|-----------|-----------|-------|
| `pg-cron` | [pg_cron](https://github.com/citusdata/pg_cron) | Adds itself to `shared_preload_libraries` |
| `pgvector` | [pgvector](https://github.com/pgvector/pgvector) (`CREATE EXTENSION vector`) | |
| `pgaudit` | [pgaudit](https://github.com/pgaudit/pgaudit) | Adds itself to `shared_preload_libraries` |
| `pg-stat-statements` | [pg_stat_statements](https://www.postgresql.org/docs/current/pgstatstatements.html) | Contrib module, adds itself to `shared_preload_libraries` |
| `pg-trgm` | [pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html) | Contrib module |

The contrib modules `pg_stat_statements` and `pg_trgm` are no longer part of the
base snap. If `postgresql.conf` lists `pg_stat_statements` in
`shared_preload_libraries`, install the component before refreshing, otherwise
PostgreSQL will not start.

## Install

Install PostgreSQL together with an extension:

```shell
sudo snap install postgresql+pg-cron+pgvector
```

or add an extension to an existing installation, then restart PostgreSQL so it
loads the new files:

```shell
sudo snap install postgresql+pg-cron
sudo snap restart postgresql.postgresql
```

Enable the extension in a database as usual:

```shell
> postgresql.psql -U postgres -h /tmp
postgres=# CREATE EXTENSION pg_cron;
postgres=# SELECT cron.schedule('nightly-vacuum', '0 3 * * *', 'VACUUM');
```

List what is installed:

```shell
sudo snap components postgresql
```

## Remove

Drop the extension from every database that uses it first, then remove the
component and restart PostgreSQL:

```shell
> postgresql.psql -U postgres -h /tmp -c "DROP EXTENSION pg_cron;"
sudo snap remove postgresql+pg-cron
sudo snap restart postgresql.postgresql
```

## How it works

On every start of the `postgresql` service the snap regenerates
`/var/snap/postgresql/common/etc/postgresql/18/main/conf.d/00-snap-components.conf`
from the installed components. It extends `dynamic_library_path`,
`extension_control_path` and `shared_preload_libraries` with the component
contents and appends any settings the component ships (for example
`cron.host = '/tmp'`, so that pg_cron connects through the local socket).
Values already set in `postgresql.conf` are kept and extended, but settings made
with `ALTER SYSTEM` take precedence over the generated file.
