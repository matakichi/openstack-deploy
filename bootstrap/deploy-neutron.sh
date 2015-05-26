#!/bin/bash

. vars.sh

# mysql -u root -p << EOF
# create database neutron;
# GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'password';
# GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'password';
# EOF

keystone user-create --name neutron --pass neutron || true
keystone user-role-add --user neutron --tenant service --role admin || true

keystone service-create --name neutron --type network --description "OpenStack Networking" || true
keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ network / {print $2}') \
  --publicurl http://$management_ip:9696 \
  --adminurl http://$management_ip:9696 \
  --internalurl http://$management_ip:9696 || true

apt-get install -y neutron-server neutron-plugin-ml2 python-neutronclient neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent

cp $repo_path/all-in-one/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini 
cp $repo_path/all-in-one/neutron/dnsmasq-neutron.conf /etc/neutron/dnsmasq-neutron.conf
cp $repo_path/all-in-one/neutron/l3_agent.ini /etc/neutron/l3_agent.ini 
cp $repo_path/all-in-one/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini 
cp $repo_path/all-in-one/neutron/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini 
cp $repo_path/all-in-one/neutron/neutron.conf /etc/neutron/neutron.conf 

service_tenant_id=$(keystone tenant-list | awk '/ service / {print $2}')

sed -i "s/##management-ip##/$management_ip/" /etc/neutron/neutron.conf
sed -i "s/##management-ip##/$management_ip/" /etc/neutron/metadata_agent.ini
sed -i "s/##nova_admin_tenant_id##/$service_tenant_id/" /etc/neutron/neutron.conf

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade juno" neutron

rm -f /var/lib/neutron/neutron.sqlite

service openvswitch-switch restart
ovs-vsctl add-br br-ex || true

cat <<EOF
You have to set your eth0 to manual and br-ex to static
as following in your /etc/network/interfaces.

    auto eth0
    iface eth0 inet manual
            up ip link set dev $IFACE up
            down ip link set dev $IFACE down
    auto br-ex
    iface br-ex inet static
            address 192.168.252.xx
            network 192.168.252.0
            netmask 255.255.255.0
            broadcast 192.168.252.255
            gateway 192.168.252.1
            dns-nameservers 8.8.8.8

And restart the eth0 as following.

    ifdown eth0
    ifconfig eth0 0.0.0.0 up
    ifdown br-ex
    ifup br-ex

Add eth0 to br-ex.

    ovs-vsctl add-port br-ex eth0

Finally, following commands to restart services.

service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service neutron-server restart

rm /var/log/neutron/*

service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service nova-compute restart

neutron agent-list
EOF
