#!/bin/bash
#
# Deploy Foo app - see README.md
#

# set up environment
echo "Testing AWS credentials"
# gets the credentials of the user who is logged in
aws sts get-caller-identity
app_playbook_path="ansible/app-playbook.yml"
cd infra
path_to_ssh_key="foo_ec2_key"
# generate an SSH key pair
ssh-keygen -f "${path_to_ssh_key}" -N ""



# create the infrastructure
echo "Initialising Terraform..."
terraform init
echo "Validating Terraform configuration..."
terraform validate
echo "Running terraform apply, get ready to review and approve actions..."
terraform apply

# connnect to the instance
foo_server_public_hostname=$(terraform output -raw foo_server_public_hostname)
echo "App public hostname: ${foo_server_public_hostname}"
# check if the app public hostname is empty
if [ -z "${foo_server_public_hostname}" ]; then
  echo "Failed to get app public hostname from Terraform output"
  exit 1
fi
# if the user doesn't have cloud-init installed, install it
if ! command -v cloud-init &> /dev/null; then
  echo "cloud-init not found, installing..."
  sudo apt-get update
  sudo apt-get install -y cloud-init
fi

# TODO: turn this into a while loop with a timeout because cloud-init can take a while
echo "Waiting for cloud-init to finish... (accept SSH fingerprint if prompted)"
# wait for cloud-init to finish and we can connect to the instance
sleep 5
ssh ubuntu@"${foo_server_public_hostname}" -i "${path_to_ssh_key}" cloud-init status -w


# cd to root directory
cd ../

# run ansible playbook
path_to_ssh_key="misc/foo_ec2_key"
echo "Running Ansible playbook..."
ansible-playbook -i "${foo_server_public_hostname}," -u ubuntu --private-key="${path_to_ssh_key}" "${app_playbook_path}"