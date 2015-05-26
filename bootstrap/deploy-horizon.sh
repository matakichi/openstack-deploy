#!/bin/bash

. vars.sh

apt-get install -y openstack-dashboard apache2 libapache2-mod-wsgi memcached python-memcache
#apt-get remove -y ubuntu-openstack-dashboard
apt-get remove -y openstack-dashboard-ubuntu-theme

cp $repo_path/all-in-one/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py
sed -i "s/##management-ip##/$management_ip/" /etc/openstack-dashboard/local_settings.py

service apache2 restart
