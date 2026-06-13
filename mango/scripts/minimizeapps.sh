#!/bin/bash

while ! mmsg get all-clients | jq -e '.clients[] | select(.appid=="nxapi-app")' > /dev/null 2>&1; do sleep 0.1; done
CLIENT_ID=$(mmsg get all-clients | jq -r '.clients[] | select(.appid=="nxapi-app") | .id')
mmsg dispatch killclient client,$CLIENT_ID
