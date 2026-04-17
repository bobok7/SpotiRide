using Toybox.Application;
using Toybox.Communications;
using Toybox.System;
using Toybox.Time;
using Toybox.Lang;

var gTokenManager = null;
var gClientId = "TWOJ_CLIENT_ID";
var gClientSecret = "TWOJ_CLIENT_SECRET";
var gRedirectUri = "https://garmin-spotify-callback.invalid/callback";

class TokenManager {
    var accessToken = null;
    var tokenExpiryTime = 0;
    var isRefreshing = false;
    var pendingCallback = null;
    var isOAuthInProgress = false;
    var isExchangingCode = false;
    var statusMsg = "";

    function initialize() {
        // Load client credentials from GCM settings (Properties) if available
        try {
            var propId = Application.Properties.getValue("ClientId");
            if (propId != null && propId instanceof Lang.String && propId.length() > 10) {
                $.gClientId = propId;
            }
        } catch (e) {}
        try {
            var propSecret = Application.Properties.getValue("ClientSecret");
            if (propSecret != null && propSecret instanceof Lang.String && propSecret.length() > 10) {
                $.gClientSecret = propSecret;
            }
        } catch (e) {}
    }

    function getClientId() {
        return $.gClientId;
    }

    function getClientSecret() {
        return $.gClientSecret;
    }

    var hardcodedRefreshToken = "TWOJ_REFRESH_TOKEN";

    function isPlaceholder(token) {
        if (token == null) { return true; }
        if (token instanceof Lang.String == false) { return true; }
        if (token.length() < 10) { return true; }
        if (token.find("TWOJ_") != null) { return true; }
        if (token.find("YOUR_") != null) { return true; }
        return false;
    }

    function getRefreshToken() {
        // 1. From Storage (saved by OAuth exchange or previous refresh)
        var stored = Application.Storage.getValue("refreshToken");
        if (stored != null && stored instanceof Lang.String && stored.length() > 0 && !isPlaceholder(stored)) {
            return stored;
        }
        // 2. From GCM settings (Properties — user pasted in Garmin Connect Mobile)
        try {
            var propToken = Application.Properties.getValue("RefreshToken");
            if (propToken != null && propToken instanceof Lang.String && !isPlaceholder(propToken)) {
                return propToken;
            }
        } catch (e) {}
        // 3. Hardcoded in source code
        if (!isPlaceholder(hardcodedRefreshToken)) {
            return hardcodedRefreshToken;
        }
        return null;
    }

    function isTokenValid() {
        if (accessToken == null) {
            return false;
        }
        return Time.now().value() < tokenExpiryTime;
    }

    function getAccessToken() {
        return accessToken;
    }

    function hasRefreshToken() {
        return (getRefreshToken() != null);
    }

    function isConfigured() {
        return (getRefreshToken() != null);
    }

    function startOAuth() {
        isOAuthInProgress = true;
        isExchangingCode = false;
        statusMsg = "Logowanie...";

        Communications.makeOAuthRequest(
            "https://accounts.spotify.com/authorize",
            {
                "client_id" => $.gClientId,
                "response_type" => "code",
                "redirect_uri" => $.gRedirectUri,
                "scope" => "user-read-currently-playing user-read-playback-state user-modify-playback-state user-library-read user-library-modify"
            },
            $.gRedirectUri,
            Communications.OAUTH_RESULT_TYPE_URL,
            {"code" => "code", "error" => "error"}
        );
        statusMsg = "Czekam na tel...";
        WatchUi.requestUpdate();
    }

    // Extract query parameter from URL string (e.g. "code" from "https://...?code=ABC&error=...")
    function extractParam(url, paramName) {
        var marker = paramName + "=";
        var idx = url.find(marker);
        if (idx == null) { return null; }
        var start = idx + marker.length();
        if (start >= url.length()) { return null; }
        var rest = url.substring(start, url.length());
        var ampIdx = rest.find("&");
        if (ampIdx != null) {
            return rest.substring(0, ampIdx);
        }
        return rest;
    }

    function exchangeCodeForTokens(code) {
        isExchangingCode = true;
        statusMsg = "Wymiana kodu...";

        Communications.makeWebRequest(
            "https://accounts.spotify.com/api/token",
            {
                "grant_type" => "authorization_code",
                "code" => code,
                "redirect_uri" => $.gRedirectUri,
                "client_id" => $.gClientId,
                "client_secret" => $.gClientSecret
            },
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onTokenResponse)
        );
    }

    function onTokenResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        isOAuthInProgress = false;
        isExchangingCode = false;

        if (responseCode == 200 && data != null && data instanceof Lang.Dictionary) {
            accessToken = data["access_token"];
            var expiresIn = data["expires_in"];
            if (expiresIn != null) {
                tokenExpiryTime = Time.now().value() + expiresIn - 60;
            }

            var refreshToken = data["refresh_token"];
            if (refreshToken != null) {
                Application.Storage.setValue("refreshToken", refreshToken);
                statusMsg = "Zalogowano!";
            } else {
                statusMsg = "Brak ref.token!";
            }

            if (pendingCallback != null) {
                pendingCallback.invoke(true);
                pendingCallback = null;
            }
        } else {
            var errDetail = "Wym:" + responseCode;
            if (data != null && data instanceof Lang.Dictionary) {
                var err = data["error"];
                if (err != null) {
                    errDetail = errDetail + " " + err;
                }
                var desc = data["error_description"];
                if (desc != null) {
                    errDetail = errDetail + " " + desc;
                }
            }
            statusMsg = errDetail;
            if (pendingCallback != null) {
                pendingCallback.invoke(false);
                pendingCallback = null;
            }
        }
        WatchUi.requestUpdate();
    }

    function refreshAccessToken(callback) {
        // Don't interfere with OAuth or code exchange in progress
        if (isOAuthInProgress || isExchangingCode) {
            return;
        }

        if (isRefreshing) {
            pendingCallback = callback;
            return;
        }

        var refreshToken = getRefreshToken();
        if (refreshToken == null) {
            // No token — user must login manually via menu
            if (callback != null) {
                callback.invoke(false);
            }
            return;
        }

        isRefreshing = true;
        pendingCallback = callback;
        statusMsg = "Odswiezanie...";

        Communications.makeWebRequest(
            "https://accounts.spotify.com/api/token",
            {
                "grant_type" => "refresh_token",
                "refresh_token" => refreshToken,
                "client_id" => $.gClientId,
                "client_secret" => $.gClientSecret
            },
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onRefreshResponse)
        );
    }

    var refreshRetryCount = 0;

    function onRefreshResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        isRefreshing = false;

        if (responseCode == 200 && data != null && data instanceof Lang.Dictionary) {
            accessToken = data["access_token"];
            var expiresIn = data["expires_in"];
            if (expiresIn != null) {
                tokenExpiryTime = Time.now().value() + expiresIn - 60;
            }
            var newRefreshToken = data["refresh_token"];
            if (newRefreshToken != null) {
                Application.Storage.setValue("refreshToken", newRefreshToken);
            }
            statusMsg = "";
            refreshRetryCount = 0;
            if (pendingCallback != null) {
                pendingCallback.invoke(true);
            }
        } else if (responseCode == 400 || responseCode == 401) {
            // Refresh token revoked or invalid — clear stored token, fall back to hardcoded
            accessToken = null;
            var stored = Application.Storage.getValue("refreshToken");
            if (stored != null && stored.length() > 0) {
                // Stored token failed — clear it and retry with hardcoded
                Application.Storage.setValue("refreshToken", null);
                statusMsg = "Token wygasl, ponawiam...";
                refreshRetryCount = 0;
                pendingCallback = null;
                WatchUi.requestUpdate();
                refreshAccessToken(null);
                return;
            } else {
                // Hardcoded token also failed
                statusMsg = "Token odrzucony (" + responseCode + ")";
                if (pendingCallback != null) {
                    pendingCallback.invoke(false);
                }
            }
        } else {
            // Network error or temporary issue — retry up to 3 times
            accessToken = null;
            refreshRetryCount++;
            if (refreshRetryCount < 3) {
                statusMsg = "Blad sieci, ponawiam...";
                pendingCallback = null;
                WatchUi.requestUpdate();
                refreshAccessToken(null);
                return;
            }
            statusMsg = "Blad: " + responseCode;
            refreshRetryCount = 0;
            if (pendingCallback != null) {
                pendingCallback.invoke(false);
            }
        }
        pendingCallback = null;
        WatchUi.requestUpdate();
    }
}
