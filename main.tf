data "external" "myipaddr" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}
resource "aws_vpc" "main" {
  cidr_block       = var.cidr
  instance_tenancy = "default"

  tags = {
    Name = "my_vpc"
  }
}
resource "aws_subnet" "main1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "main2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_priv_cidr
  availability_zone = "us-west-2b"

  tags = {
    Name = "private"
  }
}
resource "aws_internet_gateway" "main3" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "main4" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main3.id
  }
}
resource "aws_route_table_association" "main5" {
  subnet_id      = aws_subnet.main1.id
  route_table_id = aws_route_table.main4.id
}
resource "aws_security_group" "main6" {
  name        = "public"
  description = "public_security_group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public"
  }
}

resource "aws_security_group" "main7" {
  name        = "private"
  description = "private_security_group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["${data.external.myipaddr.result.ip}/32"]
  }
  ingress {
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["${data.external.myipaddr.result.ip}/32"]
  }
  ingress {
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["${data.external.myipaddr.result.ip}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private"
  }
}
resource "aws_security_group" "main8" {
  name        = "nat"
  description = "nat_security_group"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["${data.external.myipaddr.result.ip}/32"]
  }
  ingress {
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["${data.external.myipaddr.result.ip}/32"]
  }
  ingress {
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["${data.external.myipaddr.result.ip}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat"
  }
}


resource "aws_instance" "public" {
  ami           = "ami-0341aeea105412b57"
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  availability_zone = "us-west-2b"
  key_name = "terra"
  security_groups = [aws_security_group.main6.id]
  subnet_id = aws_subnet.main1.id

  tags = {
    Name = "public"
  }
}
 
