pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property bool paletteOpen: false
    property string activeScreen: ""
    property string activeCategory: "All"
    property string searchQuery: ""

    readonly property var categories: ["All", "Apps", "Projects", "Herdr", "VPN", "Clipboard"]

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
