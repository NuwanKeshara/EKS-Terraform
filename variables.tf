variable "ssh_key_name" {
  description = "AWS EC2 Key Pair name for SSH access (NOT .pem file)"
  type        = string
  default     = "runner-ec2-key"
}
