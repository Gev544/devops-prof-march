#!/bin/bash

# Create virtual private cloud
vpcId_val=$(aws ec2 create-vpc \
    --cidr-block 10.10.0.0/16 \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=permanent,Value=false}]" \
    --query 'Vpc.VpcId' \
    --output text)

if [ -n "$vpcId_val" ]; then
        echo "virtual private cloud created"
else
        echo "Faild to create virtual private cloud"
        exit 1
fi
# Declare subnet inside VPC
subnetId_val=$(aws ec2 create-subnet \
    --vpc-id "$vpcId_val" \
    --cidr-block 10.10.1.0/24 \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=permanent,Value=false}]" \
    --query 'Subnet.SubnetId' \
    --output text)

if [ -n "$subnetId_val" ]; then
        echo "Declared subnet inside VPC"
else
        echo "Faild to Declare subnet inside VPC"
        exit 1
fi

# Create Internet GateWay for subnet
internetGatewayId=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

if [ -n "$internetGatewayId" ]; then
        echo "Createed Internet GateWay for subnet"
else
        echo "Faild to Create Internet GateWay for subnet"
        exit 1
fi

# Attach internet gateway to VPC
if ! aws ec2 attach-internet-gateway --vpc-id "$vpcId_val" --internet-gateway-id "$internetGatewayId"; then
    echo "Failed to attach internet gateway to VPC $vpcId_val"
    exit 1
fi


# Get Route Table by VPC ID
routeTable_val=$(aws ec2 describe-route-tables \
    --filters Name=vpc-id,Values="$vpcId_val" \
    --query 'RouteTables[*].RouteTableId' \
    --output text)

# Attach internet gateway to route table
aws ec2 create-route \
    --route-table-id "$routeTable_val" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$internetGatewayId" \

if [ -n "$routeTable_val" ]; then
        echo "internet attaching sucssed"
else
        echo "Faild to internet attaching "
        exit 1
fi


#create key pair for new inctance
aws ec2 create-key-pair \
    --key-name MyKeyPair \
    --query 'KeyMaterial' \
    --output text > ./MyKeyPair.pem

# give an nesesery acceses to .pem file
chmod 400 MyKeyPair.pem

if [ $? -eq 0 ]; then
  echo " create key pair for new inctance successful"
else
  echo "create key pair for new inctance failed" >&2
  exit 1
fi

# Create security group
security_group_id=$(aws ec2 create-security-group \
    --group-name my-ec2-security-group \
    --description "EC2 Security Group" \
    --vpc-id "$vpcId_val" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=permanent,Value=false}]" \
    --output text --query 'GroupId')

# Authorize inbound SSH traffic
aws ec2 authorize-security-group-ingress \
    --group-id "$security_group_id" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

if [ -n "$security_group_id" ]; then
        echo "security group created "
else
        echo "Faild to create security group"
        exit 1
fi

# create and run a new instance inside new created VPC
instance_ec2_val=$(aws ec2 run-instances \
    --image-id ami-080e1f13689e07408 \
    --count 1 \
    --instance-type t2.micro \
    --key-name MyKeyPair \
    --security-group-ids "$security_group_id" \
    --subnet-id "$subnetId_val" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=permanent,Value=false}]" \
    --query 'Instances[].InstanceId' \
    --output text)

if [ -n "$instance_ec2_val" ]; then
        echo "create and run a new instance inside new created VPC succeeded"
else
        echo "Faild to create and run a new instance inside new created VPC"
        exit 1
fi

echo "finished"
