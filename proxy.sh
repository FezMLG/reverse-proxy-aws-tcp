LOCAL_PORT=25565
OUTBOUND_PORT=$(jq -r .OUTBOUND_PORT config.json)
PUBLIC_DNS=$(jq -r .EC2_PUBLIC resources.json)

case "$1" in
    "--show")
    echo ssh -i key.pem -R $OUTBOUND_PORT:localhost:$LOCAL_PORT ec2-user@$PUBLIC_DNS
    ;;
    "--connect")
    ssh -i key.pem -R $OUTBOUND_PORT:localhost:$LOCAL_PORT ec2-user@$PUBLIC_DNS
    ;;
    *)
    echo "Valid options: --show / --connect"
    exit 1
    ;;
esac