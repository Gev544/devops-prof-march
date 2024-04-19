#!/bin/bash
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id
rtb_id=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc_id --query 'RouteTables[*].RouteTableId' --output text)
aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id
aws ec2 create-key-pair --key-name CustomKeyPair --query 'KeyMaterial' --output text > ./CustomKeyPair.pem
chmod 400 CustomKeyPair.pem
aws ec2 run-instances --image-id ami-080e1f13689e07408 --count 1 --instance-type t2.micro --key-name CustomKeyPair --subnet-id $subnet_id
