#!/usr/bin/env bash
# waybar status for mako: bell icon + DND state
# Outputs JSON so waybar can use format-icons: notification / none /
# dnd-notification / dnd-none
set -u

is_dnd=0
case "$(makoctl mode 2>/dev/null)" in
    *dnd*) is_dnd=1 ;;
esac

count=$(makoctl list -j 2>/dev/null | jq 'length // 0' 2>/dev/null || echo 0)
[[ $count =~ ^[0-9]+$ ]] || count=0

if (( count > 0 )); then
    icon=notification
else
    icon=none
fi

(( is_dnd )) && icon="dnd-$icon"

printf '{"text":"%s","class":"%s","tooltip":"%s notification(s)%s"}\n' \
    "$icon" "$icon" "$count" "$([[ $is_dnd == 1 ]] && echo ' - DND')"
