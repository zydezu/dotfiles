#!/usr/bin/env python3
"""Make Waybar's wlr/taskbar resolve the right desktop entry (and icon).

This only touches files that are missing or out of date. Run after
installing games or adding Steam shortcuts.
"""

import configparser
import glob
import os
import re
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
APPS_DIR = os.path.join(HOME, ".local/share/applications")
ICONS_DIR = os.path.join(HOME, ".local/share/icons/hicolor")
STEAM_CACHE = os.path.join(HOME, ".local/share/Steam/appcache/librarycache")
ICON_SIZES = [16, 24, 32, 48, 64, 96, 128, 160, 192, 256]
ALIAS_MARKER = "X-Waybar-AppId-Alias"

DATA_DIRS = [os.path.join(HOME, ".local/share/applications"), "/usr/local/share/applications",
             "/usr/share/applications"]
for p in filter(None, os.environ.get("XDG_DATA_DIRS", "").split(":")):
    d = os.path.join(p, "applications")
    if d not in DATA_DIRS:
        DATA_DIRS.append(d)


def read_entry(path):
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    try:
        with open(path, encoding="utf-8") as f:
            cp.read_file(f)
    except Exception:
        return None
    if not cp.has_section("Desktop Entry"):
        return None
    d = cp["Desktop Entry"]
    with open(path, encoding="utf-8") as f:
        wmclasses = [line.split("=", 1)[1].strip().rstrip(";") for line in f
                     if line.startswith("StartupWMClass=")]
    return {
        "name": d.get("Name", ""),
        "icon": d.get("Icon", ""),
        "exec": d.get("Exec", ""),
        "comment": d.get("Comment", ""),
        "categories": d.get("Categories", ""),
        "terminal": d.get("Terminal", "false"),
        "wmclass": wmclasses,
        "alias": d.get(ALIAS_MARKER, ""),
    }


def write_alias(app_id, src):
    dest = os.path.join(APPS_DIR, app_id + ".desktop")
    content = (
        "[Desktop Entry]\n"
        "Type=Application\n"
        f"Name={src['name'] or app_id}\n"
        + (f"Comment={src['comment']}\n" if src["comment"] else "")
        + f"Exec={src['exec'] or app_id}\n"
        f"Icon={src['icon']}\n"
        + (f"Categories={src['categories']}\n" if src["categories"] else "")
        + f"Terminal={src['terminal']}\n"
        f"StartupWMClass={src['wmclass'][0] if src['wmclass'] else app_id}\n"
        + "NoDisplay=true\n"
        f"{ALIAS_MARKER}=true\n"
    )
    if os.path.exists(dest):
        with open(dest, encoding="utf-8") as f:
            if f.read() == content:
                return False
    with open(dest, "w", encoding="utf-8") as f:
        f.write(content)
    return True


def app_id_taken(app_id):
    for d in DATA_DIRS:
        path = os.path.join(d, app_id + ".desktop")
        if not os.path.exists(path):
            continue
        if d == APPS_DIR:
            existing = read_entry(path)
            if existing and existing["alias"]:
                continue  # ours, may be rewritten
        return True
    return False


def steam_icon_source(app_id):
    for size in reversed(ICON_SIZES):
        p = os.path.join(ICONS_DIR, f"{size}x{size}/apps", f"steam_icon_{app_id}.png")
        if os.path.exists(p):
            return p
    cache = os.path.join(STEAM_CACHE, app_id)
    if os.path.isdir(cache):
        for f in glob.glob(os.path.join(cache, "*.jpg")):
            try:
                wh = subprocess.run(["identify", "-format", "%wx%h", f], capture_output=True,
                                    text=True, check=True).stdout
            except Exception:
                continue
            if wh in ("32x32", "64x64", "128x128", "256x256"):
                return f
    return None


def ensure_steam_icon(app_id):
    have = {s for s in ICON_SIZES if os.path.exists(
        os.path.join(ICONS_DIR, f"{s}x{s}/apps", f"steam_icon_{app_id}.png"))}
    if have >= set(ICON_SIZES):
        return 0
    src = steam_icon_source(app_id)
    if not src:
        return 0
    if not shutil.which("magick"):
        return 0
    written = 0
    for size in ICON_SIZES:
        if size in have:
            continue
        out_dir = os.path.join(ICONS_DIR, f"{size}x{size}/apps")
        os.makedirs(out_dir, exist_ok=True)
        subprocess.run(["magick", src, "-resize", f"{size}x{size}", "-background", "none",
                        "-gravity", "center", "-extent", f"{size}x{size}",
                        os.path.join(out_dir, f"steam_icon_{app_id}.png")], check=True)
        written += 1
    return written


def main():
    os.makedirs(APPS_DIR, exist_ok=True)
    aliases = 0
    icons = 0
    seen = {}

    for path in sorted(glob.glob(os.path.join(APPS_DIR, "*.desktop"))):
        src = read_entry(path)
        if not src or src["alias"] or not src["icon"]:
            continue
        base = os.path.basename(path)[:-len(".desktop")]

        ids = list(src["wmclass"])
        m = re.search(r"rungameid/(\d+)", src["exec"])
        if m:
            app_id = f"steam_app_{m.group(1)}"
            ids.append(app_id)
            icons += ensure_steam_icon(m.group(1))

        for app_id in ids:
            if app_id == base or "/" in app_id or app_id.startswith("."):
                continue
            if app_id_taken(app_id) or app_id in seen:
                continue
            seen[app_id] = path
            if write_alias(app_id, src):
                aliases += 1

    if icons:
        subprocess.run(["gtk-update-icon-cache", "-f", "-t", ICONS_DIR],
                       capture_output=True)
    print(f"aliases written: {aliases}, icons written: {icons}")


if __name__ == "__main__":
    sys.exit(main())
