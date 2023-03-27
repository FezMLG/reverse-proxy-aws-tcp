#!/usr/bin/env bash

PUBLIC_DNS=$(jq -r .EC2_PUBLIC resources.json)

case "$1" in
    "--show")
    echo "ssh -i key.pem"
    jq -c '.PORTS[]' config.json | while read item; do
        in_port=$(jq --raw-output '.in' <<< "$item")
        out_port=$(jq --raw-output '.out' <<< "$item")
        local_port=$(jq --raw-output '.local' <<< "$item")
        echo " -R $out_port:localhost:$local_port"
    done
    echo " -o ServerAliveInterval=60 -o ServerAliveCountMax=5 ec2-user@$PUBLIC_DNS"
    ;;
    *)
    echo "Valid options: --show"
    exit 1
    ;;
esac