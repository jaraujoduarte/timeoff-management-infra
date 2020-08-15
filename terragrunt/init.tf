terraform {
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}

variable "branch_name" {
  default     = "develop"
  description = "Nombre del branch actual"
}

variable "env" {
  description = "Nombre del ambiente actual"
}

variable "availability_zones" {
  default     = ["a", "b"]
  description = "AZs donde los recursos van a ser desplegados"
}

variable "public_domain" {
  description = "Nombre del dominio publico (i.e. dev.cuotasoft.com)"
}

variable "private_domain" {
  description = "Nombre del dominio privado (i.e. dev.cuotasoft.internal)"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
