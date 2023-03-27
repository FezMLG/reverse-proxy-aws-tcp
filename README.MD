## Lets Build It

You will need the following to complete the rest of this tutorial:

An active AWS account (If you don’t have one, you can sign up on aws)

- Installed the AWS CLI
- Configured AWS credentials

Optionally, you may also want to install:

- jq

With those in hand, it’s time to get started!

## Where Will the Instance Live?

Before creating anything in the cloud, you’ll need to make sure that you have some information about the VPC and subnet the instance will be assigned to. This information can be found in the console, or on the command-line via `aws ec2 describe-subnets`. It will list all your subnets, and the VPCs they belong to.

If your cloud is like most peoples, you likely have quite a few of these lying around, which makes it difficult to find the one you want to place your proxy in. I like to add `jq` into the mix to make it easier to parse, like this:

```bash
aws ec2 describe-subnets | jq -r '.Subnets[] | "\(.AvailabilityZone)\t\(.CidrBlock)\t\(.SubnetId)\t\(.VpcId)"' | sort
```

```bash
cp config.template.json config.json
```

Copy one of the subnets id and paste it into config.json

## Building

```bash
build.sh
```

## Adding another port

```bash
add_port.sh in_port:out_port:local_port:name
```
