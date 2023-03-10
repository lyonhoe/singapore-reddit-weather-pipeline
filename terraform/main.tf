terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    redshift = {
      source  = "brainly/redshift"
      version = "1.0.2"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.aws_region
  profile = "default"
}

# Create our S3 bucket (Datalake)
resource "aws_s3_bucket" "reddit-weather-data-lake" {
  bucket = "singapore-weather-reddit"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "reddit-weather-data-lake-acl" {
  bucket = aws_s3_bucket.reddit-weather-data-lake.id
  acl    = "public-read-write"
}

# IAM role for EC2 to connect to AWS Redshift, S3, & EMR
resource "aws_iam_role" "reddit_weather_ec2_iam_role" {
  name = "reddit_weather_ec2_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonEMRFullAccessPolicy_v2", "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess"]
}

resource "aws_iam_instance_profile" "reddit_weather_ec2_iam_role_instance_profile" {
  name = "reddit_weather_ec2_iam_role_instance_profile"
  role = aws_iam_role.reddit_weather_ec2_iam_role.name
}

# IAM role for Redshift to be able to read data from S3 via Spectrum
resource "aws_iam_role" "reddit_weather_redshift_iam_role" {
  name = "reddit_weather_redshift_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess", "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"]
}


# Create security group for access to EC2 from your Anywhere
resource "aws_security_group" "reddit_weather_security_group" {
  name        = "reddit_weather_security_group"
  description = "Security group to allow inbound SCP & outbound 8080 (Airflow) connections"

  ingress {
    description = "Inbound SCP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "reddit_weather_security_group"
  }
}

# Set up Redshift
resource "aws_redshift_cluster" "reddit_weather_redshift_cluster" {
  cluster_identifier  = "reddit-weather-redshift-cluster"
  master_username     = var.redshift_user
  master_password     = var.redshift_password
  port                = 5439
  node_type           = var.redshift_node_type
  cluster_type        = "single-node"
  iam_roles           = [aws_iam_role.reddit_weather_redshift_iam_role.arn]
  skip_final_snapshot = true
  database_name       = "dev"
}

# Create Redshift spectrum schema
provider "redshift" {
  host     = aws_redshift_cluster.reddit_weather_redshift_cluster.dns_name
  username = var.redshift_user
  password = var.redshift_password
  database = "dev"
}

# External schema using AWS Glue Data Catalog
resource "redshift_schema" "external_from_glue_data_catalog" {
  name  = "spectrum"
  owner = var.redshift_user
  external_schema {
    database_name = "spectrum"
    data_catalog_source {
      region                                 = var.aws_region
      iam_role_arns                          = [aws_iam_role.reddit_weather_redshift_iam_role.arn]
      create_external_database_if_not_exists = true
    }
  }
}


# Create EC2 with IAM role to allow EMR, Redshift, & S3 access and security group 
resource "tls_private_key" "custom_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name_prefix = var.key_name
  public_key      = tls_private_key.custom_key.public_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20220420"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "reddit_weather_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name        = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.reddit_weather_security_group.name]
  iam_instance_profile = aws_iam_instance_profile.reddit_weather_ec2_iam_role_instance_profile.id
  tags = {
    Name = "reddit_weather_ec2"
  }

  user_data = <<EOF
#!/bin/bash

echo "-------------------------START AIRFLOW SETUP---------------------------"
sudo apt-get -y update

sudo apt-get -y install \
ca-certificates \
curl \
gnupg \
lsb-release

sudo apt -y install unzip

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo chmod 666 /var/run/docker.sock

sudo apt install make

echo 'Clone git repo to EC2'
cd /home/ubuntu && git clone https://github.com/lyonhoe/singapore-reddit-weather-pipeline.git && cd singapore-reddit-weather-pipeline && make perms

echo 'Setup Airflow environment variables'
echo "
AIRFLOW_CONN_REDSHIFT=postgres://${var.redshift_user}:${var.redshift_password}@${aws_redshift_cluster.reddit_weather_redshift_cluster.endpoint}/dev
AIRFLOW_CONN_POSTGRES=postgres://airflow:airflow@postgres:5432
AIRFLOW_CONN_IS_API_AVAILABLE_REDDIT=http://https%3A%2F%2Fapi.pushshift.io%2F
AIRFLOW_CONN_IS_API_AVAILABLE_WEATHER=http://https%3A%2F%2Fapi.open-meteo.com%2F
AIRFLOW_CONN_AWS_DEFAULT=aws://?region_name=${var.aws_region}
AIRFLOW_VAR_BUCKET=${aws_s3_bucket.reddit-weather-data-lake.id}
" > env

echo 'Start Airflow containers'
make up

echo "-------------------------END SETUP---------------------------"

EOF

}

# EC2 budget constraint
resource "aws_budgets_budget" "ec2" {
  name              = "budget-ec2-monthly"
  budget_type       = "COST"
  limit_amount      = "50"
  limit_unit        = "USD"
  time_period_end   = "2087-06-15_00:00"
  time_period_start = "2023-02-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email_id]
  }
}
