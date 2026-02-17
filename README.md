# [Project Name]

[Short description: 1-2 sentences explaining what this project does. Example: "A Terraform demo that deploys a secure internal dashboard accessible only via Tailscale."]

## Architecture

[Insert a screenshot or a Mermaid diagram here. Visually show how the user connects to the resources.]
![Tailnet and AWS diagram](https://github.com/user-attachments/assets/8002894f-395b-4b16-b9c2-c6fab339cdc2)


## Prerequisites

### Services
- [ ] API access to AWS VPC running in Canada (Central) [ca-central-1] with permissions to:
    - [ ] Create ec2 instances
    - [ ] Create security groups
- [ ] Tailnet running in tailscale with API access    

### Software
- [ ] Terraform
- [ ] AWS CLI
- [ ] Tailscale client installed and running on local machine

### Information or pre-completed steps
- [ ] Have created a Tailscale API key with proper permissions, and have the key on hand.
- [ ] Have the exact name of your Tailnet
- [ ] Have run `aws configure` [as shown in this blog post](https://medium.com/@shanmorton/set-up-terraform-tf-and-aws-cli-build-a-simple-ec2-1643bcfcb6fe) to create the AWS Shared Credentials file in your home directory.


## Quick Start

### 1. Clone or download repository
Either clone or download repo to a location that Terraform has access to.

### 2. Configure access and secrets
Create a copy of the file `terraform.tfvars.example` and rename to `terraforn.tfvars`. Edit the file to uncomment your tailscale API key and tailnet name, optionally you can skip this step and Terraform will ask you for those variables on each run.

### 3. Deploy
Navigate into the directory in your CLI and run:
- `terraform init` - Prepare the files and directories terraform needs, as well as install the required plugins.
- `terraform plan` - Ccheck code for errors, plan the order of operations etc.
- `terraform apply` - Trigger the creation of resources etc, this is when terraform will "make the things".
- `terraform destroy` - Remove all the resources and configurations that terraform performed in apply.


## Verification

[Step-by-step instructions on how to prove it worked. Example: "Ping this IP," "Visit this URL," or "Check your Tailscale admin console"]

## How It Works

[Brief explanation of the "magic." Explain specific design choices, like using `user_data` for boot scripts or how the networking is configured.]

## Configuration Reference

[A table or list of the main variables the user can change, like `region`, `instance_type`, or `vpc_cidr`]

## Clean Up

[The command to destroy resources (`terraform destroy`) to avoid costs]

## References

[Links to official documentation or blog posts that helped build this]
