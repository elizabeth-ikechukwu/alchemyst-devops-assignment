variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for VM1"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for VM2 and VM3"
  type        = string
}

variable "public_sg_id" {
  description = "Security group ID for VM1"
  type        = string
}

variable "private_sg_id" {
  description = "Security group ID for VM2 and VM3"
  type        = string
}

variable "vm1_instance_type" {
  description = "Instance type for VM1 (engine + nginx)"
  type        = string
  default     = "t3.small"
}

variable "vm2_instance_type" {
  description = "Instance type for VM2 (caller worker)"
  type        = string
  default     = "t3.small"
}

variable "vm3_instance_type" {
  description = "Instance type for VM3 (inference worker)"
  type        = string
  default     = "t3.medium"
}

variable "engine_repo_url" {
  description = "ECR repository URL for the iii engine image"
  type        = string
}

variable "caller_repo_url" {
  description = "ECR repository URL for the caller worker image"
  type        = string
}

variable "inference_repo_url" {
  description = "ECR repository URL for the inference worker image"
  type        = string
}