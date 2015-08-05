#OpenSource Connections AWS Lambda Functions
These functions make your life easier!  OSC can make your life easier too.

# About
This repo is to make it easy for you to harness some AWS Lambda functions for your environment. Currently there are the following functions:

 * AMILookup
 * StackOutputsLookup
 
Currently the functions are for CloudFormation custom resource calls only. The design is to create as minimal non-CloudFormation expressed resources as possible and then use only CloudFormation managed resources from there out. Why do it this way? By enumerating your infrastructure via CloudFormation you reduce the number of resources which are present without a readily apparent code driven reason of exiting. CloudFormation deployments keep your resource allocations explicitly defined in code.

These CloudFormations explicitly define everything needed for any of the Lambda functions provided except for the core `lambda-stack-outputs-lookup`. Because the naming of Lambda functions when declared via CloudFormation is unpredictable, the `bin/roll-out.sh` script creates the StackOutputsLookup Lambda function outside of all the CloudFormation templates, however StackOutputsLookup's permissions are defined in CloudFormation. All subsequent Lambda functions permissions and resource definitions are explicitly declared in the CloudFormations. Those Lambda functions, while having unpredictable resource names, have predictable CloudFormation names and then ARN needed to call the Lambda function is set in the Output of the CloudFormation. Therefore, to use any other Lambda functions you simple make a call to the StackOutputsLookup function to retrieve the ARN of the explicitly created and managed Lambda function you wish to call, ie ami-lookup.

# How to use
All lambda functions build upon the lambda-stack-outputs-lookup call. Because the `lambda-stack-outputs-lookup` function is predictably named you can include it in all your other templates and they will adapt to whatever region and account you need to use.

```json
  "Resources" : {
    "ExampleStackOutputsLookup": {
      "Type": "Custom::StackOutputs",
      "Properties": {
        "ServiceToken": { "Fn::Join": [ "", [ "arn:aws:lambda:", { "Ref": "AWS::Region" }, ":", { "Ref": "AWS::AccountId" }, ":function:StackOutputsLookup" ] ] },
        "StackName" : "lambda-stack-outputs-lookup"
      }
    }
  },
  "Outputs" : {
    "ExampleOutputLookupResult" : {
      "Description": "The ARN of the Lambda function.",
      "Value" : { "Fn::GetAtt": [ "ExampleStackOutputsLookup", "StackOutputsLookupRole" ] }
    }
  }
```

# Requirements
A local install of AWS CLI.
 
# Quickstart
 1. `bin/roll-out.sh all` to deploy Lambda functions.
 1. `aws cloudformation create-stack --stack-name example-ami-lookup --template-body file://./cloudformation/example-ami-lookup.json`
 1. `aws cloudformation create-stack --stack-name example-stack-outputs --template-body file://./cloudformation/example-stack-outputs-lookup.json`
 
# Deleting
You can remove everything from the infrastructure using the `bin/nuke.sh` command.

# Examples
After rolling out the core Lamba functions you can dynamically lookup 

# Get in touch
 * [TalkToUs@o19s.com](mailto:TalkToUs@o19s.com)
 * [opensourceconnections.com](http://opensourceconnections.com/)
