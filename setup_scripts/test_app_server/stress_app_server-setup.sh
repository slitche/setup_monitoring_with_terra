

# for debugging
set -xe # Exit immediately if a command fails, and print commands as they are executed
# exec > /var/log/adhoc_script.log 2>&1 # Log all output to a file


echo "Installing essential utilities (zip, unzip, stress)..."
apt install -y zip unzip


#-------------------------------------------------------------
# 4. Load Generation Scripts
#-------------------------------------------------------------
echo "===== [4/6] Setting up load generation scripts ====="
apt install -y stress stress-ng

echo "Downloading load scripts..."
wget -q -P /usr/local/bin/ https://raw.githubusercontent.com/hkhcoder/vprofile-project/refs/heads/monitoring/load.sh
wget -q -P /usr/local/bin/ https://raw.githubusercontent.com/hkhcoder/vprofile-project/refs/heads/monitoring/generate_multi_logs.sh

chmod +x /usr/local/bin/load.sh /usr/local/bin/generate_multi_logs.sh

echo "Starting load generation in background..."
nohup /usr/local/bin/load.sh > /dev/null 2>&1 &
nohup /usr/local/bin/generate_multi_logs.sh > /dev/null 2>&1 &

echo "✅ Load generation setup completed."
