#!/bin/bash

echo "Cleanup started!"
#clean up all EC2 instances which not contains "permanent=false"
# Function to remove EC2 instances with tag key 'permanent' when the value is 'false'
cleanup_instances() {
echo "Removing instances with tag key 'permanent' when the value is 'false'..."
instance_ids=$(aws ec2 describe-instances --filters "Name=tag:permanent,Values=false" --query 'Reservations[].Instances[].InstanceId' --output text)
echo $instance_ids
# Check if there are any instances to terminate
if [ -n "$instance_ids" ]; then
    # Terminate instances
    aws ec2 terminate-instances --instance-ids $instance_ids
else
    echo "No instances found with tag value not equal to 'permanent=false'."
fi
}

# Function to remove Security Groups with tag key 'permanent' when the value is 'false'
cleanup_security_groups(){
echo "Removing Security Groups with tag key 'permanent' when the value is 'false'..."
security_group_ids=$(aws ec2 describe-security-groups --filters "Name=tag:permanent,Values=false" --query 'SecurityGroups[*].GroupId' --output text)
echo $security_group_ids
for sg_id in $security_group_ids; do
        # Delete the security group
        aws ec2 delete-security-group --group-id $sg_id
        echo "Security group $sg_id deleted."
done
}

# Function to remove Security Groups with tag key 'permanent' when the value is 'false'
detach_all_internet_gateways_and_remove_those_and_remove_all_vpcs() {
    echo "Detaching all internet gateways from all VPCs..."
    # Get all VPCs
    vpc_ids=$(aws ec2 describe-vpcs --filters "Name=tag:permanent,Values=false" --query 'Vpcs[*].VpcId' --output text)
    echo "vpc_ids: $vpc_ids"
    # Detach internet gateways from each VPC
    for vpc_id in $vpc_ids; do
        # List internet gateways attached to the VPC
        igw_ids=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[*].InternetGatewayId' --output text)
        echo "igw_ids: $igw_ids"
        # Detach each internet gateway from the VPC
        for igw_id in $igw_ids; do
            echo "igw_id: $igw_id, vpc_id: $vpc_id"
            aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
            echo "Internet gateway $igw_id detached from VPC $vpc_id."
            aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
            echo "Internet gateway $igw_id deleted."
        done

        subnet_ids=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].SubnetId' --output text)
        echo "subnet_ids: $subnet_ids"
        for subnet_id in $subnet_ids; do
            aws ec2 delete-subnet --subnet-id $subnet_id
            echo "Subnet $igw_id is deleted."
        done

        rtb_ids=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[*].RouteTableId' --output text)
        echo "rtb_ids: $rtb_ids"
        for rtb_id in $rtb_ids; do
            aws ec2 delete-route-table --route-table-id $rtb_id
            echo "Route Table $rtb_id is deleted."
        done

        echo "Starting to remove vpc: $vpc_id"
        aws ec2 delete-vpc --vpc-id $vpc_id
        echo "VPC $vpc_id deleted."
    done
}

# Main cleanup function
cleanup() {
  cleanup_instances
  cleanup_security_groups
  detach_all_internet_gateways_and_remove_those_and_remove_all_vpcs
}

# Execute cleanup function
cleanup

echo "Cleanup complete!"
