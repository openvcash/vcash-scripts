# Vcash Install / Update Scripts

## Current Vcash 0.4.8 code is in release candidate stage ! See Wait for the 0.4.8 announcement: https://v.cash/forum/threads/version-0-4-8-rc1-release.575/

## For a 0.4.7 fresh install, see: https://github.com/xCoreDev/vcash-scripts/tree/0.4.7

## Warning !
Please backup your existing wallet files (~/.Vcash/data/ folder).
I can't be responsible if you broke something.

## Req.

#### GNU/Linux
GCC/G++ >= 4.8.* / git / screen / curl. On low-spec hardware, don't forget to increase the SWAP (min 1024MB) to avoid the 'Virtual memory exhausted: Cannot allocate memory' during the build process.

#### Debian / Ubuntu / Raspbian
```
sudo apt-get install build-essential openssl curl git-core screen -y
```

#### Raspbian
Be sure to have enough Swap to avoid 'Virtual memory exhausted: Cannot allocate memory'.
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

## Install / Update
As user (fresh ssh login as user, not su switch to user from the root account):
```
bash < <(curl -s  https://raw.githubusercontent.com/xCoreDev/vcash-scripts/master/build-linux.sh)
```
The script will auto launch vcashd at the end.
Resume the screen session with:
```
screen -x vcashd
```
Ctrl-a Ctrl-d to detach

## Launch
Be sure there's no vcashd running before !
```
ps x | grep '[v]cashd'
```
To launch:
```
cd ~/vcash/
screen -d -S vcashd -m ./vcashd
```

## Crontab
As user:
Autostart Vcash daemon on reboot with crontab:
```
crontab -e
```
Add this entry (edited with your username):
```
@reboot pgrep vcashd > /dev/null || cd /home/your_username/vcash && screen -d -S vcashd -m ./vcashd
```
save & check crontab:
```
crontab -l
```
Then do a reboot test.
