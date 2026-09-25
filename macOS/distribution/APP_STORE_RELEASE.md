# Mac App Store release guide

## Current configuration

| Setting | Value |
|---|---|
| Product | Daysting’s Home Inventory System |
| Suggested store name (under 30 characters) | Daysting Home Inventory |
| Bundle ID | `com.erickhofer.MediaInventory` |
| iCloud container | `iCloud.com.erickhofer.MediaInventory` |
| Version / build | 1.6 / 161 |
| Architectures | arm64 and x86_64 |
| Deployment target | macOS 13.0 |
| Category | Productivity |

The store name is a draft; availability has not been checked. Preserve the bundle ID if this is an update to an existing App Store record. Increment `BUILD_NUMBER` for later uploads of this version.

## Apple account and provisioning

1. Sign in to your Apple Developer account under **Xcode → Settings → Apple Accounts**. Refresh expired authentication if prompted.
2. Register/select the explicit macOS App ID `com.erickhofer.MediaInventory` in your developer team. Enable iCloud Documents and associate `iCloud.com.erickhofer.MediaInventory` with this App ID. Do not substitute an unrelated app’s profile.
3. Open the project, select the MediaInventory target, and select your team under Signing & Capabilities. Confirm iCloud Documents and the container match the entitlements. Allow Xcode to create/update the development profile.
4. Confirm the team has the Apple Distribution and Mac Installer Distribution signing assets needed to export a Mac App Store package. The scripts use automatic signing; Xcode may require account or keychain interaction. No credentials belong in the repository.
5. Create or select the macOS app record in App Store Connect with the same bundle ID.

The project is configured for the verified publishing team `AZ94QYXR6U` (ERICK ALAN HOFER). The scripts accept `DEVELOPMENT_TEAM` explicitly so another maintainer can override it.

## Validate, archive and export

From the repository root:

```sh
./script/test.sh
./script/archive_app_store.sh --unsigned
DEVELOPMENT_TEAM=AZ94QYXR6U BUILD_NUMBER=161 ./script/archive_app_store.sh
DEVELOPMENT_TEAM=AZ94QYXR6U ./script/export_app_store.sh
```

Default outputs are under `work/AppStore/`. `BUILD_ROOT`, `ARCHIVE_PATH` and `EXPORT_PATH` may be overridden. The export options use `app-store-connect` with `destination=export`, so these scripts never upload or publish anything. An unsigned validation archive is not submittable.

For local development without a profile, `./script/build_and_run.sh` uses minimal local entitlements. That build does not test iCloud. Pass `DEVELOPMENT_TEAM` to run with the real iCloud entitlements.

In a nested sandbox where Swift compiler macro subprocesses fail, `CODEX_SWIFT_MACRO_WORKAROUND=1` disables only Swift’s additional subprocess sandbox. The application’s App Sandbox and hardened runtime remain enabled. Normal local and CI builds do not need this option.

## Required iCloud acceptance test

Use two Macs on the same Apple ID, both running the signed build and starting with disposable test inventories. Also test macOS 13 on hardware/VM before advertising that minimum version as verified.

- On Mac A, add a book, borrower, and cover selected through the file picker. Wait until Settings says **Up to date**. On Mac B, verify the fields and image appear.
- Edit on B and verify A imports the change. Check out and return the item; verify status and loan history agree on both Macs.
- Quit/relaunch both apps. Verify persistence and unchanged sync state.
- Disconnect both Macs, make different edits on each, reconnect, and verify a conflict is shown. Confirm each original snapshot exists in Sync Backups. Test both explicit resolution choices in separate runs.
- Exercise iCloud’s unresolved document versions, not only local fixture conflicts. Verify every conflicting version is backed up before resolution and that both Macs converge afterward.
- Test a cloud file awaiting download, cloud quota exhaustion, iCloud disabled, logout/login, account switching, and cloud deletion. Local edits must remain usable, sync state must explain the issue, and no different account may receive the inventory without an explicit choice.
- Export a backup containing cover images. Import it on the other Mac with sync disabled and verify the content. Restore a saved conflict copy through Import Inventory.
- Verify notifications, print/save-PDF, image selection outside Downloads, and all inventory categories in the signed sandbox. Check Console for sandbox denials.

The automated suite covers deterministic snapshot decisions, database integrity protection, rollback, persistence, and portable cover bytes. It does not simulate Apple’s iCloud transport or provisioning. Passing it alone is not a release sign-off.

## Store listing and review

Draft listing copy is in `STORE_LISTING.md`; a factual privacy-policy draft is in `PRIVACY_POLICY.md`. Before submission:

- Publish the reviewed privacy policy at a stable public HTTPS URL and provide a support URL/contact.
- Confirm the final name, description, keywords, copyright, category, price, regions, age-rating answers, privacy disclosures, export-compliance answers, and review contact.
- Capture screenshots from the signed Release app using fictional inventory data. Supported Mac screenshot sizes include 1280×800, 1440×900, 2560×1600 and 2880×1800; verify Apple’s current specifications.
- Run **Validate App** in Xcode Organizer, then upload the exported package through Transporter or Xcode. Select the processed build in App Store Connect and complete TestFlight testing before submitting for review.

Do not promise concurrent editing with automatic record merging. This release syncs whole inventory snapshots and offers explicit conflict resolution with backups.

## References

- [Apple: prepare for distribution](https://help.apple.com/xcode/mac/current/en.lproj/dev91fe7130a.html)
- [Apple: upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Apple: iCloud document coordination and conflicts](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/DesigningForDocumentsIniCloud.html)
- [Apple: manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Apple: screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
