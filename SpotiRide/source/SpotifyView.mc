using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Timer;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Application;
using Toybox.Lang;
using Toybox.Position;
using Toybox.SensorHistory;

class SpotiRideView extends WatchUi.View {
    var pollTimer = null;
    var isReady = false;
    var currentPage = 0;
    var scrollOffset = 0;
    var tickCount = 0;
    var session = null;

    // Confirmation message
    var confirmMessage = null;
    var confirmTimer = 0;

    // Settings (persisted in Storage)
    var nightModeOption = 0;    // 0=auto, 1=light, 2=dark
    var refreshIntervalIdx = 1; // 0=~5s, 1=~10s, 2=~15s, 3=~30s
    var scrollEnabled = true;
    var tempCelsius = true;
    var autoPauseIdx = 0;       // 0=off, 1=2km/h, 2=3, 3=4, 4=5, 5=6
    var autoPauseDelayIdx = 2;  // 0=0s, 1=3s, 2=5s, 3=10s
    var autoPaused = false;     // currently auto-paused?
    var lowSpeedSince = 0;      // timestamp when speed first dropped below threshold
    var langPolish = true;      // true=PL, false=EN

    function initialize() {
        View.initialize();
        var nm = Application.Storage.getValue("nightMode");
        if (nm != null) { nightModeOption = nm; }
        var ri = Application.Storage.getValue("refreshIdx");
        if (ri != null) { refreshIntervalIdx = ri; }
        var se = Application.Storage.getValue("scrollEnabled");
        if (se != null) { scrollEnabled = se; }
        var tc = Application.Storage.getValue("tempCelsius");
        if (tc != null) { tempCelsius = tc; }
        var ap = Application.Storage.getValue("autoPauseIdx");
        if (ap != null) { autoPauseIdx = ap; }
        var apd = Application.Storage.getValue("autoPauseDelayIdx");
        if (apd != null) { autoPauseDelayIdx = apd; }
        var lp = Application.Storage.getValue("langPolish");
        if (lp != null) { langPolish = lp; }
    }

    // Helper: return PL or EN string
    function s(pl, en) {
        return langPolish ? pl : en;
    }

    var gpsSpeed = null; // speed from GPS in m/s

    function onShow() {
        pollTimer = new Timer.Timer();
        var callback = method(:onTickTimer);
        pollTimer.start(callback, 1500, true);

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));

        if ($.gTokenManager != null) {
            $.gTokenManager.refreshAccessToken(method(:onTokenRefreshed));
        }
    }

    function onPosition(info as Position.Info) as Void {
        if (info.speed != null) {
            gpsSpeed = info.speed;
        }
    }

    function onHide() {
        if (pollTimer != null) {
            pollTimer.stop();
            pollTimer = null;
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function onTickTimer() as Void {
        if ($.gTokenManager == null || $.gSpotifyApi == null) {
            return;
        }

        if (confirmMessage != null) {
            var now = Time.now().value();
            if (now - confirmTimer > 3) {
                confirmMessage = null;
            }
        }

        scrollOffset++;
        tickCount++;

        // Interpolate progress between API fetches
        if ($.gSpotifyApi != null && $.gSpotifyApi.isCurrentlyPlaying && $.gSpotifyApi.durationMs > 0) {
            $.gSpotifyApi.progressMs = $.gSpotifyApi.progressMs + 1500;
            if ($.gSpotifyApi.progressMs > $.gSpotifyApi.durationMs) {
                $.gSpotifyApi.progressMs = $.gSpotifyApi.durationMs;
            }
        }

        checkAutoPause();

        var divider = getRefreshDivider();
        if (tickCount % divider == 0) {
            if ($.gTokenManager.isTokenValid()) {
                $.gSpotifyApi.fetchCurrentTrack();
            } else {
                $.gTokenManager.refreshAccessToken(method(:onTokenRefreshed));
            }
        }

        WatchUi.requestUpdate();
    }

    function getRefreshDivider() {
        if (refreshIntervalIdx == 0) { return 4; }  // ~6s
        if (refreshIntervalIdx == 1) { return 7; }  // ~10.5s
        if (refreshIntervalIdx == 2) { return 10; } // ~15s
        return 20;                                    // ~30s
    }

    function onTokenRefreshed(success) {
        if (success) {
            isReady = true;
            if ($.gTokenManager != null) {
                $.gTokenManager.statusMsg = "";
            }
            if ($.gSpotifyApi != null) {
                $.gSpotifyApi.fetchCurrentTrack();
            }
        }
        WatchUi.requestUpdate();
    }

    function onLike() {
        if ($.gSpotifyApi == null || $.gTokenManager == null) {
            return;
        }
        if ($.gSpotifyApi.currentTrackId.length() > 0 && $.gTokenManager.isTokenValid()) {
            $.gSpotifyApi.likeCurrentTrack();
            $.gSpotifyApi.isCurrentTrackLiked = true;
            showConfirm(s("Polubiono!", "Liked!"));
        }
    }

    function showConfirm(msg) {
        confirmMessage = msg;
        confirmTimer = Time.now().value();
        WatchUi.requestUpdate();
    }

    // --- Activity Recording ---
    function toggleRecording() {
        if (session == null) {
            session = ActivityRecording.createSession({
                :name => s("Jazda", "Ride"),
                :sport => Activity.SPORT_CYCLING,
                :subSport => Activity.SUB_SPORT_ROAD
            });
            session.start();
            autoPaused = false;
            showConfirm(s("Nagrywanie!", "Recording!"));
        } else if (session.isRecording()) {
            session.stop();
            autoPaused = false;
            showConfirm(s("Pauza", "Paused"));
        } else {
            session.start();
            autoPaused = false;
            showConfirm(s("Wznowiono!", "Resumed!"));
        }
    }

    function saveAndStop() {
        if (session != null) {
            if (session.isRecording()) {
                session.stop();
            }
            session.save();
            session = null;
            showConfirm(s("Zapisano!", "Saved!"));
        }
    }

    function discardActivity() {
        if (session != null) {
            if (session.isRecording()) {
                session.stop();
            }
            session.discard();
            session = null;
            showConfirm(s("Odrzucono!", "Discarded!"));
        }
    }

    // Get current speed in m/s from Activity or GPS fallback
    function getCurrentSpeedMs() {
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null && activityInfo.currentSpeed != null && activityInfo.currentSpeed > 0) {
            return activityInfo.currentSpeed;
        }
        if (gpsSpeed != null) {
            return gpsSpeed;
        }
        return 0.0;
    }

    function getAutoPauseSpeed() {
        // Returns threshold in km/h, 0 = disabled
        if (autoPauseIdx == 0) { return 0.0; }
        return autoPauseIdx + 1.0; // 1->2, 2->3, 3->4, 4->5, 5->6
    }

    function getAutoPauseDelay() {
        // Returns delay in seconds before pause triggers
        if (autoPauseDelayIdx == 0) { return 0; }
        if (autoPauseDelayIdx == 1) { return 3; }
        if (autoPauseDelayIdx == 2) { return 5; }
        return 10;
    }

    function checkAutoPause() {
        var threshold = getAutoPauseSpeed();
        if (threshold == 0.0 || session == null) {
            lowSpeedSince = 0;
            return;
        }

        var speedKmh = getCurrentSpeedMs() * 3.6;
        var now = Time.now().value();

        if (session.isRecording()) {
            if (speedKmh < threshold) {
                if (lowSpeedSince == 0) {
                    lowSpeedSince = now;
                }
                if (now - lowSpeedSince >= getAutoPauseDelay()) {
                    session.stop();
                    autoPaused = true;
                }
            } else {
                lowSpeedSince = 0;
            }
        } else if (autoPaused && speedKmh >= threshold) {
            session.start();
            autoPaused = false;
            lowSpeedSince = 0;
        }
    }

    function isNightMode() {
        if (nightModeOption == 1) { return false; } // always light
        if (nightModeOption == 2) { return true; }  // always dark
        var hour = System.getClockTime().hour;
        return (hour >= 20 || hour < 7);
    }

    function getTemperature() {
        var tempVal = null;

        // Try Weather from phone first (more accurate)
        if ((Toybox has :Weather) && (Toybox.Weather has :getCurrentConditions)) {
            var cond = Toybox.Weather.getCurrentConditions();
            if (cond != null && cond.temperature != null) {
                tempVal = cond.temperature.toFloat();
            }
        }

        // Fallback: built-in sensor (less accurate, affected by device heat)
        if (tempVal == null && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory)) {
            var iter = Toybox.SensorHistory.getTemperatureHistory({});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    tempVal = sample.data.toFloat();
                }
            }
        }

        if (tempVal == null) { return "--"; }

        if (!tempCelsius) {
            tempVal = tempVal * 1.8 + 32.0;
        }
        return tempVal.format("%.1f");
    }

    function formatMs(ms) {
        var totalSec = ms / 1000;
        var min = totalSec / 60;
        var sec = totalSec % 60;
        return min + ":" + sec.format("%02d");
    }

    function getTempUnit() {
        return tempCelsius ? "C" : "F";
    }

    function onUpdate(dc) {
        var night = isNightMode();
        var bgColor = night ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var fgColor = night ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var dimColor = night ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
        var lineColor = night ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;

        dc.setColor(bgColor, bgColor);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // Confirmation overlay
        if (confirmMessage != null) {
            var now = Time.now().value();
            if (now - confirmTimer <= 3) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, height / 2, Graphics.FONT_LARGE,
                    confirmMessage,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                return;
            } else {
                confirmMessage = null;
            }
        }

        // Show status messages first (OAuth progress, errors, etc.)
        var displayStatus = "";
        if ($.gTokenManager != null && $.gTokenManager.statusMsg.length() > 0) {
            displayStatus = $.gTokenManager.statusMsg;
        }
        if (displayStatus.length() > 0) {
            dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2, Graphics.FONT_MEDIUM,
                displayStatus,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Check if app is configured
        if ($.gTokenManager != null && !$.gTokenManager.isConfigured()) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 - 10, Graphics.FONT_SMALL,
                s("Nacisnij MENU", "Press MENU"),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(centerX, height / 2 + 15, Graphics.FONT_SMALL,
                s("> Zaloguj Spotify", "> Login Spotify"),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        if (currentPage == 0) {
            drawPage1(dc, width, height, centerX, fgColor, dimColor, lineColor);
        } else {
            drawPage2(dc, width, height, centerX, fgColor, dimColor, lineColor);
        }
    }

    function drawPage1(dc, width, height, centerX, fgColor, dimColor, lineColor) {
        if ($.gSpotifyApi == null) { return; }

        // === ROW 0: Status bar — REC | play/pause | like ===
        if (session != null) {
            if (session.isRecording()) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(6, 2, Graphics.FONT_SMALL, "REC", Graphics.TEXT_JUSTIFY_LEFT);
            } else if (autoPaused) {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(6, 2, Graphics.FONT_SMALL, "A-PAU", Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(6, 2, Graphics.FONT_SMALL, "PAUZA", Graphics.TEXT_JUSTIFY_LEFT);
            }
        } else {
            dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(6, 2, Graphics.FONT_SMALL, "STOP", Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Play/pause (center)
        var noMusic = s("Brak muzyki", "No music");
        if ($.gSpotifyApi.currentTrackTitle.length() > 0 && !$.gSpotifyApi.currentTrackTitle.equals("Brak muzyki") && !$.gSpotifyApi.currentTrackTitle.equals("No music")) {
            if ($.gSpotifyApi.isCurrentlyPlaying) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, 2, Graphics.FONT_SMALL, ">>", Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, 2, Graphics.FONT_SMALL, "||", Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        // Like (right)
        if ($.gSpotifyApi.isCurrentTrackLiked) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 6, 2, Graphics.FONT_SMALL, "<3", Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Separator
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, 22, width - 6, 22);

        // === Track title ===
        if ($.gSpotifyApi.hasError) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, 38, Graphics.FONT_SMALL,
                $.gSpotifyApi.errorMessage,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var title = $.gSpotifyApi.currentTrackTitle;
            var artist = $.gSpotifyApi.currentTrackArtist;

            if (title.length() == 0 || title.equals("Brak muzyki") || title.equals("No music")) {
                dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, 42, Graphics.FONT_MEDIUM, noMusic,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
                var scrolledTitle = getScrolledText(dc, title, Graphics.FONT_MEDIUM, width - 12);
                dc.drawText(centerX, 34, Graphics.FONT_MEDIUM, scrolledTitle,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                if (artist.length() > 0) {
                    dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
                    var scrolledArtist = getScrolledText(dc, artist, Graphics.FONT_SMALL, width - 12);
                    dc.drawText(centerX, 52, Graphics.FONT_SMALL, scrolledArtist,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            }
        }

        // === PROGRESS BAR (single line: time | bar | time) ===
        var dataTop = 72;
        if ($.gSpotifyApi.durationMs > 0 && $.gSpotifyApi.currentTrackTitle.length() > 0
            && !$.gSpotifyApi.currentTrackTitle.equals("Brak muzyki")
            && !$.gSpotifyApi.currentTrackTitle.equals("No music")) {
            var progY = 67;
            dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(6, progY, Graphics.FONT_XTINY, formatMs($.gSpotifyApi.progressMs),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(width - 6, progY, Graphics.FONT_XTINY, formatMs($.gSpotifyApi.durationMs),
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

            var barX = 44;
            var barW = width - 88;
            var barY = 65;
            var barH = 4;
            dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, barW, barH);
            var filled = (barW * $.gSpotifyApi.progressMs) / $.gSpotifyApi.durationMs;
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, filled, barH);

            dataTop = 76;
        } else {
            dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(6, dataTop, width - 6, dataTop);
        }

        var activityInfo = Activity.getActivityInfo();
        var rowH = (height - dataTop - 18) / 4;

        // --- Row 1: Predkosc | Stoper ---
        var rY = dataTop + 2;
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY, Graphics.FONT_XTINY, s("Predk.", "Speed"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(centerX + 4, rY, Graphics.FONT_XTINY, s("Stoper", "Timer"), Graphics.TEXT_JUSTIFY_LEFT);

        var speedMs = getCurrentSpeedMs();
        var speed = (speedMs * 3.6).format("%.1f");
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 15, Graphics.FONT_LARGE, speed, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 4, rY + 22, Graphics.FONT_XTINY, "km/h", Graphics.TEXT_JUSTIFY_RIGHT);

        var stopStr = "0:00:00";
        if (activityInfo != null && activityInfo.timerTime != null) {
            var ts = activityInfo.timerTime / 1000;
            stopStr = (ts/3600) + ":" + ((ts%3600)/60).format("%02d") + ":" + (ts%60).format("%02d");
        }
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 15, Graphics.FONT_LARGE, stopStr, Graphics.TEXT_JUSTIFY_RIGHT);

        // --- Row 2: Dystans | Sr. predk. ---
        rY = dataTop + rowH + 2;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, rY - 2, width - 6, rY - 2);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY, Graphics.FONT_XTINY, s("Dystans", "Dist."), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(centerX + 4, rY, Graphics.FONT_XTINY, s("Sr.predk.", "Avg.spd"), Graphics.TEXT_JUSTIFY_LEFT);

        var dist = "--";
        if (activityInfo != null && activityInfo.elapsedDistance != null) {
            dist = (activityInfo.elapsedDistance / 1000.0).format("%.2f");
        }
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 15, Graphics.FONT_LARGE, dist, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 4, rY + 22, Graphics.FONT_XTINY, "km", Graphics.TEXT_JUSTIFY_RIGHT);

        var avgSpd = "--";
        if (activityInfo != null && activityInfo.averageSpeed != null) {
            avgSpd = (activityInfo.averageSpeed * 3.6).format("%.1f");
        }
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 15, Graphics.FONT_LARGE, avgSpd, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 46, Graphics.FONT_XTINY, "km/h", Graphics.TEXT_JUSTIFY_RIGHT);

        // --- Row 3: Czas calk. | Temp ---
        rY = dataTop + rowH * 2 + 2;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, rY - 2, width - 6, rY - 2);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY, Graphics.FONT_XTINY, s("Czas calk.", "Elapsed"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(centerX + 4, rY, Graphics.FONT_XTINY, s("Temp.", "Temp."), Graphics.TEXT_JUSTIFY_LEFT);

        var elTime = "0:00";
        if (activityInfo != null && activityInfo.elapsedTime != null) {
            var ts = activityInfo.elapsedTime / 1000;
            var h = ts / 3600;
            var m = (ts % 3600) / 60;
            var s = ts % 60;
            if (h > 0) {
                elTime = h + ":" + m.format("%02d") + ":" + s.format("%02d");
            } else {
                elTime = m + ":" + s.format("%02d");
            }
        }
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 15, Graphics.FONT_LARGE, elTime, Graphics.TEXT_JUSTIFY_LEFT);

        var temp = getTemperature();
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 15, Graphics.FONT_LARGE, temp, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 46, Graphics.FONT_XTINY, getTempUnit(), Graphics.TEXT_JUSTIFY_RIGHT);

        // --- Row 4: Tetno | Godzina ---
        rY = dataTop + rowH * 3 + 2;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, rY - 2, width - 6, rY - 2);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY, Graphics.FONT_XTINY, s("Tetno", "HR"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(centerX + 4, rY, Graphics.FONT_XTINY, s("Godz.", "Time"), Graphics.TEXT_JUSTIFY_LEFT);

        var hr = "--";
        if (activityInfo != null && activityInfo.currentHeartRate != null) {
            hr = activityInfo.currentHeartRate.toString();
        }
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 15, Graphics.FONT_LARGE, hr, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 4, rY + 22, Graphics.FONT_XTINY, "bpm", Graphics.TEXT_JUSTIFY_RIGHT);

        var clockTime = System.getClockTime();
        var clockStr = clockTime.hour + ":" + clockTime.min.format("%02d");
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 15, Graphics.FONT_LARGE, clockStr, Graphics.TEXT_JUSTIFY_RIGHT);

        // --- Bottom bar ---
        var bY = height - 16;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, bY, width - 6, bY);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, bY + 1, Graphics.FONT_XTINY, s("LAP=Polub", "LAP=Like"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(width - 6, bY + 1, Graphics.FONT_XTINY, "1/2 v", Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // Strona 2
    function drawPage2(dc, width, height, centerX, fgColor, dimColor, lineColor) {
        var activityInfo = Activity.getActivityInfo();

        // === ROW 0: Status bar — REC | play/pause | like ===
        if (session != null) {
            if (session.isRecording()) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(6, 2, Graphics.FONT_SMALL, "REC", Graphics.TEXT_JUSTIFY_LEFT);
            } else if (autoPaused) {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(6, 2, Graphics.FONT_SMALL, "A-PAU", Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(6, 2, Graphics.FONT_SMALL, "PAUZA", Graphics.TEXT_JUSTIFY_LEFT);
            }
        } else {
            dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(6, 2, Graphics.FONT_SMALL, "STOP", Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Spotify status (center)
        if ($.gSpotifyApi != null && $.gSpotifyApi.currentTrackTitle.length() > 0) {
            if ($.gSpotifyApi.isCurrentlyPlaying) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, 2, Graphics.FONT_SMALL, ">>", Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, 2, Graphics.FONT_SMALL, "||", Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        // Like (right)
        if ($.gSpotifyApi != null && $.gSpotifyApi.isCurrentTrackLiked) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 6, 2, Graphics.FONT_SMALL, "<3", Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // --- Row 1: Godz. | Bateria ---
        var row1Y = 24;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, row1Y, width - 6, row1Y);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, row1Y + 2, Graphics.FONT_XTINY, s("Godz.", "Time"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(centerX + 4, row1Y + 2, Graphics.FONT_XTINY, s("Bateria", "Battery"), Graphics.TEXT_JUSTIFY_LEFT);

        var clockTime = System.getClockTime();
        var clockStr = clockTime.hour + ":" + clockTime.min.format("%02d");
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, row1Y + 15, Graphics.FONT_LARGE, clockStr, Graphics.TEXT_JUSTIFY_LEFT);

        var stats = System.getSystemStats();
        var bat = stats.battery.format("%.0f") + "%";
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, row1Y + 15, Graphics.FONT_LARGE, bat, Graphics.TEXT_JUSTIFY_RIGHT);

        // --- Row 2: PREDKOSC DUZA ---
        var rY = 72;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, rY, width - 6, rY);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 3, Graphics.FONT_XTINY, s("Predkosc", "Speed"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(width - 6, rY + 3, Graphics.FONT_XTINY, "km/h", Graphics.TEXT_JUSTIFY_RIGHT);

        var speed = (getCurrentSpeedMs() * 3.6).format("%.1f");
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, rY + 45, Graphics.FONT_NUMBER_THAI_HOT, speed,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- Row 3: Zach. slonca | Czas calk. ---
        rY = 140;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, rY, width - 6, rY);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 3, Graphics.FONT_XTINY, s("Zach.slonca", "Sunset"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(centerX + 4, rY + 3, Graphics.FONT_XTINY, s("Czas calk.", "Elapsed"), Graphics.TEXT_JUSTIFY_LEFT);

        var sunset = getSunsetStr();
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 17, Graphics.FONT_LARGE, sunset, Graphics.TEXT_JUSTIFY_LEFT);

        var elTime = "0:00";
        if (activityInfo != null && activityInfo.elapsedTime != null) {
            var ts = activityInfo.elapsedTime / 1000;
            var h = ts / 3600;
            var m = (ts % 3600) / 60;
            var s = ts % 60;
            if (h > 0) {
                elTime = h + ":" + m.format("%02d") + ":" + s.format("%02d");
            } else {
                elTime = m + ":" + s.format("%02d");
            }
        }
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 17, Graphics.FONT_LARGE, elTime, Graphics.TEXT_JUSTIFY_RIGHT);

        // --- Row 4: Temp | Dystans ---
        rY = 200;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, rY, width - 6, rY);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 3, Graphics.FONT_XTINY, s("Temp.", "Temp."), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(centerX + 4, rY + 3, Graphics.FONT_XTINY, s("Dystans", "Dist."), Graphics.TEXT_JUSTIFY_LEFT);

        var temp = getTemperature();
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6, rY + 17, Graphics.FONT_LARGE, temp, Graphics.TEXT_JUSTIFY_LEFT);
        var tempWidth = dc.getTextWidthInPixels(temp, Graphics.FONT_LARGE);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(6 + tempWidth + 3, rY + 24, Graphics.FONT_XTINY, getTempUnit(), Graphics.TEXT_JUSTIFY_LEFT);

        var dist = "--";
        if (activityInfo != null && activityInfo.elapsedDistance != null) {
            dist = (activityInfo.elapsedDistance / 1000.0).format("%.2f");
        }
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 17, Graphics.FONT_LARGE, dist, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 6, rY + 48, Graphics.FONT_XTINY, "km", Graphics.TEXT_JUSTIFY_RIGHT);

        // --- Bottom ---
        var bY = height - 16;
        dc.setColor(lineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(6, bY, width - 6, bY);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, bY + 1, Graphics.FONT_XTINY, "2/2 ^",
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    // --- Scrolling text ---
    function getScrolledText(dc, text, font, maxWidth) {
        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            return text;
        }
        if (!scrollEnabled) {
            return truncateText(dc, text, font, maxWidth);
        }
        var sep = "     ";
        var full = text + sep;
        var len = full.length();
        var pos = scrollOffset % len;
        var rotated = full.substring(pos, null);
        if (rotated.length() < len) {
            rotated = rotated + full.substring(0, pos);
        }
        return truncateText(dc, rotated, font, maxWidth);
    }

    // --- Sunset ---
    function getSunsetStr() {
        var loc = Position.getInfo();
        if (loc != null && loc.position != null) {
            var coords = loc.position.toDegrees();
            var lat = coords[0];
            var lon = coords[1];
            if (lat != 0.0 || lon != 0.0) {
                return calcSunset(lat, lon);
            }
        }
        return "--:--";
    }

    function calcSunset(lat, lon) {
        var now = Time.now();
        var today = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var dayOfYear = getDayOfYear(today.year, today.month, today.day);

        var zenith = 90.833;
        var d2r = 3.14159265 / 180.0;
        var r2d = 180.0 / 3.14159265;

        var lngHour = lon / 15.0;
        var t = dayOfYear + ((18.0 - lngHour) / 24.0);

        var M = (0.9856 * t) - 3.289;
        var Mr = M * d2r;
        var L = M + (1.916 * Math.sin(Mr)) + (0.020 * Math.sin(2.0 * Mr)) + 282.634;
        while (L > 360.0) { L = L - 360.0; }
        while (L < 0.0) { L = L + 360.0; }

        var Lr = L * d2r;
        var tanRA = 0.91764 * Math.tan(Lr);
        var RA = Math.atan(tanRA) * r2d;

        var Lq = (L / 90.0).toNumber() * 90;
        var RAq = (RA / 90.0).toNumber() * 90;
        RA = RA + (Lq - RAq);
        RA = RA / 15.0;

        var sinDec = 0.39782 * Math.sin(Lr);
        var cosDec = Math.cos(Math.asin(sinDec));

        var cosH = (Math.cos(zenith * d2r) - (sinDec * Math.sin(lat * d2r))) / (cosDec * Math.cos(lat * d2r));
        if (cosH > 1.0 || cosH < -1.0) { return "--:--"; }

        var H = Math.acos(cosH) * r2d;
        H = H / 15.0;

        var T = H + RA - (0.06571 * t) - 6.622;
        var UT = T - lngHour;
        while (UT > 24.0) { UT = UT - 24.0; }
        while (UT < 0.0) { UT = UT + 24.0; }

        var clockTime = System.getClockTime();
        var tzOffset = clockTime.timeZoneOffset;
        var localT = UT + (tzOffset.toFloat() / 3600.0);
        while (localT >= 24.0) { localT = localT - 24.0; }
        while (localT < 0.0) { localT = localT + 24.0; }

        // Sunset must be afternoon (12:00-23:59)
        if (localT < 12.0) { localT = localT + 12.0; }

        var sunH = localT.toNumber();
        var sunM = ((localT - sunH) * 60.0).toNumber();
        return sunH + ":" + sunM.format("%02d");
    }

    function getDayOfYear(year, month, day) {
        var days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
        var doy = days[month - 1] + day;
        if (month > 2 && year % 4 == 0) { doy = doy + 1; }
        return doy;
    }

    function truncateText(dc, text, font, maxWidth) {
        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            return text;
        }
        var len = text.length();
        while (len > 1) {
            len = len - 1;
            var sub = text.substring(0, len);
            if (dc.getTextWidthInPixels(sub, font) <= maxWidth) {
                return sub;
            }
        }
        return text.substring(0, 1);
    }
}
