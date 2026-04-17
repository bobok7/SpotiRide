using Toybox.WatchUi;
using Toybox.Application;

class SpotiRideDelegate extends WatchUi.BehaviorDelegate {
    var mView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        // LAP button -> like current track
        if (key == WatchUi.KEY_LAP) {
            if (mView != null) {
                mView.onLike();
            }
            return true;
        }

        // START button -> start/pause recording
        if (key == WatchUi.KEY_START) {
            if (mView != null) {
                mView.toggleRecording();
            }
            return true;
        }

        // MENU button -> open settings
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_MENU) {
            if (mView != null) {
                openMenu();
            }
            return true;
        }

        return false;
    }

    // DOWN -> next page
    function onNextPage() {
        if (mView != null) {
            mView.currentPage = (mView.currentPage + 1) % 2;
            WatchUi.requestUpdate();
        }
        return true;
    }

    // UP -> previous page
    function onPreviousPage() {
        if (mView != null) {
            mView.currentPage = (mView.currentPage + 1) % 2;
            WatchUi.requestUpdate();
        }
        return true;
    }

    // BACK -> save activity & exit
    function onBack() {
        if (mView != null) {
            mView.saveAndStop();
        }
        return false;
    }

    function openMenu() {
        var pl = mView.langPolish;
        var menu = new WatchUi.Menu2({:title => "Menu"});

        // --- Spotify controls (first) ---
        var playSub = "---";
        if ($.gSpotifyApi != null) {
            if (pl) {
                playSub = $.gSpotifyApi.isCurrentlyPlaying ? "Gra" : "Pauza";
            } else {
                playSub = $.gSpotifyApi.isCurrentlyPlaying ? "Playing" : "Paused";
            }
        }
        menu.addItem(new WatchUi.MenuItem("Play / Pause", playSub, :playPause, {}));
        menu.addItem(new WatchUi.MenuItem(pl ? ">> Nast. utwor" : ">> Next track", null, :nextTrack, {}));
        menu.addItem(new WatchUi.MenuItem(pl ? "<< Poprz. utwor" : "<< Prev track", null, :prevTrack, {}));

        var shuffleSub = pl ? "Wyl" : "Off";
        if ($.gSpotifyApi != null && $.gSpotifyApi.shuffleOn) { shuffleSub = pl ? "Wl" : "On"; }
        menu.addItem(new WatchUi.MenuItem(pl ? "Losowo" : "Shuffle", shuffleSub, :shuffle, {}));

        var rpLabels = pl ? ["Wyl", "Playlista", "Utwor"] : ["Off", "Playlist", "Track"];
        var rpIdx = 0;
        if ($.gSpotifyApi != null) { rpIdx = $.gSpotifyApi.repeatMode; }
        menu.addItem(new WatchUi.MenuItem(pl ? "Powtarzanie" : "Repeat", rpLabels[rpIdx], :repeat, {}));

        // --- Settings ---
        var nmLabels = pl ? ["Auto", "Jasny", "Ciemny"] : ["Auto", "Light", "Dark"];
        menu.addItem(new WatchUi.MenuItem(pl ? "Tryb ekranu" : "Screen mode", nmLabels[mView.nightModeOption], :nightMode, {}));

        var riLabels = ["~5s", "~10s", "~15s", "~30s"];
        menu.addItem(new WatchUi.MenuItem(pl ? "Odsw. Spotify" : "Refresh rate", riLabels[mView.refreshIntervalIdx], :refreshInterval, {}));

        var scrollSub = mView.scrollEnabled ? (pl ? "Wlaczone" : "On") : (pl ? "Wylaczone" : "Off");
        menu.addItem(new WatchUi.MenuItem(pl ? "Przewijanie" : "Scrolling", scrollSub, :scroll, {}));

        menu.addItem(new WatchUi.MenuItem(pl ? "Temperatura" : "Temperature", mView.tempCelsius ? "Celsius" : "Fahrenheit", :tempUnit, {}));

        var apLabels = pl ? ["Wylaczona", "<2 km/h", "<3 km/h", "<4 km/h", "<5 km/h", "<6 km/h"]
                         : ["Off", "<2 km/h", "<3 km/h", "<4 km/h", "<5 km/h", "<6 km/h"];
        menu.addItem(new WatchUi.MenuItem(pl ? "Auto pauza" : "Auto pause", apLabels[mView.autoPauseIdx], :autoPause, {}));

        var apdLabels = pl ? ["Brak", "3s", "5s", "10s"] : ["None", "3s", "5s", "10s"];
        menu.addItem(new WatchUi.MenuItem(pl ? "Opoz. pauzy" : "Pause delay", apdLabels[mView.autoPauseDelayIdx], :autoPauseDelay, {}));

        // --- Language ---
        menu.addItem(new WatchUi.MenuItem(pl ? "Jezyk" : "Language", pl ? "Polski" : "English", :language, {}));

        // --- Technical ---
        var loginSub = pl ? "Niezalogowany" : "Not logged in";
        if ($.gTokenManager != null && $.gTokenManager.isConfigured()) {
            if (pl) {
                loginSub = $.gTokenManager.isTokenValid() ? "Zalogowany" : "Token wygasl";
            } else {
                loginSub = $.gTokenManager.isTokenValid() ? "Logged in" : "Token expired";
            }
        }
        menu.addItem(new WatchUi.MenuItem(pl ? "Zaloguj Spotify" : "Login Spotify", loginSub, :loginSpotify, {}));

        menu.addItem(new WatchUi.MenuItem(pl ? "Odswiez token" : "Refresh token", null, :refreshToken, {}));

        menu.addItem(new WatchUi.MenuItem(pl ? "Odswiez utwor" : "Refresh track", null, :refreshTrack, {}));

        var statusSub = pl ? "Nieznany" : "Unknown";
        if ($.gTokenManager != null) {
            if ($.gTokenManager.isTokenValid()) {
                statusSub = pl ? "Polaczono" : "Connected";
            } else {
                statusSub = pl ? "Brak tokenu" : "No token";
            }
        }
        menu.addItem(new WatchUi.MenuItem(pl ? "Status Spotify" : "Spotify status", statusSub, :status, {}));

        menu.addItem(new WatchUi.MenuItem(pl ? "O aplikacji" : "About", "bobok7", :about, {}));

        menu.addItem(new WatchUi.MenuItem(pl ? "Zapisz aktywnosc" : "Save activity", null, :saveActivity, {}));

        menu.addItem(new WatchUi.MenuItem(pl ? "Odrzuc aktywnosc" : "Discard activity", null, :discardActivity, {}));

        WatchUi.pushView(menu, new SpotiRideMenuDelegate(mView), WatchUi.SLIDE_UP);
    }
}

class SpotiRideMenuDelegate extends WatchUi.Menu2InputDelegate {
    var mView;

    function initialize(view) {
        Menu2InputDelegate.initialize();
        mView = view;
    }

    function onSelect(item) {
        var id = item.getId();
        var pl = mView.langPolish;

        if (id == :nightMode) {
            mView.nightModeOption = (mView.nightModeOption + 1) % 3;
            Application.Storage.setValue("nightMode", mView.nightModeOption);
            var labels = pl ? ["Auto", "Jasny", "Ciemny"] : ["Auto", "Light", "Dark"];
            item.setSubLabel(labels[mView.nightModeOption]);
        } else if (id == :refreshInterval) {
            mView.refreshIntervalIdx = (mView.refreshIntervalIdx + 1) % 4;
            Application.Storage.setValue("refreshIdx", mView.refreshIntervalIdx);
            var labels = ["~5s", "~10s", "~15s", "~30s"];
            item.setSubLabel(labels[mView.refreshIntervalIdx]);
        } else if (id == :scroll) {
            mView.scrollEnabled = !mView.scrollEnabled;
            Application.Storage.setValue("scrollEnabled", mView.scrollEnabled);
            item.setSubLabel(mView.scrollEnabled ? (pl ? "Wlaczone" : "On") : (pl ? "Wylaczone" : "Off"));
        } else if (id == :tempUnit) {
            mView.tempCelsius = !mView.tempCelsius;
            Application.Storage.setValue("tempCelsius", mView.tempCelsius);
            item.setSubLabel(mView.tempCelsius ? "Celsius" : "Fahrenheit");
        } else if (id == :autoPause) {
            mView.autoPauseIdx = (mView.autoPauseIdx + 1) % 6;
            Application.Storage.setValue("autoPauseIdx", mView.autoPauseIdx);
            var labels = pl ? ["Wylaczona", "<2 km/h", "<3 km/h", "<4 km/h", "<5 km/h", "<6 km/h"]
                           : ["Off", "<2 km/h", "<3 km/h", "<4 km/h", "<5 km/h", "<6 km/h"];
            item.setSubLabel(labels[mView.autoPauseIdx]);
        } else if (id == :autoPauseDelay) {
            mView.autoPauseDelayIdx = (mView.autoPauseDelayIdx + 1) % 4;
            Application.Storage.setValue("autoPauseDelayIdx", mView.autoPauseDelayIdx);
            var labels = pl ? ["Brak", "3s", "5s", "10s"] : ["None", "3s", "5s", "10s"];
            item.setSubLabel(labels[mView.autoPauseDelayIdx]);
        } else if (id == :language) {
            mView.langPolish = !mView.langPolish;
            Application.Storage.setValue("langPolish", mView.langPolish);
            item.setSubLabel(mView.langPolish ? "Polski" : "English");
            mView.showConfirm(mView.langPolish ? "Polski!" : "English!");
        } else if (id == :playPause) {
            if ($.gSpotifyApi != null && $.gTokenManager != null && $.gTokenManager.isTokenValid()) {
                if ($.gSpotifyApi.isCurrentlyPlaying) {
                    $.gSpotifyApi.pausePlayback();
                    item.setSubLabel(pl ? "Pauza" : "Paused");
                } else {
                    $.gSpotifyApi.resumePlayback();
                    item.setSubLabel(pl ? "Gra" : "Playing");
                }
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :nextTrack) {
            if ($.gSpotifyApi != null && $.gTokenManager != null && $.gTokenManager.isTokenValid()) {
                $.gSpotifyApi.nextTrack();
                mView.showConfirm(pl ? "Nastepny >>" : "Next >>");
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :prevTrack) {
            if ($.gSpotifyApi != null && $.gTokenManager != null && $.gTokenManager.isTokenValid()) {
                $.gSpotifyApi.previousTrack();
                mView.showConfirm(pl ? "<< Poprzedni" : "<< Previous");
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :shuffle) {
            if ($.gSpotifyApi != null && $.gTokenManager != null && $.gTokenManager.isTokenValid()) {
                var newState = !$.gSpotifyApi.shuffleOn;
                $.gSpotifyApi.setShuffle(newState);
                item.setSubLabel(newState ? (pl ? "Wl" : "On") : (pl ? "Wyl" : "Off"));
                if (pl) {
                    mView.showConfirm(newState ? "Losowo wl!" : "Losowo wyl!");
                } else {
                    mView.showConfirm(newState ? "Shuffle on!" : "Shuffle off!");
                }
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :repeat) {
            if ($.gSpotifyApi != null && $.gTokenManager != null && $.gTokenManager.isTokenValid()) {
                var newMode = ($.gSpotifyApi.repeatMode + 1) % 3;
                $.gSpotifyApi.setRepeat(newMode);
                var rpLabels = pl ? ["Wyl", "Playlista", "Utwor"] : ["Off", "Playlist", "Track"];
                mView.showConfirm((pl ? "Powt: " : "Rpt: ") + rpLabels[newMode]);
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :saveActivity) {
            mView.saveAndStop();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :discardActivity) {
            mView.discardActivity();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :loginSpotify) {
            if ($.gTokenManager != null) {
                $.gTokenManager.startOAuth();
                mView.showConfirm(pl ? "Otworz telefon!" : "Open phone!");
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :refreshToken) {
            if ($.gTokenManager != null) {
                $.gTokenManager.refreshAccessToken(mView.method(:onTokenRefreshed));
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :refreshTrack) {
            if ($.gSpotifyApi != null && $.gTokenManager != null && $.gTokenManager.isTokenValid()) {
                $.gSpotifyApi.fetchCurrentTrack();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :about) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.pushView(new AboutView(mView.langPolish), new AboutDelegate(), WatchUi.SLIDE_UP);
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
