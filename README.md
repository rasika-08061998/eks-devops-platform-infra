# EKS DevOps Platform Infrastructure

This repository provisions a **production-style AWS Kubernetes platform** using **Terraform**.

It is part of an **end-to-end DevOps platform project** that demonstrates modern infrastructure and platform engineering practices including:

* Infrastructure as Code with Terraform
* Production-grade AWS networking
* Kubernetes cluster provisioning (EKS)
* Secure access using IAM and AWS Systems Manager
* Container registry with Amazon ECR
* Remote Terraform state management
* Modular Terraform architecture

This repository represents the **Infrastructure Layer** of the platform.

Later phases will include:

* CI pipelines using GitHub Actions
* GitOps deployment using ArgoCD
* Observability with Prometheus and Grafana

---

# Project Architecture

This platform uses a **secure private Kubernetes architecture**.

```
Developer
   │
   ▼
GitHub Codespaces
   │
   ▼
AWS Systems Manager (SSM)
   │
   ▼
Bastion Host (Public Subnet)
   │
   ▼
Private EKS API Endpoint
   │
   ▼
EKS Worker Nodes (Private Subnets)
```

Key principles:

* Kubernetes nodes run **only in private subnets**
* No SSH access to servers
* Secure access using **AWS Systems Manager**
* Infrastructure provisioned using **Terraform modules**

---

# Repository Strategy

Production DevOps platforms usually separate responsibilities into multiple repositories.

This project uses **three repositories**.

## 1️⃣ Infrastructure Repository

```
eks-devops-platform-infra
```

Purpose:

Provision all AWS infrastructure.

Components:

* VPC
* Subnets
* NAT Gateway
* EKS Cluster
* Node Groups
* Bastion Host
* ECR Repository
* IAM Roles
* OIDC Provider

---

## 2️⃣ Application Repository

```
python-microservice-app
```

Purpose:

Application source code.

Includes:

* Python API
* Dockerfile
* GitHub Actions CI pipeline

CI pipeline builds container images and pushes them to **Amazon ECR**.

---

## 3️⃣ GitOps Repository

```
eks-gitops-manifests
```

Purpose:

Stores Kubernetes manifests.

ArgoCD continuously watches this repository and deploys applications to the cluster.

---

# AWS Infrastructure Design

## VPC Configuration

```
VPC CIDR: 10.0.0.0/16
```

| Subnet Type      | CIDR         | Purpose          |
| ---------------- | ------------ | ---------------- |
| Public Subnet A  | 10.0.1.0/24  | Bastion host     |
| Public Subnet B  | 10.0.2.0/24  | Load balancers   |
| Private Subnet A | 10.0.10.0/24 | EKS worker nodes |
| Private Subnet B | 10.0.11.0/24 | EKS worker nodes |

---

## Networking Components

The following networking resources are provisioned:

* Internet Gateway
* NAT Gateway
* Route Tables
* Security Groups
* Network ACLs

Traffic flow:

```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Public Subnets
   │
   └── Bastion Host

Private Subnets
   │
   └── EKS Worker Nodes
```

Private subnets use a **NAT Gateway** for outbound internet access.

---

# Kubernetes Cluster (Amazon EKS)

The Kubernetes cluster is created using the official Terraform module:

```
terraform-aws-modules/eks/aws
```

## Cluster Configuration

| Parameter          | Value     |
| ------------------ | --------- |
| Kubernetes Version | 1.29      |
| Node Instance Type | t3.medium |
| Node Scaling       | 1–2 nodes |
| IRSA               | Enabled   |
| OIDC Provider      | Enabled   |

Worker nodes run **only in private subnets**.

---

# Bastion Host

A Bastion host is deployed in the **public subnet**.

Purpose:

* Secure administrative access to the Kubernetes cluster
* Access the private EKS API endpoint

Security configuration:

```
SSH: Disabled
Access Method: AWS Systems Manager (SSM)
```

This removes the need for SSH keys and open ports.

---

# Amazon ECR (Elastic Container Registry)

An ECR repository is provisioned to store Docker images.

Example repository:

```
python-microservice-app
```

This registry will be used by CI pipelines to store application images.

---

# Security Design

This platform follows **modern AWS security best practices**.

| Component            | Security Method     |
| -------------------- | ------------------- |
| Developer Access     | AWS Systems Manager |
| CI/CD Authentication | OIDC Federation     |
| Pod AWS Access       | IRSA                |
| Secrets              | Kubernetes Secrets  |
| Container Registry   | IAM policies        |

Security principles:

```
No IAM users
No static credentials
Least privilege IAM roles
Private Kubernetes networking
```

---

# Terraform Project Structure

```
terraform
│
├── modules
│   │
│   ├── vpc
│   │
│   ├── eks
│   │
│   ├── ecr
│   │
│   └── bastion
│
└── environments
    │
    └── dev
         backend.tf
         main.tf
         variables.tf
         terraform.tfvars
```

## Module Responsibilities

| Module  | Purpose                             |
| ------- | ----------------------------------- |
| vpc     | Creates VPC, subnets, NAT gateway   |
| eks     | Creates EKS cluster and node groups |
| ecr     | Creates container registry          |
| bastion | Deploys bastion host with SSM       |

---

# Terraform Remote State (S3 Backend)

Terraform state must **never be stored locally in production environments**.

This project uses:

* **Amazon S3** for remote state storage
* **DynamoDB** for state locking

## Backend Configuration

File:

```
terraform/environments/dev/backend.tf
```

Example configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "eks-devops-platform-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

---

# Creating Backend Infrastructure

Terraform cannot create its own backend.

The backend infrastructure must be created manually once.

## Create S3 Bucket

```
aws s3api create-bucket \
--bucket eks-devops-platform-terraform-state \
--region ap-south-1 \
--create-bucket-configuration LocationConstraint=ap-south-1
```

Enable encryption:

```
aws s3api put-bucket-encryption \
--bucket eks-devops-platform-terraform-state \
--server-side-encryption-configuration '{
"Rules": [{
"ApplyServerSideEncryptionByDefault": {
"SSEAlgorithm": "AES256"
}}]}'
```

---

## Create DynamoDB Lock Table

```
aws dynamodb create-table \
--table-name terraform-locks \
--attribute-definitions AttributeName=LockID,AttributeType=S \
--key-schema AttributeName=LockID,KeyType=HASH \
--billing-mode PAY_PER_REQUEST \
--region ap-south-1
```

This prevents concurrent Terraform runs.

---

# Terraform Deployment Steps

Navigate to the Terraform environment:

```
cd terraform/environments/dev
```

Initialize Terraform:

```
terraform init
```

Review planned changes:

```
terraform plan
```

Apply infrastructure:

```
terraform apply
```

---

# Accessing the Kubernetes Cluster

Configure kubectl:

```
aws eks update-kubeconfig \
--region ap-south-1 \
--name eks-devops-cluster
```

Verify nodes:

```
kubectl get nodes
```

Example output:

```
ip-10-0-11-142.ap-south-1.compute.internal   Ready
```

---

# Bastion Access

Connect to bastion using AWS Systems Manager:

```
aws ssm start-session --target <instance-id>
```

Then configure kubectl:

```
aws eks update-kubeconfig \
--region ap-south-1 \
--name eks-devops-cluster
```

---

# Git Ignore Configuration

Terraform state files should never be committed.

Example `.gitignore`:

```
*.tfstate
*.tfstate.*
.terraform/
crash.log
*.tfvars
*.tfvars.json
.DS_Store
.vscode/
.idea/
```

---

# Future Enhancements

This infrastructure will later integrate:

* GitHub Actions CI pipelines
* ArgoCD GitOps deployment
* Kubernetes Ingress Controller
* Prometheus monitoring
* Grafana dashboards

---

# Skills Demonstrated

This project demonstrates real-world **DevOps and Platform Engineering skills**:

* Terraform module architecture
* AWS networking design
* Kubernetes infrastructure provisioning
* Secure access via IAM and SSM
* Container registry management
* Infrastructure automation

---

1️⃣ Terraform Architecture Diagram

This diagram explains how the environment layer orchestrates modules.

                       Terraform Environment
                terraform/environments/dev
                           │
                           ▼
                    main.tf (orchestrator)
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
   VPC Module         EKS Module          Bastion Module
 terraform/modules     terraform/modules     terraform/modules
       /vpc                 /eks                 /bastion
        │                    │                      │
        ▼                    ▼                      ▼
   VPC Resources        Kubernetes Cluster      Bastion Host
        │                    │                      │
        ▼                    ▼                      ▼
 Subnets / NAT         Node Groups            SSM Access
 Route Tables          OIDC Provider          Secure Admin
 Internet Gateway      IRSA Enabled



 2️⃣ Terraform Module Dependency Flow

This shows how modules depend on each other.


                    +----------------+
                    |   VPC Module   |
                    |----------------|
                    | VPC            |
                    | Public Subnets |
                    | Private Subnets|
                    | NAT Gateway    |
                    +--------+-------+
                             |
                             |
                             ▼
                    +----------------+
                    |   EKS Module   |
                    |----------------|
                    | EKS Cluster    |
                    | Node Groups    |
                    | OIDC Provider  |
                    | IRSA Enabled   |
                    +--------+-------+
                             |
                             |
                             ▼
                    +----------------+
                    | Bastion Module |
                    |----------------|
                    | EC2 Instance   |
                    | IAM Role (SSM) |
                    | kubectl access |
                    +----------------+


3️⃣ Terraform Directory Structure Diagram

This helps readers quickly understand the repo layout.

eks-devops-platform-infra
│
├── terraform
│
│   ├── modules
│   │
│   │   ├── vpc
│   │   │    ├── main.tf
│   │   │    ├── variables.tf
│   │   │    └── outputs.tf
│   │   │
│   │   ├── eks
│   │   │    ├── main.tf
│   │   │    ├── variables.tf
│   │   │    └── outputs.tf
│   │   │
│   │   ├── ecr
│   │   │
│   │   └── bastion
│   │
│   └── environments
│        └── dev
│             ├── main.tf
│             ├── variables.tf
│             ├── backend.tf
│             └── terraform.tfvars
│
├── README.md
└── .gitignore


