resource "aws_vpc" "pet_store_vpc" {
  cidr_block = "10.16.0.0/16"
  assign_generated_ipv6_cidr_block=true
  enable_dns_hostnames=true
  tags = {
    Name = "pet-store-vpc"
  }
}

resource "aws_subnet" "subnets" {
  for_each = local.subnets
  vpc_id     = aws_vpc.pet_store_vpc.id
  cidr_block = each.value.cidr_block
  availability_zone=each.value.az

  tags = {
    Name = each.key
    Type = each.value.type
  }
}
resource "aws_internet_gateway" "pet_store_igw" {
  vpc_id = aws_vpc.pet_store_vpc.id

  tags = {
    Name = "pet-store-igw"
  }
}

resource "aws_route_table" "pet_store_rt" {
  vpc_id = aws_vpc.pet_store_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pet_store_igw.id
  }

  tags = {
    Name = "pet-store-web-rt"
  }
}
resource "aws_route_table_association" "web_rt_association" {
  for_each = {
    "sn-web-A" = local.subnets.sn-web-A
    "sn-web-B" = local.subnets.sn-web-B
    "sn-web-C" = local.subnets.sn-web-C
  }
  subnet_id      = aws_subnet.subnets["${each.key}"].id
  route_table_id = aws_route_table.pet_store_rt.id
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/vpc/id"
  type  = "String"
  value = aws_vpc.pet_store_vpc.id
}

resource "aws_ssm_parameter" "vpc_subnet" {
  for_each = aws_subnet.subnets
  name  = "/vpc/subnets/${each.value.tags_all.Type}/${each.value.id}"
  type  = "String"
  value = each.value.id
}