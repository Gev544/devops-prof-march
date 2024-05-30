#!/bin/bash

# Exit script on error and execute the cleanup script on error
set -e
trap '../../cleanup/AKachatryan/cleanup.sh' ERR

# Creating VPC
echo "Starting to create a VPC"
vpc_id=$(aws ec2 create-vpc --cidr-block "10.0.0.0/16" --region us-east-1 --query 'Vpc.VpcId' --output text)
echo "VPC is created with ID: $vpc_id"
aws ec2 create-tags --resources $vpc_id --tags Key='permanent',Value='true' --region us-east-1

# Creating PUBLIC SUBNET
echo "Starting to create public subnet"
public_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "10.0.1.0/24" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $public_subnet_id --tags Key='permanent',Value='true' --region us-east-1
echo "Public subnet is created with ID: $public_subnet_id"

# Creating PRIVATE SUBNET
echo "Starting to create private subnet"
private_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "10.0.2.0/24" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $private_subnet_id --tags Key='permanent',Value='true' --region us-east-1
echo "Private subnet is created with ID: $private_subnet_id"

# Creating IGW
echo "Starting to create an IGW"
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $igw_id --tags Key='permanent',Value='true' --region us-east-1
echo "Internet gateway is created with ID: $igw_id"

# Attaching IGW to VPC
echo "Starting to attach IGW to VPC"
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
echo "Internet gateway is attached to VPC."

# Creating ROUTE TABLE
echo "Starting to create a route table"
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $route_table_id --tags Key='permanent',Value='true' --region us-east-1
echo "Route table created with ID: $route_table_id"

# Creating ROUTE
echo "Starting to create a route"
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id
echo "Route is created."

# Associating ROUTE TABLE with PUBLIC SUBNET
echo "Starting to associate route table with public subnet"
aws ec2 associate-route-table --subnet-id $public_subnet_id --route-table-id $route_table_id
echo "Route table successfully associated with public subnet!"

# Creating SECURITY GROUP
echo "Starting to create a security group"
security_group_id=$(aws ec2 create-security-group --vpc-id $vpc_id --group-name "cli_group" --description "Bash CLI group" --query 'GroupId' --output text)
aws ec2 create-tags --resources $security_group_id --tags Key='permanent',Value='true' --region us-east-1
echo "Security group created successfully with ID: $security_group_id"

# Creating rules for security group
echo "Starting to write inbound rules"
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 443 --cidr 0.0.0.0/0
echo "Inbound rules created successfully!"

# Creating KEY PAIR
echo "Starting to create KeyPair"
aws ec2 create-key-pair --key-name devopstest --query 'DEVOPS' --output text > devopstestViaScript.pem
chmod 400 devopstestViaScript.pem
echo "KeyPair created successfully and saved to devopstestViaScript.pem"

# Creating EC2 instance
echo "Starting to launch an EC2 instance"
instance_id=$(aws ec2 run-instances --image-id ami-080e1f13689e07408 --instance-type t2.micro --key-name KeyPairFromShCli --security-group-ids $security_group_id --subnet-id $public_subnet_id --associate-public-ip-address --query 'Instances[0].InstanceId' --output text)
echo "EC2 instance launched successfully with ID: $instance_id"
aws ec2 create-tags --resources $instance_id --tags Key='permanent',Value='true'

# Clean up (optional): echo undefined variable to trigger error handling
echo "$undefined_variable"

