#!/bin/bash
current_date=$(date +"%Y-%m-%d%H:%M:%S")


#This function will run if any error and will delete services created before
cleanup() {
    local error_message="$1"
    local current_date="$2"
    echo "Error occurred: $error_message"
    echo "Starting cleanup!"




# Get VPC ID
vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:date,Values=$current_date" --query 'Vpcs[0].VpcId' --output text)
echo "VPC ID IS: $vpc_id"

# Get Public Subnet ID
public_subnet_id=$(aws ec2 describe-subnets --filters "Name=tag:date,Values=$current_date" --query 'Subnets[0].SubnetId' --output text)
echo "Public Subnet ID IS: $public_subnet_id"

# Get Private Subnet ID
private_subnet_id=$(aws ec2 describe-subnets --filters "Name=tag:date,Values=$current_date" --query 'Subnets[1].SubnetId' --output text)
echo "Private Subnet ID IS: $private_subnet_id"

# Get Internet Gateway ID
igw_id=$(aws ec2 describe-internet-gateways --filters "Name=tag:date,Values=$current_date" --query 'InternetGateways[0].InternetGatewayId' --output text)
echo "Internet Gateway ID IS: $igw_id"

# Get Route Table ID
route_table_id=$(aws ec2 describe-route-tables --filters "Name=tag:date,Values=$current_date" --query 'RouteTables[0].RouteTableId' --output text)
echo "Route Table ID IS: $route_table_id"

# Get Security Group ID
security_group_id=$(aws ec2 describe-security-groups --filters "Name=tag:date,Values=$current_date" --query 'SecurityGroups[0].GroupId' --output text)
echo "Security Group ID: $security_group_id"

# Get EC2 Instance ID
aws_ec2_id=$(aws ec2 describe-instances --filters "Name=tag:date,Values=$current_date" --query 'Reservations[0].Instances[0].InstanceId' --output text)
echo "EC2 Instance ID IS: $aws_ec2_id"

if [ -n "$aws_ec2_id" ]; then
aws ec2 terminate-instances --instance-ids $aws_ec2_id
aws ec2 wait instance-terminated --instance-ids $aws_ec2_id

    echo "EC2 is terminated"

else
    echo "EC2 Variable is null"
fi
if [ -n "$security_group_id" ]; then
aws ec2 delete-security-group --group-id $security_group_id
    echo "Security group is deleted"

else
    echo "SECURITY GROUP Variable is null"
fi
if [ -n "$igw_id" ]; then
aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
    echo "IGW is deleted"

else
    echo "IGW Variable is null"
fi
if [ -n "$private_subnet_id" ]; then
aws ec2 delete-subnet --subnet-id $private_subnet_id
    echo "Private subnet is deleted"

else
    echo "PRIVATE SUBNET Variable is null"
fi
if [ -n "$public_subnet_id" ]; then
aws ec2 delete-subnet --subnet-id $public_subnet_id
    echo "Public subnet is deleted"

else
    echo "PUBLIC SUBNET Variable is null"
fi
if [ -n "$route_table_id" ]; then
aws ec2 delete-route-table --route-table-id $route_table_id
    echo "Route table is deleted"

else
    echo "ROUTE TABLE Variable is null"
fi
if [ -n "$vpc_id" ]; then
aws ec2 delete-vpc --vpc-id $vpc_id
    echo "VPC is deleted"

else
    echo "VPC Variable is null"
fi


}

trap "cleanup \"$BASH_COMMAND\" \"$current_date\"" ERR


# Creating VPC
echo "Starting to create a VPC"
vpc_id=$(aws ec2 create-vpc --cidr-block "10.0.0.0/16" --region us-east-1 --query 'Vpc.VpcId' --output text)
echo "VPC is created with ID: $vpc_id"
aws ec2 create-tags --resources $vpc_id --tags Key='date',Value=$current_date --region us-east-1

#creating PUBLIC SUBNET
echo "Starting to create public subnet"
public_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "10.0.1.0/24" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $public_subnet_id --tags Key='date',Value=$current_date --region us-east-1
echo "Publci subnet is created with ID: $public_subnet_id"

#creating PRIVATE SUBNET
echo "Starting to create private subnet"
private_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "10.0.2.0/24" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $private_subnet_id --tags Key='date',Value=$current_date --region us-east-1
echo "Private subnet is created with ID: $private_subnet_id"

#creating IGW
echo "Starting to create a IGW"
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $igw_id --tags Key='date',Value=$current_date --region us-east-1
echo "Internet gateway is create with ID: $igw_id"
#connecting IGW to VPC
echo "Starting to Attach IGW to VPC"
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
echo "Internet gateway is attached to VPC."

#creating ROUTE TABLE
echo "Starting to create a route table"
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $route_table_id --tags Key='date',Value=$current_date
echo "Route table created with ID: $route_table_id"
#creating ROUTE
echo "Starting to create a ROUTE"
route_id=$(aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --query 'Route.RouteId' --output text)
echo "Route is created with ID: $route_id"
#connecting ROUTETABLE to SUBNET
echo "Starting to create a Route table"
aws ec2 associate-route-table --subnet-id $public_subnet_id --route-table-id $route_table_id
echo "Route table successfully connected to subnet!"

#creating SECURITY GROUP
echo "Starting to create a Security group"
security_group_id=$(aws ec2 create-security-group --vpc-id $vpc_id --group-name "cli_group" --description "Bash CLI group" --output text --query 'GroupId')
aws ec2 create-tags --resources $security_group_id --tags Key='date',Value=$current_date
echo "Security group created succesfully!"
#creating rules for security group
echo "Starting write inbound rules"
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null 2>&1
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null 2>&1
aws ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null 2>&1
echo "Inbound rules created succesfully!"

#creating KEY PAIR
echo "Starting to create KeyPair"
aws ec2 create-key-pair --key-name KeyPairFromShCli --query 'KeyMaterial' --output text > keyPair.pem
echo "KeyPair created succesfully!"

#creating ec2 instance
echo "Starting to Lunch an EC2 instance"
aws_ec2_id=$(aws ec2 run-instances --image-id ami-080e1f13689e07408 --instance-type t2.micro --key-name KeyPairFromShCli --security-group-ids $security_group_id --subnet-id $public_subnet_id --associate-public-ip-address --query 'Instances[0].InstanceId' --output text)
echo "EC2 lunched succesfully!"
aws ec2 create-tags --resources $aws_ec2_id --tags Key='date',Value=$current_date
cleanup "Testing cleanup function" "$current_date"

