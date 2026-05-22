#!/bin/bash
set -e

# Update and install dependencies
apt-get update -y
apt-get install -y docker.io nginx awscli

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Authenticate Docker to ECR
aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${engine_repo_url}

# Write nginx config
cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream iii_http {
        server localhost:3111;
    }

    server {
        listen 80;
        server_name _;

        location /health {
            return 200 '{"status":"ok"}';
            add_header Content-Type application/json;
        }

        location /v1/chat/completions {
            proxy_pass http://iii_http;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_read_timeout 120s;
            proxy_send_timeout 120s;
        }

        location / {
            return 404 '{"error":"not found"}';
            add_header Content-Type application/json;
        }
    }
}
EOF

systemctl start nginx
systemctl enable nginx
systemctl restart nginx

# Run iii engine
docker run -d \
  --name iii-engine \
  --restart unless-stopped \
  -p 49134:49134 \
  -p 3111:3111 \
  ${engine_repo_url}:latest