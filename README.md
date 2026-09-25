# Daysting’s Home Inventory System

A native macOS app for books, video games, movies, electronics, borrowers, checkouts, and printable reports. Uses a local SQLite database with optional iCloud document sync.

- macOS 13 or later; Apple silicon and Intel.
- Xcode with the macOS SDK; no third-party dependencies.
- Bundle identifier: `com.erickhofer.MediaInventory`.
- iCloud container: `iCloud.com.erickhofer.MediaInventory`.

## Develop and test

```sh
./script/test.sh
./script/build_and_run.sh --verify
```

The Run script defaults to an ad hoc signed, sandboxed local build without iCloud entitlements. For live iCloud development, sign in to Xcode and run with `DEVELOPMENT_TEAM=YOUR_TEAM_ID`.

The app stores its database in its sandbox’s Application Support/MediaInventory directory. It does not load a database from the working directory. Use **Settings → Import Inventory** to migrate an existing `media_inventory.db`; a backup is made before replacement. Cover images in older databases must be accessible during migration or selected again with **Choose Image**. Export a portable backup from Settings.

## Mac App Store release

```sh
# Compile and validate a universal archive without signing:
./script/archive_app_store.sh --unsigned

# Sign after configuring the App ID and iCloud container in your developer team:
DEVELOPMENT_TEAM=YOUR_TEAM_ID ./script/archive_app_store.sh
DEVELOPMENT_TEAM=YOUR_TEAM_ID ./script/export_app_store.sh
```

The export script creates a local package and never uploads it. See [the release guide](macOS/distribution/APP_STORE_RELEASE.md) for provisioning, live iCloud tests, and submission requirements. The older DMG script is for direct distribution, not App Store submission.

## Sync behavior

Sync compares database content against the last common snapshot, not modification timestamps. Only one-sided changes are automatic. If both Macs changed, Settings asks which inventory to keep. All versions are preserved locally in **Sync Backups** before resolution; snapshots are not merged row by row. New images are embedded in the database, so they travel with inventory exports and iCloud snapshots.

Use **Sync Now** and wait for **Up to date** before switching Macs. Offline or simultaneous edits can require a manual choice. Backups contain borrower details and cover images; manage and share them accordingly. Delete old backups yourself when no longer needed.

The regression suite checks the sync engine with isolated local fixtures. A signed build must additionally pass the two-Mac iCloud acceptance test before release.
