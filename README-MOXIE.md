# Moxie fork notes

Fork of `luissilvaos/cordova-outsystems-debuglogs` at tag **0.0.4**, fixing a build
failure in MABS 12 / OutSystems mobile template 16.5.1.

Upstream remote is kept as `upstream`. There is no `origin` until this is pushed
somewhere.

## The failure

Android build, 2026-10-06, failed installing plugin 11 of 15:

```
Requesting plugin "com.outsystems.plugins.loader".
Plugin dependency "com.outsystems.plugins.loader" not fetched, retrieving then installing.
npm error 404 Not Found - GET https://registry.npmjs.org/com.outsystems.plugins.loader
```

`plugin.xml` declared:

```xml
<dependency id="com.outsystems.plugins.loader"/>
<dependency id="cordova-plugin-console" url="https://github.com/luissilvaos/cordova-plugin-console#outsystems"/>
```

The first has **no `url`**, so Cordova falls back to the npm registry. OutSystems
plugins are not published on npmjs.org, so this is a hard 404 that can never succeed.
The author added a `url` to the line below it, so this looks like a plain oversight.

Not a transient MABS or registry problem: the registry answered 404, the other 14
plugins fetched from GitHub fine, and it failed identically on retry.

## Fix applied (branch `moxie/fix-loader-dependency`)

Removed the `<dependency>` line. Nothing else changed.

The Java still imports the class the dependency was meant to supply:

```java
import com.outsystems.plugins.loader.clients.ChromeClient;   // OSDebugLogs.java:11
```

In template 16.5.1 that class is expected to come from the bundled
`cordova-outsystems-core`, which is fetched from inside the template tarball rather
than from a public repo. **This could not be verified from outside a build** - neither
`OutSystems/cordova-outsystems-core` nor `@outsystems/cordova-outsystems-core` is
publicly readable.

So this fix is deliberately staged:

- **If the class is on the classpath** - it compiles, and behaviour is identical to
  upstream. Best case, and the reason to try this first.
- **If it is not** - Gradle fails with `cannot find symbol: ChromeClient`. That is a
  loud, immediate, build-time failure, not a silent runtime regression. Then apply the
  fallback below.

## Fallback, if Gradle reports `cannot find symbol: ChromeClient`

See branch `moxie/selfcontained-chromeclient`. It drops the OutSystems base class and
extends Cordova's own `org.apache.cordova.engine.SystemWebChromeClient`, which is
always present. The subclass only uses the constructor and `onConsoleMessage`, so the
change is small.

**Trade-off, and it is the reason this is the fallback rather than the fix:** this
plugin calls `systemWebView.setWebChromeClient(...)`, replacing the app's chrome client
outright. Extending the stock Cordova class instead of the OutSystems one may drop
OutSystems-specific chrome behaviour for the whole app - the file-chooser path behind
`AndroidInAppBrowserFileChooserEnabled` is the one to check, given this app uses upload
widgets. Verify file upload on device if you ship this branch.

## Other things worth knowing

- `cordova-plugin-console` resolves from a **floating branch** (`#outsystems`), not a
  tag. Two builds can get different code. Verified present on 2026-10-06, with no
  dependencies of its own, so it is not the current blocker - but pin it if this plugin
  is going to stay in the build.
- Both dependencies point at a personal GitHub account. That account can rename, archive
  or delete these repos at any time and the build breaks with this same class of error.
- This is a debug-logging plugin and the failing build was `build type: debug`. If it
  was added only for troubleshooting, removing the module reference is a cheaper fix
  than any of the above.
