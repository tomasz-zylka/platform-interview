#
# Data Resource for default subnet
#
resource "aws_default_subnet" "euce1" {
  availability_zone = "eu-central-1a"
}

#
# Keypair
#
resource "aws_key_pair" "aws_chat" {
  key_name   = "aws-chat"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCK+E7Sfdjr5vyeEuDPr/Ni7Oub7niy8BxwEkRKcHFKQtg7FGBbAIezLFttfBzggma5bgFQYDeniUSRDzXFyLUGu8gwmwWkQ5IOnynqnCK6NGl2lTTtJUzFbtKlOjsJ5a50oj1I4uBzqgR07c3MgnJ5h0qVnlFl40gBKr/XAuTwTvWUOaZ+w2jlkYnL+FLvm7+FoxC+ZwCpR0ALm1+SOc2c9n93QETPhLOrctr6rF9Zpp7gBq+TEAKF2mwPzriS4BzTzujHiXwNJtvcMerqS1XS8CKkLPNmHiDPNP5RgGKTYGtda1ca+awIgdnOPUUuJw2zDtObAqyYXckNNjeUr+Dr"
}

#
# User Data
#
data "template_file" "aws_chat" {
  template = file("files/cloudinit.yml")
  vars = {
    dockerImage   = local.docker_image
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
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
      "ecr:GetDownloadUrlForLayer"
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
# Launch Template
#
resource "aws_launch_template" "aws_chat" {
  name_prefix   = "aws-chat-"
  image_id      = "ami-xxxxx"
  instance_type = "t2.small"
  key_name      = aws_key_pair.aws_chat.key_name

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
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
  max_size         = 3
  min_size         = 1

  # vpc_zone_identifier = module.vpc.private_subnets
  # target_group_arns   = [aws_alb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.aws_chat.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_default_subnet.euce1.id]

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
