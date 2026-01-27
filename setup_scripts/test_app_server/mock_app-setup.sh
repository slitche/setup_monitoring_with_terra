#!/bin/bash

# for debugging
set -xe # Exit immediately if a command fails, and print commands as they are executed
# exec > /var/log/adhoc_script.log 2>&1 # Log all output to a file

#-------------------------------------------------------------
# Basic System Setup
#-------------------------------------------------------------
# echo "===== [1/6] Setting up basic system configuration ====="
# echo "Setting hostname to web01..."
# echo "web01" > /etc/hostname
# hostname web01

echo "Updating and upgrading system packages..."
apt update -y && apt upgrade -y

echo "Installing essential utilities (zip, unzip, stress)..."
apt install -y zip unzip


#-------------------------------------------------------------
# Setup Titan App as a Service
#-------------------------------------------------------------
echo "===== [3/6] Setting up Titan App as a Service ====="

# Update system and install Python3 and venv
sudo apt update
sudo apt install -y python3 python3-venv

# Clone the project repository
mkdir -p /tmp/project
cd /tmp/project
echo "Cloning vprofile-project repository..."
git clone https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project/
git checkout monitoring

# Move titan to /opt and set up virtual environment
mkdir -p /opt/titan
echo "Moving Flask app files to /opt/titan..."
mv titan/*  /opt/titan
cd /opt/titan
echo "Creating Python virtual environment..."
python3 -m venv venv
echo "Activating virtual environment and installing requirements..."
source venv/bin/activate
pip install -r requirments.txt
chmod +x app.py

# Create log directory for Titan app and set permissions
mkdir -p /var/log/titan
chown www-data:www-data /var/log/titan
chmod 755 /var/log/titan

# Create systemd service for Flask app
echo "Creating systemd service for Flask app..."
cat <<EOF > /etc/systemd/system/titan.service
[Unit]
Description=Titan App Service
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/titan
Environment="PATH=/opt/titan/venv/bin"
ExecStart=/opt/titan/venv/bin/python3 /opt/titan/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling and starting Titan app service..."
sudo systemctl daemon-reload
sudo systemctl enable titan
sudo systemctl start titan
sudo systemctl status titan --no-pager

echo "✅ Titan app setup and service started successfully."

#-------------------------------------------------------------
# Configure UFW Firewall
#-------------------------------------------------------------
echo "===== [7/6] Configuring UFW Firewall ====="

# Install ufw if not present
apt install -y ufw

# Allow SSH (port 22), Node Exporter (9100), Loki (3100), and Flask app (80)
echo "Allowing SSH (22), and Flask app (80) through firewall..."
ufw allow 22/tcp
ufw allow 5000/tcp


# Enable UFW (force yes)
echo "Enabling UFW..."
echo "y" | ufw enable
ufw status verbose

echo "✅ UFW firewall configured."
