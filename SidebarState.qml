pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property bool sidebarOpen: false
    property string activeScreen: ""

    // Initial monitor detection on startup
    Process {
        id: initProc
        command: ["bash", "-c", "hyprctl monitors -j 2>/dev/null | python3 -c 'import json,sys; ms=json.load(sys.stdin); print(next((m[\"name\"] for m in ms if m.get(\"focused\")), \"\"))'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var mon = text.trim();
                if (mon && root.activeScreen === "") {
                    root.activeScreen = mon;
                }
            }
        }
    }

    // Keep activeScreen immediately in sync whenever Hyprland switches monitor focus
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
