resource "aws_security_group" "alarm_nat_server" {
  name        = "${var.unique_env_name}_alarm_nat_server"
  description = "NAT server with access to dev alarm servers."
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    cidr_blocks = [
      "10.50.0.0/16",
    ]
  }
}

resource "aws_security_group" "alarm_nat_client" {
  name        = "${var.unique_env_name}_alarm_nat_client"
  description = "Clients that should have access to the dev alarm servers through nat."
  vpc_id      = "${var.vpcid}"
}

resource "aws_eip" "alarm_nat" {
  instance = "${aws_instance.alarm_nat.id}"
  vpc      = true
}

resource "aws_instance" "alarm_nat" {
  ami               = "ami-303b1458"
  instance_type     = "t2.small"
  key_name          = "${var.aws_key_name}"
  count             = 1
  subnet_id         = "${element(split(",", var.public_subnets), count.index)}"
  source_dest_check = false

  vpc_security_group_ids = [
    "${aws_security_group.instance_default.id}",
    "${aws_security_group.alarm_nat_server.id}",
  ]

  connection {
    user     = "ec2-user"
    key_file = "${var.key_file}"
  }

  tags {
    Name                = "terraform-${var.unique_env_name}-alarm-nat-${count.index}"
    stackdriver_monitor = "false"
  }
}
