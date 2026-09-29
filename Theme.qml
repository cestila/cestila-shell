pragma Singleton
import QtQuick

QtObject {
    id: root

    // Backgrounds & Surfaces
    readonly property color oledBlack: "#000000"
    readonly property color bg: "#000000"
    readonly property color surfaceLowest: "#050508"
    readonly property color surfaceLow: "#0d0d12"
    readonly property color surfaceBase: "#14141d"
    readonly property color surfaceHigh: "#1c1c27"
    readonly property color surfaceElevated: "#232332"

    // Borders & Lines
    readonly property color borderSubtle: "#1a1a24"
    readonly property color borderMuted: "#1c1c27"
    readonly property color borderFocused: "#a855f7"
    readonly property real borderWidth: 1.0

    // Electric Violet Signature Accent
    readonly property color accent: "#a855f7"
    readonly property color accentBright: "#c084fc"
    readonly property color accentDim: "#581c87"
    readonly property color accentFaint: "#2a1442"

    // Semantic & Herdr Agent States
    readonly property color stateRunning: "#10b981"
    readonly property color stateRunningBg: "#064e3b"
    readonly property color stateBlocked: "#f59e0b"
    readonly property color stateBlockedBg: "#78350f"
    readonly property color stateCritical: "#ef4444"
    readonly property color stateCriticalBg: "#7f1d1d"
    readonly property color stateIdle: "#38bdf8"
    readonly property color stateIdleBg: "#0c4a6e"

    // Typography Colors
    readonly property color textPrimary: "#f8fafc"
    readonly property color textSecondary: "#94a3b8"
    readonly property color textMuted: "#475569"

    // Geometries
    readonly property int barHeight: 30
    readonly property int sidebarWidth: 380
    readonly property int paletteWidth: 640
    readonly property int paletteHeight: 480

    readonly property int radiusMicro: 4
    readonly property int radiusCard: 6
    readonly property int radiusPill: 9999

    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24

    // Typography
    readonly property string fontFamily: "Inter, sans-serif"
    readonly property string monoFamily: "JetBrainsMono Nerd Font, IosevkaTerm Nerd Font, monospace"

    readonly property int fontMicro: 10
    readonly property int fontSmall: 11
    readonly property int fontBase: 13
    readonly property int fontMedium: 14
    readonly property int fontLarge: 16
    readonly property int fontTitle: 20

    // Animation Timings (ms)
    readonly property int animFast: 120
    readonly property int animNormal: 180
    readonly property int animSlow: 260
}
