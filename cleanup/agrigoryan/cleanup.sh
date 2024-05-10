#!/bin/bash

VPC_IDS=$(aws ec2 describe-vpcs --query "Vpcs[?Tags[?Key=='Permanent' && Value!='true']].VpcId" --output text)

echo "VPC_IDS: ${VPC_IDS}"

for VPC_ID in $VPC_IDS; do
	./delete-vpc.sh $VPC_ID
done

