output "app_public_hostnames" {
  value = [aws_instance.app_server_1.public_dns, aws_instance.app_server_2.public_dns] # output the hostnames of the app ec2 instances
}

output "db_public_hostname" {
  value = aws_instance.db_server.public_dns # output the hostname of the db ec2 instance
}