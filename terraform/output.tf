output "aws_region" {
  description = "Region set for AWS"
  value       = var.aws_region
}

output "ec2_public_dns" {
  description = "EC2 public dns."
  value       = aws_instance.reddit_weather_ec2.public_dns
}

output "redshift_dns_name" {
  description = "Redshift DNS name."
  value       = aws_redshift_cluster.reddit_weather_redshift_cluster.dns_name
}

output "redshift_user" {
  description = "Redshift User name."
  value       = "awsuser"
}


output "redshift_password" {
  description = "Redshift password."
  value       = "Awsuser11"
}

output "private_key" {
  description = "EC2 private key."
  value       = tls_private_key.custom_key.private_key_pem
  sensitive   = true
}

output "public_key" {
  description = "EC2 public key."
  value       = tls_private_key.custom_key.public_key_openssh
}
