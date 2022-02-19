FROM mcr.microsoft.com/powershell:lts-ubuntu-18.04
RUN apt-get update

# install common tooling
RUN apt-get install git -y;

# install terraform
RUN apt-get install -y gnupg software-properties-common curl
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get update && apt-get install terraform -y

# install node 14, which is the latest supported nodejs runtime supported by aws lambda at the time of this writing.
RUN curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt install nodejs -y

# install aws cli
RUN apt-get install unzip -y;
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && rm awscliv2.zip
RUN ./aws/install
RUN rm -rf ./aws