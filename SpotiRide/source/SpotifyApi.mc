using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;

var gSpotifyApi = null;

class SpotifyApi {
    var currentTrackTitle = "";
    var currentTrackArtist = "";
    var currentTrackId = "";
    var isCurrentlyPlaying = false;
    var isCurrentTrackLiked = false;
    var hasError = false;
    var errorMessage = "";
    var progressMs = 0;
    var durationMs = 0;
    var shuffleOn = false;
    var repeatMode = 0; // 0=off, 1=context(playlist), 2=track

    function fetchCurrentTrack() {
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }

        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/player/currently-playing",
            null,
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Authorization" => "Bearer " + token
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onCurrentTrackResponse)
        );
    }

    function onCurrentTrackResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        if (responseCode == 401) {
            $.gTokenManager.refreshAccessToken(null);
            return;
        }

        if (responseCode == 204 || data == null) {
            currentTrackTitle = "";
            currentTrackArtist = "";
            currentTrackId = "";
            isCurrentlyPlaying = false;
            progressMs = 0;
            durationMs = 0;
            hasError = false;
            WatchUi.requestUpdate();
            return;
        }

        if (responseCode == 200 && data instanceof Lang.Dictionary) {
            hasError = false;
            var playing = data["is_playing"];
            if (playing != null) {
                isCurrentlyPlaying = playing;
            }

            var progress = data["progress_ms"];
            if (progress != null) {
                progressMs = progress;
            }

            var item = data["item"];
            if (item != null && item instanceof Lang.Dictionary) {
                var name = item["name"];
                currentTrackTitle = (name != null) ? name : "";

                var duration = item["duration_ms"];
                if (duration != null) {
                    durationMs = duration;
                }

                var artists = item["artists"];
                if (artists != null && artists instanceof Lang.Array && artists.size() > 0) {
                    var firstArtist = artists[0];
                    if (firstArtist instanceof Lang.Dictionary) {
                        var artistName = firstArtist["name"];
                        currentTrackArtist = (artistName != null) ? artistName : "";
                    }
                } else {
                    currentTrackArtist = "";
                }

                var trackId = item["id"];
                if (trackId != null) {
                    var oldTrackId = currentTrackId;
                    currentTrackId = trackId;
                    if (!oldTrackId.equals(trackId)) {
                        isCurrentTrackLiked = false;
                        checkIfLiked(trackId);
                    }
                }
            }
        } else if (responseCode != 0) {
            hasError = true;
            errorMessage = "Blad: " + responseCode;
        }
        WatchUi.requestUpdate();
    }

    function likeCurrentTrack() {
        if (currentTrackId.length() == 0) { return; }
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }

        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/tracks?ids=" + currentTrackId,
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_PUT,
                :headers => {
                    "Authorization" => "Bearer " + token
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onLikeResponse)
        );
    }

    function onLikeResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        if (responseCode == 200 || responseCode == 204) {
            isCurrentTrackLiked = true;
            WatchUi.requestUpdate();
        }
    }

    function checkIfLiked(trackId) {
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }

        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/tracks/contains?ids=" + trackId,
            null,
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Authorization" => "Bearer " + token
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onCheckLikedResponse)
        );
    }

    function onCheckLikedResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        if (responseCode == 200 && data instanceof Lang.Array) {
            if (data.size() > 0) {
                isCurrentTrackLiked = data[0];
                WatchUi.requestUpdate();
            }
        }
    }

    // --- Playback controls ---

    function nextTrack() {
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }
        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/player/next",
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => { "Authorization" => "Bearer " + token },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onControlResponse)
        );
    }

    function previousTrack() {
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }
        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/player/previous",
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => { "Authorization" => "Bearer " + token },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onControlResponse)
        );
    }

    function pausePlayback() {
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }
        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/player/pause",
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_PUT,
                :headers => { "Authorization" => "Bearer " + token },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onControlResponse)
        );
    }

    function resumePlayback() {
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }
        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/player/play",
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_PUT,
                :headers => { "Authorization" => "Bearer " + token },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onControlResponse)
        );
    }

    function setShuffle(state) {
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }
        var stateStr = state ? "true" : "false";
        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/player/shuffle?state=" + stateStr,
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_PUT,
                :headers => { "Authorization" => "Bearer " + token },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onControlResponse)
        );
        shuffleOn = state;
    }

    function setRepeat(mode) {
        var token = $.gTokenManager.getAccessToken();
        if (token == null) { return; }
        var stateStr = "off";
        if (mode == 1) { stateStr = "context"; }
        else if (mode == 2) { stateStr = "track"; }
        Communications.makeWebRequest(
            "https://api.spotify.com/v1/me/player/repeat?state=" + stateStr,
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_PUT,
                :headers => { "Authorization" => "Bearer " + token },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onControlResponse)
        );
        repeatMode = mode;
    }

    function onControlResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        if (responseCode == 401) {
            $.gTokenManager.refreshAccessToken(null);
        }
        if (responseCode == 200 || responseCode == 204) {
            fetchCurrentTrack();
        }
        WatchUi.requestUpdate();
    }
}
