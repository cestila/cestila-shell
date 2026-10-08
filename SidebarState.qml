pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool sidebarOpen: false
    property string activeScreen: ""

    // Query hyprctl synchronously before setting open state
    // so we always have the exact active monitor at the instant of opening
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
                root.sidebarOpen = true;
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
        openProc.running = false;
        openProc.running = true;
    }

    function close() {
        sidebarOpen = false;
    }
}
