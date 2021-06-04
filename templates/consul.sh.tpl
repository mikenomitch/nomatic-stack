PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

echo "=== Fetching Consul ==="

cd /tmp
curl -sLo consul.zip https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip

echo "=== Installing Consul ==="
unzip consul.zip >/dev/null
sudo chmod +x consul
sudo mv consul /usr/local/bin/consul

echo "=== Setting up Consul ==="
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/consul.d

if [ ${is_server} == true ] || [ ${is_server} == 1 ]; then
  echo "=== Setting up Consul as Server ==="

  sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "server": true,
  "acl": {
    "enabled": true,
    "default_policy": "deny",
    "enable_token_persistence": true
  },
  "log_level": "INFO",
  "ui": true,
  "data_dir": "/mnt/consul",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "advertise_addr": "$PUBLIC_IP",
  "retry_join": ["provider=${retry_provider} tag_key=${retry_tag_key} tag_value=${retry_tag_value}"],
  "bootstrap_expect": ${desired_servers},
  "ports": {
    "grpc": 8502
  },
  "connect": {
     "enabled": true
  }
}
EOF
else
  echo "=== Setting up Consul as Client ==="

  sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "server": false,
  "acl": {
    "enabled": true,
    "default_policy": "deny",
    "enable_token_persistence": true
  },
  "log_level": "INFO",
  "ui": true,
  "data_dir": "/mnt/consul",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "advertise_addr": "$PUBLIC_IP",
  "retry_join": ["provider=${retry_provider} tag_key=${retry_tag_key} tag_value=${retry_tag_value}"],
  "ports": {
    "grpc": 8502
  },
  "connect": {
     "enabled": true
  }
}
EOF
fi

echo "=== Getting CNI Plugins for Consul Connect ==="

curl -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

echo "=== Allowing container traffic thru bridge network to be routed via iptables ==="

echo 1 > /proc/sys/net/bridge/bridge-nf-call-arptables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables

sudo tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
${consul_service_config}
EOF
