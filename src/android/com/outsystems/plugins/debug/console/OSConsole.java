package com.outsystems.plugins.debug.console;

import android.app.Activity;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.view.View;

import java.util.ArrayList;
import java.util.Iterator;


public class OSConsole implements OSConsoleFragment.OSUiConsoleInterface, OSConsoleCommands {
    private OSConsoleFragment mConsoleFragment;
    private View mContainer;
    private ArrayList<Entry> mEntries;
    private FragmentManager mFragmentManager;

    public OSConsole(Activity paramActivity, View container) {
        this.mContainer = container;
        this.mFragmentManager = paramActivity.getFragmentManager();
        this.mEntries = new ArrayList<Entry>();
    }

    public void clear() {
        if (this.mConsoleFragment != null) {
            this.mConsoleFragment.clear();
        }
        this.mEntries.clear();
    }

    public void close() {
        if ((this.mContainer.getVisibility() == View.VISIBLE) && (this.mFragmentManager != null)) {
            FragmentTransaction localFragmentTransaction = this.mFragmentManager.beginTransaction();
            localFragmentTransaction.remove(this.mConsoleFragment);
            localFragmentTransaction.commit();

            this.mContainer.setVisibility(View.GONE);
        }
    }

    public OSConsoleCommands getConsoleInterface() {
        return this;
    }

    public void log(String paramString) {
        log(paramString, LEVEL_LOG);
    }

    public void log(String paramString, int level) {
        if ((this.mConsoleFragment != null) && (this.mConsoleFragment.isResumed())) {
            this.mConsoleFragment.log(paramString, level);
        }
        this.mEntries.add(new Entry(paramString, level));
    }

    public void onClear() {
        this.mEntries.clear();
    }

    public void onClose() {
        close();
    }

    public void onReadyToReceiveData() {
        Iterator<Entry> localIterator = this.mEntries.iterator();
        while (localIterator.hasNext()) {
            Entry entry = localIterator.next();
            this.mConsoleFragment.log(entry.message, entry.level);
        }
    }

    /** One buffered line and its severity, so replays keep their colour. */
    private static final class Entry {
        final String message;
        final int level;
        Entry(String message, int level) {
            this.message = message;
            this.level = level;
        }
    }

    public void open() {
        if (this.mConsoleFragment == null) {
            this.mConsoleFragment = OSConsoleFragment.newInstance();
        }
        this.mConsoleFragment.setOsUiConsoleListener(this);
        if (this.mContainer.getVisibility() != View.VISIBLE) {
            FragmentTransaction localFragmentTransaction = this.mFragmentManager.beginTransaction();
            localFragmentTransaction.add(this.mContainer.getId(), this.mConsoleFragment);
            localFragmentTransaction.commit();
            this.mContainer.setVisibility(View.VISIBLE);
        }
    }
}