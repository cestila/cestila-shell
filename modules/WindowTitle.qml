import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

Item {
    id: root

    property string windowTitle: "Desktop"
    property string windowClass: ""
    property int maxTitleWidth: 220

    implicitHeight: 22
    implicitWidth: rowLayout.implicitWidth

    function updateTitle() {
        getTitleProc.running = true;
    }

    Component.onCompleted: {
        updateTitle();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (!event) return;
            if (event.name === "activewindow" ||
                event.name === "activewindowv2" ||
                event.name === "closewindow" ||
                event.name === "workspace" ||
                event.name === "focusedmon") {
                root.updateTitle();
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.updateTitle()
    }

    Process {
        id: getTitleProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            id: titleCol
            onStreamFinished: {
                try {
                    var data = JSON.parse(titleCol.text);
                    if (data && data.title && data.title.trim() !== "") {
                        root.windowTitle = data.title;
                        root.windowClass = data.class || "";
                    } else {
                        root.windowTitle = "Desktop";
                        root.windowClass = "";
                    }
                } catch(e) {
                    root.windowTitle = "Desktop";
                    root.windowClass = "";
                }
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            radius: 2
            color: root.windowTitle !== "Desktop" ? Theme.accent : Theme.textMuted
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: titleText
            text: root.windowTitle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.weight: Font.Medium
            color: root.windowTitle !== "Desktop" ? Theme.textSecondary : Theme.textMuted
            elide: Text.ElideRight
            Layout.preferredWidth: Math.min(implicitWidth, root.maxTitleWidth)
            Layout.maximumWidth: root.maxTitleWidth
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
