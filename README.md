# cordova-plugin-outsystems-debuglogs

An on-device log console for OutSystems mobile apps. Opens a panel over the app
showing everything written to `console.*`, so a tester can read and copy the log on a
device that cannot reach the platform.

Fork of [`luissilvaos/cordova-outsystems-debuglogs`](https://github.com/luissilvaos/cordova-outsystems-debuglogs)
at tag `0.0.4`, brought up to **MABS 12 / cordova-android 14 / cordova-ios 7**, where
the original no longer builds.

> **Plugin id note.** The id is `cordova-plugin-outsystems-debuglogs`, not the
> original `com.outsystems.plugins.debuglogs`. See [Dotless id](#dotless-id).

## Install

Add a wrapper module in Service Studio with this Extensibility Configuration:

```json
{
  "plugin": {
    "url": "https://github.com/jgrazina/cordova-outsystems-debuglogs.git#1.0.0"
  }
}
```

Give the module one dummy public client action (the documented
`Check<Capability>Plugin` convention, with an `IsAvailable` boolean output) so the app
has something to reference — a module with no public elements cannot be referenced, and
an unreferenced module contributes nothing to the build.

Pin the `#` ref to a tag. An untagged reference means two builds can produce different
code.

## Usage

```js
// open the console panel
cordova.plugins.OSDebugLogs.openConsole(onSuccess, onError);

// close it
cordova.plugins.OSDebugLogs.closeConsole(onSuccess, onError);

// diagnostics: is the overlay attached and showing?
cordova.plugins.OSDebugLogs.getConsoleState(function (state) {
    // {attached, hasParent, visible, consoleCreated, debuggable,
    //  width, height, parent, indexInParent, siblings}
});

// iOS only: is the console.* hook installed?
cordova.plugins.OSDebugLogs.isConsoleHookInstalled();
```

The panel has **Close**, **Copy** and **Clear**. Copy puts the whole buffer on the
clipboard so a tester can paste it into a mail or a ticket.

Log lines are colour-coded: error red, warn amber, info cyan, debug purple, plain log
near-white.

## How each platform captures output

| | |
| --- | --- |
| Android | Native, via `ChromeClient.onConsoleMessage`. No JS hook. |
| iOS | `www/OSDebugLogs.js` wraps `console.log/info/warn/error/debug` and forwards to the native `logLevel:`, which posts `CDVLoggerNotification` for the panel to display. |

The JS hook is deliberately guarded to `cordova.platformId === 'ios'`. Hooking Android
too would log every line twice.

Only explicit `console.*` calls are captured. Uncaught JS errors are not — a
`window.onerror` hook forwarding to the same method would catch them, if that turns out
to be wanted.

## What this fork fixes

The original targets `cordova-android >=4.0.0`. On MABS 12 it fails in nine distinct
ways; all are fixed here. Short version:

1. A `<dependency>` on `com.outsystems.plugins.loader` with no `url`, so Cordova
   resolved it through the npm registry — where OutSystems plugins do not exist. Hard
   404 on every build. The class it provides turns out to come from the bundled
   `cordova-outsystems-core`, so removing the dependency is enough.
2. Packaging: ZIPs built by `git archive --format=zip` carry no Unix mode bits and
   MABS rejects them as "not a valid Cordova plugin". Moot now that this is consumed
   from git.
3. <a name="dotless-id"></a>**Dotless id**: renamed to `cordova-plugin-outsystems-debuglogs`.
   The Java package (`com.outsystems.plugins.debug`) and the JS API
   (`cordova.plugins.OSDebugLogs`) are unchanged, so nothing calling the plugin moved.
4. `org.apache.cordova.BuildConfig` no longer exists — cordova-android 14 uses AGP 8,
   which stopped generating `BuildConfig` for library modules. Replaced with a runtime
   `FLAG_DEBUGGABLE` check.
5. iOS link failure: `duplicate symbol '_OBJC_CLASS_$_CDVLogger'`. The old
   `cordova-plugin-console` dependency compiled its own `CDVLogger` while cordova-ios
   now ships one in CordovaLib.
6. Removing that dependency emptied the iOS console, since only that fork's
   `CDVLogger` posted `CDVLoggerNotification`. The behaviour now lives in this plugin,
   so there is no second dependency to maintain.
7. Android: `openConsole` appeared to do nothing. The overlay was inserted at index 0
   of a `FrameLayout`, which draws *underneath*. That assumed CordovaActivity's
   `LinearLayout` root, true only up to cordova-android 9.
8. Console buttons sat under the system bars on an edge-to-edge app.
9. `getConsoleState` was unreachable — native action present, never exported from JS.

Full detail per release is in [CHANGELOG.md](CHANGELOG.md).

## Licence

**The upstream repository carries no licence** — no `LICENSE` file, and no licence
field in `package.json` or `plugin.xml`. This fork therefore adds none, because it
cannot grant rights over code it does not own.

This exists as a GitHub fork, which is what GitHub's Terms of Service cover for public
repositories. If this is going to be distributed more widely than that, the licence
question is worth settling with the original author first.

## Known future risk

`OSConsole` and `OSConsoleFragment` use the framework `android.app.Fragment` API,
deprecated since API 28. It still works on API 36 but warns throughout. If a future
Android removes it, porting to AndroidX fragments is a larger job than anything in
this fork.
