/* VPC */
resource "aws_vpc" "prat_lab_vpc" {
  cidr_block           = "10.131.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

/* Internet Gateway */
resource "aws_internet_gateway" "prat_lab_ig" {
  vpc_id = aws_vpc.prat_lab_vpc.id
}

/* Elastic IP */
resource "aws_eip" "prat_lab_nat_eip" {
  vpc        = true

  depends_on = [
    aws_internet_gateway.prat_lab_ig
  ]
}

/* NAT Gateway */
resource "aws_nat_gateway" "prat_lab_nat" {
  allocation_id = aws_eip.prat_lab_nat_eip.id
  subnet_id     = aws_subnet.prat_lab_public_subnet.id

  depends_on    = [
    aws_internet_gateway.prat_lab_ig
  ]
}

/* Public subnet */
resource "aws_subnet" "prat_lab_public_subnet" {
  vpc_id                  = aws_vpc.prat_lab_vpc.id
  cidr_block              = var.publicSubnetCIDR
  map_public_ip_on_launch = true
}

/* Private subnet */
resource "aws_subnet" "prat_lab_private_subnet1" {
  vpc_id                  = aws_vpc.prat_lab_vpc.id
  cidr_block              = var.privateSubnetCIDR1
  map_public_ip_on_launch = false
}

/* Private subnet */
resource "aws_subnet" "prat_lab_private_subnet2" {
  vpc_id                  = aws_vpc.prat_lab_vpc.id
  cidr_block              = var.privateSubnetCIDR2
  map_public_ip_on_launch = false
}

/* Routing table for private subnet */
resource "aws_route_table" "prat_lab_private_rt" {
  vpc_id = aws_vpc.prat_lab_vpc.id
}

/* Routing table for public subnet */
resource "aws_route_table" "prat_lab_public_rt" {
  vpc_id = aws_vpc.prat_lab_vpc.id
}

/* Internet Route for public subnet*/
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.prat_lab_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.prat_lab_ig.id
}

/* Internet Route for private subnet */
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.prat_lab_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.prat_lab_nat.id
}

/* Route table associations */
resource "aws_route_table_association" "prat_lab_public_rt_association" {
  subnet_id      = aws_subnet.prat_lab_public_subnet.id
  route_table_id = aws_route_table.prat_lab_public_rt.id
}

resource "aws_route_table_association" "prat_lab_private_rt_association1" {
  subnet_id      = aws_subnet.prat_lab_private_subnet1.id
  route_table_id = aws_route_table.prat_lab_private_rt.id
}

resource "aws_route_table_association" "prat_lab_private_rt_association2" {
  subnet_id      = aws_subnet.prat_lab_private_subnet2.id
  route_table_id = aws_route_table.prat_lab_private_rt.id
}

/*==== VPC's Default Security Group ======*/
resource "aws_security_group" "prat_sec_grp" {
  name        = var.defaultSecGrp
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.prat_lab_vpc.id

  depends_on  = [
    aws_vpc.prat_lab_vpc
  ]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
}

/* ECR Repository */
resource "aws_ecr_repository" "prat_lab_ecr_repo" {
  name                 = var.ecrRepo
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "prat_lab_ecr_repo_policy" {
  repository = aws_ecr_repository.prat_lab_ecr_repo.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the demo repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "prat_lab_eks_role" {
 name = "prat-lab-eks-role"

 path = "/"

 assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "prat_lab_AmazonEKSClusterPolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
 role       = aws_iam_role.prat_lab_eks_role.name

 depends_on = [
  aws_iam_role.prat_lab_eks_role,
 ]
}

resource "aws_iam_role_policy_attachment" "prat_lab_AmazonEC2ContainerRegistryRe                                                                                        adOnly_EKS" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role       = aws_iam_role.prat_lab_eks_role.name

 depends_on = [
   aws_iam_role.prat_lab_eks_role,
 ]
}

resource "aws_eks_cluster" "prat_lab_eks_cluster" {
 name         = var.eksClusterName
 role_arn     = aws_iam_role.prat_lab_eks_role.arn

 vpc_config {
   subnet_ids = [aws_subnet.prat_lab_private_subnet1.id, aws_subnet.prat_lab_pri                                                                                        vate_subnet2.id]
 }

 depends_on   = [
   aws_iam_role_policy_attachment.prat_lab_AmazonEKSClusterPolicy,
   aws_iam_role_policy_attachment.prat_lab_AmazonEC2ContainerRegistryReadOnly_EK                                                                                        S,
 ]
}

resource "aws_iam_role" "prat_lab_workernodes_role" {
  name               = "prat-lab-workernodes-role"

  assume_role_policy = jsonencode({
   Statement = [{
    Action    = "sts:AssumeRole"
    Effect    = "Allow"
    Principal = {
      Service = "ec2.amazonaws.com"
    }
   }]
   Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "prat_lab_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.prat_lab_workernodes_role.name

  depends_on = [
    aws_iam_role.prat_lab_workernodes_role,
  ]
}

resource "aws_iam_role_policy_attachment" "prat_lab_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.prat_lab_workernodes_role.name

  depends_on = [
    aws_iam_role.prat_lab_workernodes_role,
  ]
}

resource "aws_iam_role_policy_attachment" "prat_lab_EC2InstanceProfileForImageBu                                                                                        ilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRCont                                                                                        ainerBuilds"
  role       = aws_iam_role.prat_lab_workernodes_role.name

  depends_on = [
    aws_iam_role.prat_lab_workernodes_role,
  ]
}

resource "aws_iam_role_policy_attachment" "prat_lab_AmazonEC2ContainerRegistryRe                                                                                        adOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.prat_lab_workernodes_role.name

  depends_on = [
    aws_iam_role.prat_lab_workernodes_role,
  ]
}

resource "aws_eks_node_group" "prat_lab_worker_node_group" {
  cluster_name    = aws_eks_cluster.prat_lab_eks_cluster.name
  node_group_name = var.eksWorkerNodeGroupName
  node_role_arn   = aws_iam_role.prat_lab_workernodes_role.arn
  subnet_ids      = [aws_subnet.prat_lab_private_subnet1.id, aws_subnet.prat_lab                                                                                        _private_subnet2.id]
  instance_types  = ["t3.2xlarge"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.prat_lab_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.prat_lab_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.prat_lab_AmazonEC2ContainerRegistryReadOnly,
  ]
}
