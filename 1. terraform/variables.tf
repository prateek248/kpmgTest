variable "accessKey" {
  description = "AWS account access key"
  type        = string
}

variable "secretKey" {
  description = "AWS account secret key"
  type        = string
}

variable "defaultRegion" {
  description = "Default region to be used"
  type        = string
  default     = "us-east-1"
}

variable "publicSubnetCIDR" {
  description = "Public subnet cidr"
  type        = string
  default     = "10.131.1.0/24"
}

variable "privateSubnetCIDR1" {
  description = "Private subnet cidr"
  type        = string
  default     = "10.131.2.0/24"
}

variable "privateSubnetCIDR2" {
  description = "Private subnet cidr"
  type        = string
  default     = "10.131.3.0/24"
}

variable "defaultSecGrp" {
  description = "Default security group"
  type        = string
  default     = "prat-lab-default-sg"
}

variable "ecrRepo" {
  description = "ECR Repo Name"
  type        = string
  default     = "prat-lab-ecr-repo"
}

variable "eksClusterName" {
  description = "EKS Cluster Name"
  type        = string
  default     = "prat-lab-eks-cluster"
}

variable "eksWorkerNodeGroupName" {
  description = "EKS Cluster Name"
  type        = string
  default     = "prat-lab-eks-node-group"
}
