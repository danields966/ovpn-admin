#!/usr/bin/env bash
set -ex

OVPN_SRV_NET=${OVPN_SERVER_NET:-10.8.0.0}
OVPN_SRV_MASK=${OVPN_SERVER_MASK:-255.255.255.0}
OVPN_SRV_PORT=${OVPN_SERVER_PORT:-1194}

apt install ufw ssh

BEFORE_RULES_FILE_PATH="/etc/ufw/before.rules"
SEARCH_STRING="# START OPENVPN RULES"

DEFAULT_INTERFACE=$(ip route list default | awk '{print $5}')

if ! grep -q "$SEARCH_STRING" "$BEFORE_RULES_FILE_PATH"; then
    sed -i "/# Don't delete these required lines, otherwise there will be errors/i \
# START OPENVPN RULES\n\
# NAT table rules\n\
*nat\n\
:POSTROUTING ACCEPT [0:0]\n\
-A POSTROUTING -s ${OVPN_SRV_NET}/${OVPN_SRV_MASK} -o ${DEFAULT_INTERFACE} -j MASQUERADE\n\
COMMIT\n\
# END OPENVPN RULES\n" ${BEFORE_RULES_FILE_PATH}
fi

sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

ufw allow ${OVPN_SRV_PORT}/tcp
ufw allow OpenSSH
ufw disable
ufw enable
