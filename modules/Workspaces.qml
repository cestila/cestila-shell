import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

Item {
    id: root

    property string screenName: ""
    property int activeWorkspaceId: 1
    property var displayWorkspaces: []
    property var allOccupiedIds: []

    implicitHeight: 22
    implicitWidth: rowLayout.implicitWidth

    function updateWorkspaces() {
        getWorkspacesProc.running = false;
        getWorkspacesProc.running = true;
    }

    Component.onCompleted: {
        updateWorkspaces();
    }

    onScreenNameChanged: {
        updateWorkspaces();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (!event) return;
            var name = event.name;
            if (name === "workspace" ||
                name === "workspacev2" ||
                name === "createworkspace" ||
                name === "destroyworkspace" ||
                name === "movewindow" ||
                name === "openwindow" ||
                name === "closewindow" ||
                name === "focusedmon") {
                root.updateWorkspaces();
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateWorkspaces()
    }

    Process {
        id: getWorkspacesProc
        command: ["bash", "-c", "echo \"{\\\"monitors\\\":$(hyprctl monitors -j 2>/dev/null || echo '[]'),\\\"workspaces\\\":$(hyprctl workspaces -j 2>/dev/null || echo '[]')}\""]
        stdout: StdioCollector {
            id: wsCol
            onStreamFinished: {
                try {
                    var raw = wsCol.text.trim();
                    if (!raw) return;
                    var parsed = JSON.parse(raw);
                    var monitors = parsed.monitors || [];
                    var workspaces = parsed.workspaces || [];

                    // 1. Determine active workspace on THIS specific monitor
                    var activeWs = -1;
                    for (var m = 0; m < monitors.length; m++) {
                        var mon = monitors[m];
                        if (root.screenName && mon.name === root.screenName) {
                            if (mon.activeWorkspace && typeof mon.activeWorkspace.id === "number") {
                                activeWs = mon.activeWorkspace.id;
                            }
                            break;
                        }
                    }

                    // Fallback if screenName not found or unset: pick first active workspace
                    if (activeWs <= 0 && monitors.length > 0 && monitors[0].activeWorkspace) {
                        activeWs = monitors[0].activeWorkspace.id;
                    }

                    if (activeWs > 0) {
                        root.activeWorkspaceId = activeWs;
                    }

                    // 2. Filter workspaces belonging to this monitor
                    var monitorWs = [];
                    var seenIds = {};
                    var allIds = [];

                    for (var w = 0; w < workspaces.length; w++) {
                        var ws = workspaces[w];
                        if (!ws || typeof ws.id !== "number" || ws.id <= 0) continue; // Skip special scratchpads
                        allIds.push(ws.id);

                        // If screenName is defined, strictly match monitor
                        if (!root.screenName || ws.monitor === root.screenName) {
                            seenIds[ws.id] = true;
                            monitorWs.push({
                                id: ws.id,
                                name: ws.name || ws.id.toString(),
                                windows: ws.windows || 0
                            });
                        }
                    }

                    // 3. Ensure the active workspace for this monitor is included
                    if (root.activeWorkspaceId > 0 && !seenIds[root.activeWorkspaceId]) {
                        monitorWs.push({
                            id: root.activeWorkspaceId,
                            name: root.activeWorkspaceId.toString(),
                            windows: 0
                        });
                        seenIds[root.activeWorkspaceId] = true;
                    }

                    // 4. Sort workspaces numerically by id
                    monitorWs.sort(function(a, b) {
                        return a.id - b.id;
                    });

                    root.displayWorkspaces = monitorWs;
                    root.allOccupiedIds = allIds;
                } catch(e) {}
            }
        }
    }

    Process {
        id: switchWsProc
    }

    function switchToWorkspace(wsId) {
        root.activeWorkspaceId = wsId;
        switchWsProc.running = false;
        switchWsProc.command = ["hyprctl", "dispatch", "workspace", wsId.toString()];
        switchWsProc.running = true;
    }

    function createNextWorkspace() {
        var maxId = 0;
        for (var i = 0; i < root.allOccupiedIds.length; i++) {
            if (root.allOccupiedIds[i] > maxId) {
                maxId = root.allOccupiedIds[i];
            }
        }
        var nextId = Math.max(1, maxId + 1);
        root.switchToWorkspace(nextId);
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.displayWorkspaces

            Rectangle {
                id: capsule
                required property var modelData
                required property int index

                readonly property int wsId: modelData.id
                readonly property bool isActive: root.activeWorkspaceId === wsId
                readonly property bool isOccupied: modelData.windows > 0

                implicitHeight: 20
                implicitWidth: isActive ? 26 : 20
                radius: Theme.radiusMicro

                color: isActive
                    ? Theme.accent
                    : (capsuleArea.containsMouse ? Theme.surfaceHigh : (isOccupied ? Theme.surfaceBase : "transparent"))

                border.color: isActive
                    ? Theme.accent
                    : (capsuleArea.containsMouse ? Theme.borderFocused : (isOccupied ? Theme.borderSubtle : "transparent"))
                border.width: 1

                Behavior on implicitWidth {
                    NumberAnimation { duration: Theme.animNormal }
                }

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                Behavior on border.color {
                    ColorAnimation { duration: Theme.animFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: capsule.wsId.toString()
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: capsule.isActive
                    color: capsule.isActive
                        ? Theme.textPrimary
                        : (capsule.isOccupied ? Theme.textSecondary : Theme.textMuted)

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                // Subtle dot indicator for occupied inactive workspace
                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: 2
                        horizontalCenter: parent.horizontalCenter
                    }
                    implicitWidth: 3
                    implicitHeight: 3
                    radius: 1.5
                    color: Theme.accent
                    visible: !capsule.isActive && capsule.isOccupied
                }

                MouseArea {
                    id: capsuleArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        root.switchToWorkspace(capsule.wsId);
                    }
                }
            }
        }

        // Quick add new workspace button (+)
        Rectangle {
            id: plusPill
            implicitHeight: 20
            implicitWidth: 20
            radius: Theme.radiusMicro
            color: plusMouse.containsMouse ? Theme.surfaceHigh : "transparent"
            border.color: plusMouse.containsMouse ? Theme.borderFocused : "transparent"
            border.width: 1

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: "+"
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
                color: plusMouse.containsMouse ? Theme.accentBright : Theme.textMuted

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            MouseArea {
                id: plusMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    root.createNextWorkspace();
                }
            }
        }
    }
}
