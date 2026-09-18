# Extensions

## Quick start

Lifecycle:
```shell
sudo snap install postgresql+pg-cron+pgvector          # snap plus two components

sudo snap install postgresql+jit+pg-cron+pgvector+pgaudit          # all at once

sudo snap install postgresql+jit                       # add one to an existing install
sudo snap restart postgresql.postgresql                # enable the newly added jit component

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
postgresql  18.6     272  18/edge/…  canonical✓  components[2/4]

> snap components postgresql
Component                      Status     Type
postgresql+jit                 installed  standard
postgresql+pg-cron             installed  standard
postgresql+pgaudit             available  standard
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

`snap install postgresql` is the equivalent of apt's `postgresql-18` package:
the server, the client tools and all contrib modules (`pg_stat_statements`,
`pg_trgm`, `hstore`, `pgcrypto`, ...). Everything apt keeps in a separate
package, plus third-party extensions, ships as
[snap components](https://snapcraft.io/docs/components): small add-on packages
that install next to the `postgresql` snap without duplicating PostgreSQL itself.
They are built from the same Ubuntu archive as the snap, so the binaries always
match the PostgreSQL version in the snap.

| Component | Provides | Notes |
|-----------|----------|-------|
| `jit` | LLVM JIT compiler (`llvmjit`, `libLLVM`) | apt's `postgresql-18-jit`; without it `pg_jit_available()` is false and queries run interpreted |
| `pg-cron` | [pg_cron](https://github.com/citusdata/pg_cron) | Adds itself to `shared_preload_libraries` |
| `pgvector` | [pgvector](https://github.com/pgvector/pgvector) (`CREATE EXTENSION vector`) | |
| `pgaudit` | [pgaudit](https://github.com/pgaudit/pgaudit) | Adds itself to `shared_preload_libraries` |
| `pg16` | PostgreSQL 16 server binaries | Only for [in-place upgrades](upgrade.md) with `postgresql.upgrade` |

The JIT is the largest optional part of the snap (roughly a third of its
size), which is why it is the one contrib-like piece that is a component.

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

## Extension snaps (content interface)

An extension can also be shipped as a *separate* snap that exposes the same
directory layout through the content interface, for example by a third party.
Connect it to the `extensions` plug and restart PostgreSQL:

```shell
sudo snap install postgresql-pg-cron
sudo snap connect postgresql:extensions postgresql-pg-cron:extensions
sudo snap restart postgresql.postgresql
```

Snaps from the same publisher connect automatically. If a component and an
extension snap provide the same extension, the component is used and the
extension snap is ignored. Use `SHOW snap.<name>` to see where an extension
comes from (`component 1.6.7` or `extension snap 1.5.2`). An example provider
lives in [`extensions/postgresql-pg-cron`](/extensions/postgresql-pg-cron).

Unlike components, snapd does not restart PostgreSQL when an extension snap is
refreshed: restart it yourself afterwards.

Switching an extension between sources (or refreshing one) does not change the
extension objects already created in databases. Run
`ALTER EXTENSION <name> UPDATE` in each database to move them to the new
version, for example from pg_cron 1.5 to 1.6.

## How it works

On every start of the `postgresql` service the snap regenerates
`/var/snap/postgresql/common/etc/postgresql/18/main/conf.d/00-snap-components.conf`
from the installed components and connected extension snaps. It extends `dynamic_library_path`,
`extension_control_path` and `shared_preload_libraries` with the component
contents and appends any settings the component ships (for example
`cron.host = '/tmp'`, so that pg_cron connects through the local socket).
Values already set in `postgresql.conf` are kept and extended, but settings made
with `ALTER SYSTEM` take precedence over the generated file.
