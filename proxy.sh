#!/usr/bin/env bash

LOCAL_PORT_MC=25565
LOCAL_PORT_PLEX=32400
OUTBOUND_PORT_MC=$(jq -r .OUTBOUND_PORT_MC config.json)
OUTBOUND_PORT_PLEX=$(jq -r .OUTBOUND_PORT_PLEX config.json)
PUBLIC_DNS=$(jq -r .EC2_PUBLIC resources.json)

case "$1" in
    "--show")
    echo ssh -i key.pem -R $OUTBOUND_PORT_MC:localhost:$LOCAL_PORT_MC -R $OUTBOUND_PORT_PLEX:localhost:$LOCAL_PORT_PLEX -o ServerAliveInterval=60 -o ServerAliveCountMax=5 ec2-user@$PUBLIC_DNS
    ;;
    "--connect")
    ssh -i key.pem -R $OUTBOUND_PORT_MC:localhost:$LOCAL_PORT -o ServerAliveInterval=60 -o ServerAliveCountMax=5 ec2-user@$PUBLIC_DNS
    ;;
    *)
    echo "Valid options: --show / --connect"
    exit 1
    ;;
esac