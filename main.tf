# set AWS config vars [region / access / secret] 

provider "aws" {
      region     = var.region
      access_key = var.access_key
      secret_key = var.secret_key
}

########################################################################################################################

# create VPC 
resource "aws_vpc" "default" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name="dfir_vpc"
  }
}

# create internet gateway
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name="dfir_gw"
  }
}

########################################################################################################################

# create public subnet
resource "aws_subnet" "dfir_public_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name="dfir_public_subnet"
  }
}

# create private subnet
resource "aws_subnet" "dfir_private_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.private_subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name="dfir_private_subnet"
  }
}

#######################################################################################################################

# Public route table / route / route table association
# --------------------

# create route table (public)
resource "aws_route_table" "dfir_public_rt" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name="dfir_public_rt"
  }
}

# create route (public)
resource "aws_route" "public" {
  route_table_id         = aws_route_table.dfir_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# create route table association (public)
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.dfir_public_subnet.id
  route_table_id = aws_route_table.dfir_public_rt.id
}


# Private route table / route / route table association
# ---------------------

# create route table (private)
resource "aws_route_table" "dfir_private_rt" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name="dfir_private_rt"
  }
}

# create route (private)
resource "aws_route" "private" {
  route_table_id         = aws_route_table.dfir_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.dfir_nat_gw.id
}

# create route table association (private)
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.dfir_private_subnet.id
  route_table_id = aws_route_table.dfir_private_rt.id
}

######################################################################################################################

# create security group(s)


# create public security group. For instances inside pulic subnet
# allows inbound SSH connections from extenal desktop to Jumpbox
resource "aws_security_group" "public_sg" {
  name = "public_sg"
  description = "Public security group"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.external_cidr_block] 
  }
  
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.cidr_block] 
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  vpc_id = aws_vpc.default.id

  tags = {
    Name = "public_sg"
  }

}

# create private security group. For instances inside private subnet 
# allows SSH connections from other internal machones (vpc)
resource "aws_security_group" "private_sg" {
  name = "private_sg"
  description = "Private security group"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.cidr_block] 
  }
  
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  vpc_id = aws_vpc.default.id

  tags = {
    Name = "private_sg"
  }

}

#####################################################################################################################

# create elastic IP for NAT gateway
resource "aws_eip" "nat" {
  vpc = true
}

# create a NAT gateway in Public Subnet
resource "aws_nat_gateway" "dfir_nat_gw" {
  depends_on = [aws_internet_gateway.default]
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.dfir_public_subnet.id
}

#####################################################################################################################

# create instance(s)

# create ubuntu 18 server jump box in public subnet
resource "aws_instance" "dfir_jumpbox" {
  ami = var.ami_id
  availability_zone = var.availability_zone
  instance_type = var.instance_type
  subnet_id = aws_subnet.dfir_public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_sg.id] 
  key_name = var.key_name
  associate_public_ip_address = true
  source_dest_check = false
  tags = {
    Name = "dfir jumpbox"
  }
}

# create ubuntu 18 server compromised instance in private subnet
resource "aws_instance" "dfir_compromised_instance" {
  ami = var.ami_id
  availability_zone = var.availability_zone
  instance_type = var.instance_type
  subnet_id = aws_subnet.dfir_private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id] 
  key_name = var.key_name
  associate_public_ip_address = false
  source_dest_check = false
  tags = {
    Name = "dfir compromised instance"
  }
}