# creates AWS app instance
resource "aws_instance" "app_server_2" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    key_name = aws_key_pair.admin.key_name
    security_groups = [aws_security_group.app_security_group.name]

    tags = {
      Name = "Foo_App_Server_2"
    }
}