# Extensions

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
