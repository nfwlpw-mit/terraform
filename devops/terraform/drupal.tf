resource "aws_security_group" "drupal_server" {
  name        = "${var.unique_env_name}_drupal_server"
  description = "Traffic for drupal servers"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 14367
    to_port   = 14367
    protocol  = "udp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_instance" "drupal" {
  ami           = "ami-43ee3a28"
  instance_type = "t2.small"
  key_name      = "${var.aws_key_name}"
  count         = "${var.drupal_count}"
  subnet_id     = "${element(split(",", var.public_subnets), count.index)}"

  vpc_security_group_ids = [
    "${aws_security_group.instance_default.id}",
    "${aws_security_group.drupal_server.id}",
    "${aws_security_group.consul_client.id}",
    "${aws_security_group.mongo_client.id}",
    "${aws_security_group.mysql_client.id}",
  ]

  connection {
    user     = "centos"
    key_file = "${var.key_file}"
  }

  tags {
    Name                = "terraform-${var.unique_env_name}-drupal-${count.index}"
    stackdriver_monitor = "false"
  }

  lifecycle {
    prevent_destroy = "true"
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
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=drupal FACTER_ss_consul_server=${aws_instance.consul.0.private_ip} puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'",
    ]
  }
}

output "drupal_ip" {
  value = "${aws_instance.drupal.public_ip}"
}
