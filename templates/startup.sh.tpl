#!/bin/bash

set -e

echo "================================="
echo "=== Setting up the HashiStack ==="
echo "================================="

sudo apt-get -yqq update
sudo apt-get -yqq install apt-transport-https ca-certificates curl gnupg-agent software-properties-common unzip jq

PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

if [ ${use_docker} == true ] || [ ${use_docker} == 1 ]; then
  echo "=============="
  echo "=== Docker ==="
  echo "=============="
  ${docker_config}
fi

if [ ${use_consul} == true ] || [ ${use_consul} == 1 ]; then
  echo "=============="
  echo "=== Consul ==="
  echo "=============="
  ${consul_config}
fi

if [ ${use_consul_template} == true ] || [ ${use_consul_template} == 1 ]; then
  echo "======================="
  echo "=== Consul Template ==="
  echo "======================="
  ${consul_template_config}
fi

if [ ${use_nomad} == true ] || [ ${use_nomad} == 1 ]; then
  echo "============="
  echo "=== Nomad ==="
  echo "============="
  ${nomad_config}
fi

if [ ${is_server} == true ] || [ ${is_server} == 1 ]; then
  if [ ${use_vault} == true ] || [ ${use_vault} == 1 ]; then
    echo "============="
    echo "=== Vault ==="
    echo "============="
    ${vault_config}
  fi
fi

sudo systemctl daemon-reload

if [ ${use_consul} == true ] || [ ${use_consul} == 1 ]; then
  echo "=== Starting Consul ==="
  sudo systemctl enable consul.service
  sudo systemctl start consul.service
fi

if [ ${use_consul_template} == true ] || [ ${use_consul_template} == 1 ]; then
  echo "=== Starting Consul Template ==="
  sudo systemctl enable consul-template.service
  sudo systemctl start consul-template.service
fi

if [ ${use_nomad} == true ] || [ ${use_nomad} == 1 ]; then
  echo "=== Starting Nomad ==="
  sudo systemctl enable nomad.service
  sudo systemctl start nomad.service
fi

if [ ${is_server} == true ] || [ ${is_server} == 1 ]; then
  if [ ${use_vault} == true ] || [ ${use_vault} == 1 ]; then
    echo "=== Starting Vault ==="
    sudo systemctl enable vault.service
    sudo systemctl start vault.service
  fi
fi
