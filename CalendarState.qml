pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool calendarOpen: false
    property string activeScreen: ""

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
                root.calendarOpen = true;
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
        openProc.running = false;
        openProc.running = true;
    }

    function close() {
        root.calendarOpen = false;
    }
}
