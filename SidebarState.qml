pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool sidebarOpen: false
    function toggle() { sidebarOpen = !sidebarOpen; }
    function open() { sidebarOpen = true; }
    function close() { sidebarOpen = false; }
}
