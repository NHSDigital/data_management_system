#!/bin/bash
sudo yum install ansible python3-pip -y
sudo yum install curl --allowerasing -y
sudo pip install botocore boto3 --no-input
ansible-galaxy collection install amazon.aws community.aws community.general

EXTRA_VARS='app_user=mbis_app'

echo "RUN setup-server.yml"
ansible-playbook /tmp/mbis_front/build/dms-app/ansible/setup-server.yml --extra-vars "$EXTRA_VARS"
echo "RUN main.yml"
ansible-playbook /tmp/mbis_front/script/code-deploy/AfterInstall/main.yml --extra-vars "$EXTRA_VARS"
