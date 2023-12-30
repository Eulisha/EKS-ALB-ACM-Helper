variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
variable "name" {
  type        = string
  description = "name for your resources"
  default     = "EKS-ALB-ACM-Helper"
}
variable "vpc_cidr" {
  type        = string
  description = "cidr for your vpc"
  default     = "10.0.0.0/16"
}
variable "vpc_public_subnets" {
  type        = list(string)
  description = "public subnets for your vpc"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
variable "vpc_private_subnets" {
  type        = list(string)
  description = "private subnets for your vpc"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}
