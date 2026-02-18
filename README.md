# [BzzChain.ai - POC of Tailscale subnet routing via Terraform]

This project showcases the elegance and simplicity of Tailscale, allowing access to remote resources (in this case running in AWS) without cumbersome site-to-site VPNs, or insecure firewall rules. It allows you to see how Tailscale securely allows access to devices and services even if they are not able to be joined to the tailnet.

## Architecture

This project creates two instances in the same AWS VPC subnet, the first acts as a Tailscale subnet router, allowing machines on the tailnet to connect with machines inside the AWS subnet not running Tailscale. The second instance runs a small web server on port 80 so that users can verify connectivity, this machine is not connected to the tailnet, and is only accessible on the local LAN or via SNAT from the subnet router for devices on the tailnet.
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
Create a copy of the file `terraform.tfvars.example` and rename to `terraform.tfvars`. Edit the file to uncomment your tailscale API key and tailnet name, optionally you can skip this step and Terraform will ask you for those variables on each run.

### 3. Deploy
Navigate into the directory in your CLI and run:
- `terraform init` - Prepare the files and directories terraform needs, as well as install the required plugins.
- `terraform plan` - Check code for errors, plan the order of operations etc.
- `terraform apply` - Trigger the creation of resources etc, this is when terraform will "make the things".



## Verification

At the end of the `terraform apply` command running in your CLI it will output the url of the webserver to access to test connectivity, open that url in your browser and you should see Hello World text.
Example:

<img width="426" height="70" alt="post run instructions" src="https://github.com/user-attachments/assets/486f9509-96f3-43f7-b03b-558d5bb7898c" />


## How It Works

The deployment follows a chain of dependencies where each piece of information is gathered or generated to feed into the next resource.

1. **Infrastructure Discovery**: Terraform starts by querying your AWS environment to find the **Default VPC** and its associated **Subnets**. It selects the **CIDR block** (IP range) of the first available subnet, this subnet is then applied to the machines, and used in firewall and Tailscale rules.
    > I wanted to balance complexity with flexibility here, rather than creating a dedicated VPC, subnet, etc, I am making the assumption that the default will most likely exist while still giving some flexibility to defaults having been changed or recreated.
2. **Identity & Security Setup**: 
    * A **Random Pet** name is generated to act as a unique hostname for the router, ensuring no conflicts in your Tailscale admin console.
        > I am generating random server names because there can be a delay in removing destroyed registered machines from Tailscale even when they are marked as ephemeral. The name must also be known so that we can find it in tailscale in a later step.
    * A **Tailscale Auth Key** is generated on-the-fly, which acts as a temporary one-time password for the new machine to join your network.
        > I created the auth key programmatically to save additional manual steps and requirements, it also allows the terraform to not run into expired keys since they have a maximum life of 90 days. 
    * An **AWS Security Group** is created that is "locked down"—it only allows incoming traffic on port 80 if that traffic originates from within the local AWS subnet CIDR discovered in step 1.
3. **Cloud-Init Synthesis**: The `tailscale_cloud_init` module takes the **Auth Key** to attach to the tailnet, the **Random Hostname** to set the machine hostname so it is known to find the device in Tailscale later, and the **AWS Subnet CIDR** to advertise that subnet and bundles them into a specialized boot script to install and join the tailnet. It also enabled Tailscale SSH for secure remote access.
    > This Tailscale module is a no-brainer, it makes creating the cloud-init scripts incredibly clean and straight forward.
4. **Instance Provisioning**: 
    * The **Subnet Router** instance is launched using that boot script. Upon power-up, it installs Tailscale, authenticates, and begins "advertising" that it can handle traffic for the AWS Subnet.
    * The **Web Server** instance is launched simultaneously. It runs a shell script to install Apache and hosts the "Hello World" page.
5. **Dynamic Route Approval**: Once the router is live, Terraform uses a **Data Source** to wait (up to 2 minutes) for the device to appear in your Tailscale account. As soon as it finds the matching `device_id`, it triggers a **Route Approval** resource, which automatically "clicks the button" in Tailscale to allow traffic to flow into the AWS subnet.
    > This section was perhaps the hardest for me to come up with an appropriate approach. I explored many options including tagging, ACL, etc (none of which seemed elegant from my current understanding) before finding that this option was available which worked perfectly. I added the wait because it takes some time for Tailscale to be installed after boot and connect and register itself so that the lookup can return a match.
6. **Hand-off**: Finally, Terraform captures the **Private IP** of the web server and formats it into a URL in your terminal, providing the direct path for you to test the connection.
    > I wanted to provide a simple step for users to take to test connectivity, and the output was able to be formatted in such a way that the hyperlink is clickable in many instances.

## Configuration Reference


### Required Variables
These variables must be configured in your `terraform.tfvars` file for the project to run. See Quickstart step 2.

| Name | Description | Default | Location |
| :--- | :--- | :--- | :--- |
| `my_api_key` | Tailscale API Key used for authentication. | n/a | `variables.tf` |
| `tailnet_name` | The exact name of your Tailnet. | n/a | `variables.tf` |

### Optional Settings
The following values are currently hardcoded in the configuration. You can modify them directly in the files listed below if you wish to change the deployment region or hardware.

| Name | Description | Default | Location |
| :--- | :--- | :--- | :--- |
| `region` | [cite_start]The AWS region where the infrastructure is deployed. | `ca-central-1` | `providers.tf` |
| `instance_type` | The hardware specification for the EC2 instances. | `t3.micro` | `main.tf` |
| `ami` | The Amazon Linux AMI ID used for the instances. This may need to be changed if you change region or instance type.  | `ami-09547c8673abb0190` | `main.tf` |

## Clean Up

- `terraform destroy` - Remove all the resources and configurations that terraform performed in apply.

## References

- [AWS terraform provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Tailscale terraform provider documentation](https://registry.terraform.io/providers/tailscale/tailscale/latest/docs)
- [Tailscale cloud-init provider documentation](https://registry.terraform.io/modules/tailscale/tailscale/cloudinit/latest)

## AI Disclosure
- I used Google Gemini for
    - Troubleshooting errors
    - Giving me multiple approaches for how to solve a problem, the pros and cons etc, so that I can pick an approach.
    - When I get stuck in my Google-fu, sometimes I just need to ramble via voice to text for 5 minutes with what I am trying to do but cannot put into words, and it finds me exactly what I need.
    - It is possible that some single lines of code may be copied from Gemini, however for the most part code is sourced from official or unofficial website sources. You can see many of these referenced in the inline comments.
    - Let me be very clear, Gemini did not write this for me, I'm sure it would have done a much better job than I did, and it would have lost fewer hairs! However, it was an invaluable tool, and I would be bald by now without it.
- VS code I'm assuming has "AI" in it, it is like it reads your mind, it's uncanny, you can by typing a comment and it knows the url you have on your clipboard and will suggest the entire comment perfectly. Also when it suggests changing a variable name that you just renamed in another location, chefs kiss...

## Reflection and Alternatives/Improvements

### Reflection
- I selected AWS as it is the cloud provider I am the most familiar with, and it is most likely the leading provider of Tailscale customers.
- I decided to use Terraform as my automation tool for two reasons, one there is excellent official Tailscale providers, secondarily the person telling me about this activity used the word Terraform when describing the activity, and like in any discovery call, I believe that sometimes the smallest signals are the strongest, here is hoping I was right!
- I took the approach of having as few manual or pre steps as possible, for example programatically creating the auth keys for example.
- There was a moment that I had just gotten the subnet router deployed and a manual cloud-init (before I found the module), and it just joined the tailnet perfectly, and in Tailscale I could click the SSH button and be on the CLI. I said "Holy F#%@ S^#t", loudly, alone, to myself, it was just that easy and elegant. It was one of those "where have you been all my life" moments.

## Future Roadmap Improvements
- OAuth Tailscale API access vs a key to overcome 90 day expiration.
- More robust support of custom VPCs etc
