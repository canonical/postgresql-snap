# PostgreSQL snap
[![Release to Snap Store](https://github.com/canonical/postgresql-snap/actions/workflows/release.yaml/badge.svg)](https://github.com/canonical/postgresql-snap/actions/workflows/release.yaml)

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/postgresql)

This repository contains the packaging metadata for creating a [snap](https://snapcraft.io/) of PostgreSQL built from the official Ubuntu repositories. 

For more information about using the PostgreSQL snap, including commands and examples, see [`docs/` folder](/docs/).

## Install the snap

```shell
sudo snap install postgresql
```

## Build the snap

Clone the repository:
```shell
git clone git@github.com:canonical/postgresql-snap.git
cd postgresql-snap
```

Install and configure prerequisites:
```bash
sudo snap install snapcraft
sudo snap install lxd
sudo lxd init --auto
```

In order to properly test the confinement of the snap, we must install it using the `--dangerous` flag, instead of the `--devmode` one. See snap [installation modes](https://snapcraft.io/docs/install-modes).

```bash
snapcraft pack
sudo snap install ./postgresql*.snap --dangerous --jailmode
```

## Test the snap

See the examples below for how to use [Spread](https://github.com/canonical/spread) for snap testing:

```bash
snapcraft test                       # run all tests
ls -la spread/tests/                 # list all tests
snapcraft test -- spread/tests/smoke # run one test suite
snapcraft test --debug               # to open shell for failed test
```

## License

The PostgreSQL Snap is free software, distributed under the Apache
Software License, version 2.0. See
[LICENSE](https://github.com/canonical/postgresql-snap/blob/14/edge/LICENSE)
for more information.
