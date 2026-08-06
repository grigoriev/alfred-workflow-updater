#!/bin/bash
#
# alfred-workflow-updater
# A generic GitHub-release updater for Alfred workflows.
#
# Self contained: copy this one file into any workflow and reuse it.
#
# Configure with Alfred workflow variables:
#   update_repo   required   "owner/repo" on GitHub
#   update_asset  optional   release asset filename to download; when unset
#                            the first *.alfredworkflow asset is used
#   update_icon   optional   icon path for the result (default: icon.png)
#
# Alfred provides alfred_workflow_version and alfred_workflow_cache.
#
# Wire a Script Filter (script "./update.sh") to a Run Script
# (script "./update.sh \"{query}\"") that installs the download.

repo="${update_repo:-}"
asset="${update_asset:-}"
cache="${alfred_workflow_cache:-/tmp}"
current="${alfred_workflow_version:-}"
icon="${update_icon:-icon.png}"

json_escape() {
  local text="$1"
  printf '%s' "$text" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
  return 0
}

# $1 title  $2 subtitle  $3 arg  $4 valid (true/false)
item() {
  local title="$1" subtitle="$2" arg="$3" valid="$4"
  printf '{"title":"%s","subtitle":"%s","arg":"%s","valid":%s,"icon":{"path":"%s"}}' \
    "$(json_escape "$title")" "$(json_escape "$subtitle")" "$(json_escape "$arg")" \
    "$valid" "$(json_escape "$icon")"
  return 0
}

items() {
  local body="$1"
  printf '{"items":[%s]}\n' "$body"
  return 0
}

# Action: download the workflow and let Alfred install it
query="$1"
if [[ "$query" != "" ]]; then
  mkdir -p "$cache"
  file="$cache/update.alfredworkflow"
  if curl --proto '=https' -sfL "$query" -o "$file"; then
    open "$file"
  fi
  exit
fi

if [[ "$repo" == "" ]]; then
  items "$(item 'Updater not configured' 'Set the update_repo workflow variable to owner/repo' '' false)"
  exit
fi

api=$(curl --proto '=https' -sfL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null)
latest=$(printf '%s' "$api" | grep -m 1 '"tag_name"' | sed -E 's/.*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/')

if [[ "$latest" == "" ]]; then
  items "$(item 'Could not check for updates' 'Check your connection and try again' '' false)"
  exit
fi

if [[ "$asset" != "" ]]; then
  url="https://github.com/$repo/releases/latest/download/$asset"
else
  url=$(printf '%s' "$api" | grep '"browser_download_url"' | grep '\.alfredworkflow' | head -1 | sed -E 's/.*"browser_download_url":[[:space:]]*"([^"]+)".*/\1/')
fi

if [[ "$latest" != "$current" ]] \
  && [[ "$(printf '%s\n%s\n' "$latest" "$current" | sort -V | tail -n 1)" == "$latest" ]] \
  && [[ "$url" != "" ]]; then
  items "$(item "Update to v$latest" "You have v$current, press ⏎ to update" "$url" true)"
else
  items "$(item "Up to date (v$current)" "You have the latest version" '' false)"
fi
