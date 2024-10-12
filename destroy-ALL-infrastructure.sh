#!/bin/bash
#
# Deploy Foo app - see README.md
# DESTRUCTION

set -e # exit on any error

trap 'echo "An error occured. Exiting..."' ERR # display error message when error occurs

cd infra

echo "Destroying main infrastructure..."
terraform destroy --auto-approve

cd ../bucket

echo "Destroying s3 bucket..."
terraform destroy --auto-approve