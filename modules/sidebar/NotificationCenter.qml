pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.."

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight

    Process {
        id: clearSwayNcProc
        command: ["swaync-client", "-C"]
    }

    function clearAll() {
        notiModel.clear();
        clearSwayNcProc.running = true;
    }

    ListModel {
        id: notiModel

        ListElement {
            notiId: "n1"
            iconText: "󱄅"
            title: "NixOS System Rebuilt"
            body: "Generation 142 active. Kernel 6.12 loaded with cyber-minimal profile."
            timestamp: "2m ago"
        }
        ListElement {
            notiId: "n2"
            iconText: "⚡"
            title: "Herdr Agent Completed"
            body: "agent-build-01 completed task 'Compile nixos-hardware module' in 14m."
            timestamp: "12m ago"
        }
        ListElement {
            notiId: "n3"
            iconText: "󰂚"
            title: "Quickshell IPC Ready"
            body: "Control Center drawer bound to IPC target 'sidebar'."
            timestamp: "28m ago"
        }
    }

    ColumnLayout {
        id: mainCol
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: Theme.spacingMd

        // Header: "NOTIFICATIONS" + count badge + "Clear All" link
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            Text {
                text: "NOTIFICATIONS"
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Font.Bold
                font.letterSpacing: 1.0
                color: Theme.textSecondary
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                implicitHeight: 18
                implicitWidth: countText.implicitWidth + 10
                radius: Theme.radiusPill
                color: notiModel.count > 0 ? Theme.accentDim : Theme.surfaceElevated
                border.color: notiModel.count > 0 ? Theme.accent : Theme.borderSubtle
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: notiModel.count.toString()
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontMicro
                    font.weight: Font.Bold
                    color: notiModel.count > 0 ? Theme.accent : Theme.textMuted
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                id: clearAllBtn
                text: "Clear All"
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontMicro
                font.weight: Font.Medium
                color: clearMouse.containsMouse ? Theme.accentBright : Theme.textMuted
                visible: notiModel.count > 0
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.clearAll()
                }
            }
        }

        // Empty state
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            color: Theme.surfaceBase
            radius: Theme.radiusMicro
            border.color: Theme.borderSubtle
            border.width: 1
            visible: notiModel.count === 0

            RowLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingSm

                Text {
                    text: "󰂛"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontMedium
                    color: Theme.textMuted
                }

                Text {
                    text: "No unread notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textMuted
                }
            }
        }

        // Notification Items
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm
            visible: notiModel.count > 0

            Repeater {
                model: notiModel
                delegate: Rectangle {
                    id: notiDelegate
                    required property int index
                    required property string iconText
                    required property string title
                    required property string body
                    required property string timestamp

                    Layout.fillWidth: true
                    implicitHeight: itemCol.implicitHeight + (Theme.spacingSm * 2)
                    color: Theme.surfaceBase
                    radius: Theme.radiusMicro
                    border.color: Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        id: itemCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: Theme.spacingSm
                        }
                        spacing: 4

                        // Header row: Icon + Title + Timestamp + Dismiss button
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSm

                            Text {
                                text: notiDelegate.iconText
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontMedium
                                color: Theme.accent
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: notiDelegate.title
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: notiDelegate.timestamp
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontMicro
                                color: Theme.textMuted
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Dismiss button
                            Rectangle {
                                implicitWidth: 18
                                implicitHeight: 18
                                radius: Theme.radiusMicro
                                color: dismissMouse.containsMouse ? Theme.surfaceHigh : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.family: Theme.monoFamily
                                    font.pixelSize: Theme.fontMicro
                                    color: dismissMouse.containsMouse ? Theme.stateCritical : Theme.textMuted
                                }

                                MouseArea {
                                    id: dismissMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        notiModel.remove(notiDelegate.index);
                                    }
                                }
                            }
                        }

                        // Message body
                        Text {
                            text: notiDelegate.body
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            color: Theme.textSecondary
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
