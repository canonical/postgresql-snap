import yaml
import subprocess
import time
import pytest

def test_all_apps():
    with open("snap/snapcraft.yaml") as file:
        snapcraft = yaml.safe_load(file)

        override = {}

        skip = [
            "buildext",
            "conftool",
            "createcluster",
            "dropcluster",
            "upgradecluster",
            "backupcluster",
            "restorecluster",
            "virtualenv",
            "ctlcluster",
            "renamecluster",
            "updatedicts",
            "lsclusters",
        ]

        for app, data in snapcraft["apps"].items():
            if not bool(data.get("daemon")) and app not in skip:
                print(f"Running {snapcraft['name']}.{app}...")
                try:
                    subprocess.check_output(
                        f"sudo {snapcraft['name']}.{app} {override.get(app, '--help')}".split()
                    )
                except subprocess.CalledProcessError as e:
                    print(e)
                    raise e


def test_all_services():
    with open("snap/snapcraft.yaml") as file:
        snapcraft = yaml.safe_load(file)

        skip = []

        for app, data in snapcraft["apps"].items():
            if bool(data.get("daemon")) and app not in skip:
                print(f"Running {snapcraft['name']}.{app}...")
                try:
                    subprocess.check_output(
                        f"sudo snap start {snapcraft['name']}.{app}".split()
                    )
                    time.sleep(5)
                    service = subprocess.check_output(
                        f"snap services {snapcraft['name']}.{app}".split()
                    )
                    subprocess.check_output(
                        f"sudo snap stop {snapcraft['name']}.{app}".split()
                    )

                    assert "active" in service.decode()
                except subprocess.CalledProcessError as e:
                    print(e)
                    raise e


def test_version():
    with open("snap/snapcraft.yaml") as file:
        snapcraft = yaml.safe_load(file)
        snap_version = snapcraft["version"]
        app_version = (
            subprocess.check_output([f"{snapcraft['name']}.isready", "--version"])
            .decode()
            .split(" ")[2]
            .strip()
        )
        assert snap_version == app_version
