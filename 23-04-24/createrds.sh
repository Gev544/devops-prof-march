#!/bin/bash

# AWS Region
region="us-west-2"

# RDS instance details
db_instance_identifier="my-rds-instance"
db_instance_class="db.t2.micro"
engine="mysql"
engine_version="5.7.30"
db_name="mydatabase"
db_username="myuser"
db_password="mypassword"

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier $db_instance_identifier \
    --db-instance-class $db_instance_class \
    --engine $engine \
    --engine-version $engine_version \
    --allocated-storage 20 \
    --db-name $db_name \
    --master-username $db_username \
    --master-user-password $db_password \
    --region $region

# Wait for the instance to be available
aws rds wait db-instance-available --db-instance-identifier $db_instance_identifier

# Get the endpoint of the new instance
endpoint=$(aws rds describe-db-instances --db-instance-identifier $db_instance_identifier --query 'DBInstances[0].Endpoint.Address' --output text)

echo "RDS instance created successfully."
echo "Endpoint: $endpoint"
