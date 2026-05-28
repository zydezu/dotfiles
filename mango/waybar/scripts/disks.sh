#!/bin/bash

disks=$(df -x tmpfs -x devtmpfs -x squashfs -x efivarfs -x overlay \
  --output=source,used,size,pcent,target \
  | awk 'NR>1 && /^\/dev\// && $3 > 2097152 && $5 !~ /^\/(boot|efi)/ && !seen[$1]++ {
    gsub(/%/,"",$4)
    printf "%s{\"dev\":\"%s\",\"used\":%s,\"total\":%s,\"pct\":%s,\"mount\":\"%s\"}", \
    (count++>0?",":""), $1,$2,$3,$4,$5
  }')

tooltip=""
while IFS= read -r entry; do
  dev=$(jq -r '.dev'   <<< "$entry")
  used=$(jq -r '.used / 1024 / 1024 | floor' <<< "$entry")
  total=$(jq -r '.total / 1024 / 1024 | floor' <<< "$entry")
  pct=$(jq -r '.pct'   <<< "$entry")
  mount=$(jq -r '.mount' <<< "$entry")

  label=$(lsblk -no LABEL "$dev" 2>/dev/null)
  [ -z "$label" ] && label="$mount"

  tooltip+="${label}  ${used}G / ${total}G  (${pct}%)\n"
done < <(jq -c '.[]' <<< "[${disks}]")

main=$(jq -r '[.[] | .pct] | max' <<< "[${disks}]")
printf '{"text":"󰋊 %s%%","tooltip":"%s"}' "$main" "${tooltip%\\n}"
