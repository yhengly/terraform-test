# VPC
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.namespace}-vpc"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.vpc_cidr_block1
  availability_zone = var.availability_zone
  tags              = {
    Name = "${var.namespace}-subnet-private-${var.availability_zone}"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.vpc_cidr_block2
  availability_zone = var.availability_zone2
  tags              = {
    Name = "${var.namespace}-subnet-private-${var.availability_zone2}"
  }
}

resource "aws_db_subnet_group" "private" {
  name       = "${var.namespace}-db-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
}

resource "aws_security_group" "default" {
  name        = "${var.namespace}-security-group"
  description = "Default configuration security group"
  vpc_id      = aws_vpc.default.id
}

# Define the IAM role for RDS and S3 full access
resource "aws_iam_role" "full_access_role" {
  name               = "${var.namespace}-full-access-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Define the IAM policy with full access to RDS and S3
resource "aws_iam_policy" "full_access_policy" {
  name   = "full-access-policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "rds:*",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "full_access_attachment" {
  name       = "${var.namespace}-full-access-attachment"
  roles      = [aws_iam_role.full_access_role.name]
  policy_arn = aws_iam_policy.full_access_policy.arn
}

resource "aws_iam_policy_attachment" "s3_full_access_attachment" {
  name       = "${var.namespace}-s3-full-access-attachment"
  roles      = [aws_iam_role.full_access_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_policy_attachment" "rds_full_access_attachment" {
  name       = "${var.namespace}-rds-full-access-attachment"
  roles      = [aws_iam_role.full_access_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# S3 Bucket
resource "aws_s3_bucket" "public" {
  bucket = "${var.namespace}-public-bucket"
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.public.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.public.id
  key    = "index.html"
  source = "./index.html"
}

# RDS PG
resource "aws_db_instance" "pg" {
  db_name                = "terraformTest"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  username               = "yonatan"
  password               = "qwerty123456"
  allocated_storage      = 20
  engine_version         = "12"
  vpc_security_group_ids = [aws_security_group.default.id]
  db_subnet_group_name   = aws_db_subnet_group.private.name
  skip_final_snapshot    = true
  tags                   = {
    Name = "${var.namespace}-pg"
  }
}

resource "aws_iam_instance_profile" "write" {
  name = "write-instance-profile"
  role = aws_iam_role.full_access_role.name
}

# EC2 instance
resource "aws_instance" "ec2" {
  ami                    = "ami-02d3fd86e6a2f5122"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.default.id]
  iam_instance_profile   = aws_iam_instance_profile.write.name
  tags                   = {
    Name = "${var.namespace}-ec2"
  }
}

locals {
  iam_role_name = "arn:aws:iam::375803365603:role/yhengly-lab-storage-write-role"
}
