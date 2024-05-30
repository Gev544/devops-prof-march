#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Function to delete EC2 instances
delete_ec2_instances() {
    echo "Deleting EC2 instances..."
    instance_ids=$(aws ec2 describe-instances --query 'Reservations[*].Instances[?Tags[?Key!=`permanent`]].InstanceId' --output text)
    if [ -n "$instance_ids" ]; then
        for id in $instance_ids; do
            aws ec2 terminate-instances --instance-ids $id || handle_error "Failed to delete EC2 instance $id."
        done
    else
        echo "No EC2 instances found to delete."
    fi
}

# Function to delete VPCs, subnets, and internet gateways
delete_network_resources() {
    echo "Deleting VPCs, subnets, and internet gateways..."
    vpc_ids=$(aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key!=`permanent`]].VpcId' --output text)
    if [ -n "$vpc_ids" ]; then
        for vpc_id in $vpc_ids; do
            aws ec2 delete-vpc --vpc-id $vpc_id || handle_error "Failed to delete VPC $vpc_id."
        done
    else
        echo "No VPCs found to delete."
    fi
}

# Function to delete subnets
delete_subnets() {
    echo "Deleting subnets..."
    subnet_ids=$(aws ec2 describe-subnets --query 'Subnets[?Tags[?Key!=`permanent`]].SubnetId' --output text)
    if [ -n "$subnet_ids" ]; then
        for subnet_id in $subnet_ids; do
            aws ec2 delete-subnet --subnet-id $subnet_id || handle_error "Failed to delete subnet $subnet_id."
        done
    else
        echo "No subnets found to delete."
    fi
}

# Function to delete internet gateways
delete_internet_gateways() {
    echo "Deleting internet gateways..."
    igw_ids=$(aws ec2 describe-internet-gateways --query 'InternetGateways[?Tags[?Key!=`permanent`]].InternetGatewayId' --output text)
    if [ -n "$igw_ids" ]; then
        for igw_id in $igw_ids; do
            aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id || handle_error "Failed to detach internet gateway $igw_id."
            aws ec2 delete-internet-gateway --internet-gateway-id $igw_id || handle_error "Failed to delete internet gateway $igw_id."
        done
    else
        echo "No internet gateways found to delete."
    fi
}

# Function to delete route tables
delete_route_tables() {
    echo "Deleting route tables..."
    route_table_ids=$(aws ec2 describe-route-tables --query 'RouteTables[?Tags[?Key!=`permanent`]].RouteTableId' --output text)
    if [ -n "$route_table_ids" ]; then
        for route_table_id in $route_table_ids; do
            aws ec2 delete-route-table --route-table-id $route_table_id || handle_error "Failed to delete route table $route_table_id."
        done
    else
        echo "No route tables found to delete."
    fi
}

# Function to delete security groups
delete_security_groups() {
    echo "Deleting security groups..."
    security_group_ids=$(aws ec2 describe-security-groups --query 'SecurityGroups[?Tags[?Key!=`permanent`]].GroupId' --output text)
    if [ -n "$security_group_ids" ]; then
        for sg_id in $security_group_ids; do
            aws ec2 delete-security-group --group-id $sg_id || handle_error "Failed to delete security group $sg_id."
        done
    else
        echo "No security groups found to delete."
    fi
}

# Function to delete RDS instances
delete_rds_instances() {
    echo "Deleting RDS instances..."
    db_instance_ids=$(aws rds describe-db-instances --query 'DBInstances[?DBInstanceStatus==`available`].[DBInstanceIdentifier]' --output text | while read -r db_instance_id; do
        if ! aws rds list-tags-for-resource --resource-name arn:aws:rds:us-west-2:123456789012:db:$db_instance_id --output text | grep -q -v 'permanent'; then
            echo $db_instance_id
        fi
    done)
    if [ -n "$db_instance_ids" ]; then
        for db_instance_id in $db_instance_ids; do
            aws rds delete-db-instance --db-instance-identifier $db_instance_id --skip-final-snapshot || handle_error "Failed to delete RDS instance $db_instance_id."
        done
    else
        echo "No RDS instances found to delete."
    fi
}

# Main cleanup script
delete_ec2_instances
delete_network_resources
delete_subnets
delete_internet_gateways
delete_route_tables
delete_security_groups
delete_rds_instances
echo "Cleanup completed successfully."
