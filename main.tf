terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
        tailscale = {
            source = "tailscale/tailscale"
            version = "0.27.0"
        }
    }
}

#-----------------------Providers-----------------------

provider "aws" {
    region = "ca-central-1"
  
}

provider "tailscale" {
  # Configuration options https://registry.terraform.io/providers/tailscale/tailscale/latest/docs
  oauth_client_id      = var.my_client_id
  oauth_client_secret  = var.my_client_secret
  tailnet              = var.tailnet_name
}
#-----------------------Modules-----------------------

module "tailscale_cloud_init_AWS_Ubuntu" {
  source  = "tailscale/tailscale/cloudinit"
  version = "0.0.11"
  auth_key = var.tailscale_auth_key
  advertise_routes = [data.aws_subnet.selected.cidr_block]
  # Configuration options https://registry.terraform.io/modules/tailscale/cloudinit/tailscale/latest/docs
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
    user_data = module.tailscale_cloud_init_AWS_Ubuntu.rendered
  
}

# to do next: how to approve the subnet route from terraform? https://tailscale.com/kb/1111/terraform/#approve-subnet-routes
# add the tailscale cloud init terraform module