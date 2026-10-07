# Changelog

Fork of `luissilvaos/cordova-outsystems-debuglogs` at `0.0.4`. Versions below `1.0.0`
were delivered as resource ZIPs while the build was being brought back to life; from
`1.0.0` the plugin is consumed from git.

## 1.0.0

First git-delivered release. Same code as 0.4.1; the version reflects that the plugin
builds and runs on both platforms rather than any new change.

- Plugin id is `cordova-plugin-outsystems-debuglogs`.
- Zero external dependencies.
- Consumed with `"plugin": { "url": "<repo>.git#1.0.0" }` rather than a resource ZIP.

## 0.4.1

- iOS: the smoky pane left a gap in the safe-area strips. The blur lived inside the
  controller's view, which is inset so the buttons clear the status bar. It now lives
  in a separate full-bleed backdrop behind that view, so the pane covers the screen
  while the buttons stay where they are.
- iOS: Close and Clear looked oblong next to Copy. The nib gave them no explicit size
  while Copy had one, and a fixed corner radius only reads as a pill at that height.
  All three now share size constants, with the radius derived from the height.

## 0.4.0

- **Copy button**, centred between Close and Clear. `ClipboardManager` + Toast on
  Android; `UIPasteboard` with a brief button retitle on iOS.
- Smoky translucent pane: `#E6121419` on the Android overlay, a `UIVisualEffectView`
  dark material blur plus tint on iOS.
- Translucent pill buttons, hairline border, sentence case.
- Monospace, selectable log text. The scroll area now fills the pane — it was
  `wrap_content`, so it never did.
- iOS safe-area fallback: if the parent view reports zero insets because the app
  suppresses safe-area layout, the window's insets are used.

## 0.3.0

- Export `getConsoleState`. The native action and dispatch existed in 0.2.0 but were
  never exported from the JS module, so it was unreachable.
- Pad the console by the system bar insets on both platforms, so the buttons are not
  under the status bar on an edge-to-edge app.
- Colour-code log levels: error red, warn amber, info cyan, debug purple, log
  near-white. `OSConsoleCommands` gains `log(String, int)`; the existing
  `log(String)` delegates at `LEVEL_LOG`, so no caller changed.

## 0.2.0

- Android: `openConsole` did nothing visible. The overlay was inserted at index 0 of
  the content `FrameLayout`, where the first child draws underneath — so the console
  opened behind the opaque webview. It is now the last child, with `bringToFront()`
  and an elevation. The old code assumed CordovaActivity's `LinearLayout` root, true
  only up to cordova-android 9.
- `openConsole`/`closeConsole` report from the UI thread after the work happens. They
  previously returned OK before the posted Runnable ran, so the success callback fired
  even when nothing opened.
- Added the `getConsoleState` action (not reachable until 0.3.0).

## 0.1.0

- Own the iOS console logger instead of depending on `cordova-plugin-console`.
  `OSDebugLogs` gained `logLevel:`, which posts `CDVLoggerNotification` with the same
  userInfo keys, so `OSConsoleViewController` needed no change. `www/OSDebugLogs.js`
  forwards `console.*` to it, guarded to iOS.

## 0.0.9

- Remove the `cordova-plugin-console` dependency: it compiled its own `CDVLogger`
  while cordova-ios 7.1.1 ships one in CordovaLib, giving
  `duplicate symbol '_OBJC_CLASS_$_CDVLogger'` at link time. This left the iOS console
  empty until 0.1.0.

## 0.0.7

- Replace `org.apache.cordova.BuildConfig` with a runtime `FLAG_DEBUGGABLE` check.
  cordova-android 14 uses AGP 8, which no longer generates `BuildConfig` for library
  modules.

## 0.0.5

- Rename the plugin id to `cordova-plugin-outsystems-debuglogs` (no dots).
- Packaging fix: build resource ZIPs with Info-ZIP-style entries. `git archive
  --format=zip` writes no Unix mode bits, and MABS rejected the result as "not a valid
  Cordova plugin".

## 0.0.5 (initial fix)

- Remove the `<dependency id="com.outsystems.plugins.loader"/>` that had no `url`, so
  Cordova resolved it through the npm registry and every build failed with a 404. The
  class it provides comes from the bundled `cordova-outsystems-core`.
