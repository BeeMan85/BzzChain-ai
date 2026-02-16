


####################################################################
# -------------------------Data and Locals-------------------------#
####################################################################

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

# Get the device ID of the Tailscale subnet router for the subnet routes resource from https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/data-sources/device
data "tailscale_device" "subnet-router-a" {
 hostname = local.final_hostname
 wait_for = "120s"
#  make sure these run in the correct order so the device is created before we try to get the device ID for the subnet routes resource
 depends_on = [aws_instance.tailscale-subnet-router]
}

locals {
  # Set the hostname
  final_hostname = random_pet.server_name_a.id
}

######################################################################################################
######################################################################################################
# -----------------------------------------------Resources-------------------------------------------#
######################################################################################################
######################################################################################################

####################################################################
# -----------------------Auth Key Generation-----------------------#
####################################################################
#instead of hard coding the auth key in the UI, we can generate it with terraform and pass it to the cloud init module
resource "tailscale_tailnet_key" "tailnet_key" {
  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 3600
  description   = "Ephemeral key for Terraform provisioning"
}


####################################################################
# ----------------------AWS Requirements Prep----------------------#
####################################################################
#generate a random name for the subnet router instance
resource "random_pet" "server_name_a" {
  prefix = "subnet-router"
  length = 2
}


# Create the Security Group for web server
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP from internal subnet router"
  vpc_id      = data.aws_vpc.default.id

  # INBOUND RULE (Ingress)
  ingress {
    description = "HTTP from Subnet Router"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    
    # allow local LAN traffic
    cidr_blocks = [data.aws_subnet.selected.cidr_block] 
  }

  # OUTBOUND RULE 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


####################################################################
# -----------------------Create AWS machines-----------------------#
####################################################################


#create the subnet router machine in AWS with the cloud init file to connect to tailscale and advertise the subnet route
resource "aws_instance" "tailscale-subnet-router" {
    ami = "ami-09547c8673abb0190" # Amazon Linux // ca-central-1
    instance_type = "t3.micro"
    tags = {
  Name = "tailscale-subnet-router-${local.final_hostname}" 
}
    # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
    subnet_id = data.aws_subnets.default.ids[0]
    # cloud init file found in https://www.youtube.com/watch?v=PEoMmZOj6Cg&list=PLbKN2w7aG8EIbpIcZ2iGGsFTIZ-zMqLOn&t=10s
    user_data_base64 = module.tailscale_cloud_init_AWS_Ubuntu.rendered
  
}

#create the webserver to serve the test page
resource "aws_instance" "aws-webserver" {
    ami = "ami-09547c8673abb0190" # Amazon Linux // ca-central-1
    instance_type = "t3.micro"
    tags = {
  Name = "aws-webserver-${local.final_hostname}" 
}
    # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
    subnet_id = data.aws_subnets.default.ids[0]
    # attach firewall rule
    vpc_security_group_ids = [aws_security_group.web_server_sg.id]
    # install a web server and create a simple site https://medium.com/@aravind-cloud/launch-an-ec2-instance-and-host-a-web-page-86a5b00e903c
    user_data = file("${path.module}/scripts/install_webserver.sh")
   
  
}

####################################################################
# --------------------Approve the subnet router--------------------#
####################################################################


# example from https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/device_subnet_routes
resource "tailscale_device_subnet_routes" "sample_routes" {
  # approves the route so that traffic can flow without user intervension.
  device_id = data.tailscale_device.subnet-router-a.node_id
  routes = [
    data.aws_subnet.selected.cidr_block
  ]
}
