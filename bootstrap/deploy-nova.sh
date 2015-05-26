#!/bin/bash

. vars.sh

# mysql -u root -p <<EOF
# create database nova;
# GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'$management_ip' IDENTIFIED BY 'password';
# GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'password';
# EOF

apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth \
  nova-novncproxy nova-scheduler python-novaclient nova-compute sysfsutils

virsh net-destroy default
virsh net-autostart default --disable

cp $repo_path/all-in-one/nova/nova.conf /etc/nova/nova.conf
sed -i "s/##management-ip##/$management_ip/" /etc/nova/nova.conf
su -s /bin/sh -c "nova-manage db sync" nova
rm /var/lib/nova/nova.sqlite
rm /var/log/nova/*

keystone user-create --name=nova --pass=nova
keystone user-role-add --user=nova --tenant=service --role=admin

keystone service-create --name=nova --type=compute \
  --description="OpenStack Compute"
keystone endpoint-create \
  --service-id=$(keystone service-list | awk '/ compute / {print $2}') \
  --publicurl=http://$management_ip:8774/v2/%\(tenant_id\)s \
  --internalurl=http://$management_ip:8774/v2/%\(tenant_id\)s \
--adminurl=http://$management_ip:8774/v2/%\(tenant_id\)s

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service nova-compute restart
