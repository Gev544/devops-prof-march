#!/bin/bash

AWS_PROFILE=default

echo "Terminating all running EC2 instances..."
for instance in $(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text --profile $AWS_PROFILE); do
    aws ec2 terminate-instances --instance-ids $instance --profile $AWS_PROFILE 2>/dev/null
done

echo "Waiting for all running EC2 instances to terminate..."
aws ec2 wait instance-terminated --filters "Name=instance-state-name,Values=running" --profile $AWS_PROFILE 2>/dev/null

echo "Deleting all subnets..."
for subnet in $(aws ec2 describe-subnets --query "Subnets[?VpcId!=null].SubnetId" --output text --profile $AWS_PROFILE); do
    aws ec2 delete-subnet --subnet-id $subnet --profile $AWS_PROFILE 2>/dev/null
done

echo "Deleting all route table associations and route tables..."
for rtb in $(aws ec2 describe-route-tables --query "RouteTables[?VpcId!=null].RouteTableId" --output text --profile $AWS_PROFILE); do
    for assoc in $(aws ec2 describe-route-tables --route-table-ids $rtb --query "RouteTables[].Associations[].RouteTableAssociationId" --output text --profile $AWS_PROFILE); do
        aws ec2 disassociate-route-table --association-id $assoc --profile $AWS_PROFILE 2>/dev/null
    done
    aws ec2 delete-route-table --route-table-id $rtb --profile $AWS_PROFILE 2>/dev/null
done

echo "Detaching and deleting all internet gateways..."
for igw in $(aws ec2 describe-internet-gateways --query "InternetGateways[?Attachments[?VpcId!=null]].InternetGatewayId" --output text --profile $AWS_PROFILE); do
    for vpc in $(aws ec2 describe-internet-gateways --internet-gateway-ids $igw --query "InternetGateways[].Attachments[].VpcId" --output text --profile $AWS_PROFILE); do
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc --profile $AWS_PROFILE 2>/dev/null
    done
    aws ec2 delete-internet-gateway --internet-gateway-id $igw --profile $AWS_PROFILE 2>/dev/null
done

echo "Deleting all security groups except the default one..."
for sg in $(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName!='default' && VpcId!=null].GroupId" --output text --profile $AWS_PROFILE); do
    aws ec2 delete-security-group --group-id $sg --profile $AWS_PROFILE 2>/dev/null
done

echo "Deleting all VPCs..."
for vpc in $(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output text --profile $AWS_PROFILE); do
    aws ec2 delete-vpc --vpc-id $vpc --profile $AWS_PROFILE 2>/dev/null
done

echo "Cleanup complete."
