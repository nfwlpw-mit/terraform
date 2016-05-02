resource "aws_security_group" "webapp_server" {
  name        = "${var.unique_env_name}_webapp_server"
  description = "Traffic for WebApp servers"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "64.119.134.46/32",
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "64.119.134.46/32",
    ]
  }
}

resource "aws_elb" "webapp" {
  name    = "terraform-${var.unique_env_name}-webapp-elb"
  subnets = ["${split(",", var.public_subnets)}"]
  count   = "${var.webapp_elb_count}"

  security_groups = [
    "${aws_security_group.elb_default.id}",
    "${aws_security_group.webapp_server.id}",
  ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  #listener {


  #  instance_port = 443


  #  instance_protocol = "https"


  #  lb_port = 443


  #  lb_protocol = "https"


  #  ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"


  #}

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
  instances                   = ["${aws_instance.webapp.*.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  tags {
    Name = "terraform-${var.unique_env_name}-webapp-elb"
  }
}

resource "aws_instance" "webapp" {
  ami           = "ami-7feb3f14"
  instance_type = "t2.small"
  key_name      = "${var.aws_key_name}"
  count         = "${var.webapp_count}"

  vpc_security_group_ids = [
    "${aws_security_group.instance_default.id}",
    "${aws_security_group.webapp_server.id}",
    "${aws_security_group.consul_client.id}",
  ]

  connection {
    user     = "centos"
    key_file = "${var.key_file}"
  }

  subnet_id = "${element(split(",", var.public_subnets), count.index)}"

  #Instance tags
  tags {
    Name = "terraform-${var.unique_env_name}-webapp-${count.index}"
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
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=webapp FACTER_ss_consul_server=${aws_instance.consul.0.private_ip} puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'",
    ]
  }
}

output "webapp_lb" {
  value = "${aws_elb.webapp.dns_name}"
}

output "webapp_ips" {
  value = "${join(" ", aws_instance.webapp.*.public_ip)}"
}
