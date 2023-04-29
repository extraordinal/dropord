# dropord
A btc ordinal inscription drop platform

One-click deploy project for a user-mints (and pays) ordinal inscription collection.

# Features

User provides their own recipient address.
If user leaves website and doesn't make deposit, 30? Mins, address is returned to pool.
If user makes deposit, address is removed from pool.
deposit is checked for appropriate amount.
once confirmed inscription generated
once inscribed inscription is sent!

## Front end.
Gallery of collection
Gallery of minted.
Gallery of to-be-minted.
Click to mint button

## Backend
Full bitcoin node
Ord index server
flask server listening for transactions.


# Machine setup
```
# Install bitcoin core
wget https://bitcoincore.org/bin/bitcoin-core-24.0.1/bitcoin-24.0.1-x86_64-linux-gnu.tar.gz
tar -xzvf bitcoin-24.0.1-x86_64-linux-gnu.tar.gz

# Install ord
curl --proto '=https' --tlsv1.2 -fsLS https://ordinals.com/install.sh | bash -s
echo "export PATH=$PATH:/home/ubuntu/bin:/home/ubuntu/bitcoin-24.0.1/bin" >> ~/.bashrc
sudo ln -s ~/bin/ord /usr/bin/ord
sudo ln -s ~/bitcoin-24.0.1/bin/bitcoind /usr/bin/bitcoind
sudo ln -s ~/bitcoin-24.0.1/bin/bitcoin-cli /usr/bin/bitcoin-cli
source ~/.bashrc
mkdir ~/signet
echo signet=1 >> ~/siget/bitcoin.conf
# This runs as service, but it seems to get a weird faiulre "tor: Thread interrupt shutdown"
echo daemon=1 >> ~/siget/bitcoin.conf

# Run the (test) chain
mkdir /home/ubuntu/signet
bitcoind -datadir=/home/ubuntu/signet

# Generate ord wallet, and index etc.
ord --signet  --data-dir=/home/ubuntu/signet/ wallet create
ord --signet --cookie-file /home/ubuntu/signet/signet/.cookie wallet index
ord --signet --cookie-file /home/ubuntu/signet/signet/.cookie wallet receive

# Install a few other required tools
sudo apt install jq
sudo apt install python3-flask
sudo apt install python3-pip
pip install flask_cors
sudo apt install npm
npm install http-server
sudo apt-get install nginx
sudo apt install gunicorn
```

# Configuring the Production server
Edit the flaskserver service: `sudo nano /etc/systemd/system/flaskserver.service`

```
[Unit]
Description=Gunicorn instance for running flask server
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/thefirst10k/flaskserver
ExecStart=/usr/bin/gunicorn -b 0.0.0.0:8000 --workers 3 app:app 
Restart=always

[Install]
WantedBy=multi-user.target
```

Start the service
```
sudo systemctl start flaskserver
sudo systemctl enable flaskserver
```

Some more commands:
```
sudo systemctl stop flaskserver
sudo systemctl restart flaskserver
sudo systemctl daemon-reload
journalctl --unit=flaskserver | tail -n 30
```

Now do the nginx web host service
`sudo nano /etc/nginx/sites-available/default`
It might look something like this, this seems to work, but might have some redundancy:

```

upstream flaskserver {
	    server 127.0.0.1:8000;
}

server {
	listen 80 default_server;
	listen [::]:80 default_server;
    root /var/www/html;
	index index.html index.htm index.nginx-debian.html;
	server_name <ip.address.of.server>;
	location / {
		proxy_pass http://flaskserver;
    }
}
```
```
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

```
sudo systemctl stop flaskserver
sudo systemctl stop nginx
sudo systemctl daemon-reload
sudo systemctl start flaskserver
sudo systemctl enable flaskserver
sudo systemctl start nginx
sudo systemctl enable nginx
```

# Bitcoin service (running bitcoin core as a service):
```
sudo nano /etc/systemd/system/bitcoind.service

------
[Unit]
Description=Bitcoin Core daemon
After=network.target

[Service]
User=ubuntu
Group=ubuntu
Type=forking
ExecStart=/home/ubuntu/bitcoin-24.0.1/bin/bitcoind -datadir=/home/ubuntu/signet -daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target
-------

sudo systemctl daemon-reload
sudo systemctl enable bitcoind.service
sudo systemctl start bitcoind.service
journalctl -u bitcoind.service
```


# Make a file with inscription ids 

User clicks "buy-now" and a depoist address is generated. The deposit address is attached to the inscription and the receiver address.
The deposit address is watched for a broadcast transaction.
They then have until 3? blocks to make a depoist.


