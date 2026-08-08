#!/usr/bin/env bats

. autoupdate.sh

setup() {
  export alfred_workflow_data="$BATS_TEST_TMPDIR/data"
  mkdir -p "$alfred_workflow_data"
  export UPDATE_SCRIPT="$BATS_TEST_TMPDIR/update.sh"
  cat > "$UPDATE_SCRIPT" <<'STUB'
#!/bin/bash
printf '{"items":[{"title":"Update to v9.9.9","arg":"https://example.com/W.alfredworkflow"}]}'
STUB
}

@test "set_autoupdate on and off toggles the flag" {
  set_autoupdate on
  autoupdate_enabled
  set_autoupdate off
  run autoupdate_enabled
  [ "$status" -ne 0 ]
}

@test "autoupdate_refresh records a pending update when enabled" {
  set_autoupdate on
  autoupdate_refresh
  [ -f "$alfred_workflow_data/update-available" ]
  run cat "$alfred_workflow_data/update-available"
  [ "$output" == "https://example.com/W.alfredworkflow" ]
}

@test "autoupdate_refresh does nothing when disabled" {
  autoupdate_refresh
  [ ! -f "$alfred_workflow_data/update-available" ]
}

@test "autoupdate_refresh is throttled within a day" {
  set_autoupdate on
  : > "$alfred_workflow_data/autoupdate-checked"
  autoupdate_refresh
  [ ! -f "$alfred_workflow_data/update-available" ]
}

@test "autoupdate_refresh clears a stale pending when no update" {
  set_autoupdate on
  printf 'x' > "$alfred_workflow_data/update-available"
  cat > "$UPDATE_SCRIPT" <<'STUB'
#!/bin/bash
printf '{"items":[]}'
STUB
  autoupdate_refresh
  [ ! -f "$alfred_workflow_data/update-available" ]
}

@test "autoupdate_banner emits an item for a pending update" {
  printf 'https://example.com/W.alfredworkflow' > "$alfred_workflow_data/update-available"
  add_result() { printf '%s|%s\n' "$3" "$2"; }
  run autoupdate_banner
  [ "$output" == "Update available|https://example.com/W.alfredworkflow" ]
}

@test "autoupdate_banner is silent without a pending update" {
  add_result() { printf 'CALLED'; }
  run autoupdate_banner
  [ "$output" == "" ]
}

@test "set_autoupdate off clears a pending update" {
  set_autoupdate on
  printf 'x' > "$alfred_workflow_data/update-available"
  set_autoupdate off
  [ ! -f "$alfred_workflow_data/update-available" ]
}

@test "autoupdate_clear removes a pending update" {
  printf 'x' > "$alfred_workflow_data/update-available"
  autoupdate_clear
  [ ! -f "$alfred_workflow_data/update-available" ]
}

@test "set_autoupdate ignores an unknown value" {
  run set_autoupdate bogus
  [ "$status" -eq 0 ]
  run autoupdate_enabled
  [ "$status" -ne 0 ]
}

@test "autoupdate_menu offers a check and an activate toggle when off" {
  add_result() { printf '%s|%s|%s\n' "$3" "$2" "$7"; }
  run autoupdate_menu "" "up.png"
  [[ "$output" == *"Check for updates||> update"* ]]
  [[ "$output" == *"Activate autoupdate|autoupdate on|"* ]]
}

@test "autoupdate_menu shows deactivate when autoupdate is on" {
  set_autoupdate on
  add_result() { printf '%s|%s\n' "$3" "$2"; }
  run autoupdate_menu "" "up.png"
  [[ "$output" == *"Deactivate autoupdate|autoupdate off"* ]]
}

@test "autoupdate_menu filters by a substring" {
  add_result() { printf '%s\n' "$3"; }
  run autoupdate_menu "activ" "up.png"
  [[ "$output" == *"Activate autoupdate"* ]]
  [[ "$output" != *"Check for updates"* ]]
}
