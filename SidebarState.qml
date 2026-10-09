pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property bool sidebarOpen: false

    // Automatically track focused monitor via native Quickshell.Hyprland
    readonly property string focusedMonitorName: (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : ""
    property string activeScreen: focusedMonitorName

    onFocusedMonitorNameChanged: {
        if (focusedMonitorName !== "") {
            activeScreen = focusedMonitorName;
        }
    }

    // Keep activeScreen immediately in sync on raw events as well
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
        if (sidebarOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        sidebarOpen = true;
    }

    function close() {
        sidebarOpen = false;
    }
}
