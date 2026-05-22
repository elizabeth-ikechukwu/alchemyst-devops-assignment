output "engine_repo_url" {
  value = aws_ecr_repository.engine.repository_url
}

output "caller_worker_repo_url" {
  value = aws_ecr_repository.caller_worker.repository_url
}

output "inference_worker_repo_url" {
  value = aws_ecr_repository.inference_worker.repository_url
}