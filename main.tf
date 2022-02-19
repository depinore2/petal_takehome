# === INIT CONFIG ===
terraform {
    backend "s3" {
        key = "__terraform-state"
    }
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}
provider "aws" {
    region = var.region
}
# === /INIT CONFIG ===



# === INPUTS ===
variable "region" { type = string }

# === /INPUTS ===



# === NETWORK ===
locals {
    vpc_cidr = "10.0.0.0/16"
    public1_cidr = "10.0.1.0/24"
    public2_cidr = "10.0.2.0/24"
    private1_cidr = "10.0.3.0/24"
}
resource "aws_vpc" "demo" {
    cidr_block = local.vpc_cidr
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "demo_vpc"
    }
}
resource "aws_subnet" "public1" {
    vpc_id = aws_vpc.demo.id
    cidr_block = local.public1_cidr
    map_public_ip_on_launch = true

    tags = {
        Name = "public1"
    }
}
resource "aws_subnet" "public2" {
    vpc_id = aws_vpc.demo.id
    cidr_block = local.public2_cidr
    map_public_ip_on_launch = true

    tags = {
        Name = "public2"
    }
}
resource "aws_subnet" "private1" {
    vpc_id = aws_vpc.demo.id
    cidr_block = local.private1_cidr
    map_public_ip_on_launch = true

    tags = {
        Name = "private1"
    }
}
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.demo.id

    tags = {
        Name = "demo_igw"
    }
}
resource "aws_eip" "eip_ngw_internet" {
    vpc = true
    depends_on = [aws_internet_gateway.igw]
}
resource "aws_nat_gateway" "internet" {
    allocation_id = aws_eip.eip_ngw_internet.id
    subnet_id = aws_subnet.public1.id
    depends_on = [aws_internet_gateway.igw]

    tags = {
        Name = "demo_nat"
    }
}
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.demo.id

    # all unidentified traffic goes out to the NAT
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.internet.id
    }

    tags = {
        Name = "private"
    }
}
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.demo.id

    # all unidentified traffic goes out to the IGW
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "public"
    }
}

# for the purposes of this demo, we will only need to send and receive web traffic
# meaning we only need 80/443 in each direction, and ephemeral ports (1024-65535) in each direction.
resource "aws_network_acl" "web_only" {
    vpc_id = aws_vpc.demo.id

    subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id, aws_subnet.private1.id]

    ingress {
        protocol   = "tcp"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }
    ingress {
        protocol   = "tcp"
        rule_no    = 200
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 443
        to_port    = 443
    }

    ingress {
        protocol   = "tcp"
        rule_no    = 300
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }

    egress {
        protocol   = "tcp"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
    }
    egress {
        protocol   = "tcp"
        rule_no    = 200
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 80
        to_port    = 80
    }
    egress {
        protocol   = "tcp"
        rule_no    = 300
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 443
        to_port    = 443
    }

    tags = {
        Name = "web_only"
    }
}
resource "aws_security_group" "web_only" {
    name        = "demo_web_only"
    description = "Allow inbound web traffic"
    vpc_id      = aws_vpc.demo.id

    ingress {
        description      = "HTTP"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
        description      = "HTTPS"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "demo_web_only"
    }
}
# === /NETWORK ===



# === COMPUTE ===
resource "aws_lb" "lambda_alb" {
    name = "demoLambdaAlb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.web_only.id]
    subnets = [aws_subnet.public1.id, aws_subnet.public2.id]

    tags = {
        Name = "demo_lambda_alb"
    }
}
resource "aws_lb_target_group" "lambda" {
    name = "lambdatg"
    target_type = "lambda"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.demo.id
}
resource "aws_lb_listener" "lambda" {
    load_balancer_arn = aws_lb.lambda_alb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.lambda.arn
    }
}
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
locals {
    zipPath = "${abspath(path.module)}/artifacts/spac_lla.zip"
}
resource "aws_lambda_function" "spac_lla" {
  filename      = local.zipPath
  function_name = "SPAC_LLA"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256(local.zipPath)

  runtime = "nodejs14.x"

  environment {
    variables = {
      foo = "SPAC_LLA"
    }
  }
}

resource "aws_lambda_permission" "alb" {
    statement_id = "AllowExecutionFromALB"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.spac_lla.function_name
    principal = "elasticloadbalancing.amazonaws.com"
    qualifier = aws_lambda_alias.demo_lambda.name
    source_arn = aws_lb_target_group.lambda.arn
}
resource "aws_lambda_alias" "demo_lambda" {
    name             = "demolambda"
    description      = "ALL CAPS service"
    function_name    = aws_lambda_function.spac_lla.function_name
    function_version = "$LATEST"
}
resource aws_lb_target_group_attachment main {
    target_group_arn = aws_lb_target_group.lambda.arn
    target_id = aws_lambda_alias.demo_lambda.arn
    depends_on = [ aws_lambda_permission.alb ]
}

# === /COMPUTE ===