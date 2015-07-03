#!/bin/bash
set -e

# Check root or user
if (( EUID == 0 )); then
	echo -e "\n- - - - - - - - - \n"
	echo "You are too root for this ! Recheck README.md file." 1>&2
	echo -e "\n- - - - - - - - - \n"
	exit
fi

# Check if vanillacoind is running
echo "Check if vanillacoind is running"
pgrep -l vanillacoind && echo "Vanillacoin daemon is a running ! Please close it first." && exit

# Create dir
echo -e "\nCreate vanillacoin dir"
mkdir -p vanillacoin/
cd vanillacoin/
VANILLA_ROOT=$(pwd)

# Check existing vanillacoind binary
echo "Check existing binary"
if [[ -f "$VANILLA_ROOT/vanillacoind" ]]; then
	BACKUP_VANILLACOIND="vanillacoind_$(date +%Y-%m-%d_%H-%M-%S)"
	echo "Existing vanillacoind binary ! Backup @ $VANILLA_ROOT/backup/$BACKUP_VANILLACOIND"
	mkdir -p $VANILLA_ROOT/backup/
	mv $VANILLA_ROOT/vanillacoind $VANILLA_ROOT/backup/$BACKUP_VANILLACOIND
	rm -f vanillacoind
fi

# Check existing databased binary
echo "Check existing binary"
if [[ -f "$VANILLA_ROOT/databased" ]]; then
	BACKUP_DATABASED="databased_$(date +%Y-%m-%d_%H-%M-%S)"
	echo "Existing databased binary ! Backup @ $VANILLA_ROOT/backup/$BACKUP_DATABASED"
	mkdir -p $VANILLA_ROOT/backup/
	mv $VANILLA_ROOT/databased $VANILLA_ROOT/backup/$BACKUP_DATABASED
	rm -f databased
fi

# Clean
echo "Clean for fresh install"
rm -Rf db-4.8.30/ openssl-1.0.2c/ vanillacoin-src/
rm -f openssl-1.0.2c.tar.gz db-4.8.30.tar.gz boost_1_53_0.tar.gz

# Github
echo "Git clone vanillacoin in vanillacoin-src dir"
git clone https://github.com/john-connor/vanillacoin.git vanillacoin-src

# OpenSSL
echo "OpenSSL Install"
wget --no-check-certificate "https://openssl.org/source/openssl-1.0.2c.tar.gz"
echo "0038ba37f35a6367c58f17a7a7f687953ef8ce4f9684bbdec63e62515ed36a83  openssl-1.0.2c.tar.gz" | sha256sum -c
tar -xzf openssl-*.tar.gz
cd openssl-*
mkdir -p $VANILLA_ROOT/vanillacoin-src/deps/openssl/
./config threads no-comp --prefix=$VANILLA_ROOT/vanillacoin-src/deps/openssl/
make && make install

# DB
cd $VANILLA_ROOT
wget --no-check-certificate "https://download.oracle.com/berkeley-db/db-4.8.30.tar.gz"
echo "e0491a07cdb21fb9aa82773bbbedaeb7639cbd0e7f96147ab46141e0045db72a  db-4.8.30.tar.gz" | sha256sum -c
tar -xzf db-4.8.30.tar.gz
echo "Compil & install db in deps forlder"
cd db-4.8.30/build_unix/
mkdir -p $VANILLA_ROOT/vanillacoin-src/deps/db/
../dist/configure --enable-cxx --prefix=$VANILLA_ROOT/vanillacoin-src/deps/db/
make && make install

# Boost
cd $VANILLA_ROOT
wget "https://sourceforge.net/projects/boost/files/boost/1.53.0/boost_1_53_0.tar.gz"
echo "7c4d1515e0310e7f810cbbc19adb9b2d425f443cc7a00b4599742ee1bdfd4c39  boost_1_53_0.tar.gz" | sha256sum -c
echo "Extract boost"
tar -xzf boost_1_53_0.tar.gz
echo "mv boost to deps folder & rename"
mv boost_1_53_0 vanillacoin-src/deps/boost
cd $VANILLA_ROOT/vanillacoin-src/deps/boost/
echo "Build boost system"
./bootstrap.sh
./bjam link=static toolset=gcc cxxflags=-std=gnu++0x --with-system release &

# Vanillacoin daemon
cd $VANILLA_ROOT/vanillacoin-src/
echo "1st vanillacoind bjam"
deps/boost/bjam toolset=gcc cxxflags=-std=gnu++0x release
cd test/
echo "2nd vanillacoind bjam"
../deps/boost/bjam toolset=gcc cxxflags=-std=gnu++0x release
cp $VANILLA_ROOT/vanillacoin-src/test/bin/gcc-*/release/link-static/stack $VANILLA_ROOT/vanillacoind

# Database
mv -f $VANILLA_ROOT/vanillacoin-src/deps/ $VANILLA_ROOT/vanillacoin-src/database/
cd $VANILLA_ROOT/vanillacoin-src/database/
echo "1st databased bjam"
deps/boost/bjam toolset=gcc cxxflags=-std=gnu++0x debug
cd test/
echo "2nd databased bjam"
../deps/boost/bjam toolset=gcc cxxflags=-std=gnu++0x debug
cp $VANILLA_ROOT/vanillacoin-src/database/test/bin/gcc-*/debug/link-static/stack $VANILLA_ROOT/databased
mv -f $VANILLA_ROOT/vanillacoin-src/database/deps/ $VANILLA_ROOT/vanillacoin-src/

# Clean
cd $VANILLA_ROOT
echo "Clean after install"
rm -Rf db-4.8.30/ openssl-1.0.2c/
rm openssl-1.0.2c.tar.gz db-4.8.30.tar.gz boost_1_53_0.tar.gz


