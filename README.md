# Vanillacoin Install/Update Scripts

## Warning !
Please backup your existing wallet files (.Vanillacoin folder).
I can't be responsible if you broke something.

## Req.

#### Debian / Ubuntu 
```
sudo apt-get install build-essential openssl curl git-core screen -y
```

#### Raspberry Pi
Be sure to have enough Swap to avoid 'Virtual memory exhausted: Cannot allocate memory'
Raspbian default Swap size is 100mb, please increase the size before building.

Check Swap size:
```
free -m
```

Example with 1024mb as Swap size:
```
sudo nano /etc/dphys-swapfile
```
Edit the file:
```
CONF_SWAPSIZE=1024
```
Save & restart dphys-swapfile:
```
sudo /etc/init.d/dphys-swapfile stop
sudo /etc/init.d/dphys-swapfile start
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
