# Route OpenCode's network traffic through the local Cloudflare WARP MASQUE
# proxy (WARP proxy mode). This only affects processes launched by this
# function; the rest of the shell/session is untouched.
function opencode --description 'Run OpenCode through the WARP MASQUE proxy'
    set -lx HTTP_PROXY http://127.0.0.1:40000
    set -lx HTTPS_PROXY http://127.0.0.1:40000
    set -lx ALL_PROXY http://127.0.0.1:40000
    set -lx http_proxy http://127.0.0.1:40000
    set -lx https_proxy http://127.0.0.1:40000
    set -lx all_proxy http://127.0.0.1:40000
    set -lx NO_PROXY localhost,127.0.0.1,::1
    set -lx no_proxy localhost,127.0.0.1,::1

    /home/zy/.opencode/bin/opencode $argv
end
