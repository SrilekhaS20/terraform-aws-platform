resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public_sub" {
  for_each = {
    for index, az in var.availability_zones :
    az => index
  }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[each.value]
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_internet_gateway" "igw_main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  for_each       = aws_subnet.public_sub
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "private_sub" {
  for_each = {
    for index, az in var.availability_zones :
    az => index
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[each.value]
  availability_zone = each.key

  tags = {
    Name = "${var.environment}-private-${each.key}"
    Tier = "private"
  }
}

resource "aws_eip" "nat_eip" {
  for_each = toset(var.availability_zones)

  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "natgw_main" {
  for_each = aws_subnet.public_sub

  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id = each.value.id

  depends_on = [
    aws_internet_gateway.igw_main
  ]

  tags = {
    Name = "${var.environment}-nat-${each.key}"
  }
}