import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property var currentTime: new Date()

    implicitHeight: 22
    implicitWidth: clockRow.implicitWidth

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentTime = new Date();
        }
    }

    function formatTime(date) {
        var h = date.getHours().toString().padStart(2, "0");
        var m = date.getMinutes().toString().padStart(2, "0");
        var s = date.getSeconds().toString().padStart(2, "0");
        return h + ":" + m + ":" + s;
    }

    function formatDate(date) {
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return days[date.getDay()] + " " + date.getDate() + " " + months[date.getMonth()];
    }

    property bool isHovered: false

    Rectangle {
        id: bgPill
        anchors.centerIn: parent
        implicitHeight: 20
        implicitWidth: clockRow.implicitWidth + 12
        radius: Theme.radiusMicro
        color: root.isHovered ? Theme.surfaceHigh : "transparent"
        border.color: root.isHovered ? Theme.borderFocused : "transparent"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.animFast }
        }

        RowLayout {
            id: clockRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: root.formatTime(root.currentTime)
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
                color: root.isHovered ? Theme.accentBright : Theme.textPrimary
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.formatDate(root.currentTime)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.Medium
                color: root.isHovered ? Theme.textPrimary : Theme.textSecondary
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered: root.isHovered = true
            onExited: root.isHovered = false
            onClicked: {
                CalendarState.toggle();
            }
        }
    }
}
