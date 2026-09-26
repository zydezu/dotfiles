#!/bin/bash

sleep 2

# nxapi-app doesn't always start, so give up instead of polling all session
SECONDS=0
while ! mmsg get all-clients | jq -e '.clients[] | select(.appid=="nxapi-app")' > /dev/null 2>&1; do
    (( SECONDS >= 30 )) && exit 0
    sleep 0.1
done
CLIENT_ID=$(mmsg get all-clients | jq -r '.clients[] | select(.appid=="nxapi-app") | .id')
mmsg dispatch killclient client,$CLIENT_ID
