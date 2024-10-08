output "foo_server_public_hostname" {
  value = aws_instance.foo-server.public_dns # outputs the hostname of the ec2 instance
}