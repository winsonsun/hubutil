# Enable debugging
export TF_LOG='DEBUG'; terraform apply -var 'sk_region=ap-northeast-1'

# Create in Asia - Japan, other option is 'sk_region=us-east-1'
terraform apply -var 'sk_region=ap-northeast-1'

# Create instance in US Ohio
terraform apply

terraform destroy

