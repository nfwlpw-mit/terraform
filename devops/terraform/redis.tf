resource "aws_security_group" "redis_server" {
  name        = "${var.unique_env_name}_redis_server"
  description = "Internal traffic for redis servers"
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
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.redis_client.id}",
    ]
  }
}

resource "aws_security_group" "redis_client" {
  name        = "${var.unique_env_name}_redis_client"
  description = "Grant access to dev3 redis cluster."
  vpc_id      = "${var.vpcid}"
}

resource "aws_instance" "redis" {
  ami           = "ami-7feb3f14"
  instance_type = "t2.small"
  key_name      = "${var.aws_key_name}"
  count         = 1

  vpc_security_group_ids = [
    "${aws_security_group.instance_default.id}",
    "${aws_security_group.redis_server.id}",
    "${aws_security_group.consul_client.id}",
  ]

  connection {
    user     = "centos"
    key_file = "${var.key_file}"
  }

  subnet_id = "${element(split(",", var.public_subnets), count.index)}"

  #Instance tags
  tags {
    Name                = "terraform-${var.unique_env_name}-redis-${count.index}"
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
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=redis FACTER_ss_consul_server=${aws_instance.consul.0.private_ip} puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'",
    ]
  }
}
