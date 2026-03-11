terraform {
  backend "s3" {
    bucket         = "eks-devops-platform-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}