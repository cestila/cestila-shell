pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool paletteOpen: false
    property string activeCategory: "All"
    property string searchQuery: ""

    readonly property var categories: ["All", "Apps", "Projects", "Herdr", "VPN", "Clipboard"]

    function toggle() {
        paletteOpen = !paletteOpen;
        if (!paletteOpen) searchQuery = "";
    }
    function open() {
        paletteOpen = true;
    }
    function close() {
        paletteOpen = false;
        searchQuery = "";
    }
    function cycleCategory() {
        var idx = categories.indexOf(activeCategory);
        activeCategory = categories[(idx + 1) % categories.length];
    }
}
