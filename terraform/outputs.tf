output "vm1_public_ip" {
  description = "Public IP of VM1 - use this to hit the API"
  value       = module.compute.vm1_public_ip
}

output "vm1_private_ip" {
  description = "Private IP of VM1"
  value       = module.compute.vm1_private_ip
}

output "vm2_private_ip" {
  description = "Private IP of VM2 (caller worker)"
  value       = module.compute.vm2_private_ip
}

output "vm3_private_ip" {
  description = "Private IP of VM3 (inference worker)"
  value       = module.compute.vm3_private_ip
}

output "engine_repo_url" {
  description = "ECR URL for iii engine image"
  value       = module.ecr.engine_repo_url
}

output "caller_worker_repo_url" {
  description = "ECR URL for caller worker image"
  value       = module.ecr.caller_worker_repo_url
}

output "inference_worker_repo_url" {
  description = "ECR URL for inference worker image"
  value       = module.ecr.inference_worker_repo_url
}

output "curl_command" {
  description = "Run this to test the API after deployment"
  value       = "curl -X POST http://${module.compute.vm1_public_ip}/v1/chat/completions -H 'Content-Type: application/json' -d '{\"messages\":[{\"role\":\"user\",\"content\":\"What is cloud computing?\"}]}'"
}