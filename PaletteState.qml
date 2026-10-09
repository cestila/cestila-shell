pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property bool paletteOpen: false
    property string activeCategory: "All"
    property string searchQuery: ""

    readonly property var categories: ["All", "Apps", "Projects", "Herdr", "VPN", "Clipboard"]

    // Automatically track focused monitor via native Quickshell.Hyprland
    readonly property string focusedMonitorName: (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : ""
    property string activeScreen: focusedMonitorName

    onFocusedMonitorNameChanged: {
        if (focusedMonitorName !== "") {
            activeScreen = focusedMonitorName;
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            if (event.name === "focusedmon" || event.name === "focusedmonv2") {
                var monName = event.data.split(",")[0].trim();
                if (monName) {
                    root.activeScreen = monName;
                }
            }
        }
    }

    function toggle() {
        if (paletteOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        paletteOpen = true;
    }

    function close() {
        paletteOpen = false;
        searchQuery = "";
    }

    function cycleCategory() {
        var idx = categories.indexOf(activeCategory);
        activeCategory = categories[(idx + 1) % categories.length];
    }
}
