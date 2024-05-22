
# Provide the name of the provider

provider "aws {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

# 1 Create a VPC

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags {
        "Name" = "production-vpc"
    }
}

# 2 Create a Internet Gateway

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.prod-vpc.id

}

# 3 Create a route Table

resource "aws_route_table" "prod-route-table" {
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
}


# 4 Aws Subnet add a custom subnet here 

resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags {
        Name = "prod_subnet"
    }
}

# 5. Associate a subnet with a Route Table

resource "aws_main_route_table_association" "a" {
  subnet_id         = aws_vpc.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create  a Security Group to allow port 22 , 80, 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow inbound traffic on ports 22, 80, 443"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {              // Allow Egress to everywhere
    from_port   = 0
    to_port     = 0
    protocol    = "-1" // Any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip address in the subnet that was 
#     created om step in the previous step and also in the same security group

resource "aws_network_interface" "prod-nic" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  tags = {
    Name = "prod-nic"
  }
}

# 8. Add an elastic IP here

resource "aws_eip" "one" {
  vpc                      = true // To use with instances in this VPC
  network_interface        = aws_network_interface.prod-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on               = [aws_internet_gateway.gw]  
}

# 9. Aws AMI add a AWS Instance

resource "aws_instance" "web-server-instance" {
    ami = "ID_of_the_AMI_Instance"
    availability_zone = "us-east-1a" // Hard Code the Availability zone same as machine
    instance_type = "t2.micro"
    key_name = "main-key"
    
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.prod-nic
    }

    // Install User Code here
    user_data = <<-EOF
                #!/bin/bash
                supot apt update -y
                sudo apt install apache2 -y
                sudo bash -c 'echo 'Hello' >> /var/www/html/index.html'
                EOF
    
    tags {
        Name : "Web Server"
    }
}

# 10.  Sample Output

output "server_private_ip" {
    value = aws_instance.web-server-instance.private_ip
}

# Variable 
variable "sample_variable" {
    type        = any
    description = "A sample variable"
    default     = "sample value"
}
# During apply use the --var sample_variable = name to the name the varibale you assign
# Otherwise if using a file use the name    -var-file [File_Name] of the file


# Define a terraform remote backend
terraform {
    backend "s3" {
        bucket = "your-terraform-state-bucket"
        key    = "/path/to/your/terraform.state"
        region = "us-west-2"
        encrypt = true
    }
}