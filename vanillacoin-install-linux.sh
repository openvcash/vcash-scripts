#!/bin/bash
set -e

# Check root or user
if (( EUID == 0 )); then
	echo -e "\n- - - - - - - - - \n"
	echo "You are too root for this ! Recheck README.md file." 1>&2
	echo -e "\n- - - - - - - - - \n"
	exit
fi

# Check sudo group
echo 'Check sudo'
sudo -v || exit

# System Req
echo 'Check apt-get'
sudo apt-get update -y && sudo apt-get install build-essential openssl curl git-core screen -y

# Check if vanillacoind is running
echo 'Check if vanillacoind is running'
pgrep -l vanillacoind && echo "Vanillacoin daemon is a running ! Please close it first." && exit

# Create dir
echo -e '\nCreate vanillacoin dir'
mkdir -p vanillacoin/
cd vanillacoin/
VANILLA_ROOT=$(pwd)

# Check existing binary
echo 'Check existing binary'
if [ -f "$VANILLA_ROOT/vanillacoind" ]; then
	BACKUP_FILE="vanillacoind_$(date +%Y-%m-%d_%H-%M-%S)"
	echo "Existing vanillacoind binary ! Backup @ $VANILLA_ROOT/backup/$BACKUP_FILE"
	mkdir -p $VANILLA_ROOT/backup/
	mv $VANILLA_ROOT/vanillacoind $VANILLA_ROOT/backup/$BACKUP_FILE
	rm -f vanillacoind
fi

# Clean
echo 'Clean for fresh install'
sudo rm -Rf db-4.8.30/ openssl-1.0.1l/ vanillacoin-src/
sudo rm -f openssl-1.0.1l.tar.gz db-4.8.30.tar.gz boost_1_53_0.tar.gz

# Github
echo 'Git clone vanillacoin in vanillacoin-src dir'
git clone https://github.com/john-connor/vanillacoin.git vanillacoin-src

# OpenSSL
echo 'OpenSSL Install'
wget --no-check-certificate 'https://www.openssl.org/source/openssl-1.0.1l.tar.gz'
echo 'b2cf4d48fe5d49f240c61c9e624193a6f232b5ed0baf010681e725963c40d1d4  openssl-1.0.1l.tar.gz' | sha256sum -c
tar -xzf openssl-*.tar.gz
cd openssl-*
mkdir -p $VANILLA_ROOT/vanillacoin-src/deps/openssl/
./config threads no-comp --prefix=$VANILLA_ROOT/vanillacoin-src/deps/openssl/
make && make install

# DB
cd $VANILLA_ROOT
wget --no-check-certificate 'https://download.oracle.com/berkeley-db/db-4.8.30.tar.gz'
echo 'e0491a07cdb21fb9aa82773bbbedaeb7639cbd0e7f96147ab46141e0045db72a  db-4.8.30.tar.gz' | sha256sum -c
tar -xzf db-4.8.30.tar.gz
echo 'Compil & install db in deps forlder'
cd db-4.8.30/build_unix/
mkdir -p $VANILLA_ROOT/vanillacoin-src/deps/db/
../dist/configure --enable-cxx --prefix=$VANILLA_ROOT/vanillacoin-src/deps/db/
make && make install

# Boost
cd $VANILLA_ROOT
wget 'https://sourceforge.net/projects/boost/files/boost/1.53.0/boost_1_53_0.tar.gz'
echo '7c4d1515e0310e7f810cbbc19adb9b2d425f443cc7a00b4599742ee1bdfd4c39  boost_1_53_0.tar.gz' | sha256sum -c
echo 'Extract boost'
tar -xzf boost_1_53_0.tar.gz
echo 'mv boost to deps folder & rename'
mv boost_1_53_0 vanillacoin-src/deps/boost
cd $VANILLA_ROOT/vanillacoin-src/deps/boost/
echo "Build boost system"
./bootstrap.sh
./bjam link=static toolset=gcc cxxflags=-std=gnu++0x --with-system release &

# Vanillacoin daemon
cd $VANILLA_ROOT/vanillacoin-src/
echo "1st bjam"
deps/boost/bjam toolset=gcc cxxflags=-std=gnu++0x release
cd test/
echo "2nd bjam"
../deps/boost/bjam toolset=gcc cxxflags=-std=gnu++0x release
cp $VANILLA_ROOT/vanillacoin-src/test/bin/gcc-*/release/link-static/stack $VANILLA_ROOT/vanillacoind

# Clean
cd $VANILLA_ROOT
echo "Clean after install"
rm -Rf db-4.8.30/ openssl-1.0.1l/
rm openssl-1.0.1l.tar.gz db-4.8.30.tar.gz boost_1_53_0.tar.gz

# Start
screen -d -S vanillacoind -m ./vanillacoind
echo -e "\n- - - - - - - - - \n"
echo " Vanillacoind launched in a screen session. To switch:"
echo -e "\n- - - - - - - - - \n"
echo " screen -x vanillacoind"
echo " Ctrl-a Ctrl-d to detach without kill the daemon"
echo -e "\n- - - - - - - - - \n"