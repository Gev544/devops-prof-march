#!/bin/bash

vpcId_val=$(aws ec2 create-vpc --cidr-block 10.10.0.0/16 | jq '.Vpc.VpcId' -r)
subnetId_val=$(aws ec2 create-subnet --vpc-id $vpcId_val --cidr-block 10.10.1.0/24 | jq '.Subnet.SubnetId' -r)
internetGateWayId=$(aws ec2 create-internet-gateway | jq '.InternetGateway.InternetGatewayId' -r )
aws ec2 attach-internet-gateway --vpc-id $vpcId_val --internet-gateway-id $internetGateWayId
routeTable_val=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpcId_val --query 'RouteTables[*].RouteTableId' --output text)
aws ec2 create-route --route-table-id $routeTable_val --destination-cidr-block 0.0.0.0/0 --gateway-id $internetGateWayId
aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > ./MyKeyPair.pem
chmod 400 MyKeyPair.pem
aws ec2 run-instances --image-id ami-080e1f13689e07408 --count 1 --instance-type t2.micro --key-name MyKeyPair --subnet-id $subnetId_val
insctance_ec2_val=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$vpcId_val --query 'Reservations[*].Instances[*].InstanceId' --output text)
ssh_conect_ip_ec2_val=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$vpcId_val --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
ssh -i MyKeyPair.pem ec2-user@$ssh_conect_ip_ec2_val

echo sucsses created
