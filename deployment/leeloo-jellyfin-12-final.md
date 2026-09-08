# Leeloo Jellyfin 12 final

Deployed 2026-09-08 using the official combined server/web Linux amd64 archive:
https://repo.jellyfin.org/files/server/linux/stable/v12.0/amd64/jellyfin_12.0-amd64.tar.xz

SHA256: `13c52b18119e5c2e9a2682f7b97eb4fac9babd64d43618c4ce567e578e80124a`

Upgrade script: `leeloo-upgrade-12-final.sh`.

Backup (data root, configuration, launcher, service unit and RC7 runtime):
`/home/t/.local/state/jellyfin-upgrades/20260908T061620Z-pre-12.0-final`

The stopped-service backup includes the actual SQLite database at
`data-root/data/data/jellyfin.db`. The runtime is `/home/t/jellyfin-from-source`;
the user service remains `jellyfin-source.service`.

Verified service active and API HTTP 200 reporting 12.0.0. Both Panama libraries
retain media1/media2 paths and empty external metadata/image provider lists.
Trickplay remains enabled for Panama with its daily 03:00 UTC trigger.
The previously active legacy library-refresh timer was restored.
