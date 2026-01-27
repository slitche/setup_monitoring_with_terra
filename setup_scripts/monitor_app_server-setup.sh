#!/bin/bash


# for debugging
set -xe # Exit immediately if a command fails, and print commands as they are executed
# exec > /var/log/adhoc_script.log 2>&1 # Log all output to a file

# --- Unattended apt installs ---
export DEBIAN_FRONTEND=noninteractive
# export NEEDRESTART_MODE=a   # auto-restart services without asking

# Configure needrestart to always restart services automatically
sudo sed -i 's/#\$nrconf{restart}.*/\$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf || true

# Prevent tzdata or other packages from asking questions
sudo ln -fs /usr/share/zoneinfo/UTC /etc/localtime
sudo dpkg-reconfigure -f noninteractive tzdata

#-------------------------------------------------------------
#  Install and Configure Node Exporter
#-------------------------------------------------------------
echo "===== Installing Prometheus Node Exporter ====="

mkdir -p /tmp/exporter
cd /tmp/exporter

NODE_VERSION="1.10.2"
echo "Downloading Node Exporter v${NODE_VERSION}..."
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz

echo "Extracting Node Exporter..."
tar xzf node_exporter-${NODE_VERSION}.linux-amd64.tar.gz

echo "Moving binary to /var/lib/node..."
mkdir -p /var/lib/node
mv node_exporter-${NODE_VERSION}.linux-amd64/node_exporter /var/lib/node/

echo "Creating prometheus system user..."
groupadd --system prometheus || true
useradd -s /sbin/nologin --system -g prometheus prometheus || true

chown -R prometheus:prometheus /var/lib/node/
chmod -R 775 /var/lib/node

echo "Creating Node Exporter systemd service..."
cat <<EOF > /etc/systemd/system/node.service
[Unit]
Description=Prometheus Node Exporter
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/var/lib/node/node_exporter
SyslogIdentifier=prometheus_node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling and starting Node Exporter..."
systemctl daemon-reload
systemctl enable --now node
# systemctl status node --no-pager

echo "✅ Node Exporter setup completed."


#-------------------------------------------------------------
# Install and Configure Alloy (Metrics & Logs)
#-------------------------------------------------------------
echo "===== [5/6] Installing Grafana Alloy (metrics & log collector) ====="
sudo apt install -y gpg
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update

sudo apt-get install -y alloy

cat <<EOF > /etc/alloy/config.alloy
// Metrics scraping and remote write to Prometheus

prometheus.remote_write "default" {
  endpoint {
    url = "http://prometheus.internal:9090/api/v1/write"
  }
}

prometheus.scrape "metrics_5000" {
  targets = [{
    __address__ = "localhost:5000",
    __metrics_path__ = "/metrics",
  }]
  forward_to = [prometheus.remote_write.default.receiver]
}

prometheus.scrape "metrics_default" {
  targets = [{
    __address__ = "localhost:8080",  // Adjust port if different; assuming 8080 for /metrics endpoint
    __metrics_path__ = "/metrics",
  }]
  forward_to = [prometheus.remote_write.default.receiver]
}

// Log collection from files and push to Loki

local.file_match "titan_logs" {
  path_targets = [{
    __path__ = "/var/log/titan/*.log",
    job      = "titan",
    hostname = constants.hostname,
  }]
  sync_period = "5s"
}

loki.source.file "log_scrape" {
  targets       = local.file_match.titan_logs.targets
  forward_to    = [loki.write.loki.receiver]
  tail_from_end = true
}

loki.write "loki" {
  endpoint {
    url = "http://loki.internal:3100/loki/api/v1/push"
  }
}
EOF

cat <<EOF > /etc/default/alloy
## Path:
## Description: Grafana Alloy settings
## Type:        string
## Default:     ""
## ServiceRestart: alloy
#
# Command line options for Alloy.
#
# The configuration file holding the Alloy config.
CONFIG_FILE="/etc/alloy/config.alloy"

# User-defined arguments to pass to the run command.
CUSTOM_ARGS="--server.http.listen-addr=0.0.0.0:12345"

# Restart on system upgrade. Defaults to true.
RESTART_ON_UPGRADE=true
EOF

systemctl restart alloy
systemctl enable alloy
sleep 40
# systemctl status alloy --no-pager
echo "✅ Alloy setup completed."

#-------------------------------------------------------------
#  Configure UFW Firewall
#-------------------------------------------------------------
echo "===== Configuring UFW Firewall ====="

# Install ufw if not present
apt install -y ufw

# Allow SSH (port 22), Node Exporter (9100), Loki (3100), and Flask app (80)
echo ", Node Exporter (9100), Loki (3100), and Flask app (80) through firewall..."
ufw allow 9100/tcp
ufw allow 3100/tcp
ufw allow 12345/tcp


# Enable UFW (force yes)
echo "Enabling UFW..."
echo "y" | ufw enable
ufw status verbose

echo "✅ UFW firewall configured."
