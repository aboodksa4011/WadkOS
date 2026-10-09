if [ -n "${BASH_VERSION:-}" ]; then
    [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
fi

if [ "$(tty 2>/dev/null)" = /dev/tty1 ] && [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ]; then
    exec /usr/local/bin/wadk-session
fi
