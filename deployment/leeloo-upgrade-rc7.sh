#!/usr/bin/env bash
# Run as t on Leeloo after staging the official portable server/web archive.
set -euo pipefail
umask 077
[[ $(hostname -s) == leeloo ]] || { echo 'This deployment is for Leeloo only.' >&2; exit 1; }
archive=/home/t/jellyfin-releases/jellyfin_12.0-rc7-amd64.tar.xz
stage=/home/t/jellyfin-releases/12.0-rc7-stage
live=/home/t/jellyfin-from-source
data=/home/t/.local/share/jellyfin-source/data
config=/home/t/.config/jellyfin-source
backup=/home/t/.local/state/jellyfin-upgrades/$(date -u +%Y%m%dT%H%M%SZ)-pre-12.0-rc7
printf '%s  %s\n' 43da0398dadc90aea8851e97616b44312c6067246c4e681bbbfb892f6d8f4a43 "$archive" | sha256sum --check
version=$("$stage/jellyfin" --version 2>&1 || true)
[[ $version == 'Jellyfin.Server 12.0.0.0' ]] || { echo "Unexpected staged version: $version" >&2; exit 1; }
test -s "$stage/jellyfin-web/index.html"
test -d "$live"
test -f "$data/jellyfin.db"
mkdir -p "$backup"
timer_active=false
if systemctl --user is-active --quiet zorg-encode-jellyfin-refresh.timer; then timer_active=true; fi
printf '%s\n' "$timer_active" > "$backup/refresh-timer-was-active"
trap 'echo "Upgrade interrupted; preserve backup at $backup and inspect service state before retrying." >&2' ERR
systemctl --user stop zorg-encode-jellyfin-refresh.timer zorg-encode-jellyfin-refresh.service jellyfin-source.service
[[ $(systemctl --user show jellyfin-source.service -p MainPID --value) == 0 ]]
echo "Copying stopped-server data and configuration to $backup"
cp -a --reflink=auto "$data" "$backup/data"
cp -a --reflink=auto "$config" "$backup/config"
cp -a /home/t/bin/jellyfin-from-source "$backup/launcher"
cp -a /home/t/.config/systemd/user/jellyfin-source.service "$backup/service"
cmp "$data/jellyfin.db" "$backup/data/jellyfin.db"
sync
echo 'Database copy verified; switching server and web runtime.'
mv "$live" "$backup/runtime"
mv "$stage" "$live"
printf '%s\n' '12.0-rc7' > "$backup/upgrade-target"
systemctl --user start jellyfin-source.service
echo "RC7 started. Do not interrupt database migrations. Backup: $backup"
echo 'Restore the refresh timer only after API startup and library verification succeed.'
