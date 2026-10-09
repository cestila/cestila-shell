import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "."
import "./modules/sidebar"

PanelWindow {
    id: sidebarWindow
    required property var modelData
    screen: modelData

    readonly property string thisScreenName: (modelData && modelData.name) ? modelData.name : (screen ? screen.name : "")
    readonly property bool isTargetScreen: SidebarState.activeScreen !== "" ? (SidebarState.activeScreen === thisScreenName) : true
    readonly property bool shouldBeOpen: SidebarState.sidebarOpen && isTargetScreen

    anchors {
        top: true
        bottom: true
        right: true
    }

    // No margins.top — the bar's auto-exclusion zone already docks the panel directly under the bar.
    // implicitWidth drives the exclusive zone: when open on THIS monitor it reserves 380px, shrinking tiled windows.
    implicitWidth: shouldBeOpen ? Theme.sidebarWidth : 0
    color: "transparent"
    exclusionMode: ExclusionMode.Auto
    WlrLayershell.namespace: "cestila-sidebar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Remain visible on the target monitor during slide-out animation, then unmap cleanly.
    // Instances on other monitors stay invisible and reserve 0px.
    visible: isTargetScreen && (SidebarState.sidebarOpen || slideAnim.running)

    Rectangle {
        id: drawer
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        width: Theme.sidebarWidth
        x: sidebarWindow.shouldBeOpen ? 0 : width
        color: Theme.surfaceLow

        Behavior on x {
            NumberAnimation {
                id: slideAnim
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        // 1px left border in Theme.borderMuted
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            width: 1
            color: Theme.borderMuted
        }

        // Header: Drawer title with minimal close button [✕]
        Rectangle {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 48
            color: Theme.surfaceLow

            // 1px bottom border
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
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
                spacing: Theme.spacingSm

                Text {
                    text: "󱄅"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontMedium
                    color: Theme.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "SYSTEM DRAWER"
                    font.family: Theme.monoFamily
                    font.pixelSize: Theme.fontBase
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: Theme.textPrimary
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Close button [✕]
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: Theme.radiusMicro
                    color: closeMouse.containsMouse ? Theme.surfaceHigh : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.borderFocused : "transparent"
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Theme.monoFamily
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.Bold
                        color: closeMouse.containsMouse ? Theme.stateCritical : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: SidebarState.close()
                    }
                }
            }
        }

        // Content in Flickable scroll area
        Flickable {
            id: flickable
            anchors {
                top: header.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            contentWidth: width
            contentHeight: contentCol.implicitHeight + (Theme.spacingLg * 2)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Theme.spacingLg
                }
                spacing: Theme.spacingLg

                // Herdr Agent Monitor
                HerdrMonitor {
                    Layout.fillWidth: true
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.borderMuted
                }

                // Notification Center
                NotificationCenter {
                    Layout.fillWidth: true
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.borderMuted
                }

                // Quick Settings
                QuickSettings {
                    Layout.fillWidth: true
                }

                Item {
                    implicitHeight: Theme.spacingLg
                }
            }
        }

        // Sleek scrollbar indicator
        Rectangle {
            id: scrollBar
            anchors {
                right: flickable.right
                rightMargin: 2
            }
            y: flickable.topMargin + (flickable.visibleArea.yPosition * flickable.height)
            height: Math.max(16, flickable.visibleArea.heightRatio * flickable.height)
            width: 3
            radius: 1.5
            color: Theme.accentDim
            opacity: flickable.moving || flickable.flicking ? 0.8 : 0.2
            visible: flickable.visibleArea.heightRatio < 1.0

            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast }
            }
        }
    }
}
