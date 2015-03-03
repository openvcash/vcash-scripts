#!/bin/bash
set -e
echo 'Check sudo'
sudo -v || exit

# System Req
echo 'Check apt-get'
sudo apt-get update -y
sudo apt-get install build-essential openssl curl git-core -y

# Create 
echo 'Create vanillacoin dir'
mkdir -p vanillacoin
cd vanillacoin/
VANILLA_ROOT=$(pwd)

# Clean
echo 'Clean for fresh install'
sudo rm -Rf db-4.8.30.NC/ openssl-1.0.1l/ vanillacoin-src/
sudo rm -f openssl-1.0.1l.tar.gz db-4.8.30.NC.tar.gz boost_1_53_0.tar.gz

# Github
echo 'Git clone vanillacoin in vanillacoin-src dir'
git clone https://github.com/john-connor/vanillacoin.git vanillacoin-src

# OpenSSL
echo 'OpenSSL Install'
wget --no-check-certificate https://www.openssl.org/source/openssl-1.0.1l.tar.gz
echo 'b2cf4d48fe5d49f240c61c9e624193a6f232b5ed0baf010681e725963c40d1d4  openssl-1.0.1l.tar.gz' | sha256sum -c
tar xfz openssl-*.tar.gz
cd openssl-*
mkdir -p $VANILLA_ROOT/vanillacoin-src/deps/openssl/
./config threads no-comp --prefix=$VANILLA_ROOT/vanillacoin-src/deps/openssl/
make && make install

# DB
cd $VANILLA_ROOT
wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz'
echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c
tar -xzf db-4.8.30.NC.tar.gz
echo 'Compil & install db in deps forlder'
cd db-4.8.30.NC/build_unix/
mkdir -p $VANILLA_ROOT/vanillacoin-src/deps/db/
../dist/configure --enable-cxx --prefix=$VANILLA_ROOT/vanillacoin-src/deps/db/
make
make install

# Boost
cd $VANILLA_ROOT
wget 'https://sourceforge.net/projects/boost/files/boost/1.53.0/boost_1_53_0.tar.gz'
echo '7c4d1515e0310e7f810cbbc19adb9b2d425f443cc7a00b4599742ee1bdfd4c39  boost_1_53_0.tar.gz' | sha256sum -c
echo 'extract boost'
tar -xzf boost_1_53_0.tar.gz
echo 'mv boost to deps folder & rename'
mv boost_1_53_0 vanillacoin-src/deps/boost
cd $VANILLA_ROOT/vanillacoin-src/deps/boost/
echo "Build boost system"
./bootstrap.sh
./bjam -d 0 link=static toolset=gcc cxxflags=-std=gnu++0x --with-system release &

# Vanillacoin daemon
cd $VANILLA_ROOT/vanillacoin-src/
echo "1st bjam"
deps/boost/bjam -d 0 toolset=gcc cxxflags=-std=gnu++0x release
cd test/
echo "2nd bjam"
../deps/boost/bjam -d 0 toolset=gcc cxxflags=-std=gnu++0x release
cp $VANILLA_ROOT/vanillacoin-src/test/bin/gcc-*/release/link-static/stack $VANILLA_ROOT/vanillacoind

# Clean
cd $VANILLA_ROOT
echo "Clean after install"
rm -Rf db-4.8.30.NC/ openssl-1.0.1l/
rm openssl-1.0.1l.tar.gz db-4.8.30.NC.tar.gz boost_1_53_0.tar.gz

# Start
./vanillacoind