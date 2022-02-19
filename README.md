# Petal Take-Home Assignment

## Getting Started ##
This uses terraform, nodejs, and a little bit of powershell.  Rather than assuming that you have this tooling available on your local machine, I decided to use a docker container that can be spun up in a VS Code session using the "Remote - Containers" extension.  

Please make sure you have [Visual Studio Code](https://code.visualstudio.com/) and [the aforementioned extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed.

Once that's done, follow these steps:
1. Open the Command Palette (`CTRL+Shift+P` on Linux and Windows, `Cmd+Shift+P` on macOS).
1. Select "Reopen and Rebuild in Container".
1. Once that's done building up, open the terminal.
1. Run `pwsh` to get a Powershell Core session started.
1. Run the initialization script: `./run.ps1`.
1. You will be asked for AWS API keys in order to deploy the terraform resources.
1. Once all is provisioned, the script will go through a routine where it asks you for a string and interacts with the API on your behalf.
1. After you're done with everything, please run `./destroy.ps1` to tear the AWS environment down.

## Overview ##
This project was implemented using an AWS Lambda Function sitting behind an Application Load Balancer.  The "SPAC_LLA" lambda function is hosted in a VPC, within a private subnet, and the ALB is hosted on two public subnets for internet access.  The VPC has an internet gateway, an Elastic IP address, and a NAT gateway in one of the public subnets, to give the private subnet internet access.

The lambda function stores its logs in Amazon Cloudwatch.


The structure looks like this:
![High Level Diagram](https://github.com/depinore2/petal_takehome/raw/main/docs/petal-high-level-diagram_2.png)

It wasn't strictly a requirement to host this lambda function in a VPC to fulfill the requirements of the exercise, but I was hoping to showcase some networking skills by hosting the endpoint in a VPC.

## Client Request Network Path ##
When a client makes a request to the endpoint, it folows this path:
1. Request hits the internet gateway.
1. The internet gateway routes the request to one of the two Application Load Balancer endpoints in either public1 or public2 subnets. 
1. All requests are then forwarded to the lambda ALB target group.
1. The target group forwards the request to the SPAC_LLA function, in the private1 subnet.

It looks like this:
![High Level Diagram](https://github.com/depinore2/petal_takehome/raw/main/docs/petal-user-to-lambda_2.png)

## SPAC_LLA to shoutcloud.io Network Path ##
After the lambda function is invoked, it sends a request to the shoutcloud.io API endpoint:

1. Because the lambda function is inside of a private subnet, the request is routed to the NAT gateway in public1.
1. From there, the NAT gateway performs NAT and uses an elastic IP address assigned to it in order to forward the request to the Internet Gateway.
1. The internet gateway sends the request to shoutcloud.io
1. HTTP traffic is then routed back in reverse, using an ephemeral port.

This is what the path to shoutcloud looks like:
![High Level Diagram](https://github.com/depinore2/petal_takehome/raw/main/docs/petal-lambda-to-shoutcloud_2.png)

## Choice of AWS Lambda ##
AWS Lambda is a good choice for very quick one-off APIs, or when an infrastructure engineer needs to implement some kind of customization to back-end AWS processes.

In my case, I chose lambda because I had a very limited amount of time.  I knew that AWS would handle auto-scaling for me out of the box, and I knew that robust code review and source control was not a consideration for this exercise.

## EKS Instead ##

If I had the time, and if this application was being written by a development team, I would've instead built out an EKS cluster, probably using EKS Fargate nodes.

Logs would've been sent to AWS Kinesis Data Firehose and the forwarded to S3, which would give engineers the ability to inspect logs at will using Athena.

Any important notifications from the cluster could've been handled by AWS SNS, sending messages to Slack or PagerDuty using webhooks.

![High Level Diagram](https://github.com/depinore2/petal_takehome/raw/main/docs/petal-EKS%20instead%20of%20Lambda.png)

## Deployment of the Demo As-Is ##
This demo uses terraform to provision the various AWS resources.  The source code for the lambda endpoint is zipped and then provided to terraform in binary format.

## Ideal Deployment of API to Test Environment ##
In an ideal world, the deployment of the infrastructure and API source code would've followed a different pattern.

The infrastructure would have been deployed using build and release automation on a build server, such as AWS CodeBuild.  From there, `terraform apply` would apply the appropriate infrastructural changes.

The source code for the API would have been held in a different repository, under the management of a development team.  The dev team would have followed a similar CI/CD pipeline, where they check their API source code in which triggers AWS CodeBuild.

Because we'd be working with containers, CodeBuild would have taken the source code and packaged up all of the API artifacts into a Docker Container.  This container would have been published to AWS Elastic Container Registry.  Any additional artifacts not placed directly in a container would be pushed to S3.

After the artifacts are published to both ECR and S3, the build automation would apply these changes to a test EKS cluster using a tool such as `helm` or even just `kubectl`.

Finally, the kubernetes cluster would download these updated container images from ECR, and run the API code.

![Test Environment Deployment](https://github.com/depinore2/petal_takehome/raw/main/docs/alltrails-Deployment%20(Test).png)

## Ideal Deployment of API to Prod Environment ##
Deployment to a production environment would work similarly to the test environment, except that there would not need to be additional containers produced.  Ideally, the containers would be built in such a way where they are reusable across environments (given different ConfigMaps).

The biggest difference is that perhaps there would be a stakeholder in charge of approving the release.

![Test Environment Deployment](https://github.com/depinore2/petal_takehome/raw/main/docs/alltrails-Deployment%20(Prod).png)

## Final Thoughts ##
It was nice to showcase my skills with this exercise, but I wish I managed my time a bit better.  

If I were to do this all over again, I would have worked on this incrementally, where I deploy the lambda function without a VPC first.  Much of the hang-up for me was configuring and troubleshooting the various subnets, route tables, and NACLs.  I've done a fair amount of take-home exercises, but this was the first one where it felt like there was a hard cut-off on the time allotted. 

Despite that, I'm happy I got an "almost" working solution by the 3-hour mark, finalized the solution at 4 hours, and got some good documentation in.  

I hope you enjoyed reading through my work, and I look forward to hearing your thoughts at our next encounter.  Thanks for your time!