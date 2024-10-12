# creates AWS db instance
resource "aws_instance" "db_server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    key_name = aws_key_pair.admin.key_name
    security_groups = [aws_security_group.db_security_group.name]

    tags = {
      Name = "Foo_DB_Server"
    }
}