resource "local_file" "ansible_inventory" {
    filename = "ansible-inventory.yml"
    content = <<-EOF
      app_servers:
        hosts:
          app1:
            ansible_host: ${aws_instance.app_server_1.public_dns}
          app2:
            ansible_host: ${aws_instance.app_server_2.public_dns}
      db_servers:
        hosts:
          ${aws_instance.db_server.public_dns}:
    EOF
}