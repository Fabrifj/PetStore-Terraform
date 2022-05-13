data "aws_ssm_parameter" "vpc_id_parameter" {
  name = "/vpc/id"
}

data "aws_ssm_parameters_by_path" "vpc_subnets" {
  path = "/vpc/subnets/db"
}
data "aws_ssm_parameter" "db_sg_parameter" {
  name = "/db_sg"
}
