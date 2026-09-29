import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: calWindow

    property var modelData: null
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: CalendarState.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    visible: CalendarState.visible

    // State for viewing month/year
    property var today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth() // 0-11

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear--;
        } else {
            viewMonth--;
        }
        rebuildDays();
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear++;
        } else {
            viewMonth++;
        }
        rebuildDays();
    }

    function resetToToday() {
        today = new Date();
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
        rebuildDays();
    }

    onVisibleChanged: {
        if (visible) {
            resetToToday();
        }
    }

    // Days model: array of 42 objects { day: number, isCurrentMonth: bool, isToday: bool }
    property var daysModel: []

    function rebuildDays() {
        var days = [];
        var firstDayIndex = new Date(viewYear, viewMonth, 1).getDay(); // 0 is Sunday
        var daysInCurrentMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        var daysInPrevMonth = new Date(viewYear, viewMonth, 0).getDate();

        var todayYear = today.getFullYear();
        var todayMonth = today.getMonth();
        var todayDate = today.getDate();

        // Previous month filler days
        for (var i = firstDayIndex - 1; i >= 0; i--) {
            days.push({
                day: daysInPrevMonth - i,
                isCurrentMonth: false,
                isToday: false
            });
        }

        // Current month days
        for (var d = 1; d <= daysInCurrentMonth; d++) {
            var isCurrentToday = (viewYear === todayYear && viewMonth === todayMonth && d === todayDate);
            days.push({
                day: d,
                isCurrentMonth: true,
                isToday: isCurrentToday
            });
        }

        // Next month filler days up to 42 cells (6 rows * 7)
        var remaining = 42 - days.length;
        for (var n = 1; n <= remaining; n++) {
            days.push({
                day: n,
                isCurrentMonth: false,
                isToday: false
            });
        }

        daysModel = days;
    }

    Component.onCompleted: {
        rebuildDays();
    }

    // Scrim clickaway to close
    MouseArea {
        anchors.fill: parent
        onClicked: CalendarState.close()
    }

    // Centered dropdown below the top bar
    Rectangle {
        id: calCard
        anchors {
            top: parent.top
            topMargin: Theme.barHeight + 6
            horizontalCenter: parent.horizontalCenter
        }
        width: 320
        height: contentCol.implicitHeight + 24
        radius: Theme.radiusCard
        color: Theme.surfaceLowest
        border.color: Theme.accent
        border.width: 1

        // Scrim interceptor on card
        MouseArea {
            anchors.fill: parent
            onClicked: {} // consume click
        }

        ColumnLayout {
            id: contentCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            spacing: 12

            // Header: Month, Year and Navigation controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    id: headerTitle
                    text: {
                        var months = [
                            "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
                        ];
                        return months[calWindow.viewMonth] + " " + calWindow.viewYear;
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMedium
                    font.bold: true
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                }

                // Reset to today button
                Rectangle {
                    implicitWidth: 42
                    implicitHeight: 24
                    radius: Theme.radiusMicro
                    color: todayMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase
                    border.color: todayMouse.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Hoy"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMicro
                        font.weight: Font.Medium
                        color: todayMouse.containsMouse ? Theme.accentBright : Theme.textSecondary
                    }

                    MouseArea {
                        id: todayMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: calWindow.resetToToday()
                    }
                }

                // Prev month button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 24
                    radius: Theme.radiusMicro
                    color: prevMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase
                    border.color: prevMouse.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontLarge
                        font.bold: true
                        color: prevMouse.containsMouse ? Theme.accentBright : Theme.textSecondary
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: calWindow.prevMonth()
                    }
                }

                // Next month button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 24
                    radius: Theme.radiusMicro
                    color: nextMouse.containsMouse ? Theme.surfaceHigh : Theme.surfaceBase
                    border.color: nextMouse.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontLarge
                        font.bold: true
                        color: nextMouse.containsMouse ? Theme.accentBright : Theme.textSecondary
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: calWindow.nextMonth()
                    }
                }
            }

            // Weekday labels
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sá"]
                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: 20

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontMicro
                            font.bold: true
                            color: modelData === "Do" || modelData === "Sá" ? Theme.accent : Theme.textSecondary
                        }
                    }
                }
            }

            // 7x6 Days Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: calWindow.daysModel
                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: 30

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: modelData.isToday ? Theme.radiusMicro : 4
                            color: {
                                if (modelData.isToday) return Theme.accent;
                                if (dayMouse.containsMouse && modelData.isCurrentMonth) return Theme.surfaceHigh;
                                return "transparent";
                            }
                            border.color: {
                                if (modelData.isToday) return Theme.accentBright;
                                if (dayMouse.containsMouse && modelData.isCurrentMonth) return Theme.borderFocused;
                                return "transparent";
                            }
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day.toString()
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontSmall
                                font.bold: modelData.isToday
                                color: {
                                    if (modelData.isToday) return Theme.oledBlack;
                                    if (!modelData.isCurrentMonth) return Theme.textMuted;
                                    return Theme.textPrimary;
                                }
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: modelData.isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                }
            }

            // Footer: Detailed date & live clock
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderSubtle
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰃭"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.accent
                }

                Text {
                    text: {
                        var d = calWindow.today;
                        var days = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];
                        var months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
                        return days[d.getDay()] + ", " + d.getDate() + " de " + months[d.getMonth()] + " " + d.getFullYear();
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMicro
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                }
            }
        }
    }
}
