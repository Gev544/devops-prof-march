#!/bin/bash

REGION="us-east-1"
AMI_ID="ami-04b70fa74e45c3917"
INSTANCE_TYPE="t2.micro"
KEY_NAME="myawskey"
KEY_PATH="/home/ashot/.ssh/myawskey.pem"
SECURITY_GROUP_NAME="my-security-group"
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
AVAILABILITY_ZONE="us-east-1a"

VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)

echo "Created VPC with ID: $VPC_ID"

IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
echo "Created Internet Gateway with ID: $IGW_ID"

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $REGION
echo "Attached Internet Gateway to VPC"

SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --availability-zone $AVAILABILITY_ZONE --region $REGION --query 'Subnet.SubnetId' --output text)
echo "Created Subnet with ID: $SUBNET_ID"

ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
echo "Created Route Table with ID: $ROUTE_TABLE_ID"

aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION
echo "Created Route to Internet Gateway"

aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $ROUTE_TABLE_ID --region $REGION
echo "Associated Route Table with Subnet"

aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch --region $REGION
echo "Enabled Auto-assign Public IP on Subnet"

SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Security group for EC2 instance" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)
echo "Created Security Group with ID: $SECURITY_GROUP_ID"

aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $REGION
echo "Authorized Security Group Ingress for ports 22, 80, and 443"

INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --subnet-id $SUBNET_ID --associate-public-ip-address --region $REGION --query 'Instances[0].InstanceId' --output text)
echo "Launched EC2 Instance with ID: $INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "EC2 Instance Public IP: $PUBLIC_IP"

echo "To connect to the instance, use the following command:"
echo "ssh -i $KEY_PATH ubuntu@$PUBLIC_IP"