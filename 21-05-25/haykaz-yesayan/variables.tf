variable "aws_region" {
  description = "The AWS region to create resources in."
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet."
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet."
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "The EC2 instance type."
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the key pair to use for the instance."
  default     = "key_for_ansible"
}

