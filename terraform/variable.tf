## AWS account level config: region
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

## AWS S3 bucket details
variable "bucket_prefix" {
  description = "Bucket prefix for our datalake"
  type        = string
  default     = "singapore-weather-reddit"
}


## Key to allow connection to our EC2 instance
variable "key_name" {
  description = "EC2 key name"
  type        = string
  default     = "sde-key"
}

## EC2 instance type
variable "instance_type" {
  description = "Instance type for EC2"
  type        = string
  default     = "t3.medium"
}

## Alert email receiver
variable "alert_email_id" {
  description = "Email id to send alerts to "
  type        = string
  default     = "lyonhoe@gmail.com"
}

## Your repository url
variable "repo_url" {
  description = "Repository url to clone into production machine"
  type        = string
  default     = "https://github.com/lyonhoe/data_engineering_proj_one.git"
}

## AWS Redshift credentials and node type
variable "redshift_user" {
  description = "AWS user name for Redshift"
  type        = string
  default     = "awsuser"
}

variable "redshift_password" {
  description = "AWS password for Redshift"
  type        = string
  default     = "Awsuser11"
}

variable "redshift_node_type" {
  description = "AWS Redshift node  type"
  type        = string
  default     = "dc2.large"
}