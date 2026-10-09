pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property bool calendarOpen: false

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
        if (calendarOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        calendarOpen = true;
    }

    function close() {
        root.calendarOpen = false;
    }
}
