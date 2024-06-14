#!/bin/bash

# Function to prompt user for input and store it in .env file
function prompt_and_store_env {
    local prompt_message="$1"
    local env_key="$2"

    read -p "$prompt_message: " value
    echo "$env_key=\"$value\"" >> .env
}

# Update package lists
sudo apt-get update

# Install necessary packages
sudo apt-get install -y clang cmake build-essential

# Install Rust via Rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Cargo
sudo apt install -y cargo

# Download and install Go
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz

# Add Go binary directory to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile

# Clone the repository
git clone -b v0.3.0 https://github.com/0glabs/0G-StorageNode-Auto.git
cd 0G-StorageNode-Auto/0g-storage-node

# Initialize and update submodules
git submodule update --init

# Build in release mode
cargo build --release

# Create .env file (if it doesn't exist)
touch .env

# Prompt user for miner key (wallet address)
prompt_and_store_env "Enter your miner key (wallet address) where you want to receive rewards" "MINER_KEY (Press Enter When Done)"

# Store other environment variables if needed
# prompt_and_store_env "Enter another variable" "OTHER_VAR"

# Navigate to 'run' directory
cd run

# Insert MINER_KEY into config.toml
sed -i "s/miner_key = \"\"/miner_key = \"$(grep MINER_KEY ../.env | cut -d '=' -f2 | sed 's/\"//g')\"/" config.toml

# Create systemd service file for zgs_node
sudo tee /etc/systemd/system/zgs_node.service > /dev/null << EOF
[Unit]
Description=ZGS Node Service
After=network.target

[Service]
User=$USER
Group=$(id -gn)
WorkingDirectory=$(pwd)
EnvironmentFile=$(pwd)/../.env
ExecStart=$(pwd)/../target/release/zgs_node --config $(pwd)/config.toml
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=zgs_node

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to read the new service file
sudo systemctl daemon-reload

# Enable and start the zgs_node service
sudo systemctl enable zgs_node.service
sudo systemctl start zgs_node.service
