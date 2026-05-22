#!/bin/bash
set -e

apt-get update -y
apt-get install -y docker.io awscli

systemctl start docker
systemctl enable docker

# Authenticate Docker to ECR
aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${caller_repo_url}

# Wait for engine to be ready
sleep 30

# Run caller worker
docker run -d \
  --name iii-caller-worker \
  --restart unless-stopped \
  -e III_URL=ws://${engine_private_ip}:49134 \
  ${caller_repo_url}:latest