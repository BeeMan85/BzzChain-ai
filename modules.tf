#-----------------------Modules-----------------------

# Generate the cloud init file for the AWS instance to connect to Tailscale and advertise the subnet route, also enables SSH access and sets the hostname
module "tailscale_cloud_init_AWS_Linux" {
  source  = "tailscale/tailscale/cloudinit"
  version = "0.0.11"
  auth_key = resource.tailscale_tailnet_key.tailnet_key_aws.key
  advertise_routes = [data.aws_subnet.selected.cidr_block]
  enable_ssh = true
  # Set the hostname to the random pet name generated in the locals block so we can easily identify the machine in the Tailscale admin console and also use it for the device ID data source to approve the subnet route for the correct machine.
  hostname = "aws-subnet-router-${local.final_hostname}"
  # lost many hairs to the fact that ubuntu does like to let you set the hostname this way, so switched to AWS Linux... 
  # Configuration options https://registry.terraform.io/modules/tailscale/cloudinit/tailscale/latest/docs
}

# Generate the cloud init file for the "GCP region" machine to connect to Tailscale
module "tailscale_cloud_init_GCP_Linux" {
  source  = "tailscale/tailscale/cloudinit"
  version = "0.0.11"
  auth_key = resource.tailscale_tailnet_key.tailnet_key_gcp.key
  enable_ssh = true
  # Set the hostname to the random pet name generated in the locals block so we can easily identify the machine in the Tailscale admin console.
  hostname = "gcp-database-${local.final_hostname}"
  # lost many hairs to the fact that ubuntu does like to let you set the hostname this way, so switched to AWS Linux... 
  # Configuration options https://registry.terraform.io/modules/tailscale/cloudinit/tailscale/latest/docs
}
