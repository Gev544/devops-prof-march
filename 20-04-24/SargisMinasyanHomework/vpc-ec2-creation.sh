#!/bin/bash

# Create virtual private cloud
vpcId_val=$(aws ec2 create-vpc --cidr-block 10.10.0.0/16 | jq '.Vpc.VpcId' -r)

if[-n "$vpc-id"]
then

	echo "virtual private cloud created"

else
	echo "Faild to create virtual private cloud"
	exit 1
fi
# Declare subnet inside VPC
subnetId_val=$(aws ec2 create-subnet --vpc-id $vpcId_val --cidr-block 10.10.1.0/24 | jq '.Subnet.SubnetId' -r)

if[-n "$subnetId_val"]
then
	echo "Declared subnet inside VPC"
else
	echo "Faild to Declare subnet inside VPC"
	exit 1
fi

# Create Internet GateWay for subnet
internetGateWayId=$(aws ec2 create-internet-gateway | jq '.InternetGateway.InternetGatewayId' -r )

if[-n "$internetGateWayId"]
then
	echo "Createed Internet GateWay for subnet"
else
	echo "Faild to Create Internet GateWay for subnet"
	exit 1
fi

# Attach internet gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $vpcId_val --internet-gateway-id $internetGateWayId

if [ $? -eq 0 ]
then
  echo " Attach internet gateway to VPC The script was successful"
else
  echo "Attach internet gateway to VPC failed" >&2
  exit 1
fi


# get Rout Table by VPC id and Attach internet gateway to subnet adding internetGateway id in destination block
routeTable_val=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpcId_val --query 'RouteTables[*].RouteTableId' --output text)
aws ec2 create-route --route-table-id $routeTable_val --destination-cidr-block 0.0.0.0/0 --gateway-id $internetGateWayId

if[-n "$routeTable_val"]
then
	echo "internet attaching sucssed"
else
	echo "Faild to internet attaching "
	exit 1
fi


#create key pair for new inctance
aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > ./MyKeyPair.pem

# give an nesesery acceses to .pem file
chmod 400 MyKeyPair.pem

if [ $? -eq 0 ]
then
  echo " create key pair for new inctance successful"
else
  echo "create key pair for new inctance failed" >&2
  exit 1
fi

# create and run a new instance inside new creted VPC
aws ec2 run-instances --image-id ami-080e1f13689e07408 --count 1 --instance-type t2.micro --key-name MyKeyPair --subnet-id $subnetId_val

# get insctance by VPC id
insctance_ec2_val=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$vpcId_val --query 'Reservations[*].Instances[*].InstanceId' --output text)

if[-n "$insctance_ec2_val"]
then
	echo "create and run a new instance inside new creted VPC sucssed"
else
	echo "Faild to create and run a new instance inside new creted VPC"
	exit 1
fi


#Conect to EC2 using SSH and .pem key
ssh_conect_ip_ec2_val=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$vpcId_val --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
ssh -i MyKeyPair.pem ec2-user@$ssh_conect_ip_ec2_val
