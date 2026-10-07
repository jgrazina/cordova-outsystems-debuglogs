var exec = cordova.require('cordova/exec');

exports.openConsole = function(success, error) {
    exec(success, error, "OSDebugLogs", "openConsole", []);
};

exports.closeConsole = function(success, error) {
    exec(success, error, "OSDebugLogs", "closeConsole", []);
};

/*
 * Diagnostics: reports whether the console overlay is attached and showing.
 * Android returns the real view state; on iOS it reports what the JS side knows.
 */
exports.getConsoleState = function(success, error) {
    exec(success, error, "OSDebugLogs", "getConsoleState", []);
};

/*
 * iOS console capture.
 *
 * Android needs nothing here: the native side intercepts console output through
 * ChromeClient.onConsoleMessage. iOS has no equivalent hook, so console output is
 * forwarded to the native plugin, which re-posts it as CDVLoggerNotification for
 * OSConsoleViewController to display.
 *
 * This replaces the old dependency on a fork of cordova-plugin-console, whose
 * CDVLogger class collided at link time with the one cordova-ios now ships in
 * CordovaLib. Guarded to iOS so Android does not log every line twice.
 */
var LEVELS = {
    log: 'LOG',
    info: 'INFO',
    warn: 'WARN',
    error: 'ERROR',
    debug: 'DEBUG'
};

function formatArgs(args) {
    var parts = [];
    for (var i = 0; i < args.length; i++) {
        var a = args[i];
        if (typeof a === 'string') {
            parts.push(a);
        } else if (a instanceof Error) {
            parts.push(a.message + (a.stack ? '\n' + a.stack : ''));
        } else {
            try {
                parts.push(JSON.stringify(a));
            } catch (e) {
                // circular structures, getters that throw, etc.
                parts.push(String(a));
            }
        }
    }
    return parts.join(' ');
}

function installConsoleHook() {
    if (typeof console === 'undefined' || console.__osDebugLogsHooked) {
        return;
    }

    // Re-entrancy guard: if anything inside exec() logs, we must not recurse.
    var sending = false;

    Object.keys(LEVELS).forEach(function(name) {
        var original = console[name];
        console[name] = function() {
            if (typeof original === 'function') {
                original.apply(console, arguments);
            }
            if (sending) {
                return;
            }
            sending = true;
            try {
                exec(null, null, 'OSDebugLogs', 'logLevel', [LEVELS[name], formatArgs(arguments)]);
            } catch (e) {
                // Logging must never break the caller.
            } finally {
                sending = false;
            }
        };
    });

    console.__osDebugLogsHooked = true;
}

if (cordova.platformId === 'ios') {
    installConsoleHook();
}

exports.isConsoleHookInstalled = function() {
    return typeof console !== 'undefined' && console.__osDebugLogsHooked === true;
};
