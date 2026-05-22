# Security group for VM1 (public - engine + nginx)
resource "aws_security_group" "public" {
  name        = "${var.project_name}-public-sg"
  description = "Security group for public VM1 (engine + nginx)"
  vpc_id      = var.vpc_id

  # HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-public-sg"
  }
}

# Security group for VM2 and VM3 (private workers)
resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-sg"
  description = "Security group for private worker VMs"
  vpc_id      = var.vpc_id

  # All traffic from within the VPC only
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-private-sg"
  }
}