variable "availability_zone" {
  type = string
  default = "us-west-1b"
}

variable "availability_zone2" {
  type = string
  default = "us-west-1c"
}

variable "region" {
  type = string
  default = "us-west-1"
}

variable "profile" {
  type = string
  default = "dev4"
}

variable "namespace" {
  type    = string
  default = "yhengly-terraform-workshop"
}

variable "vpc_cidr_block1" {
  type    = string
  default = "10.0.128.0/24"
}

variable "vpc_cidr_block2" {
  type    = string
  default = "10.0.144.0/20"
}
