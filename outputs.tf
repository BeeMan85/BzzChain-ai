# ------------------Generate instructions for the user to connect to the web server------------------

output "final_instructions" {
  value = <<-EOF
    To connect to the web server:
    1. Ensure you are connected to the Tailscale network.
    2. Visit the web server at: http://${aws_instance.aws-webserver.private_ip}:80
    You should see a page that says "Hello from the web server!"
  EOF
}