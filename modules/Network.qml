import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    property string netType: "none"
    property string ssid: "Disconnected"
    property string ip: ""
    property bool connected: false
    property bool isHovered: false
    property bool pinIp: false

    implicitHeight: 22
    implicitWidth: badge.implicitWidth

    function updateNetwork() {
        getNetProc.running = true;
    }

    Component.onCompleted: {
        updateNetwork();
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.updateNetwork()
    }

    Process {
        id: getNetProc
        command: [
            "sh", "-c",
            "NET=$(LC_ALL=C nmcli -t -f TYPE,STATE,CONNECTION dev status 2>/dev/null | grep -E '^(wifi|ethernet):connected:' | head -n1)\n" +
            "IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \\K\\S+' || ip -4 -o addr show up scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)\n" +
            "echo \"$NET|$IP\""
        ]
        stdout: StdioCollector {
            id: netCol
            onStreamFinished: {
                var raw = netCol.text.trim();
                if (raw) {
                    var lineParts = raw.split("|");
                    var netInfo = lineParts[0] || "";
                    root.ip = lineParts[1] ? lineParts[1].trim() : "";

                    if (netInfo) {
                        var parts = netInfo.split(":");
                        root.netType = parts[0];
                        root.connected = true;
                        var name = parts.slice(2).join(":");
                        root.ssid = name && name.trim() !== "" ? name : (root.netType === "wifi" ? "Wi-Fi" : "Ethernet");
                    } else {
                        root.connected = false;
                        root.netType = "none";
                        root.ssid = "Disconnected";
                    }
                } else {
                    root.connected = false;
                    root.netType = "none";
                    root.ssid = "Disconnected";
                    root.ip = "";
                }
            }
        }
    }

    function getNetIcon() {
        if (!root.connected) return "󰤮";
        if (root.netType === "ethernet") return "󰈀";
        return "󰤨";
    }

    Rectangle {
        id: badge
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 20
        implicitWidth: rowLayout.implicitWidth + 10
        radius: Theme.radiusMicro
        color: root.isHovered ? Theme.surfaceHigh : "transparent"
        border.color: root.isHovered ? Theme.borderSubtle : "transparent"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.animFast }
        }

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: root.getNetIcon()
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSmall
                color: root.connected ? Theme.accent : Theme.textMuted
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: (root.isHovered || root.pinIp) && root.ip !== "" ? root.ip : root.ssid
                font.family: (root.isHovered || root.pinIp) && root.ip !== "" ? Theme.monoFamily : Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.Medium
                color: root.connected ? Theme.textPrimary : Theme.textMuted
                elide: Text.ElideRight
                Layout.maximumWidth: 120
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
                SidebarState.toggle();
            }
        }
    }
}
