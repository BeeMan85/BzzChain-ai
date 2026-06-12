# ------------------Generate instructions for the user to connect to the web server------------------

output "final_instructions" {
  value = <<-EOF
   Test A: Connect to the web server through the Tailscale network:
    To connect to the web server:
    1. Ensure you are connected to the Tailscale network.
    2. Visit the web server at: http://${aws_instance.aws-webserver.private_ip}:80
    You should see a page that says "Hello from the web server!"

   Test B: ping the subnet router from your local machine to verify connectivity:
    1. Open a terminal on your local machine.
    2. Run the command: tailscale ping ${data.tailscale_device.subnet-router-a.addresses[0]}
    You should see ping responses from the subnet router, indicating that you have connectivity to the subnet router machine through Tailscale. 

   Test C: attempt to ping the GCP database machine to check you are blocked.
    1. Open a terminal on your local machine.
    2. Run the command: tailscale ping ${data.tailscale_device.gcp-database-a.addresses[0]}
    You should see no ping responses from the GCP database machine. You do not have rights to access it.
   
   Test D: SSH into the subnet router machine through Tailscale and then ping the GCP database machine to verify that the subnet router can access it.
    1. Open the tailnet machine list in your browser.
    2. For the machine aws-subnet-router-${local.final_hostname} click the "SSH" button to open a terminal session to the subnet router machine.
    (Notice also that you cannot SSH to the GCP machine because of our policy, even though it is installed.)
    You should now be logged into the subnet router machine.
    3. From the subnet router machine, run the command: tailscale ping ${data.tailscale_device.gcp-database-a.addresses[0]}
    You should see ping responses from the GCP database machine, indicating that the subnet router has connectivity to the GCP database machine through Tailscale. 
    
    Congratulations! You have successfully tested the tailscale demo environment!
  EOF
}