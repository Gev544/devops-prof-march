#!/bin/bash

# Creating VPC
echo "Starting to create a VPC"
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

# Check if VPC ID exists
if [ -n "$vpc_id" ]; then
    echo "VPC created successfully with ID: $vpc_id"
else
    echo "Failed to create VPC"
    exit 1
fi


#Creating Public subnet
echo "Starting to create a Public subnet"
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
# Check if Subnet ID exists
if [ -n "$subnet_id" ]; then
    echo "Public Subnet created successfully with ID: $subnet_id"
else
    echo "Failed to create Public Subnet"
    exit 1
fi


# Creating Internet Gateway
echo "Starting to create an Internet Gateway"
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
if [ -n "$igw_id" ]; then
    echo "Intenet Gateway created successfully with ID: $igw_id"
else
    echo "Failed to create Internet Gateway"
    exit 1
fi


# Atteching Internet Gateway to VPC
echo "Starting to attach the Internet Gateway to VPC"
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id
echo "Internet Gateway is attached to VPC"


# Getting Route table
echo "Getting a Route Table"
rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc_id --query 'RouteTables[*].RouteTableId' --output text)
if [ -n "$rtb_id" ]; then
    echo "Route Table ID: $rtb_id"
else
    echo "Failed to get Route Table"
    exit 1
fi

aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id



##### LAUNCH INSTANCE INTO SUBNET FOR TESTING #####
# Create a key pair and output to Test0KeyPair.pem
aws ec2 create-key-pair --key-name Test0KeyPair --query 'KeyMaterial' --output text > ./Test0KeyPair.pem

# Modifying Permissions
chmod 400 Test0KeyPair.pem

# Create security group with rule to allow SSH
echo "Starting to create a Security Group"
sg_id=$(aws ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access" --vpc-id $vpc_id --query 'GroupId' --output text)
if [ -n "$sg_id" ]; then
    echo "Security Group ID: $sg_id"
else
    echo "Failed to get Security ID"
    exit 1
fi

## Updateing group-id in the command below:
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0

# Launching instance in public subnet using security group and key pair created previously
aws ec2 run-instances --image-id ami-080e1f13689e07408 --count 1 --instance-type t2.micro --key-name Test0KeyPair --subnet-id $subnet_id


