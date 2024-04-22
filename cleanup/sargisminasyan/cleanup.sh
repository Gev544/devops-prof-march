#!/bin/bash

#clean up all EC2 instances whish not contains permanent

# Get instance IDs where the tag value is not equal to "permanent"
instance_ids=$(aws ec2 describe-instances --query 'Reservations[].Instances[?Tags[?Key==`state` && Value!=`permanent`]].InstanceId' --output text)
echo $instance_ids
# Check if there are any instances to terminate
if [ -n "$instance_ids" ]; then
    # Terminate instances
    aws ec2 terminate-instances --instance-ids $instance_ids
else
    echo "No instances found with tag value not equal to 'nano'."
fi


# Get all Vpv where the tag is not equal to "permanent"
vpc_ids=$(aws ec2 describe-vpcs --query 'Reservations[].Instances[?Tags[?Key==`state` && Value!=`permanent`]].InstanceId' --output text)
if [ -n "$vpc_ids" ]; then
	for vpc_id in $vpc_ids; do
		# Detouch internet Gateway
    		# Delete associated resources (subnets, route tables, etc.) first if needed
	    	# Then delete the VPC
    		aws ec2 delete-vpc --vpc-id $vpc_id
	    	echo "Deleted VPC: $vpc_id"
	done

else
    echo "No instances found with tag value not equal to 'nano'."
fi
