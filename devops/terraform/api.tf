variable "api_instance_size" {
  description = "AWS instance size to use for api nodes."
  default     = "t2.small"
}

resource "aws_security_group" "api_server" {
  name        = "${var.unique_env_name}_api_server"
  description = "Traffic for API servers"
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
    from_port = 3001
    to_port   = 3001
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.drupal_server.id}",
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

resource "aws_iam_server_certificate" "api_cert" {
  name              = "terraform-${var.unique_env_name}-api-cert"
  certificate_body  = "${file("../config/ssl_certs/${var.api_fqdn}.crt")}"
  certificate_chain = "${file("../config/ssl_certs/${var.api_fqdn}.intermediary.crt")}"
  private_key       = "${file("../config/ssl_certs/${var.api_fqdn}.key")}"
}

resource "aws_elb" "api" {
  name    = "terraform-${var.unique_env_name}-api-elb"
  subnets = ["${split(",", var.public_subnets)}"]

  security_groups = [
    "${aws_security_group.elb_default.id}",
    "${aws_security_group.api_server.id}",
  ]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"

    #ssl_certificate_id = "${aws_iam_server_certificate.api_cert.arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:443"
    interval            = 30
  }

  instances                   = ["${aws_instance.api.*.id}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  access_logs {
    bucket        = "ss-us-east-logs"
    bucket_prefix = "${var.unique_env_name}-elb-access-logs"
    interval      = "5"
  }

  tags {
    Name = "terraform-${var.unique_env_name}-api-elb"
  }
}

resource "aws_instance" "api" {
  ami           = "ami-7feb3f14"
  instance_type = "${var.api_instance_size}"
  key_name      = "${var.aws_key_name}"
  count         = 2

  vpc_security_group_ids = [
    "${aws_security_group.instance_default.id}",
    "${aws_security_group.api_server.id}",
    "${aws_security_group.consul_client.id}",
    "${aws_security_group.mongo_client.id}",
    "${aws_security_group.mysql_client.id}",
  ]

  connection {
    user     = "centos"
    key_file = "${var.key_file}"
  }

  subnet_id = "${element(split(",", var.public_subnets), count.index)}"

  #Instance tags
  tags {
    Name                = "terraform-${var.unique_env_name}-api-${count.index}"
    stackdriver_monitor = "false"
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
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=api FACTER_ss_consul_server=${aws_instance.consul.0.private_ip} puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'; exit $?",
    ]
  }
}

output "api_lb" {
  value = "${aws_elb.api.dns_name}"
}

output "api_ips" {
  value = "${join(" ", aws_instance.api.*.public_ip)}"
}

output "api_private_ips" {
  value = "${join(" ", aws_instance.api.*.private_ip)}"
}

output "api_instances" {
  value = "${join(" ", aws_instance.api.*.id)}"
}
