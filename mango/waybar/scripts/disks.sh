#!/bin/bash

main=$(df -h / | awk 'NR==2 {print $5}')

tooltip=$(df -h --output=target,used,size,pcent -x tmpfs -x devtmpfs -x efivarfs \
  | tail -n +2 \
  | awk '{printf "%s  %s / %s  (%s)\n", $1, $2, $3, $4}' \
  | sed 's/&/&amp;/g')

echo "{\"text\": \"󰋊 $main\", \"tooltip\": \"$tooltip\"}"
