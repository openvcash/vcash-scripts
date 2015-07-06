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
echo "Check vanillacoind process"
pgrep vanillacoind && echo "Vanillacoin daemon is a running ! Please close it first." && exit

# Check path & current daemon binary
echo "Check path & current binary"
VANILLA_ROOT=$(pwd)
if [[ ! -f "$VANILLA_ROOT/vanillacoind" ]]; then
	echo "Can't find current vanillacoind binary ! Check your path."
	exit
fi

# Check current deps
echo "Check current deps in source dir"
if [[ ! -d "$VANILLA_ROOT/vanillacoin-src/deps/boost" && "$VANILLA_ROOT/vanillacoin-src/deps/db" && "$VANILLA_ROOT/vanillacoin-src/deps/openssl" ]]; then
	echo "Can't find req. deps in vanillacoin-src/deps/ folder !"
	echo "Follow INSTALL instructions on Github."
	exit
fi

# Backup deps
echo "Backup deps"
mkdir -p $VANILLA_ROOT/backup/
mv -f $VANILLA_ROOT/vanillacoin-src/deps/ $VANILLA_ROOT/backup/
mv -f $VANILLA_ROOT/vanillacoind $VANILLA_ROOT/backup/vanillacoind-$(date +%s)

# Clean
echo "Clean before clone"
rm -Rf vanillacoin-src/

# Github
echo "Git clone vanillacoin in vanillacoin-src dir"
git clone https://github.com/xCoreDev/vanillacoin.git vanillacoin-src

# Restore deps
echo "Restore deps"
mv $VANILLA_ROOT/backup/deps/boost/ $VANILLA_ROOT/vanillacoin-src/deps/
mv $VANILLA_ROOT/backup/deps/db/ $VANILLA_ROOT/vanillacoin-src/deps/
mv $VANILLA_ROOT/backup/deps/openssl/ $VANILLA_ROOT/vanillacoin-src/deps/
rm -Rf $VANILLA_ROOT/backup/deps/

# Vanillacoin daemon
cd $VANILLA_ROOT/vanillacoin-src/
echo "vanillacoind bjam build"
cd test/
../deps/boost/bjam toolset=gcc cxxflags=-std=gnu++0x release
cp $VANILLA_ROOT/vanillacoin-src/test/bin/gcc-*/release/link-static/stack $VANILLA_ROOT/vanillacoind
cd $VANILLA_ROOT

# Start
screen -d -S vanillacoind -m ./vanillacoind
echo -e "\n- - - - - - - - - \n"
echo " Vanillacoind launched in a screen session. To switch:"
echo -e "\n- - - - - - - - - \n"
echo " screen -x vanillacoind"
echo " Ctrl-a Ctrl-d to detach without kill the daemon"
echo -e "\n- - - - - - - - - \n"
