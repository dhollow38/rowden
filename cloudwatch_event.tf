#scheduled cloudwatch event
resource "aws_cloudwatch_event_rule" "ec2_shut_down" {
  name        = "ec2_shut_down"
  description = "Shut down any running EC2 Instance that has the defined keyword in an attached Tag, every day"
  schedule_expression = "cron(0 23 ? * * *)"
}

#cloudwatch event target lambda s3_scanner
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.ec2_shut_down.name
  target_id = "TriggerShutDownProcess"
  arn       = "${aws_lambda_function.ec2_shut_down_lambda_function.arn}"
}