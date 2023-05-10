# DIY Ordinal Inscription collection drop

A btc ordinal inscription "project" platform.

One-click deploy for an on-demand "minting" (inscribing) experience. 

Inspiration from https://bitglyphs.com/ (the service, not the art, but that is cool too). Or something like the Candy Machine contract on SOL, or the well developed NFT collection lazy mints on ETH.

# Features

* Nice website for an ordinal inscription collection.
* User can buy an inscription.
* User provides their own recipient address and sends some btc (or any currency?)
* Magic tubes run in the background checking the funds, inscribing, and sending.
* Lazy mint, will recieve next availble item in collection.

Todo: Choose which item from collection to mint.


## Front end.

* Gallery of collection
* Gallery of minted.
* Gallery of to-be-minted.
* Click to mint button
* Click to check status

## Backend

Assume these are running:
* Full bitcoin node (bitcoin-core)
* Ord index server

This is the brain of the whole operation:
* Flask server listening and managing transactions.

Probably not necessary or a good idea to have front and backend on same server:
* Webserver hosting frontend

## Bonus

With the same kind of hacky bash scripts tying the backend together, this can be configured to act as a general inscription service or an escrow sale service.


# Machine setup
```
# Install bitcoin core
wget https://bitcoincore.org/bin/bitcoin-core-24.0.1/bitcoin-24.0.1-x86_64-linux-gnu.tar.gz
tar -xzvf bitcoin-24.0.1-x86_64-linux-gnu.tar.gz
sudo ln -s bitcoin-24.0.1/bin/bitcoind /usr/bin/bitcoind
sudo ln -s bitcoin-24.0.1/bin/bitcoin-cli /usr/bin/bitcoin-cli

# Install ord
curl --proto '=https' --tlsv1.2 -fsLS https://ordinals.com/install.sh | bash -s
echo "export PATH=$PATH:/home/ubuntu/bin:/home/ubuntu/bitcoin-24.0.1/bin" >> ~/.bashrc
sudo ln -s ~/bin/ord /usr/bin/ord
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
sudo apt install -y jq python3-flask python3-pip nginx gunicorn net-tools
pip install flask_cors
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
WorkingDirectory=/home/ubuntu/dropord/flaskserver
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

# Bitcoin service:
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



