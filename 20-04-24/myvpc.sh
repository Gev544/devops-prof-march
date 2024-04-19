#!/bin/bash

export AWS_DEFAULT_REGION=us-east-1

vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/24 --query 'Vpc.VpcId' --output text)

aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}"

igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id

route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id

subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)

aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $route_table_id

echo "VPC ID: $vpc_id"
echo "Subnet ID: $subnet_id"

