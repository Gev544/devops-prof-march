# Configure inbound rules for the security group to allow inbound traffic to the MySQL port (typically port 3306)
aws ec2 authorize-security-group-ingress \
    --group-id "$security_group_id" \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0

#create RDS and attaching security group for accessing 3306 port
instance_rds_val=$(aws rds create-db-instance \
    --db-instance-identifier mymysqlinstance \
    --db-instance-class db.t2.micro \
    --engine mysql \
    --allocated-storage 20 \
    --db-name mydatabase \
    --master-username admin \
    --master-user-password myadmin \
    --vpc-security-group-ids "$security_group_id" \
    --no-publicly-accessible \
    --tag-specifications "ResourceType=instance,Tags=[{Key=permanent,Value=false}]" \
    --query 'DBInstances[].DBInstanceIdentifier' \
    --output text)

if [ -n "$instance_rds_val" ]; then
        echo "create and run a new RDS instance "
else
        echo "Faild to create run a new RDS instanceC"
        exit 1
fi
