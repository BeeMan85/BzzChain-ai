variable "tailscale_auth_key" {
    description = "Tailscale Authentication Key"
    type        = string
    sensitive   = true
}
# reference of sensitive variables from https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables

variable "my_client_id" {
    description = "Tailscale Client ID"
    type        = string
    sensitive   = true
}

variable "my_client_secret" {
    description = "Tailscale Client Secret"
    type        = string
    sensitive   = true
}

variable "tailnet_name" {
    description = "Tailscale Tailnet Name"
    type        = string
    sensitive   = false
}
