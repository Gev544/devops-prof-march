#!/bin/bash/

VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc},{Key=Permanent,Value=false}]")
if [ -z $VPC_ID ]; then
	echo "Error creating VPC";
	exit;
fi

PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)

if [ -z $PUBLIC_SUBNET_ID ]; then
	echo "Error creating Public Subnet";
	exit 1;
fi

PUBLIC_SUBNET_ID_1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --query Subnet.SubnetId --output text)

if [ -z $PUBLIC_SUBNET_ID_1 ]; then
        echo "Error creating Subnet";
        exit 1;
fi

IGW_ID=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)

if [ -z $IGW_ID ]; then
        echo "Error creating Internet Getaway";
        exit 1;
fi

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --output json

if [ $? -ne 0 ]; then 
	echo "Error attaching internet getaway to vpc";
	exit 1;
fi

ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query RouteTable.RouteTableId --output text)
if [ -z $ROUTE_TABLE_ID ]; then
        echo "Error creating Internet Route Table";
        exit 1;
fi

aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --output json

if [ $? -ne 0 ]; then
        echo "Error creating route";
        exit 1;
fi

aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --output json

if [ $? -ne 0 ]; then
        echo "Error creating route";
        exit 1;
fi

aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $PUBLIC_SUBNET_ID --output json
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $PUBLIC_SUBNET_ID_1  --output json
if [ $? -ne 0 ]; then
        echo "Error assiociating route table with pblic subnet";
        exit 1;
fi

SG_ID=$(aws ec2 create-security-group --group-name my-sg --description "My security group" --vpc-id $VPC_ID --output text)

if [ -z $SG_ID ]; then
        echo "Error creating Security Group";
        exit 1;
fi

aws ec2 authorize-security-group-ingress --group-id $SG_ID  --protocol tcp --port 22 --cidr 0.0.0.0/0 --output json

if [ $? -ne 0 ]; then
        echo "Error authorizing security group";
        exit 1;
fi

aws ec2 run-instances --image-id ami-080e1f13689e07408 --count 1 --instance-type t2.micro --key-name aws-key1 --security-group-ids $SG_ID --subnet-id $PUBLIC_SUBNET_ID --associate-public-ip-address --output text
if [ $? -ne 0 ]; then
        echo "Error creating instance";
        exit 1;
fi

echo "Done"