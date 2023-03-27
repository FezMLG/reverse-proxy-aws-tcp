#!/usr/bin/env bash

SG_ID=$(jq -r .SG_ID resources.json)
EC2_PUBLIC=$(jq -r .EC2_PUBLIC resources.json)

# Set delimiter
IFS=':'

for arg in "$@"
do
    #Read the split words into an array based on delimiter
    read -a strarr <<< "$arg"
    
    inport=${strarr[0]}
    outport=${strarr[1]}
    localport=${strarr[2]}
    name=${strarr[3]}

    echo "$(jq '.PORTS += [{"in":"'$inport'", "out":"'$outport'", "local":"'$localport'", "name":"'$name'"}]' config.json)" > config.json
done

for arg in "$@"
do

echo -en '\n' >> haproxy.cfg

read -a strarr <<< "$arg"

inport=${strarr[0]}
outport=${strarr[1]}
localport=${strarr[2]}
name=${strarr[3]}

cat << EOF >> haproxy.cfg
frontend frontend_$name
    bind :$inport
    default_backend backend_$name

backend backend_$name
    server server_$name localhost:$outport
EOF

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port $inport \
    --cidr 0.0.0.0/0 \
    --no-cli-pager
done

IFS=''

scp -i key.pem haproxy.cfg ec2-user@$EC2_PUBLIC:/home/ec2-user
ssh -i key.pem ec2-user@$EC2_PUBLIC 'sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.old && sudo rm -rf /etc/haproxy/haproxy.cfg'
ssh -i key.pem ec2-user@$EC2_PUBLIC 'sudo cp /home/ec2-user/haproxy.cfg /etc/haproxy/haproxy.cfg'

echo "Starting HAProxy..."
ssh -i key.pem ec2-user@$EC2_PUBLIC 'sudo service haproxy restart'

echo "Proxy is ready!"