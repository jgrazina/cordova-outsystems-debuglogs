package com.outsystems.plugins.debug.console;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.app.Fragment;
import android.graphics.Color;
import android.os.Bundle;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.text.style.StyleSpan;
import android.graphics.Typeface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

public class OSConsoleFragment extends Fragment implements OSConsoleCommands {

    private OSUiConsoleInterface mListener;
    private TextView mTextView;

    public static OSConsoleFragment newInstance() {
        return new OSConsoleFragment();
    }

    public void clear() {
        if (this.mTextView != null) {
            this.mTextView.setText("");
        }
    }

    public void log(String output) {
        log(output, LEVEL_LOG);
    }

    public void log(String output, int level) {
        if (this.mTextView == null) {
            return;
        }
        SpannableString line = new SpannableString("\n" + output);
        line.setSpan(new ForegroundColorSpan(colourFor(level)), 0, line.length(),
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        if (level == LEVEL_ERROR || level == LEVEL_WARN) {
            line.setSpan(new StyleSpan(Typeface.BOLD), 0, line.length(),
                    Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        // TextView.append upgrades the buffer to EDITABLE, which preserves spans.
        this.mTextView.append(line);
    }

    /** Console palette, chosen for contrast against the #343845 background. */
    private static int colourFor(int level) {
        switch (level) {
            case LEVEL_ERROR: return Color.parseColor("#FF6B6B");
            case LEVEL_WARN:  return Color.parseColor("#FFD166");
            case LEVEL_INFO:  return Color.parseColor("#7FD1E8");
            case LEVEL_DEBUG: return Color.parseColor("#B39DDB");
            default:          return Color.parseColor("#E6E6E6");
        }
    }

    /**
     * Puts the whole buffer on the clipboard so a tester can paste it into a mail or
     * a ticket. This is the point of the console on a device that cannot reach the
     * platform to ship its logs.
     */
    private void copyLogToClipboard() {
        Activity activity = getActivity();
        if (activity == null || this.mTextView == null) {
            return;
        }
        CharSequence text = this.mTextView.getText();
        String payload = (text == null) ? "" : text.toString();
        try {
            ClipboardManager clipboard =
                    (ClipboardManager) activity.getSystemService(Context.CLIPBOARD_SERVICE);
            if (clipboard == null) {
                Toast.makeText(activity, "Clipboard unavailable", Toast.LENGTH_SHORT).show();
                return;
            }
            clipboard.setPrimaryClip(ClipData.newPlainText("App log", payload));
            Toast.makeText(activity, "Log copied (" + payload.length() + " chars)",
                    Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            Toast.makeText(activity, "Could not copy log", Toast.LENGTH_SHORT).show();
        }
    }

    public void onAttach(Activity paramActivity) {
        super.onAttach(paramActivity);
    }

    public View onCreateView(LayoutInflater paramLayoutInflater, ViewGroup paramViewGroup, Bundle paramBundle) {

        int fragment_console = getActivity().getResources().getIdentifier("fragment_console", "layout", getActivity().getPackageName());

        View view = paramLayoutInflater.inflate(fragment_console, paramViewGroup, false);

        int txtConsoleId = view.getResources().getIdentifier("txtConsole","id",getActivity().getPackageName());
        int btnClearId = view.getResources().getIdentifier("btnClear","id",getActivity().getPackageName());
        int btnCloseId = view.getResources().getIdentifier("btnClose","id",getActivity().getPackageName());

        this.mTextView = ((TextView) view.findViewById(txtConsoleId));

        int btnCopyId = view.getResources().getIdentifier("btnCopy","id",getActivity().getPackageName());

        final Button btnClear = (Button) view.findViewById(btnClearId);
        final Button btnClose = (Button) view.findViewById(btnCloseId);
        final Button btnCopy = (Button) view.findViewById(btnCopyId);

        // Null-guarded: an older cached layout would not carry btnCopy.
        if (btnCopy != null) {
            btnCopy.setOnClickListener(new View.OnClickListener() {
                public void onClick(View paramAnonymousView) {
                    OSConsoleFragment.this.copyLogToClipboard();
                }
            });
        }

        btnClear.setOnClickListener(new View.OnClickListener() {
            public void onClick(View paramAnonymousView) {
                OSConsoleFragment.this.clear();
                if (OSConsoleFragment.this.mListener != null) {
                    OSConsoleFragment.this.mListener.onClear();
                }
            }
        });

        btnClose.setOnClickListener(new View.OnClickListener() {
            public void onClick(View paramAnonymousView) {
                if (OSConsoleFragment.this.mListener != null) {
                    OSConsoleFragment.this.mListener.onClose();
                }
            }
        });
        return view;
    }

    public void onDetach() {
        super.onDetach();
        this.mListener = null;
    }

    public void onHiddenChanged(boolean paramBoolean) {
        super.onHiddenChanged(paramBoolean);
    }

    public void onResume() {
        super.onResume();
        if (this.mListener != null) {
            this.mListener.onReadyToReceiveData();
        }
    }

    public void setOsUiConsoleListener(OSUiConsoleInterface paramOSUiConsoleInterface) {
        this.mListener = paramOSUiConsoleInterface;
    }

    public interface OSUiConsoleInterface {
        void onClear();
        void onClose();
        void onReadyToReceiveData();
    }
}