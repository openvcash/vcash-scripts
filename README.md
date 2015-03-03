## Vanillacoin Install script

# Req.
-------
User have to be in sudo group :
As root:
    apt-get install sudo curl
    sudo adduser <user> sudo

# Install
-------
As user:
    cd ~
    bash < <(curl -s  https://raw.github.com/xCoreDev/vanillacoin-scripts/vanillacoin-install-linux.sh)