# modules/vpc/main.tf

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = var.project_name
  }
}

resource "aws_eip" "nat_gateway" {
  vpc        = true
  count      = length(var.public_subnets_cidrs) # One NAT Gateway per public subnet (for high availability)

  tags = {
    Name        = "${var.project_name}-nat-eip-${count.index}"
    Project     = var.project_name
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = element(aws_eip.nat_gateway.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  count         = length(var.public_subnets_cidrs)

  tags = {
    Name        = "${var.project_name}-nat-${count.index}"
    Project     = var.project_name
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index}"
    Project     = var.project_name
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index}"
    Project     = var.project_name
  }
}

resource "aws_subnet" "database" {
  count             = length(var.database_subnets_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnets_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-database-subnet-${count.index}"
    Project     = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = var.project_name
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets_cidrs)
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-private-rt-${count.index}"
    Project     = var.project_name
  }
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(var.private_subnets_cidrs)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.database.*.id
  description = "Subnet group for RDS instances"

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Project     = var.project_name
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-elasticache-subnet-group"
  subnet_ids = aws_subnet.private.*.id # ElastiCache needs at least two subnets in different AZs.
  description = "Subnet group for ElastiCache Redis"

  tags = {
    Name        = "${var.project_name}-elasticache-subnet-group"
    Project     = var.project_name
  }
}