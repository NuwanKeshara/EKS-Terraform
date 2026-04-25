output "cluster_id" {
  value = aws_eks_cluster.nuwankeshara_cluster.id
}

output "cluster_name" {
  value = aws_eks_cluster.nuwankeshara_cluster.name
}

output "node_group_id" {
  value = aws_eks_node_group.nuwankeshara_node_group.id
}

output "vpc_id" {
  value = aws_vpc.nuwankeshara_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.nuwankeshara_subnet[*].id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.nuwankeshara_cluster.endpoint
}
