#!/usr/bin/env bash
ip link show ens4 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'
EXT_MACC_ADDR=$(ip link show ens4 | awk '/ether/ {print $2}')
RT_TAP=$(ip netns exec qrouter-$(openstack router list|awk '/router/{print $2}') ip l | awk '/qg-*/ {print substr($2, 0, index($2, ":")-1)}')
ip netns exec qrouter-$(openstack router list|awk '/router/{print $2}') ip l set dev $RT_TAP address $EXT_MACC_ADDR
ip netns exec qrouter-$(openstack router list|awk '/router/{print $2}') ip a
