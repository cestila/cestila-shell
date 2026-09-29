import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: root

    property int runningCount: 2
    property bool isHovered: false

    implicitHeight: 22
    implicitWidth: badge.implicitWidth

    function updateAgents() {
        getAgentsProc.running = true;
    }

    Component.onCompleted: {
        updateAgents();
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.updateAgents()
    }

    Process {
        id: getAgentsProc
        command: ["herdr", "agent", "list"]
        stdout: StdioCollector {
            id: agentsCol
            onStreamFinished: {
                try {
                    var out = agentsCol.text.trim();
                    if (out) {
                        var res = JSON.parse(out);
                        var list = res.result && res.result.agents ? res.result.agents : [];
                        var active = 0;
                        for (var i = 0; i < list.length; i++) {
                            var st = list[i].agent_status;
                            if (st === "working" || st === "running") {
                                active++;
                            }
                        }
                        root.runningCount = active > 0 ? active : (list.length > 0 ? list.length : 2);
                    }
                } catch(e) {
                    // Fallback to initial value
                }
            }
        }
    }

    Process {
        id: toggleHerdrProc
        command: ["hyprctl", "dispatch", "togglespecialworkspace", "herdr"]
    }

    Rectangle {
        id: badge
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 20
        implicitWidth: rowLayout.implicitWidth + 12
        radius: Theme.radiusMicro
        color: root.isHovered ? Theme.stateRunning : Theme.stateRunningBg
        border.color: Theme.stateRunning
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 5

            // Pulsing green indicator dot
            Rectangle {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: root.isHovered ? Theme.bg : Theme.stateRunning
                Layout.alignment: Qt.AlignVCenter

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { from: 1.0; to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                }
            }

            Text {
                text: "⚡ " + root.runningCount + " Running"
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
                color: root.isHovered ? Theme.bg : "#6ee7b7"
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
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
