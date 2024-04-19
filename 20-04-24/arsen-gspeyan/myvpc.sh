#!/bin/bash

# Set AWS region
export AWS_DEFAULT_REGION=us-east-1

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/24 --query 'Vpc.VpcId' --output text)

# Enable DNS support and DNS hostnames for the VPC
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}"

# Create an internet gateway
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

# Attach the internet gateway to the VPC
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id

# Create a route table
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)

# Create a route to the internet gateway
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id

# Create a subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)

# Associate the route table with the subnet
aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $route_table_id

# Output VPC and subnet IDs
echo "VPC ID: $vpc_id"
echo "Subnet ID: $subnet_id"

