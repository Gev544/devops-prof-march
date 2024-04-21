#!/bin/bash

##### CLEAN UP #####
# Terminating the Instance
aws ec2 terminate-instances --instance-ids $instance_id

# Deleting the Security Group
aws ec2 delete-security-group --group-id $sg_id

# Detaching the Internet Gateway from VPC
aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id

# Deleting the Internet Gateway 
aws ec2 delete-internet-gateway --internet-gateway-id $igw_id

# Deleting the Public Subnet
aws ec2 delete-subnet --subnet-id $subnet_id

# Deleting Route Table
aws ec2 delete-route-table --route-table-id $rtb_id

# Deleting the VPC
aws ec2 delete-vpc --vpc-id $vpc_id
