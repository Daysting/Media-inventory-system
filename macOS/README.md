# macOS app

The Xcode project is `MediaInventory/MediaInventory.xcodeproj` and its shared scheme is `MediaInventory`.

Use the scripts in the repository’s `script/` directory for current build, test, archive and export workflows. The [root README](../README.md) and [App Store release guide](distribution/APP_STORE_RELEASE.md) are the current setup instructions.

The application uses sandboxed local SQLite storage and optional iCloud document sync. It does not require a web backend or a repository database. Version 1.6 uses build number 160 by default; set `BUILD_NUMBER` when archiving a subsequent upload.

The remaining older setup, roadmap and testing notes in this directory describe previous development stages. In particular, claims that App Store signing is already configured, instructions to distribute an unsigned DMG through the App Store, and repository-relative database paths should not be used for the current release.
