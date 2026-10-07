package com.outsystems.plugins.debug;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.graphics.Color;
import android.os.Build;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.webkit.ConsoleMessage;
import android.widget.RelativeLayout;

import com.outsystems.plugins.debug.console.OSConsole;
import com.outsystems.plugins.debug.console.OSConsoleCommands;
import com.outsystems.plugins.loader.clients.ChromeClient;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.engine.SystemWebView;
import org.apache.cordova.engine.SystemWebViewEngine;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

public class OSDebugLogs extends CordovaPlugin {

    private static final String TAG = "OSDebugLogs";

    private OSConsole mOsConsole;

    private ViewGroup consoleViewGroup;

    /** Id given to the overlay container so the fragment transaction can target it. */
    private static final int CONSOLE_VIEW_ID = 2016;

    /**
     * Smoky translucent pane. Painted on the overlay rather than in the layout so it
     * covers the whole screen, including the system bar inset strips that the layout
     * is padded away from.
     */
    private static final int CONSOLE_BACKGROUND = Color.parseColor("#E6121419");

    /**
     * Stands in for org.apache.cordova.BuildConfig.DEBUG, which cordova-android 14
     * (AGP 8) no longer generates for CordovaLib. Reads the host application's
     * debuggable flag at runtime, which is equivalent for guarding debug logging.
     */
    private boolean isDebuggable() {
        try {
            ApplicationInfo info = this.cordova.getActivity().getApplicationInfo();
            return (info.flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
        } catch (Exception e) {
            return false;
        }
    }

	@Override
	protected void pluginInitialize() {
		if(isDebuggable()) {
			Log.d(TAG, "Plugin Initialize: started");
		}

		SystemWebViewEngine webViewEngine = (SystemWebViewEngine)this.webView.getEngine();
		SystemWebView systemWebView = (SystemWebView)webViewEngine.getView();

		OSDebugLogsChromeClient chromeClient = new OSDebugLogsChromeClient(webViewEngine,this.cordova);
		
		systemWebView.setWebChromeClient(chromeClient);


        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                attachConsoleOverlay();
            }
        });


		if(isDebuggable()) {
			Log.d(TAG, "Plugin Initialize: finished");
		}
	}

    public ViewGroup getConsoleViewGroup() {
        return consoleViewGroup;
    }

    public void setConsoleViewGroup(ViewGroup consoleViewGroup) {
        this.consoleViewGroup = consoleViewGroup;
    }

    /**
     * Attaches the console overlay as the LAST child of the activity's content view.
     *
     * The original code walked up two parents from the webview and inserted at index 0
     * of whatever it found, after coercing a LinearLayout to vertical orientation. That
     * relied on CordovaActivity using a LinearLayout root, which was true up to
     * cordova-android 9. From cordova-android 10 onwards (14.0.1 here) createViews()
     * builds a FrameLayout root and calls setContentView on it, so the hierarchy is:
     *
     *     android.R.id.content (FrameLayout)
     *       └── rootLayout (FrameLayout, created by CordovaActivity)
     *             └── webview
     *
     * In a FrameLayout the FIRST child is drawn first, i.e. underneath. Inserting at
     * index 0 therefore put the console behind the opaque webview: it opened, the
     * fragment was added, and nothing was visible.
     *
     * Adding as the last child (plus bringToFront and an elevation) puts it on top
     * regardless of how many wrappers the platform or other plugins introduce.
     */
    private void attachConsoleOverlay() {
        try {
            Activity activity = cordova.getActivity();

            ViewGroup contentView = (ViewGroup) activity.findViewById(android.R.id.content);
            if (contentView == null) {
                Log.e(TAG, "android.R.id.content not found; console overlay not attached");
                return;
            }

            RelativeLayout overlay = new RelativeLayout(activity);
            overlay.setLayoutParams(new ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT));
            overlay.setId(CONSOLE_VIEW_ID);
            overlay.setVisibility(View.GONE);
            // Raise above the webview even if something re-orders children later.
            overlay.setElevation(1000f);
            // The overlay fills the content view, which under edge-to-edge extends
            // behind the status and navigation bars. Paint it the console's own colour
            // so the inset strips do not show the app through them.
            overlay.setBackgroundColor(CONSOLE_BACKGROUND);
            applySystemBarInsets(overlay);

            contentView.addView(overlay);
            overlay.bringToFront();
            contentView.invalidate();

            setConsoleViewGroup(overlay);
            mOsConsole = new OSConsole(activity, getConsoleViewGroup());

            if (isDebuggable()) {
                Log.d(TAG, "console overlay attached to " + contentView.getClass().getSimpleName()
                        + " as child " + (contentView.getChildCount() - 1)
                        + " of " + contentView.getChildCount());
            }
        } catch (Exception e) {
            Log.e(TAG, "failed to attach console overlay", e);
        }
    }

    /** Maps a WebView console severity onto the console's own levels. */
    private static int levelFor(ConsoleMessage.MessageLevel level) {
        if (level == null) {
            return OSConsoleCommands.LEVEL_LOG;
        }
        switch (level) {
            case ERROR:   return OSConsoleCommands.LEVEL_ERROR;
            case WARNING: return OSConsoleCommands.LEVEL_WARN;
            case DEBUG:   return OSConsoleCommands.LEVEL_DEBUG;
            case TIP:     return OSConsoleCommands.LEVEL_INFO;
            default:      return OSConsoleCommands.LEVEL_LOG;
        }
    }

    /**
     * Pads the overlay by the system bar insets so the console's close/clear buttons are
     * not hidden behind the status bar, and are not covered by the navigation bar or a
     * display cutout. This app runs edge-to-edge, so the content view extends behind
     * both bars and an unpadded overlay puts its top row under the clock and the
     * wifi/battery icons, which also swallow the taps.
     */
    private void applySystemBarInsets(final View overlay) {
        overlay.setOnApplyWindowInsetsListener(new View.OnApplyWindowInsetsListener() {
            @Override
            public WindowInsets onApplyWindowInsets(View v, WindowInsets insets) {
                int left, top, right, bottom;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    android.graphics.Insets bars = insets.getInsets(
                            WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
                    left = bars.left; top = bars.top; right = bars.right; bottom = bars.bottom;
                } else {
                    left = insets.getSystemWindowInsetLeft();
                    top = insets.getSystemWindowInsetTop();
                    right = insets.getSystemWindowInsetRight();
                    bottom = insets.getSystemWindowInsetBottom();
                }
                v.setPadding(left, top, right, bottom);
                return insets;
            }
        });
        overlay.requestApplyInsets();
    }

    /**
     * Reports whether the overlay exists and is showing. Lets the console be diagnosed
     * from JS without another build.
     */
    private void getConsoleState(CallbackContext callbackContext) {
        try {
            JSONObject state = new JSONObject();
            ViewGroup group = getConsoleViewGroup();
            state.put("attached", group != null);
            state.put("hasParent", group != null && group.getParent() != null);
            state.put("visible", group != null && group.getVisibility() == View.VISIBLE);
            state.put("consoleCreated", mOsConsole != null);
            state.put("debuggable", isDebuggable());
            if (group != null) {
                state.put("width", group.getWidth());
                state.put("height", group.getHeight());
                if (group.getParent() != null) {
                    ViewGroup parent = (ViewGroup) group.getParent();
                    state.put("parent", parent.getClass().getSimpleName());
                    state.put("indexInParent", parent.indexOfChild(group));
                    state.put("siblings", parent.getChildCount());
                }
            }
            callbackContext.success(state);
        } catch (Exception e) {
            callbackContext.error(String.valueOf(e.getMessage()));
        }
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("openConsole")) {
            this.openConsole(callbackContext);
            return true;
        } else if (action.equals("closeConsole")) {
            this.closeConsole(callbackContext);
            return true;
        } else if (action.equals("getConsoleState")) {
            this.getConsoleState(callbackContext);
            return true;
        }
        return false;
    }

    /**
     * Opens the console. The result is reported from the UI thread after the work has
     * actually happened - the previous version returned OK before the posted Runnable
     * ran, so the JS success callback fired even when nothing opened.
     */
    private void openConsole(final CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    // Normally attached during pluginInitialize; retry here so a failure
                    // or race there does not leave the console permanently dead.
                    if (getConsoleViewGroup() == null) {
                        attachConsoleOverlay();
                    }
                    if (getConsoleViewGroup() == null) {
                        callbackContext.error("console overlay could not be attached");
                        return;
                    }
                    if (mOsConsole == null) {
                        mOsConsole = new OSConsole(cordova.getActivity(), getConsoleViewGroup());
                    }
                    mOsConsole.open();
                    getConsoleViewGroup().bringToFront();
                    callbackContext.success();
                } catch (Exception e) {
                    Log.e(TAG, "openConsole failed", e);
                    callbackContext.error(String.valueOf(e.getMessage()));
                }
            }
        });
    }

    private void closeConsole(final CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    if (mOsConsole == null) {
                        callbackContext.error("console was never opened");
                        return;
                    }
                    mOsConsole.close();
                    callbackContext.success();
                } catch (Exception e) {
                    Log.e(TAG, "closeConsole failed", e);
                    callbackContext.error(String.valueOf(e.getMessage()));
                }
            }
        });
    }


    private class OSDebugLogsChromeClient extends ChromeClient {

        public OSDebugLogsChromeClient(SystemWebViewEngine parentEngine, CordovaInterface cordovaInterface) {
            super(parentEngine, cordovaInterface);
        }

        @Override
        public boolean onConsoleMessage(ConsoleMessage consoleMessage) {

            if (OSDebugLogs.this.mOsConsole != null) {
                String str = String.format("Line %d : %s", consoleMessage.lineNumber(), consoleMessage.message());
                if (OSDebugLogs.this.mOsConsole.getConsoleInterface() != null) {
                    OSDebugLogs.this.mOsConsole.getConsoleInterface()
                            .log(str, levelFor(consoleMessage.messageLevel()));
                }
            }

            return super.onConsoleMessage(consoleMessage);
        }
    }
    
}
