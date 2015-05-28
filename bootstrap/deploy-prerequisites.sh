#!/bin/bash

. vars.sh

apt-get update
apt-get install -y git
if [ ! -e /etc/apt/sources.list.d/ubuntu-cloud-archive-juno-trusty.list ]; then
	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >> \
		/etc/apt/sources.list.d/ubuntu-cloud-archive-juno-trusty.list
fi
apt-get install ubuntu-cloud-keyring 
apt-get update && apt-get dist-upgrade -y
