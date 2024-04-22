#!/bin/bash

# Get instance IDs where permanent is TRUE and terminating that instances:
instance_ids=$(aws ec2 describe-instances --filters "Name=tag:permanent,Values=true" --query 'Reservations[*].Instances[*].InstanceId' --output text)
for instance_id in $instance_ids; do
    echo "Deleting instance with id: $instance_id"
    aws ec2 terminate-instances --instance-ids $instance_id
    echo "Instance with id: $instance_id is terminated"
    echo "Waiting for status terminated"
    aws ec2 wait instance-terminated --instance-ids $instance_id
    echo "Status for $instance_id is set to TERMINATED"
    echo "--------------------------------------------------------"
done

# Get VPC IDs where permanent is TRUE and delete that VPCs:
vpc_ids=$(aws ec2 describe-vpcs --filters "Name=tag:permanent,Values=true" --query 'Vpcs[0].VpcId' --output text)
for vpc_id in $vpc_ids; do
    echo "Deleting VPC with id: $vpc_id"
    aws ec2 delete-vpc --vpc-id $vpc_id
    if [ $? -eq 0 ]; then
    echo "VPC with id: $vpc_id is deleted"
    echo "--------------------------------------------------------"
else
    echo "ERROR: VPC is not deleted"
    exit
fi
done

# Get SUBNET IDs where permanent is TRUE and delete that STUBNETS:
subnet_ids=$(aws ec2 describe-subnets --filters "Name=tag:permanent,Values=true" --query 'Subnets[1].SubnetId' --output text)
for subnet_id in $subnet_ids; do
    echo "Deleting SUBNET with id: $subnet_id"
    aws ec2 delete-subnet --subnet-id $subnet_id
    if [ $? -eq 0 ]; then
    echo "SUBNET with id: $subnet_id is deleted"
    echo "--------------------------------------------------------"
else
    echo "ERROR: SUBNET is not deleted"
    exit
fi
done

# Get IGW IDs where permanent is TRUE and delete that IGWs:
igw_ids=$(aws ec2 describe-internet-gateways --filters "Name=tag:permanent,Values=true" --query 'InternetGateways[0].InternetGatewayId' --output text)
for igw_id in $igw_ids; do
    echo "Deleting IGW with id: $igw_id"
    vpc_id=$(aws ec2 describe-internet-gateways --internet-gateway-ids "$igw_id" --query 'InternetGateways[*].Attachments[*].VpcId' --output text)
    aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
    aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
    if [ $? -eq 0 ]; then
    echo "IGW with id: $igw_id is deleted"
    echo "--------------------------------------------------------"
else
    echo "ERROR: IGW is not deleted"
    exit
fi
done

# Get RTB IDs where permanent is TRUE and delete that RTBs:
rtb_ids=$(aws ec2 describe-route-tables --filters "Name=tag:permanent,Values=true" --query 'RouteTables[0].RouteTableId' --output text)
for rtb_id in $rtb_ids; do
    echo "Deleting Route Table with id: $rtb_id"
    aws ec2 delete-route-table --route-table-id $rtb_id
    if [ $? -eq 0 ]; then
    echo "Route table with id: $rtb_id is deleted"
    echo "--------------------------------------------------------"
else
    echo "ERROR: Route table is not deleted"
    exit
fi
done

# Get Secure Group IDs where permanent is TRUE and delete that SGs:
sec_grs=$(aws ec2 describe-security-groups --filters "Name=tag:permanent,Values=true" --query 'SecurityGroups[0].GroupId' --output text)
for sec_gr in $sec_grs; do
    echo "Deleting Security group with id: $sec_gr"
    aws ec2 delete-security-group --group-id $sec_gr
    if [ $? -eq 0 ]; then
    echo "Security group with id: $sec_gr is deleted"
    echo "--------------------------------------------------------"
else
    echo "ERROR: Security group is not deleted"
    exit
fi
done