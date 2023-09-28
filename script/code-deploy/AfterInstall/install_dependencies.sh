#!/bin/bash

sudo amazon-linux-extras install ansible2 -y
sudo pip2 install botocore boto3 python-ldap
ansible-galaxy collection install amazon.aws community.aws community.general

echo "RUN setup-server.yml"
ansible-playbook /tmp/mbis_front/build/dms-app/ansible/setup-server.yml
echo "RUN main.yml"
ansible-playbook /tmp/mbis_front/script/code-deploy/AfterInstall/main.yml
