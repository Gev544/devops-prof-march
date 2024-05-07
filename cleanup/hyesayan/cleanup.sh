#!/bin/bash

# Get resources where permanent is TRUE and delete them:
resources=(
    "instance Instances"
    "vpc Vpcs"
    "subnet Subnets"
    "internet-gateway InternetGateways"
    "route-table RouteTables"
    "security-group SecurityGroups"
)

for resource in "${resources[@]}"; do
    resource_type="${resource%% *}"
    resource_name="${resource#* }"

    resource_ids=$(aws ec2 describe-${resource_type}s --filters "Name=tag:permanent,Values=true" --query "${resource_name}[].ResourceId" --output text)

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
        else
            aws ec2 delete-${resource_type} --${resource_type}-id $resource_id
        fi
        if [ $? -eq 0 ]; then
            echo "${resource_type} with id: $resource_id is deleted"
            echo "--------------------------------------------------------"
        else
            echo "ERROR: ${resource_type} with id: $resource_id is not deleted"
        fi
    done
done
