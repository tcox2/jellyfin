# Leeloo Jellyfin 12 RC7 Upgrade

Requested upgrade on 2026-09-05 from the custom 10.11.0 installation to the latest
official Jellyfin 12 release candidate, `v12.0-rc7` (published 2026-08-31).

## Artifact

- Release: https://github.com/jellyfin/jellyfin/releases/tag/v12.0-rc7
- Portable AMD64 server and matching web client:
  https://repo.jellyfin.org/files/server/linux/preview/v12.0-rc7/amd64/jellyfin_12.0-rc7-amd64.tar.xz
- Published SHA-256: `43da0398dadc90aea8851e97616b44312c6067246c4e681bbbfb892f6d8f4a43`
- Checksum source: append `?mirrorlist` to the archive URL.
- Downloaded archive: `/home/t/jellyfin-releases/jellyfin_12.0-rc7-amd64.tar.xz`
- Staging directory: `/home/t/jellyfin-releases/12.0-rc7-stage`

The upstream RC is a preview. Initial startup performs database migrations; do
not interrupt it. The release permits upgrades from 10.10.7+ or 10.11.x. Only
bundled metadata providers were installed; no external plugin DLLs were found.

## Deployment

`leeloo-upgrade-rc7.sh` checks the artifact, stops the server and its refresh timer,
copies all server data and configuration into a private backup directory, and
byte-compares the stopped SQLite database copy before switching runtimes. The
old runtime, launcher, and service definition are retained for rollback. A failure
leaves the backup intact and requires inspection before retrying.

Preserved paths:

- Service: user unit `jellyfin-source.service`
- Launcher: `/home/t/bin/jellyfin-from-source`
- Runtime: `/home/t/jellyfin-from-source`
- Data: `/home/t/.local/share/jellyfin-source/data`
- Configuration: `/home/t/.config/jellyfin-source`
- Cache: `/home/t/.cache/jellyfin-source`
- Logs: `/home/t/.local/state/jellyfin-source/log`
- FFmpeg: `/home/t/jellyfin-ffmpeg/ffmpeg`

Backup for this upgrade:
`/home/t/.local/state/jellyfin-upgrades/20260905T145331Z-pre-12.0-rc7`

Credentials, databases, configuration contents, and binaries are not committed.
The existing local Jellyfin API credential remains on Leeloo.

## Verification

Check `/System/Info/Public`, web assets, authenticated library access, plugin
loading, and migration logs. Re-read Panama TV's local NFOs and verify all 22
House episodes have season number 1 and episode numbers 1-22. Its media path is
`/mnt/media2/encodes/41df202e-e090-493c-aea9-38be8b93ba19/tv`.
Restore `zorg-encode-jellyfin-refresh.timer` only if it was previously active and
startup/verification succeeded. No Zorg or Panama encode services are changed.

### Deployment result

- Startup and all database migrations completed successfully. Public API reports
  `12.0.0`; artifact checksum above identifies RC7. Server identity is unchanged.
- `/web/index.html` returns HTTP 200. Movies, Shows, and Panama TV remain present.
- All six bundled providers are active, including the new ListenBrainz similarity
  provider. FFmpeg 7.1.3 is detected successfully. Playback has not been tested.
- RC7 rejects the legacy `X-Emby-Token` header. Panama's operations scripts and
  Zorg's refresh/publisher clients now use `Authorization: MediaBrowser Token=...`.
  The focused `LinkPublisherCommandTest` passes against a server requiring that header.
- Leeloo's existing publisher JAR received only the two client classes and the
  refresh client's nested Libraries record; no unrelated application update was
  deployed. Its original JAR is retained as `zorg-encode-queue.jar` in the backup.
- Publisher and Jellyfin services are active. A manual hourly-refresh service run
  succeeded with exit status 0, and its previously active timer was restored.
- **Unresolved:** Panama TV still contains 22 episodes with incorrect or missing
  season/episode numbers after collection, series, and pilot metadata refreshes.
  Pilot's on-disk NFO explicitly specifies season 1, episode 1, but the API still
  reports season 90. Do not claim the UUID/NFO import issue is fixed by this upgrade.
  No media was deleted or renamed to work around it.

### Follow-up local artwork and catalog repair

Panama now serves stored PostgreSQL artwork over HTTPS port 3344. All 22 House
episode NFOs and tvshow.nfo were regenerated with Panama-only image URLs, with
hidden backups alongside them. Jellyfin's isolated House refresh fetched those
images successfully; external metadata/image fetchers remain disabled.

Broad queued refreshes delayed the earlier NFO repair. After isolating House's
refresh, canonical numbering was corrected but stale LocalAlternateVersions,
OwnerId and PrimaryVersionId records continued hiding different episodes as
versions of Paternity. The API split operation did not clear all persisted state.
`repair-panama-house-alternates.sql` clears only those links, guarded by the
presence of 22 distinct canonical season-1 episode numbers and foreign-key checks.
It does not delete media, user data, episode rows or external-library entries.

The stopped, real catalog was backed up and quick_check returned ok at
`/home/t/.local/state/jellyfin-upgrades/20260905-house-alternates/jellyfin.db`.
The actual database is under `data/data/jellyfin.db`, not the empty top-level
placeholder. The upgrade copied the entire data tree, including the real database;
the script's explicit comparison target has now been corrected to the real file.

The guarded repair temporarily restored 22 visible episodes. A subsequent fresh
scan recreated incorrect alternate links, so this is **not a durable fix** for
RC7's UUID-path inference. Do not repeatedly run the SQL as routine maintenance.
The user has been asked whether to use file-UUID subdirectories or investigate a
Jellyfin code fix. Videos remain unchanged. Artwork verification confirmed the
three show images and 12 visible episode stills match canonical PostgreSQL hashes;
the 10 hidden alternatives inherit Paternity's image because of the grouping bug.
The unsupported legacy landscape image was removed through Jellyfin's image API.

## Rollback

Stop the Jellyfin service and refresh timer first. Retain the failed/new runtime,
migrated data, and configuration separately for diagnosis. Restore **all three**
from the same stopped-server backup: `runtime` to the runtime path, `data` to the
data path, and `config` to the configuration path. Preserve ownership and modes.
Restore the backed-up launcher/service if they were changed, then start Jellyfin
and verify it before restoring the timer. Never run the old binary against the
database after RC migrations. Media files are not part of this rollback and must
not be moved or deleted.
