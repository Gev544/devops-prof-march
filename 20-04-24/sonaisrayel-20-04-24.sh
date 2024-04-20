#!/bin/bash

echo "Creating VPC"
VPC_ID=$(aws ec2 create-vpc --cidr-block "10.0.0.0/16" --region us-east-1 --query 'Vpc.VpcId' --output text)
if [ -z "$VPC_ID" ]; then
    echo "Error creating VPC."
    exit 1
fi
echo "VPC created with ID: $VPC_ID"
echo "____________"

echo "Creating public subnet"
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --cidr-block "10.0.1.0/24" --vpc-id "$VPC_ID" --query 'Subnet.SubnetId' --output text)
if [ -z "$PUBLIC_SUBNET_ID" ]; then
    echo "Error creating public subnet."
    exit 1
fi
echo "Public subnet created with ID: $PUBLIC_SUBNET_ID"
echo "____________"

echo "Creating private subnet"
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --cidr-block "10.0.2.0/24" --vpc-id "$VPC_ID" --query 'Subnet.SubnetId' --output text)
if [ -z "$PRIVATE_SUBNET_ID" ]; then
    echo "Error creating private subnet."
    exit 1
fi
echo "Private subnet created with ID: $PRIVATE_SUBNET_ID"
echo "____________"

echo "Creating IGW"
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
if [ -z "$IGW_ID" ]; then
    echo "Error creating internet gateway."
    exit 1
fi
echo "Internet gateway created with ID: $IGW_ID"
echo "____________"

echo "Attaching IGW to VPC"
if [ -z "$IGW_ID" ]; then
    echo "Error: Internet gateway not created."
    exit 1
fi

aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
if [ $? -ne 0 ]; then
    echo "Error attaching internet gateway to VPC."
    exit 1
fi

echo "Internet gateway attached to VPC."
echo "____________"

echo "Create route table"
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text)
if [ -z "$ROUTE_TABLE_ID" ]; then
    echo "Error creating route table."
    exit 1
fi
echo "Route table created with ID: $ROUTE_TABLE_ID"
echo "____________"

echo "Creating route"
ROUTE_ID=$(aws ec2 create-route --route-table-id "$ROUTE_TABLE_ID" --destination-cidr-block "0.0.0.0/0" --gateway-id "$IGW_ID" --query 'Route.RouteId' --output text)
if [ -z "$ROUTE_ID" ]; then
    echo "Error creating route."
    exit 1
fi
echo "Route created with ID: $ROUTE_ID"
echo "____________"

echo "Creating SG"
SECURITY_GROUP_ID=$(aws ec2 create-security-group --vpc-id "$VPC_ID" --group-name "devops-lessons" --description "Devops Lessons group" --output text --query 'GroupId')
if [ -z "$SECURITY_GROUP_ID" ]; then
    echo "Error creating security group."
    exit 1
fi
echo "Security group created with ID: $SECURITY_GROUP_ID"
echo "____________"

echo "Creating inbound rules"
echo "Creating SSH PORT"
aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "Creating HTTP PORT"
aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "Inbound rules created"
echo "____________"

echo "Creating EC2 instance"
aws ec2 run-instances --image-id ami-080e1f13689e07408 --instance-type t2.micro --key-name aca-lessons --security-group-ids "$SECURITY_GROUP_ID" --subnet-id "$PUBLIC_SUBNET_ID"
echo "EC2 launched!"

echo "Done"
