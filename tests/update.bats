#!/usr/bin/env bats

setup() {
  export PATH="$BATS_TEST_DIRNAME/mocks/bin:$PATH"
  export alfred_workflow_cache="$BATS_TEST_TMPDIR/cache"
  export alfred_workflow_version=2.0.1
  unset update_repo update_asset MOCK_LATEST MOCK_CURL_FAIL
}

@test "unconfigured: prompts to set update_repo" {
  run bash update.sh
  [[ "$output" =~ "Updater not configured" ]]
}

@test "update available with update_asset (direct url)" {
  export update_repo=grigoriev/alfred-network-workflow
  export update_asset=Network.alfredworkflow
  export MOCK_LATEST=v2.0.2
  run bash update.sh
  [[ "$output" =~ "Update to v2.0.2" ]]
  [[ "$output" =~ "releases/latest/download/Network.alfredworkflow" ]]
}

@test "update available without update_asset (autodetect)" {
  export update_repo=owner/repo
  export MOCK_LATEST=v3.0.0
  run bash update.sh
  [[ "$output" =~ "Update to v3.0.0" ]]
  [[ "$output" =~ "example.com/Network.alfredworkflow" ]]
}

@test "up to date when versions match" {
  export update_repo=owner/repo
  export MOCK_LATEST=v2.0.1
  run bash update.sh
  [[ "$output" =~ "Up to date (v2.0.1)" ]]
}

@test "older remote is not offered" {
  export update_repo=owner/repo
  export MOCK_LATEST=v2.0.0
  run bash update.sh
  [[ "$output" =~ "Up to date" ]]
}

@test "double digit versions order correctly" {
  export update_repo=owner/repo
  export update_asset=W.alfredworkflow
  export alfred_workflow_version=2.0.9
  export MOCK_LATEST=v2.0.10
  run bash update.sh
  [[ "$output" =~ "Update to v2.0.10" ]]
}

@test "network failure shows an error" {
  export update_repo=owner/repo
  export MOCK_CURL_FAIL=1
  run bash update.sh
  [[ "$output" =~ "Could not check for updates" ]]
}

@test "output is valid json" {
  export update_repo=owner/repo
  export update_asset=W.alfredworkflow
  export MOCK_LATEST=v9.9.9
  run bash update.sh
  echo "$output" | python3 -c 'import json,sys; json.load(sys.stdin)'
}

@test "action downloads and installs" {
  run bash update.sh https://example.com/W.alfredworkflow
  [ "$status" -eq 0 ]
  [ -f "$alfred_workflow_cache/update.alfredworkflow" ]
}
