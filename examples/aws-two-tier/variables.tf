variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
DESCRIPTION
  default = "/Users/andrewwang/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = <<DESCRIPTION
Path to the SSH private key to be used for authentication.

Example: ~/.ssh/terraform.pem
DESCRIPTION
  default = "/Users/andrewwang/.ssh/id_rsa"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "tf-andywang-ss"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "us-east-1"
}

# Ubuntu Precise 12.04 LTS (x64)
variable "aws_amis" {
  default = {
    eu-west-1 = "ami-b1cf19c6"
    us-east-1 = "ami-31d29c5b"
    us-west-1 = "ami-3f75767a"
    us-west-2 = "ami-21f78e11"
  }
}
