#!/bin/bash

REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR="10.0.1.0/24"
AMI_ID="ami-04b70fa74e45c3917"  
RESOURCE_FILE="aws_resources.txt"

echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text)
echo "VPC Created: $VPC_ID"
echo "VPC_ID=$VPC_ID" > $RESOURCE_FILE

echo "Creating subnet..."
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUBLIC_SUBNET_CIDR --query 'Subnet.SubnetId' --output text)
echo "Subnet Created: $SUBNET_ID"
echo "SUBNET_ID=$SUBNET_ID" >> $RESOURCE_FILE

echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "Internet Gateway Created and Attached: $IGW_ID"
echo "IGW_ID=$IGW_ID" >> $RESOURCE_FILE

echo "Creating Route Table..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
echo "Route Table Created: $ROUTE_TABLE_ID"
echo "ROUTE_TABLE_ID=$ROUTE_TABLE_ID" >> $RESOURCE_FILE

aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "Route created to IGW"

aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $ROUTE_TABLE_ID
echo "Route Table associated with Subnet"

echo "Launching EC2 Instance..."
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro  --subnet-id $SUBNET_ID --associate-public-ip-address --query 'Instances[0].InstanceId' --output text)
echo "EC2 Instance Created: $INSTANCE_ID"
echo "INSTANCE_ID=$INSTANCE_ID" >> $RESOURCE_FILE

echo "Resources created successfully. Resource IDs stored in $RESOURCE_FILE"
