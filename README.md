# alfred-workflow-updater

![CI](https://github.com/grigoriev/alfred-workflow-updater/actions/workflows/ci.yml/badge.svg)
[![Release](https://img.shields.io/github/v/release/grigoriev/alfred-workflow-updater)](https://github.com/grigoriev/alfred-workflow-updater/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=grigoriev_alfred-workflow-updater&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=grigoriev_alfred-workflow-updater)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=grigoriev_alfred-workflow-updater&metric=coverage)](https://sonarcloud.io/summary/new_code?id=grigoriev_alfred-workflow-updater)

A tiny, self-contained GitHub-release updater for Alfred workflows. One Bash
file, no dependencies. Drop it into any workflow, point it at a GitHub repo,
and it checks the latest release and installs updates.

## How it works

`update.sh` runs as a Script Filter. It reads the latest release from the
GitHub API, compares the tag with the installed workflow version, and shows:

- **Update to vX.Y.Z** when a newer release exists. Pressing ⏎ downloads and installs it.
- **Up to date** otherwise.

Selecting the update item runs `update.sh` again with the download URL. That
downloads the asset and opens it, so Alfred installs the new version.

## Install into your workflow

1. Copy `update.sh` into your workflow folder.
2. Add a **Script Filter**:
   - Keyword: e.g. `myworkflow-update`
   - Language: `/bin/bash`
   - Script: `./update.sh`
3. Add a **Run Script** connected from the Script Filter:
   - Language: `/bin/bash`
   - Script: `./update.sh "{query}"`
4. Set workflow variables (Configuration, or the environment):
   - `update_repo` (required): `owner/repo`
   - `update_asset` (optional): release asset filename, e.g.
     `MyWorkflow.alfredworkflow`. Leave unset to use the first
     `*.alfredworkflow` asset of the release.
   - `update_icon` (optional): icon path (default `icon.png`).

Your GitHub releases must attach the `.alfredworkflow` file as an asset. The
installed version (Alfred's `alfred_workflow_version`) is compared with the
release tag using `sort -V`, so tags like `v1.2.10` sort correctly.

## Config reference

| Variable       | Required | Default     | Description                         |
| -------------- | -------- | ----------- | ----------------------------------- |
| `update_repo`  | yes      | —           | GitHub `owner/repo`.                |
| `update_asset` | no       | first asset | Release asset filename to download. |
| `update_icon`  | no       | `icon.png`  | Icon path for the result item.      |

## Tests

```sh
brew install bats-core
bats tests
```

System commands (`curl`, `open`) are mocked under `tests/mocks/bin`, so the
tests run without touching the network.

## License

MIT. See [LICENSE](LICENSE).
