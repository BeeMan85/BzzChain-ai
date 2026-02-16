#-----------------------Providers-----------------------

provider "aws" {
    region = "ca-central-1"
  
}

provider "tailscale" {
  # Configuration options https://registry.terraform.io/providers/tailscale/tailscale/latest/docs
  api_key              = var.my_api_key
  tailnet              = var.tailnet_name
}