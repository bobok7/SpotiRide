using Toybox.WatchUi;
using Toybox.Graphics;

class AboutView extends WatchUi.View {
    var langPolish;

    function initialize(pl) {
        View.initialize();
        langPolish = pl;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // App icon
        var icon = WatchUi.loadResource(Rez.Drawables.LauncherIcon);
        dc.drawBitmap(centerX - 20, 6, icon);

        // Title
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 50, Graphics.FONT_MEDIUM, "SpotiRide", Graphics.TEXT_JUSTIFY_CENTER);

        // Version
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 78, Graphics.FONT_XTINY, "v1.0", Graphics.TEXT_JUSTIFY_CENTER);

        // Author
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 96, Graphics.FONT_SMALL, langPolish ? "Autor: bobok7" : "Author: bobok7", Graphics.TEXT_JUSTIFY_CENTER);

        // QR code
        var qr = WatchUi.loadResource(Rez.Drawables.QrGithub);
        var qrX = centerX - 60;
        var qrY = 122;
        dc.drawBitmap(qrX, qrY, qr);

        // GitHub label
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, qrY + 124, Graphics.FONT_XTINY, "github.com/bobok7", Graphics.TEXT_JUSTIFY_CENTER);

        // Back hint
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 18, Graphics.FONT_XTINY, langPolish ? "< BACK = wyjscie" : "< BACK = exit", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class AboutDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
