#!/bin/bash

echo "Script started!"
# Get Security Group with tag key 'for-rds'
sg_id=$(aws ec2 describe-security-groups --filters "Name=tag:for-rds,Values=true" --query 'SecurityGroups[*].GroupId' --output text)
echo "Security group ID: $sg_id"

aws rds create-db-instance \
   --db-instance-identifier testdbinstance \
   --db-instance-class db.t3.micro \
   --engine mysql \
   --master-username admin \
   --master-user-password adminadmin \
   --allocated-storage 20 \
   --db-name testDb \
   --backup-retention-period 7 \
   --vpc-security-group-ids sg_id \
   --port 3306 \
   --engine-version 8.0.36
   
"Script Completed!"
