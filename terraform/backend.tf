# vim: set ft=ruby ts=4 ss=4 sw=4:

terraform {
  backend "s3" {
    bucket = "terraform-274js8"
    key    = "chatbot/terraform.tfstate"
    region = "eu-west-2"
  }
}
