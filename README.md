3-Tier GitOps Architecture on AWS

A production-grade containerized application deployed on AWS using Terraform, GitHub Actions, and a strict GitOps workflow.

🏗️ Architecture Diagram

graph LR
    user((User)) -->|HTTP/80| ALB(Load Balancer)
    
    subgraph AWS Cloud
        subgraph VPC
            ALB -->|Forward| Fargate(ECS Fargate Service)
            Fargate -->|Read/Write| RDS[(RDS MySQL)]
        end
        ECR(ECR Registry) -.->|Pull Image| Fargate
    end
    
    subgraph CI/CD Pipeline
        Dev(Developer) -->|Push| GitHub(GitHub Repo)
        GitHub -->|Trigger| Actions(GitHub Actions)
        Actions -->|OIDC Auth| AWS[AWS IAM]
        Actions -->|Scan| Checkov(Checkov Security)
        Actions -->|Plan/Apply| Terraform(Terraform)
        Actions -->|Build & Push| ECR
    end


🚀 Key Features

Infrastructure as Code: Complete AWS environment (VPC, ECS, RDS, ALB) defined in Terraform.

GitOps Workflow:

Infrastructure changes are verified via terraform plan on Pull Requests.

Bot comments post the plan results directly to the PR.

terraform apply runs automatically upon merge.

Security:

OIDC Authentication: No hardcoded AWS keys. GitHub assumes an IAM Role via OpenID Connect.

DevSecOps: Integrated Checkov scanning to block insecure infrastructure configurations.

Application:

Python Flask app serving a persistent "Hit Counter".

Zero-downtime rolling deployments via ECS Fargate.

🛠️ Tech Stack

Cloud: AWS (ECS Fargate, RDS, ECR, VPC, ALB, IAM)

IaC: Terraform (with S3 Backend + DynamoDB Locking)

CI/CD: GitHub Actions

App: Python Flask + PyMySQL

📂 Project Structure

├── .github/workflows/    # CI/CD Pipelines (GitOps & App Deploy)
├── app/                  # Python Application Code & Dockerfile
├── modules/              # Reusable Terraform Modules (VPC, DB, etc.)
├── main.tf               # Root Terraform Configuration
├── ecs.tf                # ECS Fargate & ALB Configuration
└── README.md             # Project Documentation


🏃 How to Run

Fork the Repo.

Configure Secrets: Add AWS_ROLE_ARN to your GitHub Repository Secrets.

Deploy: Push a change to main to trigger the initial provisioning.

Access: The Load Balancer URL will be output in the GitHub Action logs.