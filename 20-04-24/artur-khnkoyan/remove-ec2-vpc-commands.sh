#!/bin/bash
aws ec2 terminate-instances --instance-ids $instance_id
aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
aws ec2 delete-subnet --subnet-id $subnet_id
aws ec2 delete-route-table --route-table-id $rtb_id
aws ec2 delete-vpc --vpc-id $vpc_id
