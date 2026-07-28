resource "aws_vpc" "devflow_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "DevFlow-VPC"
  }
}

resource "aws_subnet" "devflow_subnet" {
  vpc_id                  = aws_vpc.devflow_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "DevFlow-Subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devflow_vpc.id

  tags = {
    Name = "DevFlow-IGW"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devflow_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.devflow_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "devflow_sg" {
  name   = "DevFlow-SG"
  vpc_id = aws_vpc.devflow_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "devflow" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.devflow_subnet.id
  vpc_security_group_ids      = [aws_security_group.devflow_sg.id]
  associate_public_ip_address = true
  key_name                    = "devflow-new-key"

  tags = {
    Name = "DevFlow-Server"
  }
}
