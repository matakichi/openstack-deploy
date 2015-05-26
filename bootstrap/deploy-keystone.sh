#!/bin/bash

. vars.sh

echo "##### Start deploying a Keystone Services.... #####"

apt-get install -y keystone python-keystoneclient
cp $repo_path/all-in-one/keystone/keystone.conf /etc/keystone/keystone.conf

sed -i "s/##management-ip##/$management_ip/" /etc/keystone/keystone.conf

su -s /bin/sh -c "keystone-manage db_sync" keystone

rm /var/log/keystone/*

rm -f /var/lib/keystone/keystone.db

service keystone restart

if [ -z "$(service keystone status | awk 'match($0, /start\/running.*/)')" ]; then
  echo "fail: Keystone service has not running."
  exit 1
fi
sleep 10

source $repo_path/tools/credentials keystone
#export OS_TOKEN="$os_token"
#export OS_SERVICE_TOKEN="$os_token"
#export OS_URL="http://$endpoint:35357/v2.0"
#export OS_SERVICE_ENDPOINT="http://$endpoint:35357/v2.0"

echo "create new admin tenant."
keystone --debug tenant-create --name admin --description "Admin Tenant"
echo "create new admin user."
keystone --debug user-create --name admin --pass admin
echo "create new role."
keystone --debug role-create --name admin
keystone --debug role-create --name _member_
echo "add role to admin user."
keystone --debug user-role-add --user admin --tenant admin --role admin
keystone --debug user-role-add --user admin --tenant admin --role _member_

echo "create new service tenant."
keystone --debug tenant-create --name service --description "Service Tenant"

keystone --debug service-create --name keystone --type identity --description "OpenStack Identity"

keystone --debug endpoint-create \
  --service-id $(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl http://$management_ip:5000/v2.0 \
  --internalurl http://$management_ip:5000/v2.0 \
  --adminurl http://$management_ip:35357/v2.0 \
  --region regionOne

source $repo_path/tools/credentials admin


keystone tenant-list

keystone endpoint-list

echo "##### Deployed Keystone Service..... #####"
