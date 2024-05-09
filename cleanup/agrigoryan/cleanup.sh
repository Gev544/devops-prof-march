VPC_ID=$1

if [ -z $VPC_ID ]; then
	echo "No VPC Id provided";
	exit 1;
fi

INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" --query "Reservations[].Instances[].InstanceId" --output text)

if [ ! -z "$INSTANCE_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
fi

aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS

aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text | xargs -n 1 aws ec2 delete-subnet --subnet-id
echo "Step 1: Get the Route Table ID(s) associated with the VPC"
route_table_ids=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[*].RouteTableId' \
    --output text)

echo " Step 2: For each Route Table ID, get the list of routes and delete them"
for rt_id in $route_table_ids; do
    routes=$(aws ec2 describe-route-tables \
        --route-table-id $rt_id \
        --query 'RouteTables[*].Routes[?DestinationCidrBlock != `local`].DestinationCidrBlock' \
        --output text)

echo    "# Step 3: Delete each route from the route table"
    for route in $routes; do
        aws ec2 delete-route \
            --route-table-id $rt_id \
            --destination-cidr-block $route
    done
done

aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text | xargs -n 1 aws ec2 detach-internet-gateway --internet-gateway-id --vpc-id $VPC_ID

aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text | xargs -n 1 aws ec2 delete-internet-gateway --internet-gateway-id

aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[].GroupId" --output text | xargs -n 1 aws ec2 delete-security-group --group-id

aws ec2 delete-vpc --vpc-id $VPC_ID

if [ $? -eq 0 ]; then
    echo "VPC deleted successfully"
else
    echo "Error: Failed to delete VPC"
fi:
