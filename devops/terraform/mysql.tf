resource "aws_security_group" "mysql_server" {
  name        = "${var.unique_env_name}_mysql_server"
  description = "Internal traffic for mysql server"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.mysql_client.id}",
    ]
  }
}

resource "aws_security_group" "mysql_client" {
  name        = "${var.unique_env_name}_mysql_client"
  description = "Grant access to mysql server."
  vpc_id      = "${var.vpcid}"
}

resource "aws_instance" "mysql" {
  ami           = "ami-7feb3f14"
  instance_type = "m4.large"
  key_name      = "${var.aws_key_name}"
  count         = "${var.mysql_count}"

  vpc_security_group_ids = [
    "${aws_security_group.instance_default.id}",
    "${aws_security_group.mysql_server.id}",
    "${aws_security_group.consul_client.id}",
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = "true"
  }

  connection {
    user     = "centos"
    key_file = "${var.key_file}"
  }

  subnet_id = "${element(split(",", var.public_subnets), count.index)}"

  #Instance tags
  tags {
    Name                = "terraform-${var.unique_env_name}-mysql-${count.index}"
    stackdriver_monitor = "false"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /vagrant",
      "sudo chown centos /vagrant",
      "mkdir /vagrant/puppet",
      "mkdir /vagrant/database",
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

  provisioner "file" {
    source      = "${path.module}/../database"
    destination = "/vagrant"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=mysql FACTER_ss_consul_server=${aws_instance.consul.0.private_ip} puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'",
    ]
  }
}
