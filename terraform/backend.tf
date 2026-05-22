terraform {
  backend "s3" {
    bucket       = "alchemyst-devops-tfstate"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}