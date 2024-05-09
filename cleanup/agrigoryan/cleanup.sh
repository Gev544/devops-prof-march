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

aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text | xargs -n 1 aws ec2 detach-internet-gateway --internet-gateway-id

aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text | xargs -n 1 aws ec2 delete-internet-gateway --internet-gateway-id

aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[].GroupId" --output text | xargs -n 1 aws ec2 delete-security-group --group-id

aws ec2 delete-vpc --vpc-id $VPC_ID

if [ $? -eq 0 ]; then
    echo "VPC deleted successfully"
else
    echo "Error: Failed to delete VPC"
fi
