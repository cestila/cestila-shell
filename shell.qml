//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import Quickshell.Io
import "."

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Bar {}
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Sidebar {}
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            CommandPalette {}
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            CalendarPopup {}
        }
    }

    IpcHandler {
        target: "calendar"

        function toggle() {
            CalendarState.toggle();
        }

        function open() {
            CalendarState.open();
        }

        function close() {
            CalendarState.close();
        }
    }

    IpcHandler {
        target: "sidebar"

        function toggle() {
            SidebarState.toggle();
        }

        function open() {
            SidebarState.open();
        }

        function close() {
            SidebarState.close();
        }
    }

    IpcHandler {
        target: "palette"

        function toggle() {
            PaletteState.toggle();
        }

        function open() {
            PaletteState.open();
        }

        function close() {
            PaletteState.close();
        }
    }
}
