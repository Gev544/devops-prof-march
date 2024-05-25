#!/bin/bash

echo "Starting create RDS db instance"
aws rds create-db-instance \
    --db-instance-identifier db_with_bash \
    --allocated-storage 20 \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --master-username user_cli \
    --master-user-password password_cli \
    --backup-retention-period 7 \
    --tags Key="permanent",Value="true"
    
if [ $? -eq 0 ]; then
    echo "RDS with MYSQL is created successfully"
else
    echo "ERROR creating RDS db instance."
fi
