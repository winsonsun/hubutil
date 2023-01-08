# Enable debugging
export TF_LOG='DEBUG'; terraform apply -var 'sk_region=ap-northeast-1'

# Create in Asia - Japan, other option is 'sk_region=us-east-1'
terraform apply -var 'sk_region=ap-northeast-1'

# Create instance in US Ohio
terraform apply

terraform destroy

#copy id for aws-console's public key
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAhXsHzyHZAR4eNjS85iqkeiFLpgjVPdk2U2Q9BNZp3/8GZUVzwVTog9Ow9ss7jGHy8WWnWAcFUxLaOjI2gZopOcuErB6Tytms/Z/zHycL3PVRhWHrqD61SEDV9U3eBnKy+tWjHEq8xTEPFDN3aTdVhA5lLw4DvH+H5IdERRjrwjotM/d/xvq73RbySE79QTEIlsmNYbCrLfnklXeoaJxoQLrBHJsd05iIoMwj/xNVTJNLuYQ0nhvtQ61waMG91hF5IvIxONyJDmlwups9+sBC6XNN9EYmXawuBfnQ4gcFIyuzodTUUzA41jYhMUxv/IaAD+mvJgZ28Zc1m8/hoewH ubuntu@ip-172-26-4-82" >> /root/.ssh/authorized_keys

# Recreate the whole instance, by terraform destroy/apply in sequence
./newsk.sh

# Refresh new static ip for skshell lightsail instance, without full recreation
script/release-attach-new-static-ip.sh
