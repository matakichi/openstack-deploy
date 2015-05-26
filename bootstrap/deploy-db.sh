#!/bin/bash

. vars.sh

mysql -u root << EOF
create database IF NOT EXISTS keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'$management_ip' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'password';
EOF

mysql -u root << EOF
create database IF NOT EXISTS glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'$management_ip' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'password';
EOF

mysql -u root << EOF
create database IF NOT EXISTS nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'$management_ip' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'password';
EOF

mysql -u root << EOF
create database IF NOT EXISTS neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'password';
EOF

