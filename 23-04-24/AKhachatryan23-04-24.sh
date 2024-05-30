#!/bin/bash

# Define variables
DB_INSTANCE_IDENTIFIER="mypostgresinstance"
DB_INSTANCE_CLASS="db.t3.micro"
ENGINE="postgres"
ALLOCATED_STORAGE=20
DB_NAME="mydatabase"
MASTER_USERNAME="myusername"
MASTER_PASSWORD="mypassword"
AVAILABILITY_ZONE="us-west-2b"
PORT=5432
BACKUP_RETENTION_PERIOD=7
PREFERRED_MAINTENANCE_WINDOW="Mon:05:00-Mon:06:00"
ROLLBACK_REQUIRED=0

# Function to handle errors
handle_error() {
    echo "Error: $1"
    rollback_actions
    exit 1
}

# Function to delete RDS instance
delete_rds_instance() {
    aws rds delete-db-instance \
        --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
        --skip-final-snapshot || echo "Failed to delete RDS instance."
}

# Function to delete VPC security group
delete_vpc_security_group() {
        aws ec2 delete-security-group \
            --group-id $SECURITY_GROUP_ID || echo "Failed to delete VPC security group."
}

# Function to delete DB subnet group
delete_db_subnet_group() {
        aws rds delete-db-subnet-group \
            --db-subnet-group-name mydbsubnetgroup || echo "Failed to delete DB subnet group."
}

# Function to rollback actions
rollback_actions() {
    case "$ROLLBACK_REQUIRED" in
        1)
            delete_vpc_security_group
            delete_db_subnet_group
            echo "subnet and sg is deleted"
            ;;
        2)
            delete_db_subnet_group
            echo "subnet is deleted"
            ;;
        *)
            echo "No rollback actions required."
            ;;
    esac
}

# Function to create DB subnet group
create_db_subnet_group() {
    aws rds create-db-subnet-group \
        --db-subnet-group-name mydbsubnetgroup \
        --db-subnet-group-description "My DB subnet group" \
        --subnet-ids subnet-07e84066b2944306d subnet-0814062a1eb5e29ea ||  handle_error "Failed to create DB subnet group."
}

# Function to create VPC security group
create_vpc_security_group() {
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name mysecuritygroup \
        --description "My security group" \
        --vpc-id vpc-044d9522a2c4e3a61 \
        --query 'GroupId' --output text) || { ROLLBACK_REQUIRED=2; handle_error "Failed to create VPC security group.";}
}

# Function to authorize inbound access to security group
authorize_security_group_ingress() {
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 5432 \
        --cidr 0.0.0.0/0 ||  handle_error "Failed to authorize security group ingress."
}

# Function to create RDS PostgreSQL instance
create_rds_instance() {
    aws rds create-db-instance \
        --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
        --db-instance-class $DB_INSTANCE_CLASS \
        --engine $ENGINE \
        --allocated-storage $ALLOCATED_STORAGE \
        --db-name $DB_NAME \
        --master-username $MASTER_USERNAME \
        --master-user-password $MASTER_PASSWORD \
        --vpc-security-group-ids $SECURITY_GROUP_ID \
        --availability-zone $AVAILABILITY_ZONE \
        --db-subnet-group-name mydbsubnetgroup \
        --port $PORT \
        --no-publicly-accessible \
        --backup-retention-period $BACKUP_RETENTION_PERIOD \
        --preferred-maintenance-window "$PREFERRED_MAINTENANCE_WINDOW" || { ROLLBACK_REQUIRED=1; handle_error "Failed to create RDS PostgreSQL instance."; }
}

# Main script execution
create_db_subnet_group
create_vpc_security_group
authorize_security_group_ingress
create_rds_instance

echo "RDS PostgreSQL instance created successfully."
