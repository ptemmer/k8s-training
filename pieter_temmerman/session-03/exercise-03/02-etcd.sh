#!/bin/bash

source ./0-common.sh

# Install etcd cluster
# I decided using rkt based etcd containers to tinker with rkt (and I loved it!)

for node in $NODE1 $NODE2; do
  node_id=1
  # Install rkt
  cat <<- EOF | ssh -i $SSH_KEY $SSH_OPTIONS ubuntu@$node
    gpg --recv-key 18AD5014C99EF7E3BA5F6CE950BDD3E0FC8A365E
    wget --quiet https://github.com/rkt/rkt/releases/download/v1.29.0/rkt_1.29.0-1_amd64.deb
    wget --quiet https://github.com/rkt/rkt/releases/download/v1.29.0/rkt_1.29.0-1_amd64.deb.asc
    gpg --verify rkt_1.29.0-1_amd64.deb.asc
    sudo dpkg -i rkt_1.29.0-1_amd64.deb

    cat << EOL | sudo tee /etc/systemd/system/etcd-node${node_id}.service
      [Unit]
      # Metadata
      Description=Bitnami Etcd
      Requires=network-online.target
      After=network-online.target

      [Service]
      Slice=machine.slice
      # Env vars
      Environment=STORAGE_PATH=/opt/myapp
      ExecStart=/usr/bin/rkt run --inherit-env --net=host coreos.com/etcd:v3.3.5
      ExecStopPost=/usr/bin/rkt gc --mark-only
      KillMode=mixed
      Restart=always
EOL
    sudo systemctl enable etcd-$node_id.service
EOF
  node_id=$(( $node_id + 1 ))
done
