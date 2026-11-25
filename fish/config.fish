source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Use systemd user ssh-agent
set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket

# fnm (nodejs manager)
fnm env --use-on-cd --shell fish | source

fish_add_path ~/go/bin
fish_add_path /usr/bin/vendor_perl

# Picard's native Wayland backend hangs on Qt 6.12 + MangoDE (wl_shm buffers fail to
# allocate, so the window never paints). Force it onto XWayland instead.
function picard
    env QT_QPA_PLATFORM=xcb /usr/bin/picard $argv
end
