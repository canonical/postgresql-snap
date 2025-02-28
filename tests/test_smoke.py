import yaml
import subprocess
import time
import pytest


def test_install():
    with open("snap/snapcraft.yaml") as file:
        snapcraft = yaml.safe_load(file)

        subprocess.run(
            f"sudo snap install ./{snapcraft['name']}_{snapcraft['version']}_amd64.snap --devmode".split(),
            check=True,
        )


@pytest.mark.run(after="test_install")
def test_all_apps():
    with open("snap/snapcraft.yaml") as file:
        snapcraft = yaml.safe_load(file)

        override = {}

        skip = [
            "pg-buildext",
            "pg-conftool",
            "pg-createcluster",
            "pg-dropcluster",
            "pg-upgradecluster",
            "pg-backupcluster",
            "pg-restorecluster",
            "pg-virtualenv",
            "pg-ctlcluster",
            "pg-renamecluster",
            "pg-updatedicts",
            "pg-lsclusters",
        ]

        for app, data in snapcraft["apps"].items():
            if not bool(data.get("daemon")) and app not in skip:
                subprocess.run(
                    f"{snapcraft['name']}.{app} {override.get(app, '--help')}".split(),
                    check=True,
                )


@pytest.mark.run(after="test_install")
def test_all_services():
    with open("snap/snapcraft.yaml") as file:
        snapcraft = yaml.safe_load(file)

        skip = []

        for app, data in snapcraft["apps"].items():
            if bool(data.get("daemon")) and app not in skip:
                subprocess.run(
                    f"sudo snap start {snapcraft['name']}.{app}".split(), check=True
                )
                time.sleep(5)
                service = subprocess.run(
                    f"snap services {snapcraft['name']}.{app}".split(),
                    check=True,
                    capture_output=True,
                )
                subprocess.run(f"sudo snap stop {snapcraft['name']}.{app}".split())

                assert "active" in str(service.stdout)


@pytest.mark.run(after="test_install")
def test_version():
    with open("snap/snapcraft.yaml") as file:
        snapcraft = yaml.safe_load(file)
        snap_version = snapcraft["version"]
        app_version = (
            subprocess.check_output([f"{snapcraft['name']}.pg-isready", "--version"])
            .decode()
            .split(" ")[2]
        )
        assert snap_version == app_version
