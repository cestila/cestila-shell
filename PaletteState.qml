pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool paletteOpen: false
    property string activeScreen: ""
    property string activeCategory: "All"
    property string searchQuery: ""

    readonly property var categories: ["All", "Apps", "Projects", "Herdr", "VPN", "Clipboard"]

    Process {
        id: openProc
        command: ["bash", "-c", "hyprctl monitors -j 2>/dev/null | python3 -c 'import json,sys; ms=json.load(sys.stdin); print(next((m[\"name\"] for m in ms if m.get(\"focused\")), \"\"))'"]
        stdout: StdioCollector {
            id: outCol
            onStreamFinished: {
                var mon = outCol.text.trim();
                if (mon) {
                    root.activeScreen = mon;
                }
                root.paletteOpen = true;
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
        openProc.running = false;
        openProc.running = true;
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
