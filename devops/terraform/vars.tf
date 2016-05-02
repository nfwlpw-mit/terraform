variable "unique_env_name" {
  description = "Environment name used to make instances unique."
  default     = "kc2-dev"
}

variable "api_fqdn" {
  description = "Url to be used for api."
  default     = "api.kc.dev.simplisafe.com"
}

variable "vpcid" {
  description = "ID of the vpc to use since we can't start from scratch yet."
}

variable "availability_zones" {
  description = "List of availability zones in us-east-1 for our account"
}

variable "public_subnets" {
  description = "List is public subnets to balance hosts between."
}

variable "mysql_count" {
  description = "Number of mysql servers to manage with terraform.  Set to 0 if mysql already exists and manually register it with consul."
  default     = "1"
}

variable "drupal_count" {
  description = "Number of drupal servers to manage with terraform.  Set to 0 if drupal already exists and manually register it with consul."
  default     = "1"
}

variable "webapp_count" {
  description = "Number of webapp servers to manage with terraform.  Set to 0 if webapp already exists and manually register it with consul, or if you don't want it deployed to your environment yet."
  default     = "0"
}

variable "webapp_elb_count" {
  description = "Whether or not to build the ELB.  Should be 0 or 1"
  default     = "0"
}

variable "key_file" {
  description = "AWS ssh key"
  default     = "~/.ssh/id_rsa"
}
