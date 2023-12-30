resource "aws_security_group" "allow_eks_cidr_all" {
  name        = "allow_eks_cidr_all"
  description = "Allow All inbound EKS VPC traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_eks_cidr_all"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.4"

  cluster_name              = local.cluster_name
  cluster_version           = "1.27"
  create_kms_key            = false
  cluster_encryption_config = {}

  vpc_id = module.vpc.vpc_id
  # nodes will place in public subnets
  subnet_ids = module.vpc.public_subnets
  # if you want to place nodes in private subnets, use the config below and enalbe NAT gateway in vpc.tf
  # subnet_ids                            = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  cluster_endpoint_public_access        = true
  cluster_additional_security_group_ids = [aws_security_group.allow_eks_cidr_all.id]

  # create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  eks_managed_node_groups = {
    main = {
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      instance_types = ["t3.small"]
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

}

# update kubeconfig
resource "null_resource" "config_kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
  }
  depends_on = [module.eks]
}
