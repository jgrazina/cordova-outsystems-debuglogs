package com.outsystems.plugins.debug.console;

public interface OSConsoleCommands {

    /** Severity levels, mirroring the console.* methods and WebView ConsoleMessage levels. */
    int LEVEL_LOG = 0;
    int LEVEL_DEBUG = 1;
    int LEVEL_INFO = 2;
    int LEVEL_WARN = 3;
    int LEVEL_ERROR = 4;

    void clear();

    /** Logs at LEVEL_LOG. Kept so existing callers are unaffected. */
    void log(String output);

    void log(String output, int level);

}
