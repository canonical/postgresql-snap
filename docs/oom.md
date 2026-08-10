# OOM tuning

When Linux runs out of memory, the kernel OOM killer picks a victim process based on its
`oom_score`, which can be biased per process via `/proc/<pid>/oom_score_adj`
(`-1000` = never kill, `0` = default, `1000` = kill first).

## Default behavior of the snap

Debian/Ubuntu APT packages of PostgreSQL start the postmaster with `oom_score_adj=-900`
(strongly protected) while each child backend resets itself to `0`, so a runaway query
can be killed without taking down the whole database. Inside the
[PostgreSQL snap](https://snapcraft.io/postgresql) this mechanism cannot work: strict
snap confinement forbids writing `/proc/<pid>/oom_score_adj` (no snapd interface grants
it), so **all PostgreSQL processes run with the default `oom_score_adj=0`** — the same
as any ordinary process or a PostgreSQL container image.

This default is safe for most deployments:

* If a backend is OOM-killed, the postmaster performs automatic crash recovery.
* If the postmaster is OOM-killed, systemd restarts the `postgresql` service.

## Protecting PostgreSQL with `resilience.vitality-hint`

To shield PostgreSQL from the OOM killer, use snapd's built-in
[service vitality](https://snapcraft.io/docs/system-options) option. It is applied by
systemd from outside the snap's confinement, so no interface is needed:

```shell
sudo snap set system resilience.vitality-hint=postgresql
sudo snap restart postgresql.postgresql
```

The option takes a comma-separated list of snap names ranked by importance: the snap in
position *N* gets `OOMScoreAdjust=-900 + N` on its services (`-900` is reserved for
snapd itself), so the example above runs PostgreSQL with `oom_score_adj=-899`.

Verify the result:

```shell
systemctl show -p OOMScoreAdjust snap.postgresql.postgresql.service
cat /proc/$(pgrep -o -x postgres)/oom_score_adj
```

To revert to the default:

```shell
sudo snap unset system resilience.vitality-hint
sudo snap restart postgresql.postgresql
```

## Caveat: the whole process tree is protected

Unlike the APT packages, this protection applies to **every** PostgreSQL process:
child backends inherit `-899` and, due to the confinement restriction above, cannot
reset themselves to `0`. Upstream PostgreSQL
[advises against](https://www.postgresql.org/docs/current/kernel-resources.html#LINUX-MEMORY-OVERCOMMIT)
protecting backends, because a single memory-hungry query then deflects OOM kills onto
the rest of the system.

In practice:

* On a **dedicated database host**, whole-tree protection is usually the right call —
  everything on the machine exists to serve PostgreSQL.
* On a **shared host**, prefer the default (`0`) and rely on crash recovery, or address
  memory pressure directly (`work_mem`, connection limits, swap/overcommit settings).

## Note on `PG_OOM_ADJUST_FILE`

The snap builds `pg_ctlcluster` with `PG_OOM_ADJUST_FILE=/dev/null` as the default so
that the (inevitably denied) per-fork writes to `oom_score_adj` do not flood the kernel
log with AppArmor denials (see
[issue #190](https://github.com/canonical/postgresql-snap/issues/190)). The value can
be overridden per cluster in
`/var/snap/postgresql/common/etc/postgresql/18/main/environment`, but pointing it back
at `/proc/self/oom_score_adj` only restores the denials — the write stays forbidden by
confinement.
