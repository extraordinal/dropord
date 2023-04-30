#!/bin/bash

# Install bitcoin core
apt-get update
wget https://bitcoincore.org/bin/bitcoin-core-24.0.1/bitcoin-24.0.1-x86_64-linux-gnu.tar.gz
tar -xzvf bitcoin-24.0.1-x86_64-linux-gnu.tar.gz
mkdir /data
mkdir /data/signet
echo signet=1 >> /data/siget/bitcoin.conf
# bitcoind -datadir=/home/ubuntu/signet # Not needed as running as service

# Install ord
curl --proto '=https' --tlsv1.2 -fsLS https://ordinals.com/install.sh | bash -s
echo "export PATH=$PATH:/bitcoin-24.0.1/bin" >> /home/ubuntu/.bashrc
mv -v /root/bin/ord /usr/bin/ord
ln -s /bitcoin-24.0.1/bin/bitcoind /usr/bin/bitcoind
ln -s /bitcoin-24.0.1/bin/bitcoin-cli /usr/bin/bitcoin-cli

# Install a few other required tools
apt install -y jq python3-flask python3-pip nginx gunicorn net-tools
pip install flask_cors

# Clone the repo
git clone https://github.com/extraordinal/dropord.git
mv -v dropord /data/


cat > /etc/systemd/system/flaskserver.service << EOF
[Unit]
Description=Gunicorn instance for running flask server
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/data/dropord/BACKEND
ExecStart=/usr/bin/gunicorn -b 0.0.0.0:8000 --workers 3 app:app 
Restart=always

[Install]
WantedBy=multi-user.target

EOF

myip=`curl ifconfig.me`

cat > /etc/nginx/sites-available/default << EOL
upstream flaskserver {
	    server 127.0.0.1:8000;
}

server {
	listen 80 default_server;
	listen [::]:80 default_server;
    root /var/www/html;
	index index.html index.htm index.nginx-debian.html;
	server_name ${myip};
	location / {
		proxy_pass http://flaskserver;
    }
}

EOL


cat > /etc/systemd/system/bitcoind.service << EOL
[Unit]
Description=Bitcoin Core daemon
After=network.target

[Service]
User=ubuntu
Group=ubuntu
Type=forking
ExecStart=/usr/bin/bitcoind -datadir=/data/signet -daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOL


systemctl daemon-reload
systemctl enable bitcoind.service
systemctl start bitcoind.service

systemctl start nginx
systemctl enable nginx

systemctl start flaskserver
systemctl enable flaskserver

# Generate ord wallet, and index etc (This will fail because it)
ord --signet --data-dir=/data/signet/ wallet create
ord --signet --cookie-file /data/signet/signet/.cookie wallet index
