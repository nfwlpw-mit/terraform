# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "terraform_example"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "terraform_example"
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "terraform_example_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "terraform_example"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_elb" "web" {
  name = "terraform-example-elb"

  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
#  instances       = ["${aws_instance.web.id}"]
	#instances = ["${aws_instance.web.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_autoscaling_policy" "tf-andywang-ss-up" {
    name = "agents-scale-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.tf-andywang-ss.name}"
}

resource "aws_autoscaling_policy" "tf-andywang-ss-down" {
    name = "agents-scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.tf-andywang-ss.name}"
}

resource "aws_launch_configuration" "tf-andywang-ss" {
    name = "terraform_example-web_config2"
    image_id = "${lookup(var.aws_amis, var.aws_region)}"
    instance_type = "t2.micro"
    # vpc_security_group_ids = ["${aws_security_group.default.id}"]
    security_groups= ["${aws_security_group.default.id}"]
    user_data = "${file("userdata.sh")}"
    key_name = "${var.key_name}"
}

# resource "aws_autoscaling_policy" "tf-andywang-ss" {
#   name = "terraform_example-asg-policy"
#   scaling_adjustment = 1
#   adjustment_type = "ChangeInCapacity"
#   cooldown = 300
#   autoscaling_group_name = "${aws_autoscaling_group.tf-andywang-ss.name}"
# }
resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "mem-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.tf-andywang-ss-up.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.tf-andywang-ss.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "mem-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "40"
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.tf-andywang-ss-down.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.tf-andywang-ss.name}"
    }
}

resource "aws_autoscaling_group" "tf-andywang-ss" {
  availability_zones = ["us-east-1e"]
  name = "terraform_example-asg2"
  max_size = 2
  min_size = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.tf-andywang-ss.name}"
  load_balancers = ["${aws_elb.web.name}"]
  tag {
    key="Name"
    value= "tf-andywang-ss-asg"
    propagate_at_launch = true
    # Name = "tf-andywang-ss.${count.index}"
  }
  vpc_zone_identifier = ["${aws_subnet.default.id}"]
}

# resource "aws_instance" "web" {
#   # The connection block tells our provisioner how to
#   # communicate with the resource (instance)
#   tags {
#     Name = "tf-andywang-ss.${count.index}"
#   }
  
#   count = "2"
#   connection {
#     # The default username for our AMI
#     user = "ubuntu"

#     key_file = "${var.private_key_path}"
#     # The connection will use the local SSH agent for authentication.
#   }

#   instance_type = "t2.micro"

#   # Lookup the correct AMI based on the region
#   # we specified
#   ami = "${lookup(var.aws_amis, var.aws_region)}"

#   # The name of our SSH keypair we created above.
#   key_name = "${aws_key_pair.auth.id}"

#   # Our Security group to allow HTTP and SSH access
#   vpc_security_group_ids = ["${aws_security_group.default.id}"]

#   # We're going to launch into the same subnet as our ELB. In a production
#   # environment it's more common to have a separate private subnet for
#   # backend instances.
#   subnet_id = "${aws_subnet.default.id}"

#   # We run a remote provisioner on the instance after creating it.
#   # In this case, we just install nginx and start it. By default,
#   # this should be on port 80
#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt-get -y update",
#       "sudo apt-get -y install nginx",
#       "sudo service nginx start"
#     ]
#   }
# }
