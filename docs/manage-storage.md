# Storage management

The [PostgreSQL snap](https://snapcraft.io/postgresql) uses the standard [`SNAP_COMMON`](https://canonical-robotics.readthedocs-hosted.com/en/latest/explanations/snaps/snap-data-and-file-storage/) location to store all DB related data. It allows users to use all snap related features, like refreshing, saving, and restore.

## Re-define data storage location

Redefining data storage location is possible using bind-mount on the host machine.

Create a storage to keep your data and logs:

```shell
sudo mkdir -p /srv/mypgdata/data /srv/mypgdata/logs
```

Stop the PostgreSQL database before moving data:

```shell
sudo snap stop postgresql.postgresql
```

Move current data and logs:

```shell
sudo cp -a /var/snap/postgresql/common/var/lib/postgresql/* /srv/mypgdata/data
sudo cp -a /var/snap/postgresql/common/var/log/postgresql/* /srv/mypgdata/logs
```

Mount data and logs storage inside the snap:

```shell
sudo mount --bind /srv/mypgdata/data /var/snap/postgresql/common/var/lib/postgresql
sudo mount --bind /srv/mypgdata/logs /var/snap/postgresql/common/var/log/postgresql
```

> [!NOTE]
> Symbolic links are not allowed. Use `mount --bind`.


Restart the PostgreSQL database:

```shell
sudo snap start postgresql.postgresql
```

> [!IMPORTANT]
> Always unmount your manually mounted storages before removing the snap.
