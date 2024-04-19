#!/bin/bash

# Creating VPC
echo "Starting to create a VPC"
vpc_id=$(aws ec2 create-vpc --cidr-block "10.0.0.0/16" --region us-east-1 --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $vpc_id --tags Key='from',Value='cli' --region us-east-1
if [ $? -ne 0 ]; then
    echo "Error creating VPC. Exiting."
    exit 1
fi
echo "VPC is created with ID: $vpc_id"

#creating PUBLIC SUBNET
echo "Starting to create public subnet"
public_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "10.0.1.0/24" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $public_subnet_id --tags Key='from',Value='cli' --region us-east-1
if [ $? -ne 0 ]; then
    echo "Error creating Public subnet. Exiting."
    exit 1
fi
echo "Publci subnet is created with ID: $public_subnet_id"

#creating PRIVATE SUBNET
echo "Starting to create private subnet"
private_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "10.0.2.0/24" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $private_subnet_id --tags Key='from',Value='cli' --region us-east-1
if [ $? -ne 0 ]; then
    echo "Error creating Private subnet. Exiting."
    exit 1
fi
echo "Private subnet is created with ID: $private_subnet_id"

#creating IGW
echo "Starting to create a IGW"
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $igw_id --tags Key='from',Value='cli' --region us-east-1
if [ $? -ne 0 ]; then
    echo "Error creating IGW. Exiting."
    exit 1
fi
echo "Internet gateway is create with ID: $igw_id"
#connecting IGW to VPC
echo "Starting to Attach IGW to VPC"
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
if [ $? -ne 0 ]; then
    echo "Error connecting IGW to VPC. Exiting."
    exit 1
fi
echo "Internet gateway is attached to VPC."

#creating ROUTE TABLE
echo "Starting to create a route table"
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $route_table_id --tags Key='from',Value='cli'
if [ $? -ne 0 ]; then
    echo "Error creating Route table. Exiting."
    exit 1
fi
echo "Route table created with ID: $route_table_id"
#creating ROUTE
echo "Starting to create a ROUTE"
route_id=$(aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --query 'Route.RouteId' --output text)
if [ $? -ne 0 ]; then
    echo "Error creating Route. Exiting."
    exit 1
fi
echo "Route is created with ID: $route_id"
#connecting ROUTETABLE to SUBNET
echo "Starting to create a Route table"
aws ec2 associate-route-table --subnet-id $public_subnet_id --route-table-id $route_table_id
if [ $? -ne 0 ]; then
    echo "Error connecting Routetable to Subnet. Exiting."
    exit 1
fi
echo "Route table successfully connected to subnet!"

#creating SECURITY GROUP
echo "Starting to create a Security group"
security_group_id=$(aws ec2 create-security-group --vpc-id $vpc_id --group-name "cli_group" --description "Bash CLI group" --output text --query 'GroupId')
if [ $? -ne 0 ]; then
    echo "Error creating Security group. Exiting."
    exit 1
fi
echo "Security group created succesfully!"
#creating rules for security group
echo "Starting write inbound rules"
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null 2>&1
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null 2>&1
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error creating rules for security group. Exiting."
    exit 1
fi
echo "Inbound rules created succesfully!"

#creating KEY PAIR
echo "Starting to create KeyPair"
aws ec2 create-key-pair --key-name KeyPairFromShCli --query 'KeyMaterial' --output text > keyPair.pem
if [ $? -ne 0 ]; then
    echo "Error creating Key Pair. Exiting."
    exit 1
fi
echo "KeyPair created succesfully!"

#creating ec2 instance
echo "Starting to Lunch an EC2 instance"
aws ec2 run-instances --image-id ami-080e1f13689e07408 --instance-type t2.micro --key-name KeyPairFromShCli --security-group-ids $security_group_id --subnet-id $public_subnet_id --associate-public-ip-address > ec2_settings.txt
if [ $? -ne 0 ]; then
    echo "Error creating EC2 instance. Exiting."
    exit 1
fi
echo "EC2 lunched succesfully!"

