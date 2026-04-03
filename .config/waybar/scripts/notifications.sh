#!/usr/bin/env bash
swaync-client -swb | jq -c '. + {tooltip: "Notifications: \(.tooltip | split(" ") | .[0])"}'
