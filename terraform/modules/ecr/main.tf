resource "aws_ecr_repository" "engine" {
  name                 = "${var.project_name}/iii-engine"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-iii-engine"
  }
}

resource "aws_ecr_repository" "caller_worker" {
  name                 = "${var.project_name}/iii-caller-worker"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-iii-caller-worker"
  }
}

resource "aws_ecr_repository" "inference_worker" {
  name                 = "${var.project_name}/iii-inference-worker"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-iii-inference-worker"
  }
}