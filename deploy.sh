#!/bin/bash
#
# Deploy Foo app - see README.md
#

# set up environment
echo "Testing AWS credentials"
# gets the credentials of the user who is logged in
aws sts get-caller-identity

cd infra
path_to_ssh_key="foo_ec2_key"
# generate an SSH key pair
rm -f "${path_to_ssh_key}"
ssh-keygen -t ed25519 -f "${path_to_ssh_key}" -N ""



# create the infrastructure
echo "Initialising Terraform..."
terraform init
echo "Validating Terraform configuration..."
terraform validate
echo "Running terraform apply, get ready to review and approve actions..."
terraform apply

sleep 30

# connnect to the instance
foo_server_public_hostname=$(terraform output -raw foo_server_public_hostname)
# echo "App public hostname: ${foo_server_public_hostname}"
# check if the app public hostname is empty
if [ -z "${foo_server_public_hostname}" ]; then
  echo "Failed to get app public hostname from Terraform output"
  exit 1
fi

cd ..
# run ansible playbook
path_to_ssh_key="infra/foo_ec2_key"
foo_playbook_path="ansible/foo-playbook.yml"
ansible_inventory_path="infra/.ansible-inventory.yml"
echo "Running Ansible playbook..."
ansible-playbook "${foo_playbook_path}" -i "${ansible_inventory_path}" --private-key="${path_to_ssh_key}" 