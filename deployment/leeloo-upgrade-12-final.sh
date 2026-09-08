#!/usr/bin/env bash
# Run as t on Leeloo after downloading the official portable archive.
set -euo pipefail
umask 077
[[ $(hostname -s) == leeloo ]]
archive=/home/t/jellyfin-releases/jellyfin_12.0-amd64.tar.xz
stage=/home/t/jellyfin-releases/12.0-final-stage
live=/home/t/jellyfin-from-source
data=/home/t/.local/share/jellyfin-source
config=/home/t/.config/jellyfin-source
backup=/home/t/.local/state/jellyfin-upgrades/$(date -u +%Y%m%dT%H%M%SZ)-pre-12.0-final
printf '%s  %s\n' 13c52b18119e5c2e9a2682f7b97eb4fac9babd64d43618c4ce567e578e80124a "$archive" | sha256sum --check
if [[ ! -e "$stage" ]]; then
    mkdir "$stage"
    tar -xJf "$archive" --strip-components=1 -C "$stage"
fi
[[ $("$stage/jellyfin" --version 2>&1) == 'Jellyfin.Server 12.0.0.0' ]]
test -s "$stage/jellyfin-web/index.html"
test -s "$data/data/data/jellyfin.db"
mkdir -p "$backup"
systemctl --user is-active zorg-encode-jellyfin-refresh.timer > "$backup/refresh-timer-state" || true
trap 'echo "Upgrade interrupted; inspect service and preserve backup: $backup" >&2' ERR
systemctl --user stop zorg-encode-jellyfin-refresh.timer zorg-encode-jellyfin-refresh.service jellyfin-source.service
[[ $(systemctl --user show jellyfin-source.service -p MainPID --value) == 0 ]]
cp -a --reflink=auto "$data" "$backup/data-root"
cp -a --reflink=auto "$config" "$backup/config"
cp -a /home/t/bin/jellyfin-from-source "$backup/launcher"
cp -a /home/t/.config/systemd/user/jellyfin-source.service "$backup/service"
cmp "$data/data/data/jellyfin.db" "$backup/data-root/data/data/jellyfin.db"
sync
mv "$live" "$backup/runtime"
mv "$stage" "$live"
systemctl --user start jellyfin-source.service
echo "Jellyfin 12 final started. Backup: $backup"
echo 'Verify startup and libraries before restoring any previously active refresh timer.'
