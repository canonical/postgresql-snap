#!/usr/bin/env python3
# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.
# /// script
# requires-python = ">=3.11"
# dependencies = ["jinja2"]
# ///
"""Generate draft release notes for a stable release of the PostgreSQL snap.

See README.md in this directory for usage.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tomllib
import urllib.request
from functools import cache
from pathlib import Path

from jinja2 import Environment, FileSystemLoader

REPO = "canonical/postgresql-snap"
HERE = Path(__file__).parent
# Section title -> PR labels that put a PR into it. Unmatched PRs go to OTHER.
SECTIONS = {"Features": {"enhancement"}, "Bug fixes": {"bug"}}
OTHER = "Other improvements"
# Snap base -> (Ubuntu release, Launchpad series)
BASES = {"core24": ("Ubuntu 24.04 LTS", "noble"), "core26": ("Ubuntu 26.04 LTS", "resolute")}


@cache
def github_token() -> str | None:
    if token := os.environ.get("GITHUB_TOKEN"):
        return token
    try:
        result = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return None
    return result.stdout.strip()


def fetch(url: str, headers: dict[str, str] | None = None) -> str:
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers or {})) as response:
        return response.read().decode()


def github(path: str, raw: bool = False):
    accept = "application/vnd.github.raw+json" if raw else "application/vnd.github+json"
    headers = {"Accept": accept}
    if token := github_token():
        headers["Authorization"] = f"Bearer {token}"
    body = fetch(f"https://api.github.com/repos/{REPO}/{path}", headers)
    return body if raw else json.loads(body)


def tag(release: dict) -> str:
    """Git tag created by the release workflow (all architectures share one commit)."""
    return f"rev{max(release['revisions'].values())}"


def select(releases: list[dict], track: str, version: str | None) -> tuple[dict, dict | None]:
    """Return the latest release of a version and the latest release of an earlier version."""
    in_track = sorted((r for r in releases if r["track"] == track), key=lambda r: r["date"])
    if not in_track:
        sys.exit(f"No releases of track {track} in the releases file")
    version = version or in_track[-1]["version"]
    same = [r for r in in_track if r["version"] == version]
    if not same:
        sys.exit(f"No release of version {version} in track {track}")
    earlier = [r for r in in_track if r["date"] < same[0]["date"] and r["version"] != version]
    return same[-1], earlier[-1] if earlier else None


def changes(base: str, head: str) -> dict[str, list[dict]]:
    """Sort merged PRs (or bare commits) between two refs into sections by label."""
    compare = github(f"compare/{base}...{head}")
    if (listed := len(compare["commits"])) < compare["total_commits"]:
        print(f"Warning: only the first {listed} commits are listed", file=sys.stderr)
    sections = {title: [] for title in [*SECTIONS, OTHER]}
    seen = set()
    for commit in compare["commits"]:
        pulls = [p for p in github(f"commits/{commit['sha']}/pulls") if p["merged_at"]]
        if pulls:
            pr = pulls[0]
            if pr["number"] in seen:
                continue
            seen.add(pr["number"])
            item = {"title": pr["title"], "ref": f"#{pr['number']}", "url": pr["html_url"]}
            labels = {label["name"] for label in pr["labels"]}
        else:
            subject = commit["commit"]["message"].splitlines()[0]
            item = {"title": subject, "ref": commit["sha"][:7], "url": commit["html_url"]}
            labels = set()
        section = next((title for title, wanted in SECTIONS.items() if labels & wanted), OTHER)
        sections[section].append(item)
    return sections


def ubuntu_package(version: str, series: str, date) -> dict | None:
    """Find the Ubuntu source package of a PostgreSQL version published by the release date."""
    name = f"postgresql-{version.split('.')[0]}"
    url = (
        "https://api.launchpad.net/devel/ubuntu/+archive/primary?ws.op=getPublishedSources"
        f"&exact_match=true&source_name={name}"
        f"&distro_series=https://api.launchpad.net/devel/ubuntu/{series}"
    )
    for entry in json.loads(fetch(url))["entries"]:  # newest first
        published = entry["date_published"]
        package_version = entry["source_package_version"]
        if (
            entry["pocket"] != "Proposed"
            and package_version.startswith(f"{version}-")
            and published
            and published[:10] <= str(date)
        ):
            url = f"https://launchpad.net/ubuntu/+source/{name}/{package_version}"
            return {"name": name, "version": package_version, "url": url}
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("track", help="snap track, e.g. 16")
    parser.add_argument("version", nargs="?", help="snap version (default: latest in the track)")
    parser.add_argument("-r", "--releases", type=Path, default=HERE / "releases.toml")
    parser.add_argument("-o", "--output", type=Path, help="output file (default: stdout)")
    args = parser.parse_args()

    with args.releases.open("rb") as file:
        release, previous = select(tomllib.load(file)["release"], args.track, args.version)

    head = tag(release)
    base_ref = release.get("since") or (tag(previous) if previous else None)
    if base_ref:
        sections = changes(base_ref, head)
    else:
        print("Warning: no previous release, set `since` to list changes", file=sys.stderr)
        sections = {title: [] for title in [*SECTIONS, OTHER]}

    snapcraft = github(f"contents/snap/snapcraft.yaml?ref={head}", raw=True)
    base = re.search(r"^base:\s*(\S+)", snapcraft, re.MULTILINE).group(1)
    ubuntu, series = BASES[base]
    date = release["date"]

    env = Environment(
        loader=FileSystemLoader(HERE),
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
    )
    notes = env.get_template("template.md.j2").render(
        repo=REPO,
        release=release,
        previous=previous,
        channel=f"{release['track']}/stable",
        date=f"{date.day} {date:%B %Y}",
        base=base,
        ubuntu=ubuntu,
        package=ubuntu_package(release["version"], series, date),
        sections=sections,
        compare_url=f"https://github.com/{REPO}/compare/{base_ref}...{head}" if base_ref else None,
    )
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(notes)
    else:
        print(notes, end="")


if __name__ == "__main__":
    main()
