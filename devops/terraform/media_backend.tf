variable "media-backend_count" {
  description = "Number of media-backend servers to manage with terraform.  Set to 0 if media-backend already exists and manually register it with consul, or if you don't want it deployed to your environment yet."
  default     = "0"
}

variable "media-backend_elb_count" {
  description = "Whether or not to build the media-backend ELB.  Should be 0 or 1"
  default     = "0"
}

variable "media-backend_fqdn" {
  description = "Url to be used for media-backend."
}

resource "aws_security_group" "media-backend_server" {
  name        = "${var.unique_env_name}_media-backend_server"
  description = "Traffic for media backend server"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port = 3010
    to_port   = 3010
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 8892
    to_port   = 8892
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_iam_server_certificate" "media-backend_cert" {
  name              = "tf-${var.unique_env_name}-media-backend-cert"
  certificate_body  = "${file("../config/ssl_certs/${var.media-backend_fqdn}.crt")}"
  certificate_chain = "${file("../config/ssl_certs/${var.media-backend_fqdn}.intermediary.crt")}"
  private_key       = "${file("../config/ssl_certs/${var.media-backend_fqdn}.key")}"
}

resource "aws_elb" "media-backend" {
  name    = "tf-${var.unique_env_name}-media-backend-elb"
  subnets = ["${split(",", var.public_subnets)}"]
  count   = "${var.media-backend_elb_count}"

  security_groups = [
    "${aws_security_group.elb_default.id}",
    "${aws_security_group.media-backend_server.id}",
  ]

  listener {
    instance_port     = 3010
    instance_protocol = "http"
    lb_port           = 3010
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8892
    instance_protocol = "tcp"
    lb_port           = 8892
    lb_protocol       = "tcp"

    #ssl_certificate_id = "${aws_iam_server_certificate.media-backend_cert.arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:443"
    interval            = 30
  }

  instances                   = ["${aws_instance.media-backend.*.id}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "tf-${var.unique_env_name}-media-backend-elb"
  }
}

resource "aws_instance" "media-backend" {
  ami           = "ami-7feb3f14"
  instance_type = "t2.small"
  key_name      = "${var.aws_key_name}"
  count         = "${var.media-backend_count}"

  vpc_security_group_ids = [
    "${aws_security_group.instance_default.id}",
    "${aws_security_group.media-backend_server.id}",
    "${aws_security_group.consul_client.id}",
    "${aws_security_group.mongo_client.id}",
    "${aws_security_group.mysql_client.id}",
  ]

  connection {
    user     = "centos"
    key_file = "~/.ssh/${var.aws_key_name}.pem"
  }

  subnet_id = "${element(split(",", var.public_subnets), count.index)}"

  #Instance tags
  tags {
    Name                = "tf-${var.unique_env_name}-media-backend-${count.index}"
    stackdriver_monitor = "false"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /vagrant",
      "sudo chown centos /vagrant",
      "mkdir /vagrant/puppet",
      "sudo mkdir -p /mnt/ss_media-backend",
      "sudo chown -R centos /mnt/ss_media-backend",
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
      "chmod ugo+rw -R /mnt/ss_media-backend",
      "cd /vagrant; sudo bash -c 'FACTER_ss_class=media FACTER_ss_consul_server=${aws_instance.consul.0.private_ip} puppet apply --modulepath puppet/modules/ --hiera_config config/hiera.yaml puppet/manifests/default.pp'; exit $?",
    ]
  }
}

output "media-backend_lb" {
  value = "${aws_elb.media-backend.dns_name}"
}

output "media-backend_ips" {
  value = "${join(" ", aws_instance.media-backend.*.public_ip)}"
}
