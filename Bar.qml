import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "."
import "./modules"

PanelWindow {
    id: barWindow
    required property var modelData
    screen: modelData

    readonly property string thisScreenName: (modelData && modelData.name) ? modelData.name : (screen ? screen.name : "")
    readonly property bool sidebarOpenHere: SidebarState.sidebarOpen && (SidebarState.activeScreen === "" || SidebarState.activeScreen === thisScreenName)

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Auto
    WlrLayershell.namespace: "cestila-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Continuous background: Theme.surfaceLow with a 1px bottom border Theme.borderMuted.
    // When the sidebar is open on this screen, the bottom border stops before the sidebar
    // so the bar and drawer merge seamlessly as one single piece.
    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceLow

        Rectangle {
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            width: barWindow.sidebarOpenHere ? (parent.width - Theme.sidebarWidth) : parent.width
            height: 1
            color: Theme.borderMuted
        }
    }

    Item {
        id: barContainer
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }

        // Left row
        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            DistroLogo {}

            Workspaces {
                screenName: (barWindow.modelData && barWindow.modelData.name) ? barWindow.modelData.name : (barWindow.screen ? barWindow.screen.name : "")
            }

            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderMuted
                Layout.alignment: Qt.AlignVCenter
            }

            WindowTitle {}
        }

        // Center row
        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Clock {}
        }

        // Right row
        RowLayout {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 6

            HardwareStats {}

            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderMuted
                Layout.alignment: Qt.AlignVCenter
            }

            Network {}

            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderMuted
                Layout.alignment: Qt.AlignVCenter
            }

            HerdrBadge {}

            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderMuted
                Layout.alignment: Qt.AlignVCenter
            }

            AudioVolume {}

            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderMuted
                Layout.alignment: Qt.AlignVCenter
            }

            Battery {}

            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderMuted
                Layout.alignment: Qt.AlignVCenter
            }

            SysTray {}

            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderMuted
                Layout.alignment: Qt.AlignVCenter
            }

            PowerMenu {}
        }
    }
}
