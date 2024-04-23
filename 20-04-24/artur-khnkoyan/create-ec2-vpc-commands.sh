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

# Add tag to the VPC
aws ec2 create-tags --resources $vpc_id --tags Key=permanent,Value=false

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

# Add tag to the subnet
aws ec2 create-tags --resources $subnet_id --tags Key=permanent,Value=false


# Creating Internet Gateway
echo "Starting to create an Internet Gateway"
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
if [ -n "$igw_id" ]; then
    echo "Intenet Gateway created successfully with ID: $igw_id"
else
    echo "Failed to create Internet Gateway"
    exit 1
fi

# Add tag to the Internet Gateway
aws ec2 create-tags --resources $igw_id --tags Key=permanent,Value=false

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

# Add tag to the Route Table
aws ec2 create-tags --resources $rtb_id --tags Key=permanent,Value=false


aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id



##### LAUNCH INSTANCE INTO SUBNET FOR TESTING #####
# Create a key pair and output to TestKeyPair.pem
aws ec2 create-key-pair --key-name TestKeyPair --query 'KeyMaterial' --output text > ./TestKeyPair.pem

# Modifying Permissions
chmod 400 TestKeyPair.pem

# Create security group with rule to allow SSH
echo "Starting to create a Security Group"
sg_id=$(aws ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access" --vpc-id $vpc_id --query 'GroupId' --output text)
if [ -n "$sg_id" ]; then
    echo "Security Group ID: $sg_id"
else
    echo "Failed to get Security ID"
    exit 1
fi

# Add tag to the Security Group
aws ec2 create-tags --resources $sg_id --tags Key=permanent,Value=false

## Updateing group-id in the command below:
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0

# Launching instance in public subnet using security group and key pair created previously
aws ec2 run-instances --image-id ami-080e1f13689e07408 --count 1 --instance-type t2.micro --key-name TestKeyPair --subnet-id $subnet_id

# get insctance by VPC id
instance_id=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$vpcId_val --query 'Reservations[*].Instances[*].InstanceId' --output text)

if [-n "$instance_id"]; then
    echo "create and run a new instance with id:$instance_id inside new creted VPC succesed"
else
    echo "Faild to create and run a new instance inside new creted VPC"
    exit 1
fi

# Add tags to the instance
aws ec2 create-tags --resources $instance_id --tags Key=permanent,Value=false


echo "Script Complete!"
