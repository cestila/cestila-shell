import QtQuick
import ".."

Item {
    id: root

    property bool isHovered: false

    implicitHeight: 22
    implicitWidth: logoPill.implicitWidth

    Rectangle {
        id: logoPill
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 22
        implicitWidth: logoText.implicitWidth + 10
        radius: Theme.radiusMicro
        color: root.isHovered ? Theme.surfaceHigh : "transparent"
        border.color: root.isHovered ? Theme.accentDim : "transparent"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        Behavior on border.color {
            ColorAnimation { duration: Theme.animFast }
        }

        Text {
            id: logoText
            anchors.centerIn: parent
            text: "[C*]"
            font.family: Theme.monoFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            color: root.isHovered ? Theme.accentBright : Theme.accent

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
                PaletteState.toggle();
            }
        }
    }
}
