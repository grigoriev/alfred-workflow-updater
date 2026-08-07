#!/bin/bash

# Shared autoupdate helpers for the Alfred workflows. Fetched at build time next
# to update.sh and sourced by a workflow. Relies on the workflow's add_result
# (workflow_handler.sh), jq, and the fetched updater script.
#
# When enabled, autoupdate_refresh runs a throttled check (at most once a day)
# and records any available update. autoupdate_banner then offers it on screen.

# Path to the fetched updater. Overridable for tests.
UPDATE_SCRIPT="${UPDATE_SCRIPT:-src/update.sh}"

# The autoupdate flag file.
autoupdate_flag() {
  printf '%s/autoupdate' "${alfred_workflow_data:-.}"
  return 0
}

autoupdate_enabled() {
  [[ -f "$(autoupdate_flag)" ]] && return 0
  return 1
}

# Timestamp of the last check.
autoupdate_stamp() {
  printf '%s/autoupdate-checked' "${alfred_workflow_data:-.}"
  return 0
}

# Holds the download url of a pending update, if any.
autoupdate_pending() {
  printf '%s/update-available' "${alfred_workflow_data:-.}"
  return 0
}

# A file's modification time as a unix timestamp. Try GNU stat first (its -c is
# a clean failure on BSD), then BSD stat, so the ambiguous BSD -f never runs on
# GNU where it can print filesystem info instead of failing.
autoupdate_mtime() {
  local file="$1"
  stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null
  return 0
}

# Toggle autoupdate. $1 = on | off.
set_autoupdate() {
  local value="$1"
  case "$value" in
    on)
      mkdir -p "${alfred_workflow_data:-.}"
      : > "$(autoupdate_flag)"
      ;;
    off)
      rm -f "$(autoupdate_flag)" "$(autoupdate_pending)"
      ;;
    *) : ;;
  esac
  return 0
}

# Clear a pending update. Call this when installing one.
autoupdate_clear() {
  rm -f "$(autoupdate_pending)"
  return 0
}

# Run a throttled update check (at most once a day) when autoupdate is on, and
# record any available update for the banner.
autoupdate_refresh() {
  autoupdate_enabled || return 0
  [[ -f "$UPDATE_SCRIPT" ]] || return 0
  local stamp now mtime out url
  stamp="$(autoupdate_stamp)"
  if [[ -f "$stamp" ]]; then
    now="$(date +%s)"
    mtime="$(autoupdate_mtime "$stamp")"
    if [[ "$mtime" =~ ^[0-9]+$ ]] && [[ $(( now - mtime )) -lt 86400 ]]; then
      return 0
    fi
  fi
  mkdir -p "${alfred_workflow_data:-.}"
  : > "$stamp"
  out="$(bash "$UPDATE_SCRIPT" "" 2>/dev/null)"
  url="$(printf '%s' "$out" | jq -r '.items[]?.arg // empty' 2>/dev/null | head -1)"
  if [[ -n "$url" ]]; then
    printf '%s' "$url" > "$(autoupdate_pending)"
  else
    rm -f "$(autoupdate_pending)"
  fi
  return 0
}

# Queue an "update available" banner when a pending update was found. Uses the
# workflow's add_result and its icon.png.
autoupdate_banner() {
  local file url
  file="$(autoupdate_pending)"
  [[ -f "$file" ]] || return 0
  url="$(cat "$file" 2>/dev/null)"
  [[ -n "$url" ]] || return 0
  add_result "" "$url" "Update available" "Install the new version of this workflow" "icon.png" "yes"
  return 0
}
