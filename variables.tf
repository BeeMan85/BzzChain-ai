variable "tailscale_auth_key" {
    description = "Tailscale Authentication Key"
    type        = string
    sensitive   = true
}
# reference of sensitive variables from https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables
