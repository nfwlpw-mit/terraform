variable "consul_count" {
  description = "How many consul servers to build"
  default     = "3"
}

resource "aws_security_group" "consul_server" {
  name        = "${var.unique_env_name}_consul_server"
  description = "Internal traffic for consul servers"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
  }

  ingress {
    from_port = 8300
    to_port   = 8300
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.consul_client.id}",
    ]
  }

  ingress {
    from_port = 8500
    to_port   = 8500
    protocol  = "tcp"

    cidr_blocks = [
      "64.119.134.46/32",
    ]
  }
}

resource "aws_security_group" "consul_client" {
  name        = "${var.unique_env_name}_consul_client"
  description = "Gives access to consul cluster services and gossip pool."
  vpc_id      = "${var.vpcid}"

  # LAN and WAN gossip ports
  ingress {
    from_port = 8301
    to_port   = 8302
    protocol  = "udp"
    self      = true
  }

  ingress {
    from_port = 8301
    to_port   = 8302
    protocol  = "tcp"
    self      = true
  }
}

resource "aws_instance" "consul" {
  ami           = "ami-7feb3f14"
  instance_type = "t2.small"
  key_name      = "${var.aws_key_name}"
  count         = "${var.consul_count}"

  vpc_security_group_ids = [
    "${aws_security_group.instance_default.id}",
    "${aws_security_group.consul_server.id}",
    "${aws_security_group.consul_client.id}",
  ]

  connection {
    user     = "centos"
    key_file = "${var.key_file}"
  }

  subnet_id = "${element(split(",", var.public_subnets), count.index)}"

  #Instance tags
  tags {
    Name                = "terraform-${var.unique_env_name}-consul-${count.index}"
    stackdriver_monitor = "false"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /vagrant",
      "sudo chown centos /vagrant",
      "mkdir /vagrant/puppet",
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
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=consul FACTER_ss_consul_server=${aws_instance.consul.0.private_ip} FACTER_ss_consul_count=${var.consul_count} puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'",
    ]
  }
}

output "consul_ips" {
  value = "${join(" ", aws_instance.consul.*.public_ip)}"
}
