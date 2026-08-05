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

REPO="${update_repo:-}"
ASSET="${update_asset:-}"
CACHE="${alfred_workflow_cache:-/tmp}"
CURRENT="${alfred_workflow_version:-}"
ICON="${update_icon:-icon.png}"

jsonEscape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# $1 title  $2 subtitle  $3 arg  $4 valid (true/false)
item() {
  printf '{"title":"%s","subtitle":"%s","arg":"%s","valid":%s,"icon":{"path":"%s"}}' \
    "$(jsonEscape "$1")" "$(jsonEscape "$2")" "$(jsonEscape "$3")" "$4" "$(jsonEscape "$ICON")"
}

items() {
  printf '{"items":[%s]}\n' "$1"
}

# Action: download the workflow and let Alfred install it
if [ "$1" != "" ]; then
  mkdir -p "$CACHE"
  FILE="$CACHE/update.alfredworkflow"
  if curl -sfL "$1" -o "$FILE"; then
    open "$FILE"
  fi
  exit
fi

if [ "$REPO" == "" ]; then
  items "$(item 'Updater not configured' 'Set the update_repo workflow variable to owner/repo' '' false)"
  exit
fi

API=$(curl -sfL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null)
LATEST=$(printf '%s' "$API" | grep -m 1 '"tag_name"' | sed -E 's/.*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/')

if [ "$LATEST" == "" ]; then
  items "$(item 'Could not check for updates' 'Check your connection and try again' '' false)"
  exit
fi

if [ "$ASSET" != "" ]; then
  URL="https://github.com/$REPO/releases/latest/download/$ASSET"
else
  URL=$(printf '%s' "$API" | grep '"browser_download_url"' | grep '\.alfredworkflow' \
    | head -1 | sed -E 's/.*"browser_download_url":[[:space:]]*"([^"]+)".*/\1/')
fi

if [ "$LATEST" != "$CURRENT" ] \
  && [ "$(printf '%s\n%s\n' "$LATEST" "$CURRENT" | sort -V | tail -n 1)" == "$LATEST" ] \
  && [ "$URL" != "" ]; then
  items "$(item "Update to v$LATEST" "You have v$CURRENT, press ⏎ to update" "$URL" true)"
else
  items "$(item "Up to date (v$CURRENT)" "You have the latest version" '' false)"
fi
