variable "aws_asterisk_access_key" {
  description = "AWS Access Key for asterisk"
}

variable "aws_asterisk_secret_key" {
  description = "AWS Secret Key for asterisk"
}

variable "asterisk_instance_size" {
  description = "AWS instance size to use for asterisk nodes."
  default     = "t2.small"
}

variable "aws_primary_asterisk_region" {
  description = "AWS instance size to use for asterisk nodes."
  default     = "us-east-1"
}

variable "aws_secondary_asterisk_region" {
  description = "AWS instance size to use for asterisk nodes."
  default     = "us-west-2"
}

provider "aws" {
  alias      = "primary_asterisk"
  access_key = "${var.aws_asterisk_access_key}"
  secret_key = "${var.aws_asterisk_secret_key}"
  region     = "${var.aws_primary_asterisk_region}"
}

provider "aws" {
  alias      = "secondary_asterisk"
  access_key = "${var.aws_asterisk_access_key}"
  secret_key = "${var.aws_asterisk_secret_key}"
  region     = "${var.aws_secondary_asterisk_region}"
}

resource "aws_vpc" "primary_asterisk" {
  cidr_block = "10.0.0.0/24"
  provider   = "aws.primary_asterisk"
}

resource "aws_vpc" "secondary_asterisk" {
  cidr_block = "10.0.1.0/24"
  provider   = "aws.secondary_asterisk"
}

resource "aws_subnet" "primary_asterisk" {
  vpc_id                  = "${aws_vpc.primary_asterisk.id}"
  provider                = "aws.primary_asterisk"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "secondary_asterisk" {
  vpc_id                  = "${aws_vpc.secondary_asterisk.id}"
  provider                = "aws.secondary_asterisk"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-west-2a"
}

resource "aws_internet_gateway" "primary_asterisk" {
  vpc_id   = "${aws_vpc.primary_asterisk.id}"
  provider = "aws.primary_asterisk"
}

resource "aws_internet_gateway" "secondary_asterisk" {
  vpc_id   = "${aws_vpc.secondary_asterisk.id}"
  provider = "aws.secondary_asterisk"
}

resource "aws_route_table" "primary_asterisk" {
  vpc_id   = "${aws_vpc.primary_asterisk.id}"
  provider = "aws.primary_asterisk"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.primary_asterisk.id}"
  }
}

resource "aws_route_table" "secondary_asterisk" {
  vpc_id   = "${aws_vpc.secondary_asterisk.id}"
  provider = "aws.secondary_asterisk"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.secondary_asterisk.id}"
  }
}

resource "aws_main_route_table_association" "primary_asterisk" {
  vpc_id         = "${aws_vpc.primary_asterisk.id}"
  route_table_id = "${aws_route_table.primary_asterisk.id}"
  provider       = "aws.primary_asterisk"
}

resource "aws_main_route_table_association" "secondary_asterisk" {
  vpc_id         = "${aws_vpc.secondary_asterisk.id}"
  route_table_id = "${aws_route_table.secondary_asterisk.id}"
  provider       = "aws.secondary_asterisk"
}

resource "aws_security_group" "primary_asterisk_server" {
  name        = "${var.unique_env_name}_primary_asterisk_server"
  provider    = "aws.primary_asterisk"
  description = "Traffic for Asterisk servers"
  vpc_id      = "${aws_vpc.primary_asterisk.id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "udp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 8088
    to_port   = 8089
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "secondary_asterisk_server" {
  name        = "${var.unique_env_name}_asterisk_server"
  provider    = "aws.secondary_asterisk"
  description = "Traffic for Asterisk servers"
  vpc_id      = "${aws_vpc.secondary_asterisk.id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "udp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 8088
    to_port   = 8089
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "primary_asterisk" {
  provider = "aws.primary_asterisk"
  instance = "${aws_instance.primary_asterisk.id}"
  vpc      = true
}

resource "aws_eip" "secondary_asterisk" {
  provider = "aws.secondary_asterisk"
  instance = "${aws_instance.secondary_asterisk.id}"
  vpc      = true
}

resource "aws_instance" "primary_asterisk" {
  provider      = "aws.primary_asterisk"
  ami           = "ami-43ee3a28"
  instance_type = "${var.asterisk_instance_size}"
  key_name      = "${var.aws_key_name}"
  count         = 1

  vpc_security_group_ids = [
    "${aws_security_group.primary_asterisk_server.id}",
  ]

  connection {
    user     = "centos"
    key_file = "${var.key_file}"
  }

  subnet_id = "${aws_subnet.primary_asterisk.id}"

  root_block_device {
    volume_size = 50

    #    delete_on_termination = "true"
  }

  #Instance tags
  tags {
    Name = "terraform-${var.unique_env_name}-primary_asterisk-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /vagrant",
      "sudo chown centos /vagrant",
      "mkdir /vagrant/puppet",
      "sudo mkdir -p /mnt/ss_api",
      "sudo chown -R centos /mnt/ss_api",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../puppet/modules"
    destination = "/vagrant/puppet"
  }

  provisioner "file" {
    source      = "${path.module}/../puppet/manifests"
    destination = "/vagrant/puppet"
  }

  provisioner "file" {
    source      = "${path.module}/../config"
    destination = "/vagrant"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod ugo+rw -R /mnt/ss_api",
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=asterisk puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'; exit $?",
    ]
  }

  depends_on = ["aws_main_route_table_association.primary_asterisk"]
}

resource "aws_instance" "secondary_asterisk" {
  provider      = "aws.secondary_asterisk"
  ami           = "ami-ac21c69f"
  instance_type = "${var.asterisk_instance_size}"
  key_name      = "${var.aws_key_name}"
  count         = 1

  vpc_security_group_ids = [
    "${aws_security_group.secondary_asterisk_server.id}",
  ]

  connection {
    user     = "centos"
    key_file = "${var.key_file}"
  }

  subnet_id = "${aws_subnet.secondary_asterisk.id}"

  root_block_device {
    volume_size = 50

    #    delete_on_termination = "true"
  }

  #Instance tags
  tags {
    Name = "terraform-${var.unique_env_name}-secondary_asterisk-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /vagrant",
      "sudo chown centos /vagrant",
      "mkdir /vagrant/puppet",
      "sudo mkdir -p /mnt/ss_api",
      "sudo chown -R centos /mnt/ss_api",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../puppet/modules"
    destination = "/vagrant/puppet"
  }

  provisioner "file" {
    source      = "${path.module}/../puppet/manifests"
    destination = "/vagrant/puppet"
  }

  provisioner "file" {
    source      = "${path.module}/../config"
    destination = "/vagrant"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod ugo+rw -R /mnt/ss_api",
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=asterisk puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'; exit $?",
    ]
  }

  depends_on = ["aws_main_route_table_association.secondary_asterisk"]
}

output "primary_asterisk_ips" {
  value = "${join(" ", aws_instance.primary_asterisk.*.public_ip)}"
}

output "secondary_asterisk_ips" {
  value = "${join(" ", aws_instance.secondary_asterisk.*.public_ip)}"
}
