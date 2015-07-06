# Vanillacoin Install script

## Warning !
Testing phase, so please backup your existing wallet files (.Vanillacoin folder) & your daemon binary (vanillacoind file) before running install script.
I can't be responsible if you broke something.

#### Debian / Ubuntu
As root:
```
sudo apt-get install build-essential openssl curl git-core screen -y
```

## Install
As user:
```
cd ~
bash < <(curl -s  https://raw.githubusercontent.com/xCoreDev/vanillacoin-scripts/master/build-linux.sh)
```
Install script auto launch vanillacoind at the end.
Resume the screen session with:
```
screen -x vanillacoind
```
Ctrl-a Ctrl-d to detach

## Launch
Be sure there's no vanillacoind running before !
```
ps x | grep vanillacoind
```
To launch:
```
cd ~/vanillacoin/
screen -d -S vanillacoind -m ./vanillacoind
```

## Update
As user: You must be in the vanillacoin/ folder before running the update script !

```
cd ~/vanillacoin/
bash < <(curl -s  https://raw.githubusercontent.com/xCoreDev/vanillacoin-scripts/master/update-linux.sh)
```
Previous binaries are saved in the backup/ dir.