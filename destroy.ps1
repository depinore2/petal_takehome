param([string]$region = 'us-west-2')
terraform destroy -auto-approve -var region=$region