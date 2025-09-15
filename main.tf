provider "aws" {
  region = "ap-south-1"
}

# Use existing VPC
data "aws_vpc" "vpc_existing" {
  filter {
    name   = "tag:Name"
    values = ["kind-vpc"]
  }
}

# Use existing Public Subnet
data "aws_subnet" "subnet_public" {
  filter {
    name   = "tag:Name"
    values = ["kind-public-subnet-1"]
  }

  vpc_id = data.aws_vpc.vpc_existing.id
}

# Use existing Security Group
data "aws_security_group" "sg_kind" {
  filter {
    name   = "group-name"
    values = ["kind-security-group"]
  }

  vpc_id = data.aws_vpc.vpc_existing.id
}


# Create instance in public subnet
resource "aws_instance" "kind" {
  ami                    = "ami-03bb6d83c60fc5f7c"
  instance_type          = "t2.medium"
  key_name               = "testing-dev-1"
  subnet_id              = data.aws_subnet.subnet_public.id
  vpc_security_group_ids = [data.aws_security_group.sg_kind.id]

   user_data              = file("kind.sh")

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name                               = "kind"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}

# Output Public IP
output "kind_public_ip" {
  description = "The Public IP address of the kind instance"
  value       = aws_instance.kind.public_ip
}
