variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "alchemyst"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "AWS availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "vm1_instance_type" {
  description = "Instance type for VM1"
  type        = string
  default     = "t3.small"
}

variable "vm2_instance_type" {
  description = "Instance type for VM2"
  type        = string
  default     = "t3.small"
}

variable "vm3_instance_type" {
  description = "Instance type for VM3 (needs more RAM for the model)"
  type        = string
  default     = "t3.medium"
}