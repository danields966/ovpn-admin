#!/usr/bin/env bash

docker compose -p openvpn-master up -d --build openvpn ovpn-admin nginx-auth
