# vim: set ft=ruby ts=4 ss=4 sw=4:

resource "aws_iam_role" "bot_lambda" {
    name = "bot_lambda"

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bot_lambda" {
    role       = "${aws_iam_role.bot_lambda.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "lambda_zip" {
    type  = "zip"
    source_dir = "lambda"
    output_path = "prometheus.zip"
}

resource "aws_lambda_function" "prometheus" {
    filename = "prometheus.zip"
    function_name = "prometheus"
    role = "${aws_iam_role.bot_lambda.arn}"
    handler = "exports.handler"
    source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
    runtime = "nodejs6.10"

    vpc_config {
        subnet_ids = ["${aws_subnet.private.*.id}"]
        security_group_ids = ["${data.aws_security_group.default.id}"]
    }
}
