import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import "."

PanelWindow {
    id: paletteWindow
    required property var modelData
    screen: modelData

    readonly property string thisScreenName: (modelData && modelData.name) ? modelData.name : (screen ? screen.name : "")
    readonly property bool isTargetScreen: PaletteState.activeScreen !== "" ? (PaletteState.activeScreen === thisScreenName) : true
    readonly property bool shouldBeOpen: PaletteState.paletteOpen && isTargetScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cestila-palette"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldBeOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: shouldBeOpen

    property int selectedIndex: 0

    function resolveIcon(icon) {
        if (!icon || icon === "") return "";
        if (icon.startsWith("/") || icon.startsWith("file:") || icon.startsWith("image:")) {
            return icon;
        }
        return Quickshell.iconPath(icon);
    }

    // Process executor
    Process {
        id: execProc
        property var cmd: []
        command: cmd
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    console.warn("[CommandPalette] exec error:", text.trim());
                }
            }
        }
    }

    // Desktop Apps discovery process
    property var discoveredApps: []

    Process {
        id: appsProc
        command: ["bash", "-c", "python3 $(dirname $(readlink -f ~/.config/quickshell/cestila-shell/shell.qml 2>/dev/null || echo ~/.config/quickshell/cestila-shell))/get_apps.py"]
        stdout: StdioCollector {
            id: appsCol
            onStreamFinished: {
                try {
                    var raw = appsCol.text.trim();
                    if (!raw) return;
                    var parsed = JSON.parse(raw);
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        paletteWindow.discoveredApps = parsed;
                    }
                } catch(e) {
                    console.warn("[CommandPalette] Failed to parse apps:", e);
                }
            }
        }
    }

    Component.onCompleted: {
        appsProc.running = true;
    }

    // VPN discovery process
    property var vpnItems: []

    Process {
        id: vpnProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE,ACTIVE connection show 2>/dev/null | awk -F: '$2 ~ /vpn|wireguard|openconnect|tailscale/ {print $1 \"|\" $2 \"|\" $3}' | while IFS='|' read -r n t a; do if [ \"$n\" = \"MunJK-Forti\" ] && systemctl is-active --quiet openconnect-munijk.service 2>/dev/null; then a=\"yes\"; elif [ \"$n\" = \"Slots\" ] && systemctl is-active --quiet openconnect-slots.service 2>/dev/null; then a=\"yes\"; fi; echo \"$n|$t|$a\"; done"]
        stdout: StdioCollector {
            id: vpnCol
            onStreamFinished: {
                try {
                    var raw = vpnCol.text.trim();
                    var items = [];
                    if (raw) {
                        var lines = raw.split("\n");
                        for (var i = 0; i < lines.length; i++) {
                            var line = lines[i].trim();
                            if (!line) continue;
                            var parts = line.split("|");
                            if (parts.length >= 2) {
                                var vpnName = parts[0];
                                var vpnType = parts[1] === "wireguard" ? "WireGuard" : "VPN";
                                var isConnected = parts.length >= 3 && parts[2] === "yes";
                                items.push({
                                    title: vpnName,
                                    subtitle: (isConnected ? "● Conectado • " : "○ Desconectado • ") + vpnType + " Network",
                                    category: "VPN",
                                    badge: "VPN",
                                    shortcut: isConnected ? "[↵ Disconnect]" : "[↵ Connect]",
                                    vpnName: vpnName,
                                    vpnActive: isConnected
                                });
                            }
                        }
                    }
                    paletteWindow.vpnItems = items;
                } catch(e) {
                    console.warn("[CommandPalette] Failed to parse VPNs:", e);
                }
            }
        }
    }

    // Cliphist reader process
    Process {
        id: cliphistProc
        command: ["bash", "-c", "cliphist list | head -n 30"]
        stdout: StdioCollector {
            id: cliphistCol
            onStreamFinished: {
                try {
                    var raw = cliphistCol.text.trim();
                    if (!raw) return;
                    var lines = raw.split("\n");
                    var items = [];
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i];
                        var tabIdx = line.indexOf("\t");
                        var id = "";
                        var txt = "";
                        if (tabIdx !== -1) {
                            id = line.substring(0, tabIdx).trim();
                            txt = line.substring(tabIdx + 1).trim();
                        } else {
                            txt = line.trim();
                        }
                        if (txt.length > 0) {
                            items.push({
                                title: txt,
                                subtitle: "Clipboard item" + (id ? " #" + id : ""),
                                category: "Clipboard",
                                badge: "CLIP",
                                shortcut: "[Ctrl+Y Copy]",
                                clipId: id,
                                clipText: txt,
                                command: ["wl-copy", txt]
                            });
                        }
                    }
                    if (items.length > 0) {
                        paletteWindow.clipboardItems = items;
                    }
                } catch(e) {}
            }
        }
    }

    property var clipboardItems: [
        {
            title: "nh os switch --hostname cestila-desktop",
            subtitle: "Recent command • Clipboard",
            category: "Clipboard",
            badge: "CLIP",
            shortcut: "[Ctrl+Y Copy]",
            clipText: "nh os switch --hostname cestila-desktop",
            command: ["wl-copy", "nh os switch --hostname cestila-desktop"]
        },
        {
            title: "git status --porcelain=v1",
            subtitle: "Recent command • Clipboard",
            category: "Clipboard",
            badge: "CLIP",
            shortcut: "[Ctrl+Y Copy]",
            clipText: "git status --porcelain=v1",
            command: ["wl-copy", "git status --porcelain=v1"]
        },
        {
            title: "herdr pool status --json",
            subtitle: "Recent command • Clipboard",
            category: "Clipboard",
            badge: "CLIP",
            shortcut: "[Ctrl+Y Copy]",
            clipText: "herdr pool status --json",
            command: ["wl-copy", "herdr pool status --json"]
        },
        {
            title: "https://github.com/cestila/CestilaNixOS",
            subtitle: "Recent URL • Clipboard",
            category: "Clipboard",
            badge: "CLIP",
            shortcut: "[Ctrl+Y Copy]",
            clipText: "https://github.com/cestila/CestilaNixOS",
            command: ["wl-copy", "https://github.com/cestila/CestilaNixOS"]
        }
    ]

    readonly property var allItems: [
        // Apps
        {
            title: "Ghostty Terminal",
            subtitle: "Launch GPU-accelerated terminal emulator",
            category: "Apps",
            badge: "APP",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "ghostty"]
        },
        {
            title: "NeoVim Editor",
            subtitle: "Hyperextensible Vim-based text editor in Ghostty",
            category: "Apps",
            badge: "APP",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "ghostty -e nvim"]
        },
        {
            title: "Web Browser",
            subtitle: "Open default web browser",
            category: "Apps",
            badge: "APP",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "xdg-open https://duckduckgo.com"]
        },
        {
            title: "Btop System Monitor",
            subtitle: "Resource monitor showing CPU, memory, disks and processes",
            category: "Apps",
            badge: "APP",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "ghostty -e btop"]
        },
        {
            title: "Hyprland Configuration",
            subtitle: "Edit NixOS Hyprland desktop config in NeoVim",
            category: "Apps",
            badge: "APP",
            shortcut: "[↵ Run]",
            path: "/home/cestila/CestilaNixOS/modules/home/hyprland/default.nix",
            command: ["hyprctl", "dispatch", "exec", "ghostty -e nvim /home/cestila/CestilaNixOS/modules/home/hyprland/default.nix"]
        },
        {
            title: "NixOS Rebuild Switch",
            subtitle: "Rebuild and apply system configuration with nh",
            category: "Apps",
            badge: "APP",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "ghostty -e bash -c 'cd /home/cestila/CestilaNixOS && nh os switch; read -p \"Press enter to close...\"'"]
        },
        {
            title: "Notification Center",
            subtitle: "Toggle SwayNC notification center",
            category: "Apps",
            badge: "APP",
            shortcut: "[↵ Run]",
            command: ["swaync-client", "-t", "-sw"]
        },
        {
            title: "Power Menu",
            subtitle: "Lock, logout, suspend, reboot or shutdown with wlogout",
            category: "Apps",
            badge: "APP",
            shortcut: "[↵ Run]",
            command: ["wlogout"]
        },

        // Git Projects
        {
            title: "CestilaNixOS",
            subtitle: "~/CestilaNixOS • Flake & Quickshell Desktop System",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/CestilaNixOS",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/CestilaNixOS -e nvim"]
        },
        {
            title: "Herdr Workspace",
            subtitle: "~/workspace/herdr • Multi-Agent Orchestrator",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/herdr",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/workspace/herdr -e nvim"]
        },
        {
            title: "Gentleman Pi Harness",
            subtitle: "~/workspace/gentleman • Pi Coding Agent Harness",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/gentleman",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/workspace/gentleman -e nvim"]
        },
        {
            title: "Antigravity Awesome Skills",
            subtitle: "~/workspace/antigravity-awesome-skills • Agent Skills Catalog",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/antigravity-awesome-skills",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/workspace/antigravity-awesome-skills -e nvim"]
        },
        {
            title: "demoTaller",
            subtitle: "~/workspace/demoTaller • Workshop Demo Project",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/demoTaller",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/workspace/demoTaller -e nvim"]
        },
        {
            title: "EVA Technology",
            subtitle: "~/workspace/EVA Technology • Workspace Repository",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/EVA Technology",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory='/home/cestila/workspace/EVA Technology' -e nvim"]
        },
        {
            title: "girs",
            subtitle: "~/workspace/girs • Git Repository",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/girs",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/workspace/girs -e nvim"]
        },
        {
            title: "GrupoSlots",
            subtitle: "~/workspace/GrupoSlots • Project Repository",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/GrupoSlots",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/workspace/GrupoSlots -e nvim"]
        },
        {
            title: "MuniJK",
            subtitle: "~/workspace/MuniJK • Municipal Project",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/MuniJK",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/workspace/MuniJK -e nvim"]
        },
        {
            title: "Personales",
            subtitle: "~/workspace/Personales • Personal Workspace",
            category: "Projects",
            badge: "GIT",
            shortcut: "[Ctrl+E Editor]",
            path: "/home/cestila/workspace/Personales",
            command: ["hyprctl", "dispatch", "exec", "ghostty --working-directory=/home/cestila/workspace/Personales -e nvim"]
        },

        // Herdr Actions
        {
            title: "Attach scratchpad to agent-build-01",
            subtitle: "Interactive terminal session attached to agent-build-01",
            category: "Herdr",
            badge: "HERDR",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "[float;size 960 640;center] ghostty -e herdr attach agent-build-01"]
        },
        {
            title: "Attach scratchpad to agent-eval-02",
            subtitle: "Interactive terminal session attached to agent-eval-02",
            category: "Herdr",
            badge: "HERDR",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "[float;size 960 640;center] ghostty -e herdr attach agent-eval-02"]
        },
        {
            title: "herdr agent start",
            subtitle: "Launch a new Herdr autonomous worker instance",
            category: "Herdr",
            badge: "HERDR",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "[float;size 960 640;center] ghostty -e herdr agent start"]
        },
        {
            title: "herdr pool status",
            subtitle: "Inspect active agent pool, queues, and task dispatch",
            category: "Herdr",
            badge: "HERDR",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "[float;size 960 640;center] ghostty -e herdr pool status"]
        },
        {
            title: "herdr agent logs",
            subtitle: "Stream live agent execution logs in floating terminal",
            category: "Herdr",
            badge: "HERDR",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "[float;size 960 640;center] ghostty -e herdr logs -f"]
        },
        {
            title: "herdr sync-all",
            subtitle: "Synchronize all working worktrees and state mirrors",
            category: "Herdr",
            badge: "HERDR",
            shortcut: "[↵ Run]",
            command: ["hyprctl", "dispatch", "exec", "[float;size 960 640;center] ghostty -e herdr sync-all"]
        }
    ]

    readonly property var combinedItems: {
        var list = [];
        for (var a = 0; a < discoveredApps.length; a++) {
            list.push(discoveredApps[a]);
        }
        for (var i = 0; i < allItems.length; i++) {
            list.push(allItems[i]);
        }
        for (var v = 0; v < vpnItems.length; v++) {
            list.push(vpnItems[v]);
        }
        for (var j = 0; j < clipboardItems.length; j++) {
            list.push(clipboardItems[j]);
        }
        return list;
    }

    readonly property var filteredItems: {
        var cat = PaletteState.activeCategory;
        var query = PaletteState.searchQuery.trim().toLowerCase();
        var list = combinedItems;
        var out = [];

        for (var i = 0; i < list.length; i++) {
            var item = list[i];
            if (cat !== "All" && item.category !== cat) {
                continue;
            }
            if (query.length > 0) {
                var matchTitle = item.title && item.title.toLowerCase().indexOf(query) !== -1;
                var matchSub = item.subtitle && item.subtitle.toLowerCase().indexOf(query) !== -1;
                var matchCat = item.category && item.category.toLowerCase().indexOf(query) !== -1;
                if (!matchTitle && !matchSub && !matchCat) {
                    continue;
                }
            }
            out.push(item);
        }
        return out;
    }

    onFilteredItemsChanged: {
        if (selectedIndex >= filteredItems.length) {
            selectedIndex = Math.max(0, filteredItems.length - 1);
        }
    }

    function runAction(commandArray) {
        if (!commandArray || commandArray.length === 0) return;
        execProc.running = false;
        execProc.cmd = commandArray;
        execProc.running = true;
        PaletteState.close();
    }

    function copyToClipboard(text) {
        if (!text) return;
        execProc.running = false;
        execProc.cmd = ["wl-copy", text];
        execProc.running = true;
        PaletteState.close();
    }

    function openProjectInEditor(projectPath) {
        if (!projectPath) return;
        execProc.running = false;
        execProc.cmd = ["hyprctl", "dispatch", "exec", "ghostty --working-directory=" + projectPath + " -e nvim"];
        execProc.running = true;
        PaletteState.close();
    }

    function toggleVpn(item) {
        if (!item || !item.vpnName) return;
        var cmd = item.vpnActive ? ["vpn-ctl", item.vpnName, "down"] : ["vpn-ctl", item.vpnName, "up"];
        runAction(cmd);
    }

    function executeItem(item) {
        if (!item) return;
        if (item.category === "VPN") {
            toggleVpn(item);
            return;
        }
        if (item.category === "Clipboard" && item.clipText) {
            copyToClipboard(item.clipText);
            return;
        }
        if (item.command) {
            runAction(item.command);
        } else if (item.exec) {
            runAction(["hyprctl", "dispatch", "exec", item.exec]);
        } else if (item.path) {
            openProjectInEditor(item.path);
        }
    }

    function openInEditor(item) {
        if (!item) return;
        if (item.path) {
            openProjectInEditor(item.path);
        } else if (item.category === "Projects") {
            runAction(["hyprctl", "dispatch", "exec", "ghostty -e nvim"]);
        } else if (item.command) {
            runAction(item.command);
        }
    }

    function copyItem(item) {
        if (!item) return;
        var txt = item.clipText || item.title;
        copyToClipboard(txt);
    }

    Timer {
        id: focusTimer
        interval: 40
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Connections {
        target: PaletteState
        function onPaletteOpenChanged() {
            if (PaletteState.paletteOpen) {
                searchInput.text = "";
                selectedIndex = 0;
                vpnProc.running = true;
                cliphistProc.running = true;
                if (paletteWindow.discoveredApps.length === 0) {
                    appsProc.running = true;
                }
                focusTimer.start();
            }
        }
    }

    // Transparent clickaway dismiss area (NO dark scrim, does not dim the screen)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: PaletteState.close()
    }

    // Dropdown Palette Panel — seamlessly attached & unfolds from the top bar
    Rectangle {
        id: modalBox
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.paletteWidth
        height: Theme.paletteHeight

        // Smooth slide-down unfolding animation directly from the bar bottom
        y: PaletteState.paletteOpen ? Theme.barHeight : (Theme.barHeight - 20)
        opacity: PaletteState.paletteOpen ? 1.0 : 0.0

        Behavior on y {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutCubic
            }
        }

        // Bottom rounded corners only; seamlessly flush with the top bar
        radius: Theme.radiusCard
        color: Theme.surfaceBase
        border.width: 1
        border.color: Theme.borderFocused
        clip: true

        // Top bar connector line matching the bar's bottom edge color
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Theme.accentDim
        }

        // Subtle bottom/side glow shadow to emphasize depth below the bar
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: Theme.radiusCard
            color: "transparent"
            border.color: Theme.accentBright
            border.width: 1
            opacity: 0.35
            z: -1
        }

        MouseArea {
            anchors.fill: parent
            onClicked: searchInput.forceActiveFocus()
        }

        // 1. Search Input Header
        Item {
            id: searchHeader
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 48

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Theme.spacingLg
                    rightMargin: Theme.spacingLg
                }
                spacing: Theme.spacingMd

                // Cyber prompt icon `>` in Theme.accent (#a855f7)
                Text {
                    text: ">"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontLarge
                    font.weight: Font.Bold
                    color: Theme.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMedium
                        color: Theme.textPrimary
                        selectionColor: Theme.accentDim
                        selectedTextColor: Theme.textPrimary
                        clip: true
                        selectByMouse: true

                        onTextChanged: {
                            PaletteState.searchQuery = text;
                            paletteWindow.selectedIndex = 0;
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Down) {
                                if (paletteWindow.filteredItems.length > 0) {
                                    paletteWindow.selectedIndex = (paletteWindow.selectedIndex + 1) % paletteWindow.filteredItems.length;
                                    resultsList.positionViewAtIndex(paletteWindow.selectedIndex, ListView.Contain);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                if (paletteWindow.filteredItems.length > 0) {
                                    paletteWindow.selectedIndex = (paletteWindow.selectedIndex - 1 + paletteWindow.filteredItems.length) % paletteWindow.filteredItems.length;
                                    resultsList.positionViewAtIndex(paletteWindow.selectedIndex, ListView.Contain);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                PaletteState.cycleCategory();
                                paletteWindow.selectedIndex = 0;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Backtab) {
                                var cats = PaletteState.categories;
                                var idx = cats.indexOf(PaletteState.activeCategory);
                                PaletteState.activeCategory = cats[(idx - 1 + cats.length) % cats.length];
                                paletteWindow.selectedIndex = 0;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                PaletteState.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (paletteWindow.filteredItems.length > 0 && paletteWindow.selectedIndex >= 0 && paletteWindow.selectedIndex < paletteWindow.filteredItems.length) {
                                    paletteWindow.executeItem(paletteWindow.filteredItems[paletteWindow.selectedIndex]);
                                }
                                event.accepted = true;
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_E) {
                                if (paletteWindow.filteredItems.length > 0 && paletteWindow.selectedIndex >= 0 && paletteWindow.selectedIndex < paletteWindow.filteredItems.length) {
                                    paletteWindow.openInEditor(paletteWindow.filteredItems[paletteWindow.selectedIndex]);
                                }
                                event.accepted = true;
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Y) {
                                if (paletteWindow.filteredItems.length > 0 && paletteWindow.selectedIndex >= 0 && paletteWindow.selectedIndex < paletteWindow.filteredItems.length) {
                                    paletteWindow.copyItem(paletteWindow.filteredItems[paletteWindow.selectedIndex]);
                                }
                                event.accepted = true;
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Type a command, search apps, VPNs, git repos, or herdr tasks..."
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMedium
                            color: Theme.textMuted
                            visible: !searchInput.text
                        }
                    }
                }

                // Clear button when query is present
                Rectangle {
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: Theme.radiusMicro
                    color: clearMouse.containsMouse ? Theme.surfaceHigh : "transparent"
                    visible: searchInput.text.length > 0
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontSmall
                        color: Theme.textMuted
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // Divider
        Rectangle {
            id: headerDivider
            anchors {
                top: searchHeader.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Theme.borderMuted
        }

        // Filter mode chips row: [All], [Apps], [Projects], [Herdr], [Clipboard]
        Rectangle {
            id: chipsContainer
            anchors {
                top: headerDivider.bottom
                left: parent.left
                right: parent.right
            }
            height: 38
            color: Theme.surfaceLow

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Theme.spacingLg
                    rightMargin: Theme.spacingLg
                }
                spacing: Theme.spacingSm

                Repeater {
                    model: PaletteState.categories

                    Rectangle {
                        id: chipDelegate
                        required property string modelData
                        readonly property bool isActive: PaletteState.activeCategory === chipDelegate.modelData
                        implicitHeight: 24
                        implicitWidth: chipLabel.implicitWidth + 16
                        radius: Theme.radiusMicro
                        color: chipDelegate.isActive ? Theme.accent : (chipMouse.containsMouse ? Theme.surfaceElevated : Theme.surfaceHigh)
                        border.width: 1
                        border.color: chipDelegate.isActive ? Theme.accentBright : (chipMouse.containsMouse ? Theme.borderFocused : Theme.borderMuted)
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: chipDelegate.modelData
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontSmall
                            font.weight: chipDelegate.isActive ? Font.Bold : Font.Medium
                            color: chipDelegate.isActive ? Theme.surfaceLowest : Theme.textSecondary
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                PaletteState.activeCategory = chipDelegate.modelData;
                                paletteWindow.selectedIndex = 0;
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Tab ↹ cycle"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontMicro
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Divider
        Rectangle {
            id: chipsDivider
            anchors {
                top: chipsContainer.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Theme.borderMuted
        }

        // 3. Footer Bar
        Rectangle {
            id: footerBar
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 34
            color: Theme.surfaceLowest

            // Top border
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 1
                color: Theme.borderMuted
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Theme.spacingLg
                    rightMargin: Theme.spacingLg
                }

                // Keyboard legend in Theme.textMuted
                Text {
                    text: "↑↓ Navigate • ↵ Select • Tab Filter • Esc Close • Ctrl+E Open Editor"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontMicro
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Brand chip: CestilaNixOS Command HUD
                Rectangle {
                    implicitHeight: 20
                    implicitWidth: brandText.implicitWidth + 12
                    radius: Theme.radiusMicro
                    color: Theme.surfaceLow
                    border.color: Theme.borderMuted
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: brandText
                        anchors.centerIn: parent
                        text: "CestilaNixOS Command HUD"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMicro
                        font.weight: Font.Bold
                        color: Theme.accentBright
                    }
                }
            }
        }

        // 2. Results ListView
        ListView {
            id: resultsList
            anchors {
                top: chipsDivider.bottom
                bottom: footerBar.top
                left: parent.left
                right: parent.right
                margins: Theme.spacingXs
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: filteredItems

            delegate: Rectangle {
                id: itemDelegate
                required property var modelData
                required property int index

                readonly property bool isSelected: paletteWindow.selectedIndex === itemDelegate.index

                implicitWidth: resultsList.width
                implicitHeight: 48
                radius: Theme.radiusMicro
                color: itemDelegate.isSelected ? Theme.surfaceHigh : (itemMouse.containsMouse ? Theme.surfaceLow : "transparent")

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                // Left 3px indicator line in Theme.accent when selected
                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 3
                    radius: 1
                    color: Theme.accent
                    visible: itemDelegate.isSelected
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Theme.spacingMd
                        rightMargin: Theme.spacingMd
                    }
                    spacing: Theme.spacingMd

                    // Category / Icon Badge
                    Rectangle {
                        readonly property bool hasIcon: !!(itemDelegate.modelData && itemDelegate.modelData.icon)
                        implicitWidth: hasIcon ? 28 : 52
                        implicitHeight: hasIcon ? 28 : 22
                        radius: Theme.radiusMicro
                        color: {
                            if (hasIcon) return "transparent";
                            if (itemDelegate.modelData.category === "Apps") return Theme.stateIdleBg;
                            if (itemDelegate.modelData.category === "Projects") return Theme.stateRunningBg;
                            if (itemDelegate.modelData.category === "Herdr") return Theme.accentFaint;
                            if (itemDelegate.modelData.category === "VPN") return itemDelegate.modelData.vpnActive ? Theme.stateRunningBg : Theme.surfaceHigh;
                            if (itemDelegate.modelData.category === "Clipboard") return Theme.stateBlockedBg;
                            return Theme.surfaceElevated;
                        }
                        border.color: {
                            if (hasIcon) return "transparent";
                            if (itemDelegate.modelData.category === "Apps") return Theme.stateIdle;
                            if (itemDelegate.modelData.category === "Projects") return Theme.stateRunning;
                            if (itemDelegate.modelData.category === "Herdr") return Theme.accent;
                            if (itemDelegate.modelData.category === "VPN") return itemDelegate.modelData.vpnActive ? Theme.stateRunning : Theme.borderFocused;
                            if (itemDelegate.modelData.category === "Clipboard") return Theme.stateBlocked;
                            return Theme.borderMuted;
                        }
                        border.width: hasIcon ? 0 : 1
                        Layout.alignment: Qt.AlignVCenter

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 22
                            source: parent.hasIcon ? paletteWindow.resolveIcon(itemDelegate.modelData.icon) : ""
                            visible: parent.hasIcon
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !parent.hasIcon
                            text: itemDelegate.modelData.badge || (itemDelegate.modelData.category ? itemDelegate.modelData.category.toUpperCase().substring(0, 4) : "APP")
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            font.weight: Font.Bold
                            color: {
                                if (itemDelegate.modelData.category === "Apps") return Theme.stateIdle;
                                if (itemDelegate.modelData.category === "Projects") return Theme.stateRunning;
                                if (itemDelegate.modelData.category === "Herdr") return Theme.accentBright;
                                if (itemDelegate.modelData.category === "VPN") return itemDelegate.modelData.vpnActive ? Theme.stateRunning : Theme.accentBright;
                                if (itemDelegate.modelData.category === "Clipboard") return Theme.stateBlocked;
                                return Theme.textSecondary;
                            }
                        }
                    }

                    // Title and Subtitle column
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: itemDelegate.modelData.title || ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBase
                            font.weight: Font.DemiBold
                            color: itemDelegate.isSelected ? Theme.textPrimary : Theme.textSecondary
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: itemDelegate.modelData.subtitle || ""
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            color: itemDelegate.isSelected ? Theme.textSecondary : Theme.textMuted
                            elide: Text.ElideRight
                        }
                    }

                    // Action shortcut badge on right: [↵ Run], [Ctrl+E Editor], [Ctrl+Y Copy]
                    Rectangle {
                        implicitHeight: 22
                        implicitWidth: shortcutLabel.implicitWidth + 12
                        radius: Theme.radiusMicro
                        color: itemDelegate.isSelected ? Theme.surfaceElevated : "transparent"
                        border.color: itemDelegate.isSelected ? Theme.borderFocused : Theme.borderMuted
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: shortcutLabel
                            anchors.centerIn: parent
                            text: itemDelegate.modelData.shortcut || "[↵ Run]"
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            font.weight: Font.Medium
                            color: itemDelegate.isSelected ? Theme.accentBright : Theme.textMuted
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: paletteWindow.selectedIndex = itemDelegate.index
                    onClicked: {
                        paletteWindow.selectedIndex = itemDelegate.index;
                        paletteWindow.executeItem(itemDelegate.modelData);
                    }
                }
            }
        }

        // Empty state when no items match
        Item {
            anchors {
                top: chipsDivider.bottom
                bottom: footerBar.top
                left: parent.left
                right: parent.right
            }
            visible: filteredItems.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingSm

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "◈"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontTitle
                    color: Theme.accentDim
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No matching commands or actions found"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontBase
                    color: Theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Try switching category (Tab) or adjusting query"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textMuted
                    opacity: 0.7
                }
            }
        }
    }
}
