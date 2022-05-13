resource "aws_db_instance" "pet_store_db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "pet_store_db"
  username             = "admi"
  password             = "admi1234"
  skip_final_snapshot  = true
  publicly_accessible  = true # CAmbiar
  db_subnet_group_name  = aws_db_subnet_group.pet_store_subnet_group.id
  vpc_security_group_ids = [aws_security_group.pet_store_db_sg.id]
  parameter_group_name   = aws_db_parameter_group.pet_store_rds_pg.id

}

resource "aws_db_subnet_group" "pet_store_subnet_group" {
  name       = "pet-store-subnet-group"
  subnet_ids = data.aws_ssm_parameters_by_path.vpc_subnets_db.values

  tags = {
    Name = "pet-store-subnet-group"
  }
}

# Segurity Groups
resource "aws_security_group" "pet_store_db_sg" {
  name        = "pet-store-db-sg"
  vpc_id      = data.aws_ssm_parameter.vpc_id_parameter.value

  ingress {
    description      = "MYSQL traffic"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  } 

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "pet-store-db-sg"
  }
}

resource "aws_db_parameter_group" "pet_store_rds_pg" {
  name   = "pet-store-rds-pg"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
}
resource "aws_ssm_parameter" "db_sg" {
  name  = "/db_sg"
  type  = "String"
  value = aws_security_group.pet_store_db_sg.id
}
