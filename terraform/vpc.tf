# vim: set ft=ruby ts=4 ss=4 sw=4:

provider "aws" {
    region = "us-east-1"
}

variable "cidr_block" {
    default = "10.0.0.0/16"
}

variable "subnet_newbits" {
    default = 8
}

data "aws_availability_zones" "all" {}

data "aws_route_table" "main" {
    vpc_id = "${aws_vpc.main.id}"

    filter {
        name = "association.main"
        values = ["true"]
    }
}

data "aws_security_group" "default" {
    name = "default"
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_vpc" "main" {
    cidr_block = "${var.cidr_block}"
    enable_dns_support = true
    enable_dns_hostnames = false

    tags {
        Name = "Chatbot Test"
    }
}

output "vpc_id" {
    value = "${aws_vpc.main.id}"
}

resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${data.aws_availability_zones.all.names[count.index]}"
    count = "${length(data.aws_availability_zones.all.names)}" 
    cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, var.subnet_newbits, count.index)}"

    tags {
        Name = "Public ${count.index}"
    }
}

resource "aws_subnet" "private" {
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${data.aws_availability_zones.all.names[count.index]}"
    count = "${length(data.aws_availability_zones.all.names)}" 
    cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, var.subnet_newbits, count.index + length(data.aws_availability_zones.all.names))}"

    tags {
        Name = "Private ${count.index}"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "dmz" {
    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "Public Routing Table"
    }
}

resource "aws_route" "dmz_igw" {
    route_table_id = "${aws_route_table.dmz.id}"
    depends_on = ["aws_route_table.dmz"]
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table_association" "dmz" {
    subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id = "${aws_route_table.dmz.id}"
    count = "${length(data.aws_availability_zones.all.names)}" 
}

resource "aws_nat_gateway" "main" {
    subnet_id = "${aws_subnet.public.0.id}"
    allocation_id = "${aws_eip.nat_gateway.id}"
}

resource "aws_eip" "nat_gateway" {
    vpc = true
}

resource "aws_route" "nat" {
    route_table_id = "${data.aws_route_table.main.id}"
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.main.id}"
}
