# cog's native 'wl' platform crashes on Mesa >= 25 (libWPEBackend's wayland
# platform needs eglCreateWaylandBufferFromImageWL, removed with wl_drm).
# 'gtk4' renders natively on Wayland and works; use 'x11' for Xwayland.
set -gx COG_PLATFORM_NAME gtk4
