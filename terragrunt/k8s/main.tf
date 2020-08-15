data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

data "aws_subnet_ids" "main_private" {
  vpc_id = data.aws_vpc.main.id

  filter {
    name   = "tag:Access"
    values = ["private"]
  }
}
