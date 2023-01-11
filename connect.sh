PUBLIC_DNS=$(jq -r .EC2_PUBLIC resources.json)

case "$1" in
    "--show")
    echo ssh -i key.pem ec2-user@$PUBLIC_DNS
    ;;
    "--connect")
    ssh -i key.pem ec2-user@$PUBLIC_DNS
    ;;
    *)
    echo "Valid options: --show / --connect"
    exit 1
    ;;
esac