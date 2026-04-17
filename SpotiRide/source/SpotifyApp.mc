using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Communications;
using Toybox.Lang;

class SpotiRideApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        $.gTokenManager = new TokenManager();
        $.gSpotifyApi = new SpotifyApi();
    }

    function onStop(state) {
    }

    function getInitialView() {
        var view = new SpotiRideView();
        return [view, new SpotiRideDelegate(view)];
    }

    // Called when makeOAuthRequest completes
    function onOAuthMessage(message) {
        if ($.gTokenManager == null) {
            return;
        }

        if (message == null) {
            $.gTokenManager.isOAuthInProgress = false;
            $.gTokenManager.statusMsg = "OAuth: brak odp.";
            WatchUi.requestUpdate();
            return;
        }

        // Try to extract code from any message type
        var code = null;
        var error = null;

        if (message instanceof Lang.Dictionary) {
            code = message["code"];
            error = message["error"];
        } else if (message instanceof Lang.String) {
            // GCM might return the full redirect URL as a string
            code = $.gTokenManager.extractParam(message, "code");
            error = $.gTokenManager.extractParam(message, "error");
        } else {
            // Try treating it as having string representation
            try {
                var msgStr = message.toString();
                code = $.gTokenManager.extractParam(msgStr, "code");
                error = $.gTokenManager.extractParam(msgStr, "error");
            } catch (e) {
                $.gTokenManager.isOAuthInProgress = false;
                $.gTokenManager.statusMsg = "OAuth: nieznany typ";
                WatchUi.requestUpdate();
                return;
            }
        }

        if (error != null) {
            $.gTokenManager.isOAuthInProgress = false;
            $.gTokenManager.statusMsg = "OAuth err: " + error;
            WatchUi.requestUpdate();
            return;
        }

        if (code != null) {
            $.gTokenManager.statusMsg = "Kod OK, wymiana...";
            WatchUi.requestUpdate();
            $.gTokenManager.exchangeCodeForTokens(code);
            return;
        }

        // No code and no error found
        $.gTokenManager.isOAuthInProgress = false;
        $.gTokenManager.statusMsg = "OAuth: brak kodu";
        WatchUi.requestUpdate();

        if ($.gTokenManager.pendingCallback != null) {
            $.gTokenManager.pendingCallback.invoke(false);
            $.gTokenManager.pendingCallback = null;
        }
    }
}
