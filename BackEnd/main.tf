locals {
    instance_ami = "ami-0022f774911c1d690"
    subnet_ids   = data.aws_ssm_parameters_by_path.vpc_subnets.values
}
# BackEnd Template
resource "aws_launch_template" "dbsite_lt" {
  name = "dbsite_launch_template"

  image_id = local.instance_ami

  instance_type = "t2.micro"

  #key_name = "petStoreKeyPair"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.pet_store_instance_sg.id, db_sg_parameter]
  }

#   vpc_security_group_ids = 

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "asg-instance"
    }
  } 

  user_data = filebase64("${path.module}/user_data.sh")
}
# Segurity Groups
resource "aws_security_group" "pet_store_instance_sg" {
  name        = "pet-store-instance-sg"
  vpc_id      = data.aws_ssm_parameter.vpc_id_parameter.value

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "pet-store-instance-sg"
  }
}

resource "aws_autoscaling_group" "dbsite_asg" {
  vpc_zone_identifier = local.subnet_ids
  desired_capacity   = 2
  max_size           = 3
  min_size           = 1

  launch_template {
    id      = aws_launch_template.dbsite_lt.id
    version = "$Latest"
  }
}

resource "aws_lb_target_group" "dbsite_tg" {
  name        = "dbsite-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id_parameter.value
}

resource "aws_security_group" "pet_store_load_balancer_sg" {
  name        = "pet-store-load-balancer-sg"
  vpc_id      = data.aws_ssm_parameter.vpc_id_parameter.value

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags = {
    Name = "pet-store-load-balancer-sg"
  }
}



resource "aws_lb" "pet_store_alb" {
  name               = "pet-store-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pet_store_load_balancer_sg.id]
  subnets            = local.subnet_ids

}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.dbsite_asg.id
  lb_target_group_arn    = aws_lb_target_group.dbsite_tg.arn
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.pet_store_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dbsite_tg.arn
  }
}

