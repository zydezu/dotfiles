#!/bin/bash

cmd="$*"
cmd_name=$(echo "$cmd" | awk '{print $1}')

if command -v "$cmd_name" >/dev/null 2>&1; then
    $cmd &
else
    if [[ "$cmd" =~ ^[a-zA-Z0-9.-]+\.[a-z]{2,}(/.*)?$ ]]; then
        if [[ "$cmd" =~ ^https?:// ]]; then
            firefox "$cmd"
        else
            firefox "http://$cmd"
        fi
    else
        search_query=$(printf '%s' "$cmd" | sed 's/ /+/g')
        firefox "https://www.google.com/search?q=$search_query"
    fi
fi
