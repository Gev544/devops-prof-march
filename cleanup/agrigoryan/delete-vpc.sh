VPC_ID=$1

if [ -z $VPC_ID ]; then
        echo "No VPC Id provided";
        exit 1;
fi
echo "starting to delete VPC with id ${VPC_ID}"

INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=${VPC_ID}" --query "Reservations[].Instances[].InstanceId" --output text)

if [ ! -z "$INSTANCE_IDS" ]; then
    echo "Instance Ids: ${INSTANCE_IDS}"
    echo "Terminating EC2 Instances"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
    echo "All Ec2 Instances are terminated"
fi


SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${VPC_ID}" --query "SecurityGroups[].GroupId" --output text)

echo "SECURITY_GROUP_IDS: ${SECURITY_GROUP_IDS}"
for SECURITY_GROUP_ID in $SECURITY_GROUP_IDS; do
  aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID
  echo "Deleted security group: ${SECURITY_GROUP_ID}"
done

echo "Deleting Subnets"

SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[].SubnetId" --output text)

echo "SUBNET_IDS: ${SUBNET_IDS}"

for SUBNET_ID in $SUBNET_IDS; do
  aws ec2 delete-subnet --subnet-id $SUBNET_ID
  echo "Deleted subnet: ${SUBNET_ID}"
done

echo "Detaching and deleting internet getaways"

IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --query "InternetGateways[].InternetGatewayId" --output text)

echo "Internet Getaway ids: ${IGW_IDS}"

for IGW_ID in $IGW_IDS; do
  aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
  echo "Detached Internet Getaway ${IGW_ID}"
  aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
  echo "Deleted Internet Getaway ${IGW_ID}"
 done

 echo "Deleting route Tables"

ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" "Name=route.origin,Values=CreateRoute,EnableVgwRoutePropagation" --query "RouteTables[].RouteTableId" --output text)

echo "Route Table Ids: ${ROUTE_TABLE_IDS}"

for ROUTE_TABLE_ID in $ROUTE_TABLE_IDS; do
  aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID
  echo "Deleted route table: ${ROUTE_TABLE_ID}"
done

echo "Deleting Vpc with id ${VPC_ID}"
aws ec2 delete-vpc --vpc-id $VPC_ID

if [ $? -eq 0 ]; then
    echo "VPC with id ${VPC_ID} deleted successfully"
else
    echo "Error: Failed to delete VPC with id ${VPC_ID}"
    fi
