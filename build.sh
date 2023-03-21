#!/usr/bin/env bash

KEY_NAME=$(jq -r .KEY_NAME config.json)
SUBNET_ID=$(jq -r .SUBNET_ID config.json)
INBOUND_PORT=$(jq -r .INBOUND_PORT config.json)
OUTBOUND_PORT=$(jq -r .OUTBOUND_PORT config.json)

echo "Creating EC2 Key Pair..."
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    > key-output.json

KEY_ID=$(jq -r .KeyPairId key-output.json)
jq -r .KeyMaterial key-output.json > key.pem

VPC_ID=$(aws ec2 describe-subnets | jq -r ".Subnets[] | select(.SubnetId==\"$SUBNET_ID\") | .VpcId")
echo "Found VPC ID for $SUBNET_ID: $VPC_ID"

echo "Creating EC2 Security Group..."
aws ec2 create-security-group \
    --group-name reverse-proxy \
    --description reverse-proxy \
    --vpc-id $VPC_ID \
    > sg-output.json

SG_ID=$(jq -r .GroupId sg-output.json)
CIDR=$(curl -s https://checkip.amazonaws.com)/32

echo "Configuring EC2 Security Group..."
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr $CIDR \
    --no-cli-pager

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --no-cli-pager

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port $INBOUND_PORT \
    --cidr 0.0.0.0/0 \
    --no-cli-pager

echo "Starting EC2 Instance..."
aws ec2 run-instances \
    --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --subnet-id $SUBNET_ID \
    > ec2-output.json

EC2_ID=$(jq -r '.Instances[0].InstanceId' ec2-output.json)

echo "Waiting for Instance to Start..."
aws ec2 wait instance-status-ok --instance-ids $EC2_ID

EC2_PUBLIC=$(aws ec2 describe-instances --instance-ids $EC2_ID | jq -r ".Reservations[].Instances[].PublicDnsName")
echo "Instance is running; public DNS is: $EC2_PUBLIC"

cat << EOF > resources.json
{
    "EC2_PUBLIC": "$EC2_PUBLIC",
    "EC2_ID": "$EC2_ID",
    "KEY_ID": "$KEY_ID",
    "SG_ID": "$SG_ID"
}
EOF

echo "Configuring HAProxy..."
chmod 600 key.pem
ssh -o 'StrictHostKeyChecking=no' -i key.pem ec2-user@$EC2_PUBLIC 'sudo yum install haproxy -y'

sed "s/INBOUND/$INBOUND_PORT/g" haproxy.template.cfg > haproxy.cfg.temp
sed "s/OUTBOUND/$OUTBOUND_PORT/g" haproxy.cfg.temp > haproxy.cfg
rm haproxy.cfg.temp

scp -i key.pem haproxy.cfg ec2-user@$EC2_PUBLIC:/home/ec2-user
ssh -i key.pem ec2-user@$EC2_PUBLIC 'sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.old && sudo rm -rf /etc/haproxy/haproxy.cfg'
ssh -i key.pem ec2-user@$EC2_PUBLIC 'sudo cp /home/ec2-user/haproxy.cfg /etc/haproxy/haproxy.cfg'

echo "Starting HAProxy..."
ssh -i key.pem ec2-user@$EC2_PUBLIC 'sudo service haproxy start'
ssh -i key.pem ec2-user@$EC2_PUBLIC 'sudo service haproxy status'

echo "Proxy is ready!"