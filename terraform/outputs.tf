output "nat_public_ip" {
  value       = aws_instance.tf_k8s_nat.public_ip
  description = "Public IP to use to access the cluster API"
}

output "control_plane_ip" {
  value       = aws_instance.tf_k8s_control_plane.private_ip
  description = "Private IP of the control plane"
}

output "worker_node_ip" {
  value       = aws_instance.tf_k8s_worker_node.private_ip
  description = "Private IP of the worker node"
}