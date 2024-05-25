#!/bin/bash
instance=$( aws ec2 run-instances --image-id ami-080e1f13689e07408 --count 1 --instance-type t2.micro --key-name testkeypair --security-group-ids sg-0263330b77ed1b840 --subnet-id subnet-028bb1998891370d8 )
sleep 3
instanceID=$( aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --filters "Name=instance-state-name,Values=pending" --output text )
echo "EC2 deployed with ID: $instanceID"
while true; 
do
    instanceState=$( aws ec2 describe-instances --instance-ids $instanceID --query 'Reservations[*].Instances[*].[State.Name]' --output text )
    if [ "$instanceState" == "running" ]; then
        stop=$( aws ec2 stop-instances --instance-ids $instanceID )
        echo "Instance $instanceID has been stopped."
        break
    else
        echo "Instance $instanceID is currently in state: $instanceState"
        sleep 5
    fi
done
sleep 10
Delete=$( aws ec2 terminate-instances --instance-ids $instanceID )
echo "instane with ID : $instanceID Has been removed succesfully"
