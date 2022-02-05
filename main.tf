provider "aws" {
  region = "us-east-1"
}

variable "vpc_config" {
  type = map(any)
  default = {
    region               = "us-east-1"
    cluster_version      = "1.19"
    cluster_name         = "interactive-learning"
    instance_type        = "t2.large"
    asg_max_size         = 1
    asg_min_size         = 1
    asg_desired_capacity = 1
    vpc_cidr             = "10.0.0.0/16"
    public_cidr1         = "10.0.1.0/24"
    public_cidr2         = "10.0.2.0/24"
    public_cidr3         = "10.0.3.0/24"
  }
}

variable "vpc2_config" {
  type = map(any)
  default = {
    region               = "us-east-2"
    cluster_version      = "1.19"
    cluster_name         = "interactive-learning"
    instance_type        = "t2.large"
    asg_max_size         = 1
    asg_min_size         = 1
    asg_desired_capacity = 1
    vpc_cidr             = "10.0.0.0/16"
    public_cidr1         = "10.0.1.0/24"
    public_cidr2         = "10.0.2.0/24"
    public_cidr3         = "10.0.3.0/24"
  }
}

variable "tags" {
  type = map(any)
  default = {
    Name        = "interactive-learning"
    Environment = "interactive-learning"
    Created_by  = "Terraform"
  }
}

module "vpc" {
  source       = "farrukh90/vpc/aws"
  version      = "7.0.0"
  region       = var.vpc_config["region"]
  vpc_cidr     = var.vpc_config["vpc_cidr"]
  public_cidr1 = var.vpc_config["public_cidr1"]
  public_cidr2 = var.vpc_config["public_cidr2"]
  public_cidr3 = var.vpc_config["public_cidr3"]
  tags         = var.tags
}



output "vpc" {
  value = module.vpc.vpc
}
output "public_subnet1" {
  value = module.vpc.public_subnets[0]
}
output "public_subnet2" {
  value = module.vpc.public_subnets[1]
}
output "public_subnet3" {
  value = module.vpc.public_subnets[2]
}
output "region" {
  value = module.vpc.region
}


module "vpc2" {
  source       = "farrukh90/vpc/aws"
  version      = "7.0.0"
  region       = var.vpc2_config["region"]
  vpc_cidr     = var.vpc2_config["vpc_cidr"]
  public_cidr1 = var.vpc2_config["public_cidr1"]
  public_cidr2 = var.vpc2_config["public_cidr2"]
  public_cidr3 = var.vpc2_config["public_cidr3"]
  tags         = var.tags
}

output "vpc2" {
  value = module.vpc.vpc
}
output "vpc2_public_subnet1" {
  value = module.vpc.public_subnets[0]
}
output "vpc2_public_subnet2" {
  value = module.vpc.public_subnets[1]
}
output "vpc2_public_subnet3" {
  value = module.vpc.public_subnets[2]
}
output "vpc2_region" {
  value = module.vpc2.region
}

####################################################################################################################################################################################################
resource "random_password" "password" {
  length  = 6
  number  = false
  special = false
  lower   = true
  upper   = false
}
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "aws_key_pair" "generated_key" {
  key_name   = "generated_key-${random_password.password.result}"
  public_key = tls_private_key.example.public_key_openssh
  provisioner "local-exec" {
    command = "echo '${tls_private_key.example.private_key_pem}' > ./myKey.pem && chmod  600 ./myKey.pem"
  }
}
####################################################################################################################################################################################################
module "ilearning" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "ilearning"
  description = "Security group for ilearning with custom ports open within VPC"
  vpc_id      = module.vpc.vpc
  ingress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "ilearning ports"
    },
  ]
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "ilearning ports"
    },
  ]
}
####################################################################################################################################################################################################

data "aws_eks_cluster" "dev_cluster" {
  name = module.dev.cluster_id
}
data "aws_eks_cluster_auth" "dev_cluster" {
  name = module.dev.cluster_id
}
##################
data "aws_eks_cluster" "qa_cluster" {
  name = module.qa.cluster_id
}
data "aws_eks_cluster_auth" "qa_cluster" {
  name = module.qa.cluster_id
}
##################
data "aws_eks_cluster" "stage_cluster" {
  name = module.stage.cluster_id
}
data "aws_eks_cluster_auth" "stage_cluster" {
  name = module.stage.cluster_id
}
#################
data "aws_eks_cluster" "prod_cluster" {
  name = module.prod.cluster_id
}
data "aws_eks_cluster_auth" "prod_cluster" {
  name = module.prod.cluster_id
}


###########################
provider "kubernetes" {
  host                   = data.aws_eks_cluster.dev_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.dev_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.dev_cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

provider "kubernetes" {
  alias                  = "qa"
  host                   = data.aws_eks_cluster.qa_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.qa_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.qa_cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

provider "kubernetes" {
  alias                  = "prod"
  host                   = data.aws_eks_cluster.prod_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.prod_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.prod_cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

provider "kubernetes" {
  alias                  = "stage"
  host                   = data.aws_eks_cluster.stage_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.stage_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.stage_cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}


###########################


module "dev" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "17.1.0"
  cluster_name                         = "dev"
  cluster_version                      = var.vpc_config["cluster_version"]
  subnets                              = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]
  vpc_id                               = module.vpc.vpc
  worker_additional_security_group_ids = [module.ilearning.security_group_id]


  worker_groups = [
    {
      instance_type          = var.vpc_config["instance_type"]
      asg_max_size           = var.vpc_config["asg_max_size"]
      asg_min_size           = var.vpc_config["asg_min_size"]
      asg_desired_capacity   = var.vpc_config["asg_desired_capacity"]
      key_name               = aws_key_pair.generated_key.key_name
      create_launch_template = true

    }
  ]
}

module "qa" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "17.1.0"
  cluster_name                         = "qa"
  cluster_version                      = var.vpc_config["cluster_version"]
  subnets                              = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]
  vpc_id                               = module.vpc.vpc
  worker_additional_security_group_ids = [module.ilearning.security_group_id]


  worker_groups = [
    {
      instance_type          = var.vpc_config["instance_type"]
      asg_max_size           = var.vpc_config["asg_max_size"]
      asg_min_size           = var.vpc_config["asg_min_size"]
      asg_desired_capacity   = var.vpc_config["asg_desired_capacity"]
      key_name               = aws_key_pair.generated_key.key_name
      create_launch_template = true

    }
  ]
}

module "stage" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "17.1.0"
  cluster_name                         = "stage"
  cluster_version                      = var.vpc_config["cluster_version"]
  subnets                              = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]
  vpc_id                               = module.vpc.vpc
  worker_additional_security_group_ids = [module.ilearning.security_group_id]


  worker_groups = [
    {
      instance_type          = var.vpc_config["instance_type"]
      asg_max_size           = var.vpc_config["asg_max_size"]
      asg_min_size           = var.vpc_config["asg_min_size"]
      asg_desired_capacity   = var.vpc_config["asg_desired_capacity"]
      key_name               = aws_key_pair.generated_key.key_name
      create_launch_template = true

    }
  ]
}

module "prod" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "17.1.0"
  cluster_name                         = "prod"
  cluster_version                      = var.vpc_config["cluster_version"]
  subnets                              = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]
  vpc_id                               = module.vpc.vpc
  worker_additional_security_group_ids = [module.ilearning.security_group_id]


  worker_groups = [
    {
      instance_type          = var.vpc_config["instance_type"]
      asg_max_size           = var.vpc_config["asg_max_size"]
      asg_min_size           = var.vpc_config["asg_min_size"]
      asg_desired_capacity   = var.vpc_config["asg_desired_capacity"]
      key_name               = aws_key_pair.generated_key.key_name
      create_launch_template = true
      

    }
  ]
}


output "Instructions" {
  value = <<EOT
    
    
        "Your clusters are ready!!! And the clusters are located in ${var.vpc_config["region"]} and named dev-qa-stage-prod

        To login to worker nodes, please use the pem key in ~/.interactive-learning/myKey.pem

    EOT
}