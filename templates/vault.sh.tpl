PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

echo "=== Fetching Vault ==="

cd /tmp
curl -sLo vault.zip https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip

echo "=== Installing Vault ==="
unzip vault.zip >/dev/null
sudo chmod +x vault
sudo mv vault /usr/local/bin/vault

echo "=== Setting up Vault ==="
sudo mkdir -p /mnt/vault
sudo mkdir -p /etc/vault.d

sudo tee /etc/vault.d/vault.hcl > /dev/null <<EOF
ui = true

backend "consul" {
  path = "vault/"
  address = "$PRIVATE_IP:8500"
  cluster_addr = "https://$PRIVATE_IP:8201"
  redirect_addr = "http://$PRIVATE_IP:8200"
}

listener "tcp" {
  address = "$PRIVATE_IP:8200"
  cluster_address = "$PRIVATE_IP:8201"
  tls_disable = 1
}
EOF

sudo tee /etc/systemd/system/vault.service > /dev/null <<"EOF"
${vault_service_config}
EOF
