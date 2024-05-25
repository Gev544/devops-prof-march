#!/bin/bash

# Define resources to check and delete
resources=(
    "instance Instances"
    "vpc Vpcs"
    "subnet Subnets"
    "internet-gateway InternetGateways"
    "route-table RouteTables"
    "security-group SecurityGroups"
)

delete_vpc_dependencies() {
    vpc_id=$1

    # Delete subnets
    subnet_ids=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query "Subnets[*].SubnetId" --output text)
    for subnet_id in $subnet_ids; do
        echo "Deleting subnet with id: $subnet_id"
        aws ec2 delete-subnet --subnet-id $subnet_id
    done

    # Delete route tables
    route_table_ids=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query "RouteTables[*].RouteTableId" --output text)
    for route_table_id in $route_table_ids; do
        echo "Deleting route-table with id: $route_table_id"
        aws ec2 delete-route-table --route-table-id $route_table_id
    done

    # Detach and delete internet gateways
    internet_gateway_ids=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query "InternetGateways[*].InternetGatewayId" --output text)
    for igw_id in $internet_gateway_ids; do
        echo "Detaching internet-gateway $igw_id from VPC $vpc_id"
        aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
        echo "Deleting internet-gateway with id: $igw_id"
        aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
    done

    # Delete security groups (except the default one)
    security_group_ids=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
    for sg_id in $security_group_ids; do
        echo "Deleting security-group with id: $sg_id"
        aws ec2 delete-security-group --group-id $sg_id
    done
}

# Loop through each resource type
for resource in "${resources[@]}"; do
    resource_type="${resource%% *}"
    resource_name="${resource#* }"

    # Determine the correct query key based on the resource type
    case $resource_type in
        instance)
            query_key="Instances[*].InstanceId"
            ;;
        vpc)
            query_key="Vpcs[*].VpcId"
            ;;
        subnet)
            query_key="Subnets[*].SubnetId"
            ;;
        internet-gateway)
            query_key="InternetGateways[*].InternetGatewayId"
            ;;
        route-table)
            query_key="RouteTables[*].RouteTableId"
            ;;
        security-group)
            query_key="SecurityGroups[*].GroupId"
            ;;
        *)
            echo "Unknown resource type: $resource_type"
            continue
            ;;
    esac

    # Construct the command to fetch resource IDs
    command="aws ec2 describe-${resource_type}s --filters \"Name=tag:permanent,Values=true\" --query \"${query_key}\" --output text"

    # Debugging: print the command being run
    echo "Running: $command"

    # Fetch resource IDs
    resource_ids=$(eval $command)

    # Debugging: print the fetched IDs
    echo "Fetched IDs for ${resource_type}: $resource_ids"

    if [ -z "$resource_ids" ]; then
        echo "No ${resource_type}s found with 'permanent' tag set to 'true'."
        continue
    fi

    for resource_id in $resource_ids; do
        if [ "$resource_id" == "None" ]; then
            echo "Skipping ${resource_type} deletion as the ID is 'None'."
            continue
        fi

        echo "Deleting ${resource_type} with id: $resource_id"
        if [ "$resource_type" == "instance" ]; then
            echo "Terminating instance with id: $resource_id"
            aws ec2 terminate-instances --instance-ids $resource_id
        elif [ "$resource_type" == "vpc" ]; then
            delete_vpc_dependencies $resource_id
            aws ec2 delete-vpc --vpc-id $resource_id
        elif [ "$resource_type" == "internet-gateway" ]; then
            # Detach the internet gateway from any VPCs before deleting i
            vpc_id=$(aws ec2 describe-internet-gateways --internet-gateway-ids $resource_id --query "InternetGateways[0].Attachments[0].VpcId" --output text)
            if [ "$vpc_id" != "None" ]; then
                echo "Detaching internet-gateway $resource_id from VPC $vpc_id"
                aws ec2 detach-internet-gateway --internet-gateway-id $resource_id --vpc-id $vpc_id
            fi
            aws ec2 delete-internet-gateway --internet-gateway-id $resource_id
        elif [ "$resource_type" == "security-group" ]; then
            aws ec2 delete-security-group --group-id $resource_id
        else
            delete_command="aws ec2 delete-${resource_type} --${resource_type}-id $resource_id"
            echo "Running: $delete_command"
            $delete_command
        fi

        if [ $? -eq 0 ]; then
            echo "${resource_type} with id: $resource_id is deleted"
            echo "--------------------------------------------------------"
        else
            echo "ERROR: ${resource_type} with id: $resource_id is not deleted"
        fi
    done
done

