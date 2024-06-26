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
    aws ec2 wait instance-terminated --instance-ids $instance_ids
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
delete_all_routs-from_routh_tabel_by_vpcid(){
echo "Step 1: Get the Route Table ID(s) associated with the VPC"
route_table_ids=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'RouteTables[*].RouteTableId' \
    --output text)

echo " Step 2: For each Route Table ID, get the list of routes and delete them"
for rt_id in $route_table_ids; do
    routes=$(aws ec2 describe-route-tables \
        --route-table-id $rt_id \
        --query 'RouteTables[*].Routes[?DestinationCidrBlock != `local`].DestinationCidrBlock' \
        --output text)

echo    "# Step 3: Delete each route from the route table"
    for route in $routes; do
        aws ec2 delete-route \
            --route-table-id $rt_id \
            --destination-cidr-block $route
    done
done
}

clean_all_subnets(){
echo " Step 1: Get the Subnet IDs associated with the VPC"
subnet_ids=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].SubnetId' \
    --output text)

echo " Step 2: Delete each subnet"
for subnet_id in $subnet_ids; do
    aws ec2 delete-subnet --subnet-id $subnet_id
done
}

# Function to remove Security Groups with tag key 'permanent' when the value is 'false'
detach_all_internet_gateways_and_remove_those_and_remove_all_vpcs() {
    echo "Detaching all internet gateways from all VPCs..."
    # Get all VPCs
    vpc_ids=$(aws ec2 describe-vpcs --filters "Name=tag:permanent,Values=false" --query 'Vpcs[*].VpcId' --output text)
    # Detach internet gateways from each VPC
    for vpc_id in $vpc_ids; do
        # List internet gateways attached to the VPC
        igw_ids=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[*].InternetGatewayId' --output text)
        # Detach each internet gateway from the VPC
        for igw_id in $igw_ids; do
            aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
            echo "Internet gateway $igw_id detached from VPC $vpc_id."
            aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
            echo "Internet gateway $igw_id deleted."
	    delete_all_routs-from_routh_tabel_by_vpcid
	done
	    clean_all_subnets
            aws ec2 delete-vpc --vpc-id $vpc_id
            echo "VPC $vpc_id deleted."
    done
}

remove_security_group_ids_and_rds(){
    echo "Step 1: Identify the security group(s) with the specified tag"
    security_group_ids=$(aws ec2 describe-security-groups \
        --filters "Name=tag:permanent,Values=false" \
        --query 'SecurityGroups[*].GroupId' \
        --output text)

    echo "Step 2: Delete each security group"
    for sg_id in $security_group_ids; do
        aws ec2 delete-security-group --group-id $sg_id
    done

    echo " Step 1: Identify the RDS instance(s) with the specified tag"
    instance_identifiers=$(aws rds describe-db-instances \
        --filters "Name=tag:permanent,Values=false" \
        --query 'DBInstances[*].DBInstanceIdentifier' \
        --output text)

    echo " Step 2: Delete each RDS instance"
    for instance_id in $instance_identifiers; do
        aws rds delete-db-instance --db-instance-identifier $instance_id --skip-final-snapshot
    done
}

# Main cleanup function
cleanup() {
	cleanup_instances
 	cleanup_security_groups
 	detach_all_internet_gateways_and_remove_those_and_remove_all_vpcs
	remove_security_group_ids_and_rds
}

# Execute cleanup function
cleanup

echo "Cleanup complete!"
