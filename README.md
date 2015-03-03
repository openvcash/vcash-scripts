# Vanillacoin Install script

## Warning !
Testing phase, so please backup your existing wallet files (.Vanillacoin folder) & your daemon binary (vanillacoind file) before running install script.
I can't be responsible if you broke something.

## Req.
User must be in sudo group :

#### Debian
As root: user must already exist (non-root-user for example)
```
apt-get install sudo curl screen -y
adduser non-root-user sudo
```

#### Ubuntu
As user: user must already be in sudo group (or try Debian style)
```
sudo apt-get install sudo curl screen -y
```

## Install
As user: Please logoff/login if user freshly added to sudo group
```
cd ~
bash < <(curl -s  https://raw.githubusercontent.com/xCoreDev/vanillacoin-scripts/master/vanillacoin-install-linux.sh)
```