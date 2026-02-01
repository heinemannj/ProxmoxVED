#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Joerg Heinemann (heinemannj)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/smallstep/certificates

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

#setup_deb822_repo \
#  "smallstep" \
#  "https://packages.smallstep.com/keys/apt/repo-signing-key.gpg" \
#  "https://packages.smallstep.com/stable/debian" \
#  "debs" \
#  "main"

curl -fsSL https://packages.smallstep.com/keys/apt/repo-signing-key.gpg -o /etc/apt/keyrings/smallstep.asc
cat << EOF > /etc/apt/sources.list.d/smallstep.sources
Types: deb
URIs: https://packages.smallstep.com/stable/debian
Suites: debs
Components: main
Signed-By: /etc/apt/keyrings/smallstep.asc
EOF

msg_info "Installing step-ca and step-cli"
$STD apt install -y step-ca step-cli
msg_ok "Installed step-ca and step-cli"

msg_info "Add a CA service user - Will only be used by systemd to manage the CA"
$STD useradd --user-group --system --home /etc/step-ca --shell /bin/false step
msg_ok "Created CA service user"

msg_info "Define step environment variables"
$STD export STEPPATH=/etc/step-ca
msg_ok "Defined step environment variables"

msg_info "Authorize step-ca binary with low port-binding capabilities"
$STD setcap CAP_NET_BIND_SERVICE=+eip $(which step-ca)
msg_ok "Authorized low port-binding capabilities"

msg_info "Initializing step-ca"

# 'step ca init' with the following settings:
#
# Deployment Type: Standalone
# PKI Name: MyPrivateCA – For larger deployments, you should make this name descriptive to distinguish between test, dev, and production environments.
# DNS names or IP addresses: ca.mydomain.int – These DNS names and IP addresses will be included in the CA certificate. Add your own DNS names and IP addresses here.
# IP and port to bind to 443 – This will bind to all IPs on port 443. If you proxy the app using Nginx or a load balancer, you can bind to the internal IP 127.0.0.1 and/or use another port.
# First provisioner: pki@mydomain.int – This is the equivalent of the superuser or root user of the PKI server. mydomain.int is built on my personal DNS infrastructure. Please adjust it according to your requirements.
# Password: Leave empty – This will auto-generate a password, which you should safeguard.

$STD step ca init

$STD chown -R step:step $(step path)

msg_ok "Initialized step-ca"

#$STD systemctl daemon-reload -q
#$STD systemctl enable -q --now step-ca
#$STD systemctl status step-ca

motd_ssh
customize
cleanup_lxc
