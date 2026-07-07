# Resources

The app icon lives in `AeroBriefAI/Assets.xcassets` (`AppIcon.appiconset` +
`logo.svg`) and is wired up via `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
in `project.yml`. Everything else in the UI uses SF Symbols — no other
bundled image assets are required.

Note: `Assets.xcassets` must be listed in this target's Resources build
phase for the icon to actually end up in the compiled app and for
`CFBundleIconName` to be set — a build that's missing this will build fine
locally but get rejected by App Store Connect with a "missing app icon"
error. See `scripts/generate-project.sh` for why this matters and how to
keep `project.pbxproj` in sync with `project.yml`.
