import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    property int cpuPercent: 0
    property string ramGb: "0.0G"
    property int ramPercent: 0
    property int tempC: 0

    // Stored for CPU delta calculation
    property real lastTotalTime: 0
    property real lastIdleTime: 0

    implicitHeight: 22
    implicitWidth: rowLayout.implicitWidth

    FileView {
        id: statView
        path: "/proc/stat"
        watchChanges: false
        onLoaded: {
            try {
                var firstLine = text().split("\n")[0];
                var parts = firstLine.trim().split(/\s+/).slice(1);
                if (parts.length >= 4) {
                    var user = parseFloat(parts[0]) || 0;
                    var nice = parseFloat(parts[1]) || 0;
                    var system = parseFloat(parts[2]) || 0;
                    var idle = parseFloat(parts[3]) || 0;
                    var iowait = parseFloat(parts[4]) || 0;
                    var irq = parseFloat(parts[5]) || 0;
                    var softirq = parseFloat(parts[6]) || 0;
                    var steal = parseFloat(parts[7]) || 0;

                    var total = user + nice + system + idle + iowait + irq + softirq + steal;
                    var currentIdle = idle + iowait;

                    if (root.lastTotalTime > 0) {
                        var diffTotal = total - root.lastTotalTime;
                        var diffIdle = currentIdle - root.lastIdleTime;
                        if (diffTotal > 0) {
                            var usage = Math.round(100 * (diffTotal - diffIdle) / diffTotal);
                            root.cpuPercent = Math.min(Math.max(usage, 0), 100);
                        }
                    }

                    root.lastTotalTime = total;
                    root.lastIdleTime = currentIdle;
                }
            } catch(e) {}
        }
    }

    FileView {
        id: memView
        path: "/proc/meminfo"
        watchChanges: false
        onLoaded: {
            try {
                var lines = text().split("\n");
                var totalKb = 0;
                var availKb = 0;
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.startsWith("MemTotal:")) {
                        totalKb = parseInt(line.replace(/[^0-9]/g, "")) || 0;
                    } else if (line.startsWith("MemAvailable:")) {
                        availKb = parseInt(line.replace(/[^0-9]/g, "")) || 0;
                    }
                }
                if (totalKb > 0) {
                    var usedKb = totalKb - availKb;
                    root.ramGb = (usedKb / (1024 * 1024)).toFixed(1) + "G";
                    root.ramPercent = Math.round((usedKb / totalKb) * 100);
                }
            } catch(e) {}
        }
    }

    FileView {
        id: tempView1
        path: "/sys/class/thermal/thermal_zone1/temp"
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                var raw = parseInt(text().trim()) || 0;
                if (raw > 0) {
                    root.tempC = Math.round(raw / 1000);
                }
            } catch(e) {}
        }
        onLoadFailed: {
            tempView0.reload();
        }
    }

    FileView {
        id: tempView0
        path: "/sys/class/thermal/thermal_zone0/temp"
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                var raw = parseInt(text().trim()) || 0;
                if (raw > 0) {
                    root.tempC = Math.round(raw / 1000);
                }
            } catch(e) {}
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statView.reload();
            memView.reload();
            tempView1.reload();
        }
    }

    function getMetricColor(value, warnThreshold, critThreshold) {
        if (value >= critThreshold) return Theme.stateCritical;
        if (value >= warnThreshold) return Theme.stateBlocked;
        return Theme.textPrimary;
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        // CPU Badge
        Rectangle {
            implicitHeight: 20
            implicitWidth: cpuContent.implicitWidth + 12
            radius: Theme.radiusMicro
            color: Theme.surfaceBase
            border.color: Theme.borderSubtle
            border.width: 1

            RowLayout {
                id: cpuContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: ""
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.cpuPercent + "%"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                    color: root.getMetricColor(root.cpuPercent, 70, 85)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // RAM Badge
        Rectangle {
            implicitHeight: 20
            implicitWidth: ramContent.implicitWidth + 12
            radius: Theme.radiusMicro
            color: Theme.surfaceBase
            border.color: Theme.borderSubtle
            border.width: 1

            RowLayout {
                id: ramContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰍛"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.accentBright
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.ramGb
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                    color: root.getMetricColor(root.ramPercent, 75, 90)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Temperature Badge
        Rectangle {
            implicitHeight: 20
            implicitWidth: tempContent.implicitWidth + 12
            radius: Theme.radiusMicro
            color: Theme.surfaceBase
            border.color: Theme.borderSubtle
            border.width: 1
            visible: root.tempC > 0

            RowLayout {
                id: tempContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: ""
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.tempC + "°C"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                    color: root.getMetricColor(root.tempC, 65, 80)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
