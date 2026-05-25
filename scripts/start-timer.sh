#!/usr/bin/env bash
set -euo pipefail

# Install/refresh user systemd units for IOAA release automation, then restart timer.
# Run this after editing files in astro-dev/systemd/.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_SERVICE="$PROJECT_ROOT/systemd/ioaa-astro-release.service"
SRC_TIMER="$PROJECT_ROOT/systemd/ioaa-astro-release.timer"
DST_DIR="$HOME/.config/systemd/user"

if [[ ! -f "$SRC_SERVICE" ]]; then
  echo "Missing source service file: $SRC_SERVICE" >&2
  exit 1
fi

if [[ ! -f "$SRC_TIMER" ]]; then
  echo "Missing source timer file: $SRC_TIMER" >&2
  exit 1
fi

mkdir -p "$DST_DIR"

cp -f "$SRC_SERVICE" "$DST_DIR/ioaa-astro-release.service"
cp -f "$SRC_TIMER" "$DST_DIR/ioaa-astro-release.timer"

systemctl --user daemon-reload
systemctl --user enable --now ioaa-astro-release.timer
systemctl --user restart ioaa-astro-release.timer

echo "Installed units to $DST_DIR and restarted ioaa-astro-release.timer."
echo
systemctl --user list-timers ioaa-astro-release.timer --no-pager
echo
echo "Loaded timer file: $DST_DIR/ioaa-astro-release.timer"
systemctl --user cat ioaa-astro-release.timer | sed -n 's/^OnCalendar=//p'
