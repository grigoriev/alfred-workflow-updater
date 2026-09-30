# CLAUDE.md

A self-contained GitHub-release updater for Alfred workflows. It is not an Alfred workflow itself.
Every sibling workflow fetches its release bundle `updater.tar.gz` at build time and ships it in `src/`.
A change here reaches all 7 workflows on their next build.

## Layout

- `update.sh` - the update check and install. A Script Filter with no argument, an installer with a download URL.
- `autoupdate.sh` - sourced helpers: `autoupdate_refresh`, `autoupdate_banner`, `autoupdate_menu`, `set_autoupdate`, `autoupdate_clear`.
- The scripts live at the repo root. There is no `src/`, no `info.plist` and no `workflow_handler.sh`.
- `tests/update.bats`, `tests/autoupdate.bats`. Test files have no `_tests` suffix here.
- `tests/mocks/bin/` - fake `curl` and `open`, so tests never touch the network.

Configuration comes from Alfred workflow variables: `update_repo` (required), `update_asset`, `update_icon`.
Alfred supplies `alfred_workflow_version`, `alfred_workflow_cache` and `alfred_workflow_data`.

## Commands

```sh
make lint       # ShellCheck update.sh and autoupdate.sh in Docker, all severities
make test       # run bats tests (macOS), no updater fetch
make coverage   # bats under kcov in Docker, writes sonar-coverage.xml, lists uncovered lines
make build      # pack update.sh and autoupdate.sh into updater.tar.gz
make clean      # remove the bundle, provenance and coverage
```

1. Install tools with `brew install bats-core jq`.
2. `make lint SHELLCHECK=shellcheck` uses a local ShellCheck instead of Docker.
3. `make lint` runs ShellCheck without `--severity=warning`, so style findings fail here too.

## Constraints and conventions

- The scripts run under stock macOS `/bin/bash` 3.2 on end-user Macs.
- No bash 4+ features: no `mapfile`, `readarray`, `declare -A`, `${var,,}` or `${var^^}`.
- Check a construct with `/bin/bash -c '...'`. zsh and Homebrew bash 5 hide 3.2 gaps.
- No perl. Use `awk`, `sed`, `jq` or bash.
- `update.sh` stays standalone. It builds its own JSON with `json_escape` and needs no other file.
- `autoupdate.sh` may assume only `add_result`, `jq`, `icon.png` and the fetched `update.sh`. All 7 workflows provide these.
- Versions compare with `sort -V`, so `v1.2.10` sorts after `v1.2.9`.
- The autoupdate check is throttled to once a day and is opt-in.
- A new script ships to every workflow only when the `SCRIPTS` list in the Makefile includes it.
- The bundle interface is shared: renaming or removing a function breaks every workflow that calls it.
- SonarCloud shell rules: `[[ ]]` not `[ ]`, positional params into named lowercase `local`s, snake_case functions, explicit `return` at function end, a `*)` default in every `case`, HTTPS for `curl`.

## Review focus

Flag these in a pull request:

- Any bash 4+ feature, or any perl call.
- A new or changed function without a bats test. A bug fix without a test that fails before the fix.
- Unquoted variable expansions, especially URLs, asset names and file paths.
- A `curl` call without `--proto '=https'` or `-f`, as the existing calls use.
- A download installed from anything other than the configured repo's release asset.
- A breaking change to a function name, argument order, variable or flag file that the workflows use.
- A new dependency in `autoupdate.sh` beyond `add_result`, `jq`, `icon.png` and `update.sh`.
- `update.sh` made to depend on another file.
- A new script that the Makefile `SCRIPTS` list, `sonar.sources` and the kcov include pattern miss.
- A test that hits the real GitHub API instead of the `curl` mock.
- A violation of the Sonar shell rules listed above, or any ShellCheck finding.
- A change to `.github/workflows/ci.yml`, `release.yml` or `bump-version.yml` in this repo only. These are byte-identical across all 8 Alfred repos.
- A user-facing change without an entry under `## [Unreleased]` in `CHANGELOG.md`.
- A behavior or variable change without a README update.

Commit, branch and pull request rules are in `CONTRIBUTING.md`.

## CI and release

- `ci.yml`: ShellCheck, actionlint and zizmor on Ubuntu, bats on `macos-latest`, the build, and a SonarCloud scan with kcov coverage.
- The version lives in the git tags only. `make print-version` reads the latest tag. `make set-version` is a no-op.
- A maintainer runs **Bump Version & Release**. It cuts the `CHANGELOG.md` section and tags `v*`.
- `release.yml` attests `update.sh`, `autoupdate.sh` and `updater.tar.gz` and publishes them with `updater.intoto.jsonl`.
- Workflows verify that attestation with `make build CHECK_PROVENANCE=1` before they bundle the updater.
