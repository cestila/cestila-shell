import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.SystemTray

Item {
    id: root

    implicitHeight: 22
    implicitWidth: rowLayout.implicitWidth
    visible: trayRepeater.count > 0

    Process {
        id: trayActionProc
    }

    function handleTrayClick(item, mouseButton) {
        if (!item) return;

        var idStr = "" + (item.id || "");
        var titleStr = "" + (item.title || "");
        var iconStr = "" + (item.icon || "");
        var combined = (idStr + " " + titleStr + " " + iconStr).toLowerCase();

        // 1. Standard StatusNotifierItem DBus invocation
        try {
            if (mouseButton === Qt.RightButton) {
                if (typeof item.secondaryActivate === "function") {
                    item.secondaryActivate();
                }
            } else {
                if (typeof item.activate === "function") {
                    item.activate();
                }
            }
        } catch(e) {}

        // 2. Hyprland workspace focus & window raising
        var cmd = "";
        if (combined.indexOf("zapzap") !== -1 || combined.indexOf("whatsapp") !== -1) {
            cmd = "hyprctl dispatch focuswindow class:com.rtosta.zapzap";
        } else if (combined.indexOf("remmina") !== -1) {
            try { if (typeof item.secondaryActivate === "function") item.secondaryActivate(); } catch(e) {}
            cmd = "hyprctl clients -j | grep -q 'org.remmina.Remmina' && hyprctl dispatch focuswindow class:org.remmina.Remmina || (remmina &)";
        } else {
            var candidate = item.id || item.title || "";
            if (candidate && mouseButton === Qt.LeftButton) {
                cmd = "hyprctl dispatch focuswindow " + candidate;
            }
        }

        if (cmd) {
            trayActionProc.running = false;
            trayActionProc.command = ["bash", "-c", cmd];
            trayActionProc.running = true;
        }
    }

    function resolveIcon(icon) {
        if (!icon || icon === "") return "";
        if (icon.startsWith("/") || icon.startsWith("file:") || icon.startsWith("image:")) {
            return icon;
        }
        return Quickshell.iconPath(icon);
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            Item {
                id: trayDelegate
                required property var modelData

                implicitWidth: 18
                implicitHeight: 18

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 14
                    source: root.resolveIcon(trayDelegate.modelData ? trayDelegate.modelData.icon : "")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        root.handleTrayClick(trayDelegate.modelData, mouse.button);
                    }
                }
            }
        }
    }
}
