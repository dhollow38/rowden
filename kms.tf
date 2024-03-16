#kms key for sns topic encryption
resource "aws_kms_key" "kms_ec2_shut_down_lambda_function_key" {
  description         = "KMS Key for the EC2 Shut Down Lambda Function"
  key_usage           = "ENCRYPT_DECRYPT"
  policy              = "${data.aws_iam_policy_document.kms_ec2_shut_down_lambda_function_key_policy.json}"
}

#kms key alias
resource "aws_kms_alias" "kms_ec2_shut_down_lambda_function_alias" {
  name          = "alias/kms-ec2-shut-down-lambda-encryptionkey"
  target_key_id = "${aws_kms_key.kms_ec2_shut_down_lambda_function_key.key_id}"
}

#kms key policy
data "aws_iam_policy_document" "kms_ec2_shut_down_lambda_function_key_policy" {
  policy_id = "kms_ec2_shut_down_lambda_function_key_policy"

  statement {
    sid = "Enable IAM User Permissions"
    actions = ["kms:*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account}:root"
      ]
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow access for key usage"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:Encrypt"
    ]
    resources = [
      "*"
    ]
  }
}