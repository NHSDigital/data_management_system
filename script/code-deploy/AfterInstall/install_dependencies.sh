#!/bin/bash

sudo amazon-linux-extras install ansible2 -y
sudo yum install python-pip python-devel openldap-devel -y
sudo pip2 install botocore boto3 python-ldap
ansible-galaxy collection install amazon.aws community.aws community.general
sudo yum install jq -y

echo "APPLICATION_NAME"
echo $APPLICATION_NAME

echo "DEPLOYMENT_ID"
echo $DEPLOYMENT_ID

echo "DEPLOYMENT_GROUP_NAME"
echo $DEPLOYMENT_GROUP_NAME

echo "DEPLOYMENT_GROUP_ID"
echo $DEPLOYMENT_GROUP_ID

echo "LIFECYCLE_EVENT $LIFECYCLE_EVENT"

echo "directory: " $PWD 
echo "home: " $HOME
echo "user: " $USER

echo "RUN main.yml"
ansible-playbook /tmp/mbis_front/build/dms-app/ansible/setup-server.yml
ansible-playbook /tmp/mbis_front/script/code-deploy/AfterInstall/main.yml

# echo "" > ~/.ssh/known_hosts
# source ~/.bash_profile && bundle exec cap localhost_live deploy:setup
# source ~/.bash_profile && bundle exec cap localhost_live deploy:cold


# ansible-playbook install_dependencies.yml 
# DATABASE_PASSWORD=$(aws ssm get-parameters --names '/dms/dev/postgres/users/dmsmaster/password'  --with-decryption | jq -r '.Parameters[]' | jq -r '.Value')
# echo $DATABASE_PASSWORD
# ODR_USERS=$(aws  ssm get-parameters --names '/mbis/dev/odr_users.yml'  --with-decryption | jq -r '.Parameters[]' | jq -r '.Value')
# echo $ODR_USERS