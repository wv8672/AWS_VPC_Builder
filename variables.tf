#AWS Configurations
variable "access_key" {
     description = "Access key to AWS account"
     
}

variable "secret_key" {
     description = "Secret key to AWS account"
     
}

variable "region" {
  description = "VPC region"
  default     = "us-east-2"
  type        = string
}

####################################################################################################################

# create /16 VPC 
variable "cidr_block" {
  description = "VPC CIDR notation"
  default     = "10.0.0.0/16"
  type        = string
}

####################################################################################################################

# create /24 public subnet 
variable "public_subnet_cidr_block" {
  description = "Public subnet CIDR notation"
  default     = "10.0.1.0/24"
}

# create a /24 private subnet 
variable "private_subnet_cidr_block" {
  description = "Private subnet CIDR notation"
  default     = "10.0.2.0/24"
}

# customize external addresses
variable "external_cidr_block" {
  description = "Desktop IP"
  default     = "xx.xx.xx.xx/32"
}

####################################################################################################################

# set availibility zone
variable "availability_zone" {
  description = "Current availability zone"
  default     = "us-east-2a"
}

#####################################################################################################################


# instances 
# -------------------

# set AMI value for both instances 
variable "ami_id" {
  description = "The AMI used by the instance"
  default = "ami-0a63f96e85105c6d3"
}

# set instance type 
variable "instance_type" {
  description = "type of instance"
  default = "t2.micro"
}

# set key name 
variable "key_name" {
  description = "key_name for SSH"
  default = "capstone_forensics"
}
