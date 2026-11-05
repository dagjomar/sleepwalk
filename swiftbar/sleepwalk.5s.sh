#!/bin/bash
# <xbar.title>sleepwalk</xbar.title>
# <xbar.desc>Keep the Mac awake, lid closed too, for a set time.</xbar.desc>
# <xbar.dependencies>sleepwalk</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
#
# SwiftBar plugin for the sleepwalk CLI. Symlink this file into your SwiftBar
# plugin folder; it finds the CLI next to itself in the repo
# (../sleepwalk). The ".5s" in the name makes SwiftBar refresh it every 5s.

SELF=$(readlink -f "$0")
CLI=$(dirname "$SELF")/../sleepwalk
# Copied instead of symlinked: fall back to the CLI on PATH. SwiftBar's PATH
# is minimal, so add the usual user bin folders.
if [ ! -x "$CLI" ]; then
  CLI=$(PATH="$HOME/.local/bin:$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH" command -v sleepwalk)
fi
PRESETS="15m 30m 1h 2h 3h 5h"

alert() {
  osascript -e 'on run argv' -e 'display alert "sleepwalk" message (item 1 of argv) as warning' -e 'end run' "$1" >/dev/null
}

# Runs the CLI and shows its error, if any, as an alert instead of losing it.
run_cli() {
  local err
  err=$("$CLI" "$@" 2>&1 >/dev/null) || alert "${err:-sleepwalk $* failed}"
}

# Menu clicks call this script again with an action argument.
case "${1:-}" in
  run)
    shift
    run_cli "$@"
    exit 0
    ;;
  custom)
    answer=$(osascript \
      -e 'text returned of (display dialog "Sleepwalk for how long?" & return & "1m to 5h, e.g. 45m, 2h, 1h30m" default answer "1h" with title "sleepwalk")' \
      2>/dev/null) || exit 0 # Cancel
    run_cli "$answer"
    exit 0
    ;;
esac

# 2700 -> "45m", 5400 -> "1h30m", 42 -> "42s": short enough for the menu bar.
short_left() {
  local s=$1 h m
  [ "$s" -lt 0 ] && s=0
  h=$((s / 3600))
  m=$(((s % 3600 + 59) / 60)) # round up so "1m" shows until the last minute
  if [ "$s" -lt 60 ]; then
    echo "${s}s"
  elif [ "$m" -eq 60 ]; then
    echo "$((h + 1))h"
  elif [ "$m" -eq 0 ]; then
    echo "${h}h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh%02dm\n' "$h" "$m"
  else
    echo "${m}m"
  fi
}

# 4521 -> "1h 15m 21s"
long_left() {
  local s=$1
  [ "$s" -lt 0 ] && s=0
  local h=$((s / 3600)) m=$((s % 3600 / 60)) sec=$((s % 60))
  if [ "$h" -gt 0 ]; then
    echo "${h}h ${m}m ${sec}s"
  elif [ "$m" -gt 0 ]; then
    echo "${m}m ${sec}s"
  else
    echo "${sec}s"
  fi
}

if [ ! -x "$CLI" ]; then
  echo ":exclamationmark.triangle: | color=red"
  echo "---"
  echo "sleepwalk CLI not found at $CLI"
  exit 0
fi

read -r state exp pw < <("$CLI" status --raw)
now=$(date +%s)
action="bash=\"$SELF\" terminal=false refresh=true"

# Menu bar title
if [ "$state" = disabled ] && [ "$exp" != - ]; then
  echo ":figure.walk: $(short_left $((exp - now)))"
elif [ "$state" = disabled ]; then
  echo ":exclamationmark.triangle.fill: | sfcolor=red"
else
  echo ":moon.zzz:"
fi
echo "---"

# Status
if [ "$state" = disabled ] && [ "$exp" != - ]; then
  echo "Sleepwalking until $(date -r "$exp" +%H:%M:%S)"
  echo "$(long_left $((exp - now))) left | size=12"
elif [ "$state" = disabled ]; then
  echo "Sleep is off and no timer is running | color=red"
else
  echo "Sleep is on"
fi
echo "---"

if [ "$pw" != yes ]; then
  # Without the sudoers rule every change needs a password, which only a
  # terminal can ask for.
  echo "Set up passwordless mode… | bash=\"$CLI\" param1=setup terminal=true refresh=true"
  echo "Needed once so the menu can turn sleep off and on. Opens Terminal. | size=11"
  if [ "$state" = disabled ]; then
    echo "Wake up now (Terminal) | bash=\"$CLI\" param1=off terminal=true refresh=true"
  fi
  exit 0
fi

if [ "$state" = disabled ]; then
  echo "Wake up now (sleep back on) | $action param1=run param2=off"
  echo "---"
  echo "Restart timer with"
else
  echo "Sleepwalk for"
fi
for d in $PRESETS; do
  echo "--$d | $action param1=run param2=$d"
done
echo "Custom… | $action param1=custom"
