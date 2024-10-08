module "vpc" {
  source = "../vpc"

  cidr        = var.vpc_cidr
  environment = var.environment
}

module "private_subnet" {
  source = "../subnet"

  name               = "${var.project}_private_subnet"
  environment        = var.environment
  vpc_id             = module.vpc.id
  cidrs              = var.private_subnet_cidrs
  availability_zones = var.availability_zones
}


module "public_subnet" {
  source = "../subnet"

  name               = "${var.project}_public_subnet"
  environment        = var.environment
  vpc_id             = module.vpc.id
  cidrs              = var.public_subnet_cidrs
  availability_zones = var.availability_zones
}

# module "nat" {
#   source = "../nat_gateway"

#   subnet_ids   = module.public_subnet.ids
#   subnet_count = length(var.public_subnet_cidrs)
# }


module "ec2_utils"{
  source = "../ec2_utils"

  environment = var.environment
  vpc_id      = module.vpc.id
  subnet_ids  = module.public_subnet.ids
  key_name    = var.key_name
  vpc_cidr    = module.vpc.cidr_block
}

resource "aws_route" "public_igw_route" {
  count                  = length(var.public_subnet_cidrs)
  route_table_id         = element(module.public_subnet.route_table_ids, count.index)
  gateway_id             = module.vpc.igw
  destination_cidr_block = var.destination_cidr_block
}

# resource "aws_route" "private_nat_route" {
#   count                  = length(var.private_subnet_cidrs)
#   route_table_id         = element(module.private_subnet.route_table_ids, count.index)
#   nat_gateway_id         = element(module.nat.ids, count.index)
#   destination_cidr_block = var.destination_cidr_block
# }



# Creating a NAT Gateway takes some time. Some services need the internet (NAT Gateway) before proceeding. 
# Therefore we need a way to depend on the NAT Gateway in Terraform and wait until is finished. 
# Currently Terraform does not allow module dependency to wait on.
# Therefore we use a workaround described here: https://github.com/hashicorp/terraform/issues/1178#issuecomment-207369534


# resource "null_resource" "dummy_dependency" {
#   depends_on = [module.nat]
# }




module "nat_instance"{
  source = "../nat_instance"

  vpc_id = module.vpc.id
  environment = var.environment
  public_subnets = module.public_subnet.ids
  private_subnet_route_table_ids = module.private_subnet.route_table_ids
  private_subnets_cidr_blocks = var.private_subnet_cidrs
  vpc_cidr = module.vpc.cidr_block
  key_name = var.key_name
  nat_instance_network_interface_id = module.nat_instance.nat_instance_network_interface_id

}

// private subnet route table nat instance 
resource "aws_route" "private_nat_instance_route" {
  count                  = length(var.private_subnet_cidrs)
  route_table_id         = element(module.private_subnet.route_table_ids, count.index)
  network_interface_id            = module.nat_instance.nat_instance_network_interface_id
  destination_cidr_block = var.destination_cidr_block
}
resource "null_resource" "dummy_dependency" {
  depends_on = [module.nat_instance]
}