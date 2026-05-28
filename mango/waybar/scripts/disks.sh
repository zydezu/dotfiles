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
  used_raw=$(jq -r '.used'  <<< "$entry")
  total_raw=$(jq -r '.total' <<< "$entry")
  pct=$(jq -r '.pct'   <<< "$entry")
  mount=$(jq -r '.mount' <<< "$entry")

  used_h=$(numfmt --to=iec --from-unit=1024 "$used_raw")
  total_h=$(numfmt --to=iec --from-unit=1024 "$total_raw")

  label=$(lsblk -no LABEL "$dev" 2>/dev/null)
  [ -z "$label" ] && label="$mount"
  [ "$mount" = "/" ] && label="$(hostname)"

  tooltip+="${label}  ${used_h} / ${total_h}  (${pct}%)\n"
done < <(jq -c '.[]' <<< "[${disks}]")

main=$(jq -r '[.[] | .pct] | max' <<< "[${disks}]")
printf '{"text":"󰋊 %s%%","tooltip":"%s"}' "$main" "${tooltip%\\n}"
