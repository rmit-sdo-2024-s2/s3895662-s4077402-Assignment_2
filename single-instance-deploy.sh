#!/bin/bash
#
# Deploy Foo app - see README.md
# SINGLE INSTANCE

# input aws credentials
echo -e "\nEnter AWS Access Key ID (leave blank for existing creds):"
read AWS_ACCESS_KEY_ID 
echo -e "\nEnter AWS Secret Access Key (leave blank for existing creds):"
read AWS_SECRET_ACCESS_KEY
echo -e "\nEnter AWS Session Token (leave blank for existing creds):"
read AWS_SESSION_TOKEN
echo -e "\nEnter Default Region (leave blank for existing creds):" # e.g. us-east-1
read AWS_DEFAULT_REGION

# load existing credentials if available
if [ -f ~/.aws/credentials ]; then
    EXISTING_ACCESS_KEY_ID=$(grep -oP '(?<=aws_access_key_id=).*' ~/.aws/credentials)
    EXISTING_SECRET_ACCESS_KEY=$(grep -oP '(?<=aws_secret_access_key=).*' ~/.aws/credentials)
    EXISTING_SESSION_TOKEN=$(grep -oP '(?<=aws_session_token=).*' ~/.aws/credentials)
    EXISTING_DEFAULT_REGION=$(grep -oP '(?<=region=).*' ~/.aws/config)
fi

# if inputs are blank then use existing credentials
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    AWS_ACCESS_KEY_ID=$EXISTING_ACCESS_KEY_ID
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    AWS_SECRET_ACCESS_KEY=$EXISTING_SECRET_ACCESS_KEY
fi

if [ -z "$AWS_SESSION_TOKEN" ]; then
    AWS_SESSION_TOKEN=$EXISTING_SESSION_TOKEN
fi

if [ -z "$AWS_DEFAULT_REGION" ]; then
    AWS_DEFAULT_REGION=$EXISTING_DEFAULT_REGION
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
echo "Applying Terraform configuration..."
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