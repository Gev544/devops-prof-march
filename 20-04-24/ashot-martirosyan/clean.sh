#!/bin/bash

RESOURCE_FILE="aws_resources.txt"
if [ ! -f "$RESOURCE_FILE" ]; then
    echo "Resource file not found, cannot proceed with deletion."
    exit 1
fi
source $RESOURCE_FILE

echo "Detaching and deleting Internet Gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

echo "Disassociating and deleting Route Table..."
ASSOCIATION_ID=$(aws ec2 describe-route-tables --route-table-id $ROUTE_TABLE_ID --query 'RouteTables[0].Associations[0].RouteTableAssociationId' --output text)
aws ec2 disassociate-route-table --association-id $ASSOCIATION_ID
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID

echo "Terminating EC2 Instance..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

echo "Deleting Subnet..."
aws ec2 delete-subnet --subnet-id $SUBNET_ID

echo "Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "All resources have been deleted."
rm $RESOURCE_FILE  
