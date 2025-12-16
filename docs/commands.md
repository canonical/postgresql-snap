# Commands

The [PostgreSQL snap](https://snapcraft.io/postgresql) ships a set of useful tools for managing your application - including cluster management, health checks, backups, and more.


## PostgreSQL clients

* [postgresql.psql](https://www.postgresql.org/docs/current/app-psql.html) - PostgreSQL interactive terminal. 

<details><summary>Example for <code>postgresql.psql</code></summary>

```shell
> postgresql.psql -U postgres -h /tmp
psql (18.1 (Ubuntu 18.1-2))
Type "help" for help.

postgres=# \du+
                                    List of roles
 Role name |                         Attributes                         | Description 
-----------+------------------------------------------------------------+-------------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | 
```
</details>

## Cluster management

Those tools are Ubuntu/Debian-specific wrappers around '[initdb](https://www.postgresql.org/docs/current/app-initdb.html)' and '[pg_ctl](https://www.postgresql.org/docs/current/app-pg-ctl.html)' precisely for the purpose of providing a simpler interface for managing multiple postgresql instances on the same host:

* [postgresql.lsclusters](https://manpages.ubuntu.com/manpages/noble/en/man1/pg_lsclusters.1.html) - show information about all PostgreSQL clusters
* [postgresql.ctlcluster](https://manpages.ubuntu.com/manpages/noble/en/man1/pg_ctlcluster.1.html) - start/stop/restart/reload a PostgreSQL cluster
* [postgresql.createcluster](https://manpages.ubuntu.com/manpages/noble/en/man1/pg_createcluster.1.html) - create a new PostgreSQL cluster
* [postgresql.renamecluster](https://manpages.ubuntu.com/manpages/noble/en/man1/pg_renamecluster.1.html) - rename a PostgreSQL cluster
* [postgresql.dropcluster](https://manpages.ubuntu.com/manpages/noble/en/man1/pg_dropcluster.1.html) - completely delete a PostgreSQL cluster

<details><summary>Example for <code>postgresql.lsclusters</code></summary>

```shell
> postgresql.lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
18  main    5432 online _daemon_ /var/lib/postgresql/18/main2   /var/log/postgresql/postgresql-18-main.log
18  test    5434 online _daemon_ /var/lib/postgresql/18/test    /var/log/postgresql/postgresql-18-test.log
18  test1   5433 online _daemon_ /var/lib/postgresql/18/test1   /var/log/postgresql/postgresql-18-test1.log
18  test123 5435 online _daemon_ /var/lib/postgresql/18/test123 /var/log/postgresql/postgresql-18-test123.log
```
</details>

<details><summary>Example for <code>postgresql.ctlcluster</code></summary>

```shell
> sudo postgresql.ctlcluster --skip-systemctl-redirect 18 main status
pg_ctl: server is running (PID: 41805)
...

> sudo postgresql.ctlcluster --skip-systemctl-redirect 18 main stop

> sudo postgresql.ctlcluster --skip-systemctl-redirect 18 main status
pg_ctl: no server running

> sudo postgresql.ctlcluster --skip-systemctl-redirect 18 main start

> sudo postgresql.ctlcluster --skip-systemctl-redirect 18 main status
pg_ctl: server is running (PID: 42101)
...
```
Usage:
```shell
Usage: postgresql.ctlcluster <version> <cluster> <action> [-- <pg_ctl options>]
```
</details>

<details><summary>Example for <code>postgresql.createcluster</code></summary>

```shell
> sudo postgresql.createcluster 18 test1
Creating new PostgreSQL cluster 18/test1
...
The cluster can be started with: 'postgresql.ctlcluster --skip-systemctl-redirect 18 test1 start'

> postgresql.lsclusters 18 test1
Ver Cluster Port Status Owner    Data directory               Log file
18  test1   5435 down   _daemon_ /var/lib/postgresql/18/test1 /var/log/postgresql/postgresql-18-test1.log

> sudo postgresql.ctlcluster --skip-systemctl-redirect 18 test1 start

> postgresql.lsclusters 18 test1
Ver Cluster Port Status Owner    Data directory               Log file
18  test1   5435 online _daemon_ /var/lib/postgresql/18/test1 /var/log/postgresql/postgresql-18-test1.log

> postgresql.psql -U postgres -h /tmp -p 5435 -d postgres
psql (18.1 (Ubuntu 18.1-2))
Type "help" for help.

postgres=# 
```
</details>

<details><summary>Example for <code>postgresql.renamecluster</code></summary>

```shell
> postgresql.lsclusters 18
Ver Cluster Port Status Owner    Data directory               Log file
18  main    5432 online _daemon_ /var/lib/postgresql/18/main  /var/log/postgresql/postgresql-18-main.log
18  test1   5433 online _daemon_ /var/lib/postgresql/18/test1 /var/log/postgresql/postgresql-18-test1.log

> sudo postgresql.renamecluster 18 test1 test123
Stopping cluster 18 test1 ...
Warning: systemd does not know about the new cluster yet. Operations like "service postgresql start" will not handle it. To fix, run:
  sudo systemctl daemon-reload
Starting cluster 18 test123 ...
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@18-test123

> postgresql.lsclusters 18
Ver Cluster Port Status Owner    Data directory                 Log file
18  main    5432 online _daemon_ /var/lib/postgresql/18/main    /var/log/postgresql/postgresql-18-main.log
18  test123 5433 online _daemon_ /var/lib/postgresql/18/test123 /var/log/postgresql/postgresql-18-test123.log
```
</details>

<details><summary>Example for <code>postgresql.dropcluster</code></summary>

```shell
> postgresql.lsclusters 18 test123
Ver Cluster   Port Status Owner    Data directory               Log file
18  test123   5433 online _daemon_ /var/lib/postgresql/18/test1 /var/log/postgresql/postgresql-18-test1.log

> sudo postgresql.dropcluster --stop 18 test123

> postgresql.lsclusters 18 test123
Error: Cluster 18 test123 does not exist
```
</details>

## Instance management

* [postgresql.createuser](https://www.postgresql.org/docs/current/app-createuser.html) - define a new PostgreSQL user account
* [postgresql.createdb](https://www.postgresql.org/docs/current/app-createdb.html) - create a new PostgreSQL database
* [postgresql.ctl](https://www.postgresql.org/docs/current/app-pg-ctl.html) - initialize, start, stop, or control a PostgreSQL server

<details><summary>Example for <code>postgresql.createuser</code></summary>

```shell
> postgresql.createuser -U postgres -h /tmp mynewuser

> postgresql.psql -U postgres -h /tmp -p 5432 -d postgres -c "\du"
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 mynewuser | 
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
```
</details>

<details><summary>Example for <code>postgresql.createdb</code></summary>

```shell
> postgresql.createdb -U postgres -h /tmp -p 5432 mybench

> postgresql.psql -U postgres -h /tmp -p 5432 -d postgres -c "\l"
                                                   List of databases
   Name    |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
-----------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 mybench   | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
...
```
</details>

<details><summary>Example for <code>postgresql.ctl</code></summary>

```shell
>  sudo postgresql.ctl status -D /var/lib/postgresql/18/main/
pg_ctl: server is running (PID: 1690)
/usr/lib/postgresql/18/bin/postgres "-c" "config_file=/etc/postgresql/18/main/postgresql.conf"

> sudo postgresql.ctl restart -D /var/lib/postgresql/18/main/
waiting for server to shut down.... done
server stopped
waiting for server to start....2025-07-01 21:13:15.019 UTC [51249] LOG:  starting PostgreSQL 18.1 (Ubuntu 18.1-2)...
2025-07-01 21:13:15.020 UTC [51249] LOG:  listening on IPv6 address "::1", port 5432
2025-07-01 21:13:15.020 UTC [51249] LOG:  listening on IPv4 address "127.0.0.1", port 5432
2025-07-01 21:13:15.033 UTC [51249] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
2025-07-01 21:13:15.067 UTC [51254] LOG:  database system was shut down at 2025-07-01 21:13:14 UTC
2025-07-01 21:13:15.104 UTC [51249] LOG:  database system is ready to accept connections
 done
server started
```
</details>

## Health checks

* [postgresql.isready](https://www.postgresql.org/docs/current/app-pg-isready.html) - check the connection status of a PostgreSQL server
* [postgresql.pgbench](https://www.postgresql.org/docs/current/pgbench.html) - run a benchmark test on PostgreSQL

<details><summary>Example for <code>postgresql.isready</code></summary>

```shell
> postgresql.isready
/tmp:5432 - accepting connections

> postgresql.isready -h /tmp -p 5435
/tmp:5435 - accepting connections

> postgresql.isready -h /tmp -p 5442
/tmp:5442 - no response
```
</details>

<details><summary>Example for <code>postgresql.pgbench</code></summary>

```shell
> postgresql.createdb -U postgres -h /tmp -p 5432 mybench

> postgresql.pgbench -U postgres -h /tmp -p 5432 -d mybench --initialize
...
done in 4.98 s (drop tables 0.00 s, create tables 0.04 s, client-side generate 4.18 s, vacuum 0.23 s, primary keys 0.54 s).

> postgresql.pgbench -U postgres -h /tmp -p 5432 -d mybench -T 60
...
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 6634
number of failed transactions: 0 (0.000%)
latency average = 9.043 ms
initial connection time = 14.192 ms
tps = 110.587085 (without initial connection time)
```
</details>

## PostgreSQL configuration

* [postgresql.config](https://www.postgresql.org/docs/current/app-pgconfig.html) - retrieve information about the installed version of PostgreSQL
* [postgresql.conftool](https://manpages.ubuntu.com/manpages/focal/man1/pg_conftool.1.html) - read and edit PostgreSQL cluster configuration files

<details><summary>Example for <code>postgresql.config</code></summary>

```shell
> postgresql.config
BINDIR = /usr/lib/postgresql/18/bin
DOCDIR = /usr/share/doc/postgresql-doc-18
HTMLDIR = /usr/share/doc/postgresql-doc-18
INCLUDEDIR = /usr/include/postgresql
PKGINCLUDEDIR = /usr/include/postgresql
INCLUDEDIR-SERVER = /usr/include/postgresql/18/server
LIBDIR = /usr/lib/riscv64-linux-gnu
PKGLIBDIR = /usr/lib/postgresql/18/lib
LOCALEDIR = /usr/share/locale
MANDIR = /usr/share/postgresql/18/man
SHAREDIR = /usr/share/postgresql/18
SYSCONFDIR = /etc/postgresql-common
PGXS = /usr/lib/postgresql/18/lib/pgxs/src/makefiles/pgxs.mk
CONFIGURE =  '--build=riscv64-linux-gnu' '--prefix=/usr' '--includedir=${prefix}/include' '--mandir=${prefix}/share/man' '--infodir=${prefix}/share/info' '--sysconfdir=/etc' '--localstatedir=/var' '--disable-option-checking' '--disable-silent-rules' '--libdir=${prefix}/lib/riscv64-linux-gnu' '--runstatedir=/run' '--disable-maintainer-mode' '--disable-dependency-tracking' '--with-tcl' '--with-perl' '--with-python' '--with-pam' '--with-openssl' '--with-libxml' '--with-libxslt' '--mandir=/usr/share/postgresql/18/man' '--docdir=/usr/share/doc/postgresql-doc-18' '--sysconfdir=/etc/postgresql-common' '--datarootdir=/usr/share/' '--datadir=/usr/share/postgresql/18' '--bindir=/usr/lib/postgresql/18/bin' '--libdir=/usr/lib/riscv64-linux-gnu/' '--libexecdir=/usr/lib/postgresql/' '--includedir=/usr/include/postgresql/' '--with-extra-version= (Ubuntu 18.1-2)' '--enable-nls' '--enable-thread-safety' '--enable-debug' '--enable-dtrace' '--disable-rpath' '--with-uuid=e2fs' '--with-gnu-ld' '--with-gssapi' '--with-ldap' '--with-pgport=5432' '--with-system-tzdata=/usr/share/zoneinfo' 'AWK=mawk' 'MKDIR_P=/bin/mkdir -p' 'PROVE=/usr/bin/prove' 'PYTHON=/usr/bin/python3' 'TAR=/bin/tar' 'XSLTPROC=xsltproc --nonet' 'CFLAGS=-g -O2 -fno-omit-frame-pointer -fstack-protector-strong -Wformat -Werror=format-security -fno-stack-clash-protection' 'LDFLAGS=-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now' '--enable-tap-tests' '--with-icu' '--with-lz4' '--with-zstd' '--with-systemd' '--with-selinux' 'build_alias=riscv64-linux-gnu' 'CPPFLAGS=-Wdate-time -D_FORTIFY_SOURCE=3' 'CXXFLAGS=-g -O2 -fno-omit-frame-pointer -fstack-protector-strong -Wformat -Werror=format-security -fno-stack-clash-protection'
CC = gcc
CPPFLAGS = -Wdate-time -D_FORTIFY_SOURCE=3 -D_GNU_SOURCE -I/usr/include/libxml2
CFLAGS = -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wimplicit-fallthrough=3 -Wcast-function-type -Wshadow=compatible-local -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fno-omit-frame-pointer -fstack-protector-strong -Wformat -Werror=format-security -fno-stack-clash-protection
CFLAGS_SL = -fPIC
LDFLAGS = -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed
LDFLAGS_EX = 
LDFLAGS_SL = 
LIBS = -lpgcommon -lpgport -lselinux -lzstd -llz4 -lxslt -lxml2 -lpam -lssl -lcrypto -lgssapi_krb5 -lz -lreadline -lm 
VERSION = PostgreSQL 18.1 (Ubuntu 18.1-2)
```
</details>

<details><summary>Example for <code>postgresql.conftool</code></summary>

```shell
> postgresql.conftool 18 main show max_connections
max_connections = 100

> postgresql.conftool 18 test1 show all
data_directory = '/var/lib/postgresql/18/test1'
datestyle = 'iso, mdy'
default_text_search_config = 'pg_catalog.english'
dynamic_shared_memory_type = posix
external_pid_file = '/tmp/18-test1.pid'
hba_file = '/etc/postgresql/18/test1/pg_hba.conf'
ident_file = '/etc/postgresql/18/test1/pg_ident.conf'
lc_messages = 'C.UTF-8'
lc_monetary = 'C.UTF-8'
lc_numeric = 'C.UTF-8'
lc_time = 'C.UTF-8'
log_timezone = UTC
max_connections = 100
max_wal_size = 1GB
min_wal_size = 80MB
port = 5435
shared_buffers = 128MB
timezone = UTC
unix_socket_directories = '/tmp'

> postgresql.conftool 18 main edit
...
```
</details>

## Backups

* [postgresql.dump](https://www.postgresql.org/docs/current/app-pgdump.html) - extract a PostgreSQL database into a script file or other archive file
* [postgresql.dumpall](https://www.postgresql.org/docs/current/app-pg-dumpall.html) - extract a PostgreSQL database cluster into a script file
* [postgresql.restore](https://www.postgresql.org/docs/current/app-pgrestore.html) - restore a PostgreSQL database from an archive file created by pg_dump
* [postgresql.archivecleanup](https://www.postgresql.org/docs/current/pgarchivecleanup.html) - clean up PostgreSQL WAL archive files
* [postgresql.basebackup](https://www.postgresql.org/docs/current/app-pgbasebackup.html) - take a base backup of a PostgreSQL cluster
* [postgresql.receivewal](https://www.postgresql.org/docs/current/app-pgreceivewal.html) - stream write-ahead logs from a PostgreSQL server
* [postgresql.recvlogical](https://www.postgresql.org/docs/current/app-pgrecvlogical.html) -  control PostgreSQL logical decoding streams

<details><summary>Example for <code>postgresql.dump</code></summary>

Dump:

```shell
> postgresql.dump -c -C -U postgres -h /tmp -d mydb > mydb.sql
```

Restore:

```shell
> psql -U postgres -h /tmp < mydb.sql
```
</details>

<details><summary>Example for <code>postgresql.dumpall</code></summary>

```shell
> postgresql.dumpall -c -U postgres -h /tmp > all.sql
```
</details>

<details><summary>Example for <code>postgresql.restore</code></summary>

```shell
> postgresql.restore -c -U postgres -h /tmp -v -f mydb.sql
```
</details>

<details><summary>Example for <code>postgresql.archivecleanup</code></summary>

Command-line interface:

```shell
> postgresql.archivecleanup /mnt/server/archiverdir 000000010000000000000010.00000020.backup
```

Inside `postgresql.conf`:

```shell
> archive_cleanup_command = 'pg_archivecleanup /mnt/server/archiverdir %r'
```
</details>

<details><summary>Example for <code>postgresql.basebackup</code></summary>

Create slot:
```shell
> mkdir -p /tmp/test1 && postgresql.basebackup -D /tmp/test1 -C --slot myslot -P -U postgres -h /tmp
```

Reuse slot:
```shell
> mkdir -p /tmp/test2 && postgresql.basebackup -D /tmp/test2 --slot myslot -P -U postgres -h /tmp
31295/31295 kB (100%), 1/1 tablespace
```
</details>

<details><summary>Example for <code>postgresql.receivewal</code></summary>

```shell
> mkdir -p ~/wal_archive
> sudo postgresql.receivewal -D ~/wal_archive -U postgres -h /tmp -p 5432
...

> ls -la ~/wal_archive/
...
-rw-------  1 root   root   16777216 Apr 10 12:16 000000010000000000000001.partial
-rw-------  1 root   root   16777216 Apr 10 23:59 000000010000000000000002.partial
-rw-------  1 root   root   16777216 Apr 11 22:23 000000010000000000000003.partial
...
```
</details>

<details><summary>Example for <code>postgresql.recvlogical</code></summary>

```shell
> postgresql.conftool 18 main edit # set wal_level=logical !

> sudo postgresql.ctlcluster --skip-systemctl-redirect 18 main restart

> postgresql.conftool 18 main show wal_level
wal_level = logical

> postgresql.recvlogical -U postgres -d mybench --create-slot -S myslot1

> postgresql.recvlogical -U postgres -d mybench --start -S myslot1 -f logical_repl.sql &
[1] 44782

>  postgresql.pgbench -U postgres -h /tmp -p 5432 -d mybench
...

> head -5 logical_repl.sql 
BEGIN 7406
table public.pgbench_history: TRUNCATE: (no-flags)
COMMIT 7406
BEGIN 7407
table public.pgbench_accounts: UPDATE: aid[integer]:79774 bid[integer]:1 abalance[integer]:2767 filler[character]:'     

> kill 44782
pg_recvlogical: error: unexpected termination of replication stream: 
 
```
</details>
