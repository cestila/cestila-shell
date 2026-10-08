import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.SystemTray
import ".."

Item {
    id: root

    implicitHeight: 22
    implicitWidth: rowLayout.implicitWidth
    visible: trayRepeater.count > 0

    Process {
        id: focusProc
    }

    // Generic Hyprland window focus resolver
    function focusAppWindow(item) {
        if (!item) return;

        var idStr = "" + (item.id || "");
        var titleStr = "" + (item.title || "");
        var script = [
            "python3 -c '",
            "import json, subprocess, sys;",
            "tokens = [t.lower() for t in [\"" + idStr.replace(/"/g, "") + "\", \"" + titleStr.replace(/"/g, "") + "\"] if t];",
            "clients = json.loads(subprocess.check_output([\"hyprctl\", \"clients\", \"-j\"]));",
            "best = None;",
            "for c in clients:",
            "    c_cls = (c.get(\"class\") or \"\").lower();",
            "    c_ini = (c.get(\"initialClass\") or \"\").lower();",
            "    c_tit = (c.get(\"title\") or \"\").lower();",
            "    for tok in tokens:",
            "        if tok in c_cls or tok in c_ini or tok in c_tit:",
            "            best = c; break;",
            "        sub = tok.replace(\"desktop\", \"\").replace(\"-\", \"\").replace(\"_\", \"\");",
            "        if len(sub) >= 4 and (sub in c_cls or sub in c_tit):",
            "            best = c; break;",
            "    if best: break;",
            "if best:",
            "    subprocess.run([\"hyprctl\", \"dispatch\", \"focuswindow\", \"address:\" + best[\"address\"]]);",
            "'"
        ].join(" ");

        focusProc.running = false;
        focusProc.command = ["bash", "-c", script];
        focusProc.running = true;
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

                // Native SNI DBus context menu anchor
                QsMenuAnchor {
                    id: menuAnchor
                    anchor.window: trayDelegate.QsWindow.window
                    anchor.item: trayDelegate
                    menu: trayDelegate.modelData ? trayDelegate.modelData.menu : null
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        var it = trayDelegate.modelData;
                        if (!it) return;

                        if (mouse.button === Qt.RightButton) {
                            // Right click: open native SNI menu if available (to quit, configure, etc.)
                            if (it.hasMenu && it.menu) {
                                menuAnchor.open();
                            } else if (typeof it.secondaryActivate === "function") {
                                try { it.secondaryActivate(); } catch(e) {}
                            }
                        } else {
                            // Left click: activate via SNI and focus the window in Hyprland
                            try {
                                if (typeof it.activate === "function") {
                                    it.activate();
                                }
                            } catch(e) {}
                            root.focusAppWindow(it);
                        }
                    }
                }
            }
        }
    }
}
