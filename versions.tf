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