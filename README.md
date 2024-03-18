# Rowden EC2 Shut Down
The Rowden EC2 Shut Down project is designed to provide Lambda Function code in Python and the required Terraform scripts to deploy all required resources into AWS..
## Description
The EC2 Shut Down solution has been designed to be effective and flexible. It has been designed to include some additional checks and automated configuration options to remain effective for varying environments. 
The components are as follows:

AWS Resources:

* Lambda Function code (Python 3.12)
*	IAM Role (Lambda execution role with very limited permissions)
*	EventBridge Rule (Formerly CloudWatch Event) to trigger the Lambda Function (Set as a Cron job to run every day at 23:00 current, but can easily be reconfigured to any suitable time frame and frequency in the Terraform code or directly in AWS)
*	KMS Key (For encryption of the Lambda Function)
  
Terraform Scripts:

*	lambda.tf: To deploy the Lambda Function and any directly related components (The IAM Role for example)
*	kms.tf: To deploy the KMS encryption key
*	cloudwatch_event.tf: To deploy the triggering EventBridge event
*	_global_defaults.tf: Default values to be used during the deployment process
*	_global_variables.tf: Variables requested at deployment time to be used during the deployment process
*	outputs.tf: The outputs to be used during the deployment process
*	provider.tf: Holds the configuration information for where the deployment is to target. Defined here as AWS but without any keys provided, so does need to be amended with specific access keys here, or this can be done through a local account if the code is run from a local source

The basic Lambda Function process is as follows:

*	Check the invoking command for:
    * Any specific ‘Keyword’ to use to identify EC2 instances to be shut down
    *	A list of specific regions to search for matching EC2 instances
*	If none use the defaults:
    *	Keyword defaults to ‘Rowden’ but can easily be edited to be any desired keyword
    *	All available AWS regions (Through the use of ec2:DescribeRegions)
*	Loop through each region in turn getting a list of all EC2 instances in that region
*	The status of the EC2 instance is checked:
    *	If the status is not ‘Running’ or ‘Pending’ then the function moves on to the next instance. Only if the status is ‘Running’ or ‘Pending’ does the code move onto the next stage
*	It uses pattern matching to identify the relevant EC2 instances by looking for the keyword in Tags on the instances (This includes the name of the instance)
*	The configuration of the instances is checked to see if the instance should be hibernated rather than shut down:
    *	If it should be hibernated it is added to a list of instances to be hibernated
    *	If not then it is added to a list of instances that are to be shut down
*	In turn each of the lists is passed to the shut down method
*	The instances are shut down in turn:
    *	Any failures are handled and saved to a list of failed instance shut downs
    *	All completions are saved to a list of completed instance shut downs
*	The output is logged and stored in the CloudWatch log group created by the Lambda Function in the same region and Account that the Function is deployed to (The log group will have the same name as the Lambda Function. If this is not changed it will be ‘ec2_shut_down’)
##Getting Started
###Dependencies
*	All dependences are accounted for with this deployment. The Python packages required by the Lambda Function are already available in AWS so do not need to be packaged with the code
###Installing
To use this code for deployment the following will need to be updated/provided:
* AWS Credentials (Either in the scripts or through local credentials):
    * Needs to have permission in the deployment Account to create:
        * Lambda Functions
        * EventBridge Rules
        * IAM Roles
        * IAM Policies
        * KMS Keys
* AWS deployment Account Id
*	AWS deployment Region
## GitHub Actions
As part of this project GitHub Actions are being used to check any pull request or push command. Theses checks include:
* Completing flake8 checks on the Python code
*	Terraform formatting checks and updates on all Terraform code
There is also scope to additionally complete Terraform Plan and Apply as well, but this is reliant on active AWS credentials being provided.
## Notes
This project has been tailored to provide additional functionality beyond a simple Instance Shut Down process. The code has been written to reduce unnecessary run time and reduce overall computing time as well. By using the Boto3 resource for EC2 to gather the instances list first before creating a Boto3 EC2 client allows for faster information gathering,  and also allows for the client to only be created when needed; If there are instances in a region. 

Additionally, by ensuring that there is the capability to check multiple regions in one invocation the Lambda Function is able to ensure that all relevant instances in all required regions are shut down at the same time, and not missed. By adding in the ability to refine the regions to be checked to a limited list allows for greater targeting and flexibility. Combined with the ability to change the keyword to check for this code becomes much more flexible and reusable as a result. And given the ephemeral and isolated nature of Lambda invocations, this same code can be used for multiple keywords without changing the code at all; Multiple EventBridge rules can be setup to target the same Lambda Function, passing different keywords (And regions if required) without any impact on functionality , latency or run time. 

The output is currently configured to go purely to CloudWatch Logs, but it is a very simple tweak to add in functionality that will enable to output to be sent out using SNS or SES if that was desired.




