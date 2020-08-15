resource "aws_vpc" "main" {
  cidr_block           = var.vpc_main_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "main-vpc"
    Environment = var.env
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  availability_zone = "${data.aws_region.current.name}${var.availability_zones[count.index]}"
  cidr_block        = cidrsubnet(var.vpc_main_cidr, 8, 1 + count.index)
  vpc_id            = aws_vpc.main.id

  tags = {
    Name                              = "main-private-subnet-${var.availability_zones[count.index]}"
    Environment                       = var.env
    Access                            = "private"
    "kubernetes.io/cluster/default"   = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  availability_zone = "${data.aws_region.current.name}${var.availability_zones[count.index]}"
  cidr_block        = cidrsubnet(var.vpc_main_cidr, 8, 249 - count.index)
  vpc_id            = aws_vpc.main.id

  tags = {
    Name                            = "main-public-subnet-${var.availability_zones[count.index]}"
    Environment                     = var.env
    Access                          = "public"
    "kubernetes.io/cluster/default" = "shared"
    "kubernetes.io/role/elb"        = "1"
  }
}

resource "aws_eip" "main_natgw" {
  count = length(var.availability_zones)

  vpc = true

  tags = {
    Name        = "main-eip-natgw-${aws_subnet.public[count.index].availability_zone}"
    Environment = var.env
  }
}

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.main_natgw[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "main-natgw-${aws_subnet.public[count.index].availability_zone}"
    Environment = var.env
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name        = "main-internetgw"
    Environment = var.env
  }
}

resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.main[count.index].id}"
  }

  tags = {
    Name        = "main-private-rtb-${aws_subnet.private[count.index].availability_zone}"
    Environment = var.env
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags = {
    Name        = "main-public-rtb"
    Environment = var.env
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
