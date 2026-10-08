import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.."

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight

    // State properties
    property bool wifiActive: true
    property string wifiSsid: "Wi-Fi"
    property bool wifiListExpanded: false
    property var wifiList: []
    property var vpnList: []
    readonly property int activeVpnCount: {
        var count = 0;
        for (var i = 0; i < vpnList.length; i++) {
            if (vpnList[i].active) count++;
        }
        return count;
    }
    property bool btActive: false
    property bool nightLightActive: false
    property bool dndActive: false

    property int volumeLevel: 50
    property int brightnessLevel: 75

    // Processes for state checking & toggling
    Process {
        id: checkWifiProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            id: wifiCol
            onStreamFinished: {
                root.wifiActive = wifiCol.text.trim() === "enabled";
            }
        }
    }

    Process {
        id: getWifiProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE,ACTIVE connection show 2>/dev/null | grep -E ':(wifi|802-11-wireless):'"]
        stdout: StdioCollector {
            id: wifiListCol
            onStreamFinished: {
                var raw = wifiListCol.text.trim();
                var list = [];
                if (raw) {
                    var lines = raw.split("\n");
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].split(":");
                        if (parts.length >= 3) {
                            var isActive = parts[2] === "yes";
                            if (isActive) root.wifiSsid = parts[0];
                            list.push({
                                name: parts[0],
                                type: "Wi-Fi",
                                active: isActive
                            });
                        }
                    }
                }
                root.wifiList = list;
            }
        }
    }

    Process {
        id: getVpnProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE,ACTIVE connection show 2>/dev/null | grep -E ':(vpn|wireguard):'"]
        stdout: StdioCollector {
            id: vpnCol
            onStreamFinished: {
                var raw = vpnCol.text.trim();
                var list = [];
                if (raw) {
                    var lines = raw.split("\n");
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].split(":");
                        if (parts.length >= 3) {
                            list.push({
                                name: parts[0],
                                type: parts[1] === "wireguard" ? "WireGuard" : "VPN",
                                active: parts[2] === "yes"
                            });
                        }
                    }
                }
                root.vpnList = list;
            }
        }
    }

    Process {
        id: checkBtProc
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off"]
        stdout: StdioCollector {
            id: btCol
            onStreamFinished: {
                root.btActive = btCol.text.trim() === "on";
            }
        }
    }

    Process {
        id: checkNightProc
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            id: nightCol
            onStreamFinished: {
                root.nightLightActive = nightCol.text.trim() === "on";
            }
        }
    }

    Process {
        id: checkDndProc
        command: ["sh", "-c", "swaync-client -D 2>/dev/null || echo false"]
        stdout: StdioCollector {
            id: dndCol
            onStreamFinished: {
                root.dndActive = dndCol.text.trim() === "true";
            }
        }
    }

    // Volume fetch
    Process {
        id: getVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            id: volCol
            onStreamFinished: {
                var text = volCol.text.trim();
                var match = text.match(/([0-9]+(\.[0-9]+)?)/);
                if (match) {
                    root.volumeLevel = Math.round(parseFloat(match[1]) * 100);
                }
            }
        }
    }

    // Brightness fetch
    Process {
        id: getBrightProc
        command: ["sh", "-c", "ACT=$(brightnessctl g 2>/dev/null || echo 0); MAX=$(brightnessctl m 2>/dev/null || echo 1); echo $(( ACT * 100 / MAX ))"]
        stdout: StdioCollector {
            id: brightCol
            onStreamFinished: {
                var val = parseInt(brightCol.text.trim());
                if (!isNaN(val) && val >= 0) {
                    root.brightnessLevel = Math.min(Math.max(val, 5), 100);
                }
            }
        }
    }

    // Generic command runner
    Process {
        id: cmdProc
        property var cmd: []
        command: cmd
    }

    function runCmd(args) {
        cmdProc.cmd = args;
        cmdProc.running = true;
    }

    function toggleWifi() {
        if (root.wifiActive) {
            runCmd(["nmcli", "radio", "wifi", "off"]);
            root.wifiActive = false;
        } else {
            runCmd(["nmcli", "radio", "wifi", "on"]);
            root.wifiActive = true;
        }
    }

    function toggleBt() {
        if (root.btActive) {
            runCmd(["bluetoothctl", "power", "off"]);
            root.btActive = false;
        } else {
            runCmd(["bluetoothctl", "power", "on"]);
            root.btActive = true;
        }
    }

    function toggleNightLight() {
        if (root.nightLightActive) {
            runCmd(["sh", "-c", "pkill -x hyprsunset"]);
            root.nightLightActive = false;
        } else {
            runCmd(["sh", "-c", "hyprsunset -t 4500 &"]);
            root.nightLightActive = true;
        }
    }

    function toggleDnd() {
        runCmd(["swaync-client", "-d"]);
        root.dndActive = !root.dndActive;
    }

    function setVolume(pct) {
        root.volumeLevel = Math.max(0, Math.min(100, Math.round(pct)));
        runCmd(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (root.volumeLevel / 100).toFixed(2)]);
    }

    function setBrightness(pct) {
        root.brightnessLevel = Math.max(5, Math.min(100, Math.round(pct)));
        runCmd(["brightnessctl", "set", root.brightnessLevel + "%"]);
    }

    function toggleVpnConnection(vpnName, isCurrentlyActive) {
        if (isCurrentlyActive) {
            runCmd(["nmcli", "connection", "down", "id", vpnName]);
        } else {
            runCmd(["nmcli", "connection", "up", "id", vpnName]);
        }
        refreshVpnTimer.restart();
    }

    function connectWifi(ssidName) {
        runCmd(["nmcli", "connection", "up", "id", ssidName]);
        refreshVpnTimer.restart();
    }

    Timer {
        id: refreshVpnTimer
        interval: 1200
        repeat: false
        onTriggered: {
            getVpnProc.running = true;
            getWifiProc.running = true;
            checkWifiProc.running = true;
        }
    }

    function refreshAll() {
        checkWifiProc.running = true;
        getWifiProc.running = true;
        getVpnProc.running = true;
        checkBtProc.running = true;
        checkNightProc.running = true;
        checkDndProc.running = true;
        getVolProc.running = true;
        getBrightProc.running = true;
    }

    Component.onCompleted: {
        refreshAll();
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    property bool collapsed: false

    ColumnLayout {
        id: mainCol
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: Theme.spacingMd

        // Header: "QUICK SETTINGS" + accordion chevron
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            color: accordMouse.containsMouse ? Theme.surfaceHigh : "transparent"
            radius: Theme.radiusMicro

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingSm
                anchors.rightMargin: Theme.spacingSm
                spacing: Theme.spacingSm

                Text {
                    text: root.collapsed ? "󰅂" : "󰅃"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "QUICK SETTINGS"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }
            }

            MouseArea {
                id: accordMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.collapsed = !root.collapsed
            }
        }

        // Accordion collapsible body
        ColumnLayout {
            id: accordContent
            Layout.fillWidth: true
            spacing: Theme.spacingMd
            visible: !root.collapsed

        // 2x2 Grid of Quick Toggles
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Theme.spacingSm
            columnSpacing: Theme.spacingSm

            // Toggle 1: Wi-Fi
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: Theme.radiusMicro
                color: root.wifiActive ? Theme.accent : (wifiMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase)
                border.color: root.wifiActive ? Theme.accentBright : (wifiMouse.containsMouse ? Theme.borderFocused : Theme.borderSubtle)
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Theme.spacingSm
                    }
                    spacing: 8

                    Text {
                        text: root.wifiActive ? "󰤨" : "󰤭"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontTitle
                        color: root.wifiActive ? Theme.oledBlack : Theme.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Wi-Fi"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBase
                            font.weight: Font.DemiBold
                            color: root.wifiActive ? Theme.oledBlack : Theme.textPrimary
                        }
                        Text {
                            text: root.wifiActive ? (root.wifiSsid || "Connected") : "Disabled"
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            color: root.wifiActive ? "#2a1442" : Theme.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Expand arrow to open network list
                    Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: Theme.radiusMicro
                        color: wifiExpMouse.containsMouse ? (root.wifiActive ? "#8b35df" : Theme.surfaceHigh) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: root.wifiListExpanded ? "󰅃" : "󰅂"
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                            color: root.wifiActive ? Theme.oledBlack : Theme.textSecondary
                        }

                        MouseArea {
                            id: wifiExpMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                root.wifiListExpanded = !root.wifiListExpanded;
                                if (root.wifiListExpanded) {
                                    getWifiProc.running = true;
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: wifiMouse
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                        rightMargin: 32
                    }
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.toggleWifi()
                }
            }

            // Toggle 2: Bluetooth
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: Theme.radiusMicro
                color: root.btActive ? Theme.accent : (btMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase)
                border.color: root.btActive ? Theme.accentBright : (btMouse.containsMouse ? Theme.borderFocused : Theme.borderSubtle)
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Theme.spacingSm
                    }
                    spacing: 8

                    Text {
                        text: root.btActive ? "󰂯" : "󰂲"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontTitle
                        color: root.btActive ? Theme.oledBlack : Theme.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Bluetooth"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBase
                            font.weight: Font.DemiBold
                            color: root.btActive ? Theme.oledBlack : Theme.textPrimary
                        }
                        Text {
                            text: root.btActive ? "Enabled" : "Disabled"
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            color: root.btActive ? "#2a1442" : Theme.textMuted
                        }
                    }
                }

                MouseArea {
                    id: btMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.toggleBt()
                }
            }

            // Toggle 3: Night Light
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: Theme.radiusMicro
                color: root.nightLightActive ? Theme.accent : (nightMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase)
                border.color: root.nightLightActive ? Theme.accentBright : (nightMouse.containsMouse ? Theme.borderFocused : Theme.borderSubtle)
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Theme.spacingSm
                    }
                    spacing: 8

                    Text {
                        text: "󱩌"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontTitle
                        color: root.nightLightActive ? Theme.oledBlack : Theme.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Night Light"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBase
                            font.weight: Font.DemiBold
                            color: root.nightLightActive ? Theme.oledBlack : Theme.textPrimary
                        }
                        Text {
                            text: root.nightLightActive ? "Active (4500K)" : "Off"
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            color: root.nightLightActive ? "#2a1442" : Theme.textMuted
                        }
                    }
                }

                MouseArea {
                    id: nightMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.toggleNightLight()
                }
            }

            // Toggle 4: DND
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: Theme.radiusMicro
                color: root.dndActive ? Theme.accent : (dndMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase)
                border.color: root.dndActive ? Theme.accentBright : (dndMouse.containsMouse ? Theme.borderFocused : Theme.borderSubtle)
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Theme.spacingSm
                    }
                    spacing: 8

                    Text {
                        text: "󰂛"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontTitle
                        color: root.dndActive ? Theme.oledBlack : Theme.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Do Not Disturb"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBase
                            font.weight: Font.DemiBold
                            color: root.dndActive ? Theme.oledBlack : Theme.textPrimary
                        }
                        Text {
                            text: root.dndActive ? "Silent Mode" : "Normal"
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            color: root.dndActive ? "#2a1442" : Theme.textMuted
                        }
                    }
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.toggleDnd()
                }
            }
        }

        // Expandable Wi-Fi Networks List
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: wifiColLayout.implicitHeight + (Theme.spacingSm * 2)
            color: Theme.surfaceBase
            radius: Theme.radiusMicro
            border.color: Theme.borderFocused
            border.width: 1
            visible: root.wifiListExpanded

            ColumnLayout {
                id: wifiColLayout
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: Theme.spacingSm
                }
                spacing: Theme.spacingSm

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰤨"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontSmall
                        color: Theme.accent
                    }

                    Text {
                        text: "REDES WI-FI CONOCIDAS"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        color: Theme.textSecondary
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "↻"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMedium
                        font.bold: true
                        color: wifiRefreshMouse.containsMouse ? Theme.accentBright : Theme.textMuted

                        MouseArea {
                            id: wifiRefreshMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.getWifiProc.running = true
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(contentHeight, 140)
                    clip: true
                    model: root.wifiList
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        width: parent ? parent.width : 0
                        implicitHeight: 28
                        radius: Theme.radiusMicro
                        color: modelData.active ? Theme.surfaceElevated : (itemMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLowest)
                        border.color: modelData.active ? Theme.borderFocused : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 6
                            }
                            spacing: 8

                            Text {
                                text: modelData.active ? "󰄬" : "󰤨"
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontMicro
                                color: modelData.active ? Theme.stateRunning : Theme.textMuted
                            }

                            Text {
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: modelData.active ? Font.DemiBold : Font.Medium
                                color: modelData.active ? Theme.textPrimary : Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.active ? "Conectado" : "Conectar"
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontMicro
                                font.bold: modelData.active
                                color: modelData.active ? Theme.stateRunning : (itemMouse.containsMouse ? Theme.accentBright : Theme.textMuted)
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (!modelData.active) {
                                    root.connectWifi(modelData.name);
                                }
                            }
                        }
                    }
                }
            }
        }

        // VPN & WireGuard Section
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: vpnColLayout.implicitHeight + (Theme.spacingSm * 2)
            color: Theme.surfaceBase
            radius: Theme.radiusMicro
            border.color: Theme.borderSubtle
            border.width: 1

            ColumnLayout {
                id: vpnColLayout
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: Theme.spacingSm
                }
                spacing: Theme.spacingSm

                // Section Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰖂"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMedium
                        color: Theme.accent
                    }

                    Text {
                        text: "VPN & WIREGUARD"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        color: Theme.textSecondary
                        Layout.fillWidth: true
                    }

                    // Active count badge
                    Rectangle {
                        implicitHeight: 18
                        implicitWidth: vpnCountText.implicitWidth + 8
                        radius: Theme.radiusMicro
                        color: root.activeVpnCount > 0 ? Theme.stateRunningBg : Theme.surfaceHigh
                        border.color: root.activeVpnCount > 0 ? Theme.stateRunning : Theme.borderSubtle
                        border.width: 1

                        Text {
                            id: vpnCountText
                            anchors.centerIn: parent
                            text: root.activeVpnCount + " Activa" + (root.activeVpnCount !== 1 ? "s" : "")
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            font.bold: true
                            color: root.activeVpnCount > 0 ? Theme.stateRunning : Theme.textMuted
                        }
                    }
                }

                // List of VPN tunnels
                ListView {
                    Layout.fillWidth: true
                    implicitHeight: Math.min(contentHeight, 180)
                    clip: true
                    model: root.vpnList
                    spacing: 4

                    delegate: Rectangle {
                        required property var modelData
                        width: parent ? parent.width : 0
                        implicitHeight: 32
                        radius: Theme.radiusMicro
                        color: modelData.active ? Theme.surfaceElevated : (delegateMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceLowest)
                        border.color: modelData.active ? Theme.borderFocused : (delegateMouse.containsMouse ? Theme.borderSubtle : "transparent")
                        border.width: 1

                        RowLayout {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 8
                            }
                            spacing: 8

                            // Status Indicator dot
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: modelData.active ? Theme.stateRunning : Theme.textMuted
                            }

                            // VPN Name
                            Text {
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: modelData.active ? Font.DemiBold : Font.Medium
                                color: modelData.active ? Theme.textPrimary : Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Protocol Badge (WireGuard / VPN)
                            Rectangle {
                                implicitHeight: 16
                                implicitWidth: protoText.implicitWidth + 6
                                radius: 3
                                color: Theme.surfaceBase
                                border.color: Theme.borderSubtle
                                border.width: 1

                                Text {
                                    id: protoText
                                    anchors.centerIn: parent
                                    text: modelData.type
                                    font.family: Theme.monoFamily
                                    font.pixelSize: Theme.fontMicro
                                    color: Theme.textMuted
                                }
                            }

                            // Toggle Switch / Pill
                            Rectangle {
                                implicitWidth: 62
                                implicitHeight: 22
                                radius: Theme.radiusMicro
                                color: modelData.active ? Theme.accent : (delegateMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase)
                                border.color: modelData.active ? Theme.accentBright : Theme.borderSubtle
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.active ? "󰄬 Activa" : "Conectar"
                                    font.family: Theme.monoFamily
                                    font.pixelSize: Theme.fontMicro
                                    font.bold: modelData.active
                                    color: modelData.active ? Theme.oledBlack : (delegateMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                                }
                            }
                        }

                        MouseArea {
                            id: delegateMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                root.toggleVpnConnection(modelData.name, modelData.active);
                            }
                        }
                    }
                }
            }
        }

        // Precision Sliders Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: slidersCol.implicitHeight + (Theme.spacingSm * 2)
            color: Theme.surfaceBase
            radius: Theme.radiusMicro
            border.color: Theme.borderSubtle
            border.width: 1

            ColumnLayout {
                id: slidersCol
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: Theme.spacingSm
                }
                spacing: Theme.spacingMd

                // Volume Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    Text {
                        text: root.volumeLevel === 0 ? "󰝟" : (root.volumeLevel < 50 ? "󰕿" : "󰕾")
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMedium
                        color: Theme.accent
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        id: volSliderTrack
                        Layout.fillWidth: true
                        implicitHeight: 24

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            height: 6
                            radius: 3
                            color: Theme.surfaceElevated

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: parent.width * (root.volumeLevel / 100)
                                radius: 3
                                color: Theme.accent
                            }
                        }

                        // Thumb
                        Rectangle {
                            x: Math.max(0, Math.min(parent.width - width, (parent.width * (root.volumeLevel / 100)) - (width / 2)))
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.textPrimary
                            border.color: Theme.accent
                            border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            function updateFromPos(mouseX) {
                                var pct = (mouseX / width) * 100;
                                root.setVolume(pct);
                            }

                            onPressed: mouse => updateFromPos(mouse.x)
                            onPositionChanged: mouse => {
                                if (pressed) updateFromPos(mouse.x);
                            }
                        }
                    }

                    Text {
                        text: root.volumeLevel + "%"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Brightness Slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    Text {
                        text: "󰃠"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMedium
                        color: Theme.accentBright
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        id: brightSliderTrack
                        Layout.fillWidth: true
                        implicitHeight: 24

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            height: 6
                            radius: 3
                            color: Theme.surfaceElevated

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: parent.width * (root.brightnessLevel / 100)
                                radius: 3
                                color: Theme.accentBright
                            }
                        }

                        // Thumb
                        Rectangle {
                            x: Math.max(0, Math.min(parent.width - width, (parent.width * (root.brightnessLevel / 100)) - (width / 2)))
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.textPrimary
                            border.color: Theme.accentBright
                            border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            function updateFromPos(mouseX) {
                                var pct = (mouseX / width) * 100;
                                root.setBrightness(pct);
                            }

                            onPressed: mouse => updateFromPos(mouse.x)
                            onPositionChanged: mouse => {
                                if (pressed) updateFromPos(mouse.x);
                            }
                        }
                    }

                    Text {
                        text: root.brightnessLevel + "%"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        // Session Power Buttons Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            // Lock (hyprlock)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radiusMicro
                color: lockMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase
                border.color: lockMouse.containsMouse ? Theme.borderFocused : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰌾"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMedium
                        color: lockMouse.containsMouse ? Theme.accent : Theme.textSecondary
                    }
                    Text {
                        text: "Lock"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.Medium
                        color: lockMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.runCmd(["hyprlock"])
                }
            }

            // Suspend (systemctl suspend)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radiusMicro
                color: suspMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase
                border.color: suspMouse.containsMouse ? Theme.borderFocused : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰤄"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMedium
                        color: suspMouse.containsMouse ? Theme.accent : Theme.textSecondary
                    }
                    Text {
                        text: "Sleep"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.Medium
                        color: suspMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: suspMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.runCmd(["systemctl", "suspend"])
                }
            }

            // Reboot (systemctl reboot)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radiusMicro
                color: rebootMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase
                border.color: rebootMouse.containsMouse ? Theme.borderFocused : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰜉"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMedium
                        color: rebootMouse.containsMouse ? Theme.stateBlocked : Theme.textSecondary
                    }
                    Text {
                        text: "Reboot"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.Medium
                        color: rebootMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.runCmd(["systemctl", "reboot"])
                }
            }

            // Power Off (systemctl poweroff)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radiusMicro
                color: pwrMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase
                border.color: pwrMouse.containsMouse ? Theme.stateCritical : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰐥"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontMedium
                        color: pwrMouse.containsMouse ? Theme.stateCritical : Theme.textSecondary
                    }
                    Text {
                        text: "Power"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.Medium
                        color: pwrMouse.containsMouse ? Theme.stateCritical : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: pwrMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.runCmd(["systemctl", "poweroff"])
                }
            }
        }
    }
}
}
