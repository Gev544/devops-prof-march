resource "aws_instance" "web" {
  ami                    = "ami-04b70fa74e45c3917"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]

  associate_public_ip_address = true

  key_name = "myawskey"

  tags = {
    Name = "dev_test"
  }
}
