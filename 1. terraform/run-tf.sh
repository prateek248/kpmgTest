#!/bin/bash

echo "please ensure aws access key and secret key have been put in variables.tf"
terraform init
terraform plan
terraform apply --auto-approve