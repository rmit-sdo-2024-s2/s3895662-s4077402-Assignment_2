#!/bin/bash
#
# Deploy Foo app - see README.md
# SINGLE INSTANCE

# input aws credentials
read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
read -p "Enter AWS Session Token: " AWS_SESSION_TOKEN
read -p "Enter Default Region (default is 'us-east-1'): " AWS_DEFAULT_REGION

# us-east-1 is the default if the user doesn't enter a region
if [ -z "$AWS_DEFAULT_REGION" ]; then
    AWS_DEFAULT_REGION="us-east-1"
fi

# populate the credentials file
cat <<EOL > ~/.aws/credentials
[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
aws_session_token=$AWS_SESSION_TOKEN
EOL

# populate the config file
cat <<EOL > ~/.aws/config
[default]
region=$AWS_DEFAULT_REGION
EOL

# get the identity of the user who is logged in
echo "Testing AWS credentials"
aws sts get-caller-identity
echo

sleep 2

cd infra

path_to_ssh_key="foo_ec2_key"
# delete ssh key if present
rm -f "${path_to_ssh_key}"
# generate ssh key
ssh-keygen -t ed25519 -f "${path_to_ssh_key}" -N ""

# create the infrastructure
echo "Initialising Terraform..."
terraform init
echo "Validating Terraform configuration..."
terraform validate
echo "Running terraform apply, get ready to review and approve actions..."
terraform apply --auto-approve

echo -e "\nThe oven is warming up the SSH port...Please wait approximately 30 seconds (sorry)\n"

sleep 30

foo_server_public_hostname=$(terraform output -raw foo_server_public_hostname)
# check if the app public hostname is empty
if [ -z "${foo_server_public_hostname}" ]; then
  echo "Failed to get instance public hostname from Terraform output"
  exit 1
fi

cd ..

path_to_ssh_key="infra/foo_ec2_key"
foo_playbook_path="ansible/foo-playbook.yml"
ansible_inventory_path="infra/ansible-inventory.yml"
# run ansible playbook command
echo "Running Ansible playbook..."
ansible-playbook "${foo_playbook_path}" -i "${ansible_inventory_path}" --private-key="${path_to_ssh_key}" 