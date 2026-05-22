data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role for SSM + ECR access
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# VM1 - Engine + Nginx (public subnet)
resource "aws_instance" "vm1_engine" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.vm1_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.public_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../../user-data/vm1.sh.tpl", {
    engine_repo_url = var.engine_repo_url
    aws_region      = data.aws_region.current.name
    account_id      = data.aws_caller_identity.current.account_id
  })

  tags = {
    Name = "${var.project_name}-vm1-engine"
  }
}

# VM2 - Caller Worker (private subnet)
resource "aws_instance" "vm2_caller" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.vm2_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.private_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data = templatefile("${path.module}/../../user-data/vm2.sh.tpl", {
    engine_private_ip  = aws_instance.vm1_engine.private_ip
    caller_repo_url    = var.caller_repo_url
    aws_region         = data.aws_region.current.name
  })

  tags = {
    Name = "${var.project_name}-vm2-caller"
  }
}

# VM3 - Inference Worker (private subnet)
resource "aws_instance" "vm3_inference" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.vm3_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.private_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data = templatefile("${path.module}/../../user-data/vm3.sh.tpl", {
    engine_private_ip  = aws_instance.vm1_engine.private_ip
    inference_repo_url = var.inference_repo_url
    aws_region         = data.aws_region.current.name
  })

  tags = {
    Name = "${var.project_name}-vm3-inference"
  }
}