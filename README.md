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

## Overview ##
This project was implemented using an AWS Lambda Function sitting behind an Application Load Balancer.  The lambda function is hosted in a VPC, within a private subnet, and the ALB is hosted on two public subnets for internet access.  The VPC has an internet gateway, an Elastic IP address, and a NAT gateway in one of the public subnets, to give the private subnet internet access.


The structure looks like this:
![High Level Diagram](https://github.com/depinore2/petal_takehome/raw/main/docs/petal-high-level-diagram_2.png)