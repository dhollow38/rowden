#the lambda function for the ec2 shut down process
resource "aws_lambda_function" "ec2_shut_down_lambda_function" {
  filename          = "lambda_source_code/lambda_ec2_shut_down.zip"
  function_name     = "ec2_shut_down"
  role              = "${aws_iam_role.ec2_shut_down_lambda_execution_role.arn}"
  handler           = "lambda_function.lambda_handler"
  runtime           = "python3.12"
  timeout           = 600
  kms_key_arn       = "${aws_kms_key.kms_ec2_shut_down_lambda_function_key.arn}"
}

#lambda permission to be executed via cloudwatch
resource "aws_lambda_permission" "cloudwatch_execution_lambda_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ec2_shut_down_lambda_function.function_name}"
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.ec2_shut_down.arn}"
}

#execution role for lambda
resource "aws_iam_role" "ec2_shut_down_lambda_execution_role" {
  name               = "iamrole-lambda-ec2-shut-down"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#required cloudwatch logs permissions
resource "aws_iam_policy" "cloudwatch_logs_access_policy" {
  name        = "cloudwatch_logs_access_policy"
  path        = "/"
  description = "Cloudwatch logs permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
                "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${var.account}:*"
      },
      {
        Action = [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${var.account}:log-group:/aws/lambda/${aws_lambda_function.ec2_shut_down_lambda_function.function_name}:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_shut_down_lambda_execution_role_cloudwatch_access" {
  role       = "${aws_iam_role.ec2_shut_down_lambda_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

#required ec2 permissions
resource "aws_iam_policy" "ec2_limited_access_policy" {
  name        = "ec2_limited_access_policy"
  path        = "/"
  description = "Limited EC2 permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
                "ec2:DescribeRegions",
                "ec2:DescribeInstances",
                "ec2:StopInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_shut_down_lambda_execution_role_ec2_limited_access_policy_attachment" {
  role       = "${aws_iam_role.ec2_shut_down_lambda_execution_role.name}"
  policy_arn = "${aws_iam_policy.ec2_limited_access_policy.arn}"
}


