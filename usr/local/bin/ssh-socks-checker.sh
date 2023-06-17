#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Please execute this script file as root"
  exit 1
fi

DEFAULT_CONFIG='{
  "socks_host": "",
  "socks_port": "",
  "server": "",
  "server_port": 22,
  "server_username": "",
  "server_password": "",
  "check_url": "http://example.com",
  "recheck_time_sec": 5,
  "timeout": 5
}'
CONFIG_DIRECTORY="/etc/ssh-socks-checker"
CONFIG_FILE="config.json"
CONFIG_FILE_PATH="$CONFIG_DIRECTORY/$CONFIG_FILE"

# check config directory exists
if [ ! -d $CONFIG_DIRECTORY ]; then 
  mkdir -p $CONFIG_DIRECTORY
  echo "Configs directory created!"
fi
if [ ! -f $CONFIG_FILE_PATH ]; then
  touch $CONFIG_FILE_PATH

  echo $DEFAULT_CONFIG | jq '.' > $CONFIG_FILE_PATH

  echo "Config file created!"
fi

# read configs
socks_host=$(jq -r '.socks_host' $CONFIG_FILE_PATH)
socks_port=$(jq -r '.socks_port' $CONFIG_FILE_PATH)
server_ip=$(jq -r '.server' $CONFIG_FILE_PATH)
server_port=$(jq -r '.server_port' $CONFIG_FILE_PATH)
server_username=$(jq -r '.server_username' $CONFIG_FILE_PATH)
server_password=$(jq -r '.server_password' $CONFIG_FILE_PATH)
recheck_time_sec=$(jq -r '.recheck_time_sec' $CONFIG_FILE_PATH)
timeout=$(jq -r '.timeout' $CONFIG_FILE_PATH)
check_url=$(jq -r '.check_url' $CONFIG_FILE_PATH)

# validation configs
if [ ! $socks_host ]; then
  echo "Please check 'socks_host' config"
  exit 1
fi
if [ ! $socks_port ]; then
  echo "Please check 'socks_port' config"
  exit 1
fi
if [ ! $server_ip ]; then
  echo "Please check 'server_ip' config"
  exit 1
fi
if [ ! $server_port ]; then
  echo "Please check 'server_port' config"
  exit 1
fi
if [ ! $server_username ]; then
  echo "Please check 'server_username' config"
  exit 1
fi
if [ ! $server_password ]; then
  echo "Please check 'server_password' config"
  exit 1
fi
if [ ! $recheck_time_sec ]; then
  echo "Please check 'recheck_time_sec' config"
  exit 1
fi
if [ ! $timeout ]; then
  echo "Please check 'timeout' config"
  exit 1
fi
if [ ! $check_url ]; then
  echo "Please check 'check_url' config"
  exit 1
fi

FINGERPRINT=$(ssh-keygen -F $server_ip)

# If the fingerprint does not exist, use ssh-keyscan to obtain it and add it to the known_hosts file
if [[ -z "$FINGERPRINT" ]]; then
  FINGERPRINT=$(ssh-keyscan -p $server_port $server_ip)
  echo "$FINGERPRINT" >> ~/.ssh/known_hosts
fi

while true
do
  if `curl --max-time $timeout --socks5-hostname 127.0.0.1:$socks_port $check_url -o /dev/null -w '%{http_code}\n' -s | grep -q "200"`; then
    echo "connected! >>>> local: 127.0.0.1:$socks_port | network: $socks_host:$socks_port"
    sleep $recheck_time_sec
  else
    echo "no connection..."
    # kill ssh tunnel
    if [[ -v ssh_pid ]]; then
      echo "Kill ssh tunnel..."
      kill "$ssh_pid"
    fi
    # restart ssh tunnel
    echo "Reconnect ssh tunnel..."
    sshpass -p "$server_password" ssh -D $socks_host:$socks_port -fqCN $server_username@$server_ip -p $server_port
    wait
    if [ $? -ne 0 ]; then
      echo "Error: check server connection configurations"
    else
      ssh_pid=$(pgrep -f "ssh -D $socks_host:$socks_port")
      echo "Socks connection established with pid: $ssh_pid"
    fi
    sleep 1
  fi
done