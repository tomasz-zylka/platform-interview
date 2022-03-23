#
# Data Resource for default subnet
#
resource "aws_default_subnet" "euce1a" {
  availability_zone = "eu-central-1a"
}

resource "aws_default_subnet" "euce1b" {
  availability_zone = "eu-central-1b"
}

resource "aws_default_subnet" "euce1c" {
  availability_zone = "eu-central-1c"
}

#
# Keypair
#
resource "aws_key_pair" "aws_chat" {
  key_name   = "aws-chat"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC739jbtjtMULeBkrvexh9no5yauukhzzu1xVhcspRTqGEYBhi9M8Gs+bOCI+A61xeZ0CBMaXqrWcD0G6kiQpzR9vjG8Vgq0WKslyUiT6wiPfxoD7bMT9RPkzCcByKEWwNuj3Mqra86lPmoOGQZzzywwnxj45qDVf+Mz3gL0BfSgOKdCnD37BHet6ieildAFibd+XqEVEXUY5bArW1npwrXGOsBIOtFoFOfr3/GxC6G/1WPynfaRuNP5ZfmV1jpcEW6fCkvs/7F14/ShF2XyuYCax+fMXZrH5mjrf1siXD5jBytHU1jSRieTmv1cmicA3PO6TTpD56+nJdlEIaT6OlkzRGT7hFzLrUzLyAA3updXzx34MH6GCzHXZ4OmsGmyUVINlbTFmXZQhteG5cOIMbX62AxT7PwB5NGouoGwbQ8m19s4MwiLNeiCgef87FDMNwdlEkA18RXjIqi4YsqRsND9s+pTQHtnupYaLpG+V6cJ8IcXAJ+jyMrO3rGeM6Jau8=  tomek@tomek-Dell-G15-5515"
}

#
# User Data
#
data "template_file" "aws_chat" {
  template = file("files/cloudinit.yml")
  vars = {
    dockerImage   = local.docker_image
    redisEndpoint = local.redis_endpoint
  }
}

#
# EC2 Security Group
#
resource "aws_security_group" "aws_chat" {
  name = "aws-chat"

  ingress {
    protocol    = "tcp"
    from_port   = "22"
    to_port     = "22"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = "80"
    to_port     = "80"
    security_groups = [aws_security_group.aws_chat_lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# Load balancer: security group, load balancer, target group, listener
#
resource "aws_security_group" "aws_chat_lb" {
  name = "aws-chat-lb"

  ingress {
    protocol    = "tcp"
    from_port   = "443"
    to_port     = "443"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "aws_chat" {
  name               = "aws-chat"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.aws_chat_lb.id]
  subnets            = [aws_default_subnet.euce1a.id, aws_default_subnet.euce1b.id, aws_default_subnet.euce1c.id]

  enable_deletion_protection = true
  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "aws_chat" {
  name     = "aws-chat"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_security_group.aws_chat_lb.vpc_id
}

resource "aws_lb_listener" "aws_chat" {
  load_balancer_arn = aws_lb.aws_chat.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aws_chat.arn
  }
}

#
# Instance Role
#
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
      "ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "aws_chat" {
  name               = "aws-chat"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

#
# Instance Policy
#
data "aws_iam_policy_document" "aws_chat" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:GetItem",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "aws_chat" {
  name   = "aws_chat"
  policy = data.aws_iam_policy_document.aws_chat.json
}

resource "aws_iam_role_policy_attachment" "aws_chat" {
  role       = aws_iam_role.aws_chat.name
  policy_arn = aws_iam_policy.aws_chat.arn
}

#
# Instance Profile
#
resource "aws_iam_instance_profile" "aws_chat" {
  name = "aws_chat"
  role = aws_iam_role.aws_chat.name
}

#
# AMI ID
#
data "aws_ami" "amazon-linux-2" {
 most_recent = true

 owners = ["amazon"]

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

#
# Launch Template
#
resource "aws_launch_template" "aws_chat" {
  name_prefix   = "aws-chat-"
  image_id      = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.small"
  key_name      = "awschat"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 10
      encrypted   = true
      volume_type = "gp2"
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.aws_chat.arn
  }

  user_data              = base64encode(data.template_file.aws_chat.rendered)
  vpc_security_group_ids = [aws_security_group.aws_chat.id]
}

#
# Autoscaling Group
#
resource "aws_autoscaling_group" "aws_chat" {
  desired_capacity = 1
  max_size         = 2
  min_size         = 1

  target_group_arns   = [aws_lb_target_group.aws_chat.arn]

  launch_template {
    id      = aws_launch_template.aws_chat.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  vpc_zone_identifier = [aws_default_subnet.euce1a.id, aws_default_subnet.euce1b.id, aws_default_subnet.euce1c.id]

  tag {
    key                 = "Name"
    value               = "AWS-Chat-Client"
    propagate_at_launch = true
  }

}

#
# Redis Cluster
#
resource "aws_elasticache_cluster" "aws_chat" {
  cluster_id           = "aws-chat"
  engine               = "redis"
  node_type            = "cache.t4g.small"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  security_group_ids   = [aws_security_group.redis.id]
}

#
# Redis Security Group
#
resource "aws_security_group" "redis" {
  name = "aws-chat-redis"

  ingress {
    protocol        = "tcp"
    from_port       = "6379"
    to_port         = "6379"
    security_groups = [aws_security_group.aws_chat.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# Dynamodb Users Table
#
resource "aws_dynamodb_table" "users" {
  name         = "prod_Users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }
}

#
# Dynamodb Messages Table
#
resource "aws_dynamodb_table" "messages" {
  name         = "prod_Messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "room"
  range_key    = "message"

  attribute {
    name = "room"
    type = "S"
  }

  attribute {
    name = "message"
    type = "S"
  }
}
