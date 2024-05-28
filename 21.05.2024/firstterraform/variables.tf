variable "region" {
  description = "The AWS region to create resources in"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "The type of EC2 instance"
  default     = "t2.micro"
}

variable "ami" {
  description = "The AMI ID for the EC2 instance"
  default     = "ami-04b70fa74e45c3917"  # Replace with your desired AMI ID
}

variable "key_name" {
  description = "The key pair name to access the EC2 instance"
  default     = "newars"  # Replace with your key pair
}

