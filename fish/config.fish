source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Use systemd user ssh-agent
set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket

# fnm (nodejs manager)
if command -q fnm
    fnm env --use-on-cd --shell fish | source
end

fish_add_path ~/go/bin
