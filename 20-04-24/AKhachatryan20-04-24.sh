#!/bin/bash

aws ec2 create-key-pair --key-name devopstest --query 'DEVOPS' --output text > devopstestViaScript.pem
security_group=$(aws ec2 create-security-group --group-name script-sg-test --description "My security group test via script file" --vpc-id vpc-044d9522a2c4e3a61 --output text --query 'GroupId')
instance_id=$(aws ec2 run-instances --image-id ami-08116b9957a259459 --count 1 --instance-type t2.micro --key-name devopstest --security-group-ids $security_group --subnet-id subnet-0814062a1eb5e29ea --output text --query 'Instances[0].InstanceId')
aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=ec2ViaScript
sleep 120
aws ec2 terminate-instances --instance-ids $instance_id
