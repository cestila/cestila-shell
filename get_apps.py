#!/usr/bin/env python3
import os
import glob
import json

user = os.environ.get("USER", "cestila")
dirs = [
    "/run/current-system/sw/share/applications",
    "/etc/profiles/per-user/" + user + "/share/applications",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
    "/var/lib/flatpak/exports/share/applications",
    os.path.expanduser("~/.local/share/applications")
]

apps = []
seen = set()

for d in dirs:
    if not os.path.isdir(d):
        continue
    for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
        try:
            with open(f, "r", errors="ignore") as fp:
                lines = fp.readlines()
            name, exec_cmd, icon, nodisplay, comment = "", "", "", False, ""
            in_desktop_entry = False
            for line in lines:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_desktop_entry = True
                    continue
                elif line.startswith("[") and line.endswith("]"):
                    in_desktop_entry = False
                    continue
                if not in_desktop_entry:
                    continue

                if line.startswith("Name=") and not name:
                    name = line.split("=", 1)[1].strip()
                elif line.startswith("Exec=") and not exec_cmd:
                    exec_cmd = line.split("=", 1)[1].strip()
                elif line.startswith("Icon=") and not icon:
                    icon = line.split("=", 1)[1].strip()
                elif line.startswith("Comment=") and not comment:
                    comment = line.split("=", 1)[1].strip()
                elif line == "NoDisplay=true" or line == "Hidden=true":
                    nodisplay = True

            if nodisplay or not name or not exec_cmd:
                continue

            # Strip desktop field codes (%U, %u, %f, %F, %i, %c, %k) and flatpak markers
            tokens = [p for p in exec_cmd.split() if not (p.startswith("%") and len(p) == 2) and p not in ("@@u", "@@", "@@U")]
            exec_clean = " ".join(tokens)

            display_title = name
            if "zapzap" in name.lower():
                display_title = "WhatsApp (ZapZap)"

            key = display_title.lower()
            if key not in seen:
                seen.add(key)
                apps.append({
                    "title": display_title,
                    "subtitle": comment or exec_clean,
                    "category": "Apps",
                    "badge": "APP",
                    "shortcut": "[↵ Run]",
                    "icon": icon,
                    "exec": exec_clean,
                    "command": ["hyprctl", "dispatch", "exec", exec_clean]
                })
        except Exception:
            pass

# Sort alphabetically by title
apps.sort(key=lambda x: x["title"].lower())
print(json.dumps(apps))
