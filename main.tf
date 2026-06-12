


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
 hostname = "tailscale-subnet-router-${local.final_hostname}"
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
#key for "AWS region" machines
resource "tailscale_tailnet_key" "tailnet_key_aws" {
  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 3600
  description   = "Ephemeral key for Terraform provisioning"
  tags          =  ["tag:aws" ]
#need to make sure the ACL is created before the key so that the tags are in place for the key, otherwise the machines will not get tagged and the ACL will not apply to them, which will cause issues with access and connectivity.
  depends_on    = [tailscale_acl.main_acl]
}

#key for "GCP region" machines
resource "tailscale_tailnet_key" "tailnet_key_gcp" {
  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 3600
  description   = "Ephemeral key for Terraform provisioning"
  tags          =  ["tag:gcp" ]
  #need to make sure the ACL is created before the key so that the tags are in place for the key, otherwise the machines will not get tagged and the ACL will not apply to them, which will cause issues with access and connectivity.
  depends_on    = [tailscale_acl.main_acl]
}

####################################################################
# ----------------------Tailscale ACL Policy-----------------------#
####################################################################
#you cannot just run this acl because you will get the error ! You seem to be trying to overwrite a non-default policy file with a tailscale_acl resource.
#Before doing this, please import your existing policy file into Terraform state using:
#terraform import $(this_resource) acl
#(got error "precondition failed, invalid old hash (412)")
# to get around this I set the "overwrite_existing_content" argument to true, but be aware that this will overwrite your existing ACL policy in the Tailscale admin console, so use with caution and make sure to back up your existing policy if you have one.

resource "tailscale_acl" "main_acl" {
  overwrite_existing_content = true
  reset_acl_on_destroy = true
  acl = jsonencode({
    // Define users and devices that can use Tailscale SSH.
	"ssh": [
		// Allow all users to SSH into their own devices in check mode.
		// Comment this section out if you want to define specific restrictions.
		{
			"action": "check",
			"src":    ["autogroup:member"],
			"dst":    ["autogroup:self"],
			"users":  ["autogroup:nonroot", "root"],
		},
	],
// Define tags for devices based on their group membership. This allows you to create dynamic groups and policies based on these tags.
	"tagOwners": {
		"tag:aws": ["autogroup:admin"],
		"tag:gcp": ["autogroup:admin"],
	},
"grants": [
		// Allow all connections.
		// Comment this section out if you want to define specific restrictions.
		//{
		//	"src": ["*"],
		//	"dst": ["*"],
		//	"ip":  ["*"],
		//},
    //allow aws tagged machines to acess gcp tagged machines.
		{
			"src": ["tag:aws"],
			"dst": ["tag:gcp"],
			"ip":  ["*"],
		}
],
    //Grant access dynamically using AWS subnet data source
    "acls": [
      {
        "action": "accept",
        "src":    ["autogroup:admin"], 
        // Inject the dynamic CIDR block here
        "dst":    ["${data.aws_subnet.selected.cidr_block}:*"] 
      }
    ]
  })
}

####################################################################
# ----------------------AWS Requirements Prep----------------------#
####################################################################
#generate a random name for the subnet router instance
resource "random_pet" "server_name_a" {
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

# ----------------- "Demo AWS region" ------------------- #

#create the subnet router machine in AWS with the cloud init file to connect to tailscale and advertise the subnet route
resource "aws_instance" "tailscale-subnet-router" {
    ami = "ami-09547c8673abb0190" # Amazon Linux // ca-central-1
    instance_type = "t3.micro"
    tags = {
  Name = "tailscale-subnet-router-${local.final_hostname}" 
}
    # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
    subnet_id = data.aws_subnets.default.ids[0]
    # cloud init file generated by the tailscale cloud init module to connect to tailscale and advertise the subnet route, also enables SSH access and sets the hostname
    user_data_base64 = module.tailscale_cloud_init_AWS_Linux.rendered
  
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

# ----------------- "Demo GCP region" ------------------- #

#create the subnet router machine in AWS with the cloud init file to connect to tailscale
resource "aws_instance" "tailscale-gcp-database" {
    ami = "ami-09547c8673abb0190" # Amazon Linux // ca-central-1
    instance_type = "t3.micro"
    tags = {
  Name = "gcp-database-${local.final_hostname}" 
}
    # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
    subnet_id = data.aws_subnets.default.ids[0]
    # cloud init file generated by the tailscale cloud init module to connect to tailscale and advertise the subnet route, also enables SSH access and sets the hostname
    user_data_base64 = module.tailscale_cloud_init_GCP_Linux.rendered
  
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
