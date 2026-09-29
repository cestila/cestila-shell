import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    property bool isHovered: false

    implicitHeight: 22
    implicitWidth: 22

    Process {
        id: wlogoutProc
        command: ["wlogout"]
    }

    Rectangle {
        id: bgPill
        anchors.centerIn: parent
        implicitHeight: 20
        implicitWidth: 20
        radius: Theme.radiusMicro
        color: root.isHovered ? Theme.surfaceHigh : "transparent"
        border.color: root.isHovered ? Theme.stateCritical : "transparent"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        Behavior on border.color {
            ColorAnimation { duration: Theme.animFast }
        }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: Theme.monoFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            color: root.isHovered ? Theme.stateCritical : Theme.textMuted

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered: root.isHovered = true
            onExited: root.isHovered = false

            onClicked: {
                wlogoutProc.running = true;
            }
        }
    }
}
