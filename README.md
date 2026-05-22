# Alchemyst DevOps Internship Assignment
### Distributed Inference System on AWS - Elizabeth Ikechukwu

---

## Architecture

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                  AWS VPC  10.0.0.0/16                   │
                    │                                                          │
                    │  ┌───────────────────────────────────────────────────┐  │
                    │  │           Public Subnet 10.0.1.0/24               │  │
                    │  │                                                    │  │
   Internet         │  │   ┌────────────────────────────────────────────┐  │  │
       │            │  │   │              VM1 (t3.small)                │  │  │
  HTTP :80          │  │   │                                            │  │  │
       │            │  │   │   Nginx (port 80)                          │  │  │
       ▼            │  │   │       │                                    │  │  │
  ┌─────────┐       │  │   │       ▼                                    │  │  │
  │Internet │       │  │   │   iii Engine (port 49134, 3111)            │  │  │
  │Gateway  │──────►│  │   └────────────────────────────────────────────┘  │  │
  └─────────┘       │  └───────────────────────────────────────────────────┘  │
                    │                       │ ws:49134                         │
                    │  ┌───────────────────────────────────────────────────┐  │
                    │  │           Private Subnet 10.0.2.0/24              │  │
                    │  │                                                    │  │
                    │  │  ┌─────────────────┐    ┌──────────────────────┐  │  │
                    │  │  │  VM2 (t3.small) │    │   VM3 (t3.medium)    │  │  │
                    │  │  │                 │    │                      │  │  │
                    │  │  │ caller-worker   │    │  inference-worker    │  │  │
                    │  │  │ TypeScript      │    │  Python + Gemma 270M │  │  │
                    │  │  └─────────────────┘    └──────────────────────┘  │  │
                    │  │        │ ws:49134               │ ws:49134         │  │
                    │  │        └───────────────────────►│                  │  │
                    │  │               both connect to iii Engine on VM1    │  │
                    │  └───────────────────────────────────────────────────┘  │
                    │                                                          │
                    │   NAT Gateway (outbound only for private subnet)        │
                    └─────────────────────────────────────────────────────────┘
```

## RPC Request Flow

```
curl POST /v1/chat/completions
        │
        ▼
Nginx (VM1, port 80)
        │
        ▼
iii-http worker (VM1, port 3111)
        │
        ▼  RPC via WebSocket (port 49134)
caller-worker (VM2)
inference::get_response
        │
        ▼  RPC via WebSocket (port 49134)
inference-worker (VM3)
inference::run_inference
        │
   Gemma 270M model runs
        │
        ▼
Response bubbles back through the same chain
        │
        ▼
JSON response to curl
```

## VM Layout

| VM  | Subnet  | Instance  | Role                                    |
|-----|---------|-----------|------------------------------------------|
| VM1 | Public  | t3.small  | iii engine + Nginx (public entrypoint)  |
| VM2 | Private | t3.small  | caller-worker (TypeScript)              |
| VM3 | Private | t3.medium | inference-worker (Python + Gemma 270M)  |

---

## API Reference

### Health Check

```bash
curl http://<VM1_PUBLIC_IP>/health
```

**Response:**
```json
{ "status": "ok" }
```

### Run Inference

```bash
curl -X POST http://<VM1_PUBLIC_IP>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "What is cloud computing?"}
    ]
  }'
```

### Sample Response

```json
{
  "result": {
    "response": "Cloud computing is the delivery of computing services over the internet...",
    "success": "You've connected two workers and they're interoperating seamlessly..."
  }
}
```

### Request Schema

| Field               | Type   | Required | Description                          |
|---------------------|--------|----------|--------------------------------------|
| `messages`          | Array  | Yes      | Array of chat messages               |
| `messages[].role`   | String | Yes      | `user`, `assistant`, or `system`     |
| `messages[].content`| String | Yes      | The message text                     |

### Response Schema

| Field            | Type   | Description                                    |
|------------------|--------|------------------------------------------------|
| `result`         | Object | Top level result object                        |
| `result.response`| String | The model generated text output                |
| `result.success` | String | Confirmation message from caller worker        |

### Error Response

```json
{ "error": "not found" }
```

| HTTP Code | Meaning                                    |
|-----------|--------------------------------------------|
| `200`     | Inference successful                       |
| `404`     | Endpoint not found                         |
| `405`     | Method not allowed (only POST accepted)    |

---

## Redeploy from Scratch

### Prerequisites

- AWS account with credentials configured (`aws configure`)
- Terraform >= 1.10 installed
- Docker installed
- AWS CLI installed

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/elizabeth-ikechukwu/alchemyst-devops-assignment.git
cd alchemyst-devops-assignment

# 2. Initialize and deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# 3. Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(terraform output -raw engine_repo_url)

# 4. Build and push Docker images
docker build -f docker/engine/Dockerfile \
  -t $(terraform output -raw engine_repo_url):latest .
docker push $(terraform output -raw engine_repo_url):latest

docker build -f docker/caller-worker/Dockerfile \
  -t $(terraform output -raw caller_worker_repo_url):latest .
docker push $(terraform output -raw caller_worker_repo_url):latest

docker build -f docker/inference-worker/Dockerfile \
  -t $(terraform output -raw inference_worker_repo_url):latest .
docker push $(terraform output -raw inference_worker_repo_url):latest

# 5. Get the public IP
terraform output vm1_public_ip

# 6. Wait 5-8 minutes for VMs to boot and pull images, then test
curl http://<VM1_PUBLIC_IP>/health

curl -X POST http://<VM1_PUBLIC_IP>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"What is cloud computing?"}]}'
```

### Teardown

```bash
cd terraform
terraform destroy -auto-approve
```

---

## Repository Structure

```
.
├── .github/workflows/
│   ├── deploy.yml              # CI/CD: provisions ECR, builds images, deploys VMs
│   └── destroy.yml             # Manual teardown workflow
├── docker/
│   ├── engine/
│   │   ├── Dockerfile          # iii engine container
│   │   └── nginx.conf          # Nginx reverse proxy config
│   ├── caller-worker/
│   │   └── Dockerfile          # TypeScript caller worker container
│   └── inference-worker/
│       └── Dockerfile          # Python inference worker container
├── terraform/
│   ├── main.tf                 # Root module - calls all child modules
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Outputs: public IP, ECR URLs, curl command
│   ├── backend.tf              # S3 remote state config
│   ├── terraform.tfvars        # Variable values (gitignored)
│   ├── modules/
│   │   ├── networking/         # VPC, subnets, IGW, NAT, route tables
│   │   ├── security-groups/    # Firewall rules
│   │   ├── ecr/                # ECR repositories
│   │   └── compute/            # EC2 instances + IAM roles
│   └── user-data/
│       ├── vm1.sh.tpl          # VM1 bootstrap script
│       ├── vm2.sh.tpl          # VM2 bootstrap script
│       └── vm3.sh.tpl          # VM3 bootstrap script
├── workers/
│   ├── caller-worker/          # TypeScript worker source (from Alchemyst)
│   └── inference-worker/       # Python worker source (from Alchemyst)
├── docker-compose.vm1.yml      # VM1 services reference
├── docker-compose.vm2.yml      # VM2 services reference
├── docker-compose.vm3.yml      # VM3 services reference
├── config.yaml                 # iii engine configuration
└── README.md
```

---

## Production Hardening

- **HTTPS:** Add an ACM certificate with an Application Load Balancer in front of Nginx. All traffic is currently plain HTTP.
- **Authentication:** Add API key validation in Nginx using the `auth_request` directive. The inference endpoint is currently open to anyone with the public IP.
- **Secrets:** Move any sensitive configuration to AWS Secrets Manager. EC2 instances access secrets at runtime via their IAM role, no credentials on disk.
- **No SSH:** SSH is eliminated entirely. All VM access is through AWS SSM Session Manager which routes through AWS internal network, removing port 22 as an attack surface.
- **Private images:** Docker images are stored in private ECR repositories. EC2 instances pull images using their IAM role, no Docker credentials stored on any VM.
- **OIDC:** GitHub Actions authenticates to AWS via OIDC. No long-lived access keys stored anywhere in GitHub secrets.
- **Remote state:** Terraform state is stored in S3 with native locking (Terraform 1.10+). No local state files. Any engineer can run terraform from a fresh machine.
- **Least privilege:** Each VM has only the IAM permissions it needs - SSM Session Manager access and ECR read-only. No broad admin permissions on the instances.
- **Observability:** Ship container logs to CloudWatch via the awslogs Docker log driver. Add Prometheus scraping on the iii engine metrics endpoint (port 9464).

---

## Scaling to 100x Larger Model

A 100x scale-up from Gemma 270M lands at roughly a 27B parameter model (~54 GB in FP16):

- **GPU instances:** Move the inference VM to a `g4dn.xlarge` (NVIDIA T4, 16 GB VRAM) or `p3.2xlarge` (V100). Use vLLM instead of raw transformers for continuous batching and higher throughput.
- **Quantization:** 4-bit GPTQ or AWQ cuts VRAM requirements by 4x, fitting larger models on smaller and cheaper GPU instances.
- **Model storage:** Store weights in S3 or EFS instead of baking them into the Docker image. A 54 GB Docker image is not practical, pull weights at container startup from a mounted volume.
- **Async queue:** Replace synchronous RPC with SQS. Clients submit requests and poll for results. This decouples the API tier from inference latency and handles bursts without blocking.
- **Auto scaling:** EKS with KEDA for GPU-aware horizontal scaling based on SQS queue depth. Spot instances for the inference tier to reduce cost by 60-70%.
- **Cold start:** Keep a minimum of one warm inference instance running at all times. Loading a 27B model from S3 into GPU memory takes 2-3 minutes, unacceptable without a warm instance strategy.
- **Multi-GPU:** Models above 40B parameters need tensor parallelism across multiple GPUs. vLLM handles this natively. The iii worker architecture supports this cleanly since the inference worker is just a process.
