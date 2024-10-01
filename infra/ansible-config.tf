resource "local_file" "ansible_inventory" {
    filename = "${path.module}ansible-inventory.yml"
    content = <<-EOF
      foo_server:
        hosts:
          foo:
            ansible_host: ${aws_instance.foo-server.public_dns}
    EOF
}