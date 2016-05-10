#!/bin/bash

# Check root or user
if (( EUID == 0 )); then
	echo -e "\n- - - - - - - - - \n"
	echo "You are too root for this ! Recheck README.md file." 1>&2
	echo -e "\n- - - - - - - - - \n"
	exit
fi

# Check if vanillacoind is running
pgrep -l vanillacoind && echo "vanillacoind is running ! Please close it first." && exit

# Check if vcashd is running
pgrep -l vcashd && echo "vcashd is running ! Please close it first." && exit

# Check thread number. Keep n-1 thread(s) if nproc >= 2
nproc=$(nproc)
if [ $nproc -eq 1 ]
then
	((job=nproc))
elif [ $nproc -gt 1 ]
then
	((job=nproc-1))
fi
echo "Will use $job thread(s)"

# Vcash home dir
if [[ -d "$HOME/vanillacoin" ]]; then
	echo "Found ~/vanillacoin/ dir, renaming to ~/vcash/"
	if [[ ! -d "$HOME/vcash" ]]; then
		mv ~/vanillacoin/ ~/vcash/
	fi
	if [[ -d "$HOME/vcash" ]]; then
		echo "Vcash dir renamed from ~/vanillacoin/ to ~/vcash/"
		VCASH_ROOT=$HOME/vcash/
	else
		echo "Vcash dir renaming failed..."
		if [[ -d "$HOME/vanillacoin" ]]; then
			echo "Vcash dir renaming failed... Using ~/vanillacoin/"
			VCASH_ROOT=$HOME/vanillacoin/
		fi
	fi
elif [[ -d "$HOME/vcash" ]]; then
	echo "Found ~/vcash/ dir"
	VCASH_ROOT=$HOME/vcash/
else
	echo "Creating ~/vcash/ dir"
	mkdir -p ~/vcash/
	VCASH_ROOT=$HOME/vcash/
fi

# Remove build.log file
rm -f $VCASH_ROOT/build.log

# Backup dir
mkdir -p $VCASH_ROOT/backup/

# Rename daemon binary
if [[ -f "$VCASH_ROOT/vanillacoind" ]]; then
	mv $VCASH_ROOT/vanillacoind $VCASH_ROOT/vcashd
	echo "daemon renamed from vanillacoind to vcashd"
fi

# Rename src dir
if [[ -d "$VCASH_ROOT/vanillacoin-src" ]]; then
	mv $VCASH_ROOT/vanillacoin-src/ $VCASH_ROOT/src/
	echo "source dir renamed from vanillacoin-src/ to src/"
fi

# Check src dir & backup deps
ALL_DEPS=0
if [[ -d "$VCASH_ROOT/src" ]]; then
	if [[ -d "$VCASH_ROOT/src/deps/boost" && "$VCASH_ROOT/src/deps/db" && "$VCASH_ROOT/src/deps/openssl" ]]; then
		mv -f $VCASH_ROOT/src/deps/ $VCASH_ROOT/backup/
		echo "Deps backed up." | tee -a $VCASH_ROOT/build.log
		ALL_DEPS=1
	elif [[ -d "$VCASH_ROOT/backup/deps/boost" && "$VCASH_ROOT/backup/deps/db" && "$VCASH_ROOT/backup/deps/openssl" ]]; then
		echo "Deps already backed up." | tee -a $VCASH_ROOT/build.log
		ALL_DEPS=1
	fi
else
	if [[ -d "$VCASH_ROOT/backup/deps/boost" && "$VCASH_ROOT/backup/deps/db" && "$VCASH_ROOT/backup/deps/openssl" ]]; then
		echo "Deps already backed up." | tee -a $VCASH_ROOT/build.log
		ALL_DEPS=1
	fi
fi

# Remove src dir
echo "Clean before clone" | tee -a $VCASH_ROOT/build.log
rm -Rf $VCASH_ROOT/src/

# Check existing vcash binary
echo "Check existing binary" | tee -a $VCASH_ROOT/build.log
if [[ -f "$VCASH_ROOT/vcashd" ]]; then
	BACKUP_VCASHD="vcashd-$(date +%s)"
	echo "Existing vcashd binary ! Let's backup." | tee -a $VCASH_ROOT/build.log
	mkdir -p $VCASH_ROOT/backup/
	mv $VCASH_ROOT/vcashd $VCASH_ROOT/backup/$BACKUP_VCASHD
	rm -f vcashd
fi

# Github
echo "Git clone vcash in src dir" | tee -a $VCASH_ROOT/build.log
cd $VCASH_ROOT/
git clone https://github.com/john-connor/vcash.git src

# Deps
if [[ $ALL_DEPS == 1 ]]; then
	mv $VCASH_ROOT/backup/deps/boost/ $VCASH_ROOT/src/deps/
	mv $VCASH_ROOT/backup/deps/db/ $VCASH_ROOT/src/deps/
	mv $VCASH_ROOT/backup/deps/openssl/ $VCASH_ROOT/src/deps/
	rm -Rf $VCASH_ROOT/backup/deps/
	echo "Deps restored." | tee -a $VCASH_ROOT/build.log
else
	# OpenSSL
	echo "OpenSSL Install" | tee -a $VCASH_ROOT/build.log
	cd $VCASH_ROOT
	wget "https://www.openssl.org/source/openssl-1.0.1s.tar.gz"
	echo "e7e81d82f3cd538ab0cdba494006d44aab9dd96b7f6233ce9971fb7c7916d511  openssl-1.0.1s.tar.gz" | sha256sum -c
	tar -xzf openssl-*.tar.gz
	cd openssl-*
	mkdir -p $VCASH_ROOT/src/deps/openssl/
	./config threads no-comp --prefix=$VCASH_ROOT/src/deps/openssl/
	make -j$job depend && make -j$job && make install

	# DB
	cd $VCASH_ROOT
	wget --no-check-certificate "https://download.oracle.com/berkeley-db/db-4.8.30.tar.gz"
	echo "e0491a07cdb21fb9aa82773bbbedaeb7639cbd0e7f96147ab46141e0045db72a  db-4.8.30.tar.gz" | sha256sum -c
	tar -xzf db-4.8.30.tar.gz
	echo "Compil & install db in deps folder" | tee -a $VCASH_ROOT/build.log
	cd db-4.8.30/build_unix/
	mkdir -p $VCASH_ROOT/src/deps/db/
	../dist/configure --enable-cxx --disable-shared --prefix=$VCASH_ROOT/src/deps/db/
	make -j$job && make install

	# Boost
	cd $VCASH_ROOT
	wget "https://sourceforge.net/projects/boost/files/boost/1.53.0/boost_1_53_0.tar.gz"
	echo "7c4d1515e0310e7f810cbbc19adb9b2d425f443cc7a00b4599742ee1bdfd4c39  boost_1_53_0.tar.gz" | sha256sum -c
	echo "Extract boost" | tee -a $VCASH_ROOT/build.log
	tar -xzf boost_1_53_0.tar.gz
	echo "mv boost to deps folder & rename" | tee -a $VCASH_ROOT/build.log
	mv boost_1_53_0 src/deps/boost
	cd $VCASH_ROOT/src/deps/boost/
	echo "Build boost system" | tee -a $VCASH_ROOT/build.log
	./bootstrap.sh
	./bjam -j$job link=static toolset=gcc cxxflags=-std=gnu++0x --with-system release &

	# Clean
	cd $VCASH_ROOT
	echo "Clean after install" | tee -a $VCASH_ROOT/build.log
	rm -Rf db-4.8.30/ openssl-*/
	rm openssl-*.tar.gz db-4.8.30.tar.gz boost_1_53_0.tar.gz
fi

# Vcash daemon
echo "vcashd bjam build" | tee -a $VCASH_ROOT/build.log
cd $VCASH_ROOT/src/test/
../deps/boost/bjam -j$job toolset=gcc cxxflags=-std=gnu++0x release | tee -a $VCASH_ROOT/build.log
cd $VCASH_ROOT/src/test/bin/gcc-*/release/link-static/
STACK_OUT=$(pwd)
if [[ -f "$STACK_OUT/stack" ]]; then
	echo "vcashd built !" | tee -a $VCASH_ROOT/build.log
	strip $STACK_OUT/stack
	cp $STACK_OUT/stack $VCASH_ROOT/vcashd
else
	cd $VCASH_ROOT/src/test/
	echo "vcashd building error..." 
	exit
fi

# Start
cd $VCASH_ROOT
screen -d -S vcashd -m ./vcashd
echo -e "\n- - - - - - - - - \n"
echo " Vcash daemon launched in a screen session. To switch:"
echo -e "\n- - - - - - - - - \n"
echo " screen -x vcashd"
echo " Ctrl-a Ctrl-d to detach without kill the daemon"
echo -e "\n- - - - - - - - - \n"
