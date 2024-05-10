VPC_ID=$1

if [ -z $VPC_ID ]; then
	echo "No VPC Id provided";
	exit 1;
fi

INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" --query "Reservations[].Instances[].InstanceId" --output text)

echo "Terminating EC2 Instances"

if [ ! -z "$INSTANCE_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
fi

aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS

echo "All Ec2 Instances are terminated"

aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[].GroupId" --output text | xargs -n 1 aws ec2 delete-security-group --group-id


# Get Route Table IDs associated with the specified VPC
ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[].RouteTableId' --output text)

# Disassociate and delete each Route Table
for ROUTE_TABLE_ID in $ROUTE_TABLE_IDS; do
    # Get Subnet IDs associated with the Route Table
    SUBNET_IDS=$(aws ec2 describe-route-tables --route-table-id $ROUTE_TABLE_ID --query 'RouteTables[].Associations[?SubnetId!=`null`].SubnetId' --output text)
    
    # Disassociate the Route Table from each Subnet
    for SUBNET_ID in $SUBNET_IDS; do
        aws ec2 disassociate-route-table --association-id $(aws ec2 describe-route-tables --route-table-id $ROUTE_TABLE_ID --query "RouteTables[].Associations[?SubnetId=='$SUBNET_ID'].RouteTableAssociationId" --output text)
    done
    
    # Delete explicit routes associated with the Route Table
    # Fetch explicit route IDs
    EXPLICIT_ROUTE_IDS=$(aws ec2 describe-route-tables --route-table-id $ROUTE_TABLE_ID --query 'RouteTables[].Routes[?DestinationCidrBlock!=`local`].RouteTableId' --output text)

    # Delete each explicit route
    for EXPLICIT_ROUTE_ID in $EXPLICIT_ROUTE_IDS; do
        aws ec2 delete-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block $EXPLICIT_ROUTE_ID
    done
    
    # Delete the Route Table
    aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID
done

aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text | xargs -n 1 aws ec2 delete-subnet --subnet-id

aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text | xargs -n 1 aws ec2 detach-internet-gateway --internet-gateway-id --vpc-id $VPC_ID

aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text | xargs -n 1 aws ec2 delete-internet-gateway --internet-gateway-id

aws ec2 delete-vpc --vpc-id $VPC_ID

if [ $? -eq 0 ]; then
    echo "VPC deleted successfully"
else
    echo "Error: Failed to delete VPC"
    fi
