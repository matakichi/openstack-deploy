#!/bin/bash

. vars.sh

keystone user-create --name glance --pass glance || true
keystone user-role-add --user glance --tenant service --role admin || true

keystone service-create --name glance --type image \
  --description "OpenStack Image Service" || true

keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ image / {print $2}') \
  --publicurl http://$management_ip:9292 \
  --internalurl http://$management_ip:9292 \
  --adminurl http://$management_ip:9292 \
  --region regionOne || true

apt-get install -y glance python-glanceclient

cp $repo_path/all-in-one/glance/glance-api.conf /etc/glance/glance-api.conf
cp $repo_path/all-in-one/glance/glance-registry.conf /etc/glance/glance-registry.conf 
sed -i "s/##management-ip##/$management_ip/" /etc/glance/glance-api.conf
sed -i "s/##management-ip##/$management_ip/" /etc/glance/glance-registry.conf 
su -s /bin/sh -c "glance-manage db_sync" glance
rm /var/log/glance/* 
rm -f /var/lib/glance/glance.sqlite

service glance-registry restart
service glance-api restart

sleep 10

glance image-create --name="cirros-0.3.4-x86_64" --disk-format=qcow2 \
  --container-format=bare --is-public=true \
  --copy-from http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

glance image-list
