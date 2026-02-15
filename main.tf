terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

#-----------------------Providers-----------------------

provider "aws" {
    region = "ca-central-1"
  
}

#-----------------------Data-----------------------

# Get the default VPC Reference from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpc" "default" {
  default = true
}

# Get the default subnets Reference from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the CIDR of the AWS subnet Reference from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet
data "aws_subnet" "selected" {
  id = data.aws_subnets.default.ids[0]
}

#-----------------------Resources-----------------------

resource "aws_instance" "tailscale-subnet-router" {
    ami = "ami-0631168b8ae6e1731" # Ubuntu Server 22.04 LTS // ca-central-1
    instance_type = "t3.micro"
    # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
    subnet_id = data.aws_subnets.default.ids[0]
    # cloud init file found in https://www.youtube.com/watch?v=PEoMmZOj6Cg&list=PLbKN2w7aG8EIbpIcZ2iGGsFTIZ-zMqLOn&t=10s
    user_data = templatefile("cloud-init/AWS-Ubuntu.tftpl", {
        tailscale_auth_key = var.tailscale_auth_key 
        tailscale_subnet_region_A = data.aws_subnet.selected.cidr_block
    })
  
}

# to do next: how to approve the subnet route from terraform? https://tailscale.com/kb/1111/terraform/#approve-subnet-routes