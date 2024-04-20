#!/bin/bash
aws ec2 terminate-instances --instance-ids $insctance_ec2_val
aws ec2 detach-internet-gateway --internet-gateway-id $internetGateWayId --vpc-id $vpcId_val
aws ec2 delete-internet-gateway --internet-gateway-id $internetGateWayId
aws ec2 delete-subnet --subnet-id $subnetId_val
aws ec2 delete-route-table --route-table-id $routeTable_val
aws ec2 delete-vpc --vpc-id $vpcId_val

echo sucsses delated 
