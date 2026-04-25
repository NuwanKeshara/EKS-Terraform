provider "aws" {
  region = "us-east-1"
}

# ---------------- VPC ----------------
resource "aws_vpc" "nuwankeshara_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "nuwankeshara-vpc"
  }
}

# ---------------- Subnets ----------------
resource "aws_subnet" "nuwankeshara_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.nuwankeshara_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.nuwankeshara_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "nuwankeshara-subnet-${count.index}"
  }
}

# ---------------- Internet Gateway ----------------
resource "aws_internet_gateway" "nuwankeshara_igw" {
  vpc_id = aws_vpc.nuwankeshara_vpc.id

  tags = {
    Name = "nuwankeshara-igw"
  }
}

# ---------------- Route Table ----------------
resource "aws_route_table" "nuwankeshara_route_table" {
  vpc_id = aws_vpc.nuwankeshara_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nuwankeshara_igw.id
  }

  tags = {
    Name = "nuwankeshara-route-table"
  }
}

resource "aws_route_table_association" "nuwankeshara_assoc" {
  count          = 2
  subnet_id      = aws_subnet.nuwankeshara_subnet[count.index].id
  route_table_id = aws_route_table.nuwankeshara_route_table.id
}

# ---------------- Security Groups ----------------
resource "aws_security_group" "cluster_sg" {
  vpc_id = aws_vpc.nuwankeshara_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nuwankeshara-cluster-sg"
  }
}

resource "aws_security_group" "node_sg" {
  vpc_id = aws_vpc.nuwankeshara_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nuwankeshara-node-sg"
  }
}

# ---------------- IAM Cluster Role ----------------
resource "aws_iam_role" "cluster_role" {
  name = "nuwankeshara-cluster-role"

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

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---------------- IAM Node Role ----------------
resource "aws_iam_role" "node_role" {
  name = "nuwankeshara-node-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "node_policy_1" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_policy_2" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_policy_3" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ---------------- EKS Cluster ----------------
resource "aws_eks_cluster" "nuwankeshara_cluster" {
  name     = "nuwankeshara-cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.nuwankeshara_subnet[*].id
    security_group_ids = [aws_security_group.cluster_sg.id]
  }
}

# ---------------- Node Group ----------------
resource "aws_eks_node_group" "nuwankeshara_node_group" {
  cluster_name    = aws_eks_cluster.nuwankeshara_cluster.name
  node_group_name = "nuwankeshara-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.nuwankeshara_subnet[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [aws_security_group.node_sg.id]
  }
}
