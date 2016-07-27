#!/bin/bash

# Deps infos
OPENSSL_VER=1.0.1t
OPENSSL_URL=https://www.openssl.org/source/openssl-1.0.1t.tar.gz
OPENSSL_SHA=4a6ee491a2fdb22e519c76fdc2a628bb3cec12762cd456861d207996c8a07088

DB_VER=6.1.29.NC
DB_URL=https://download.oracle.com/berkeley-db/db-6.1.29.NC.tar.gz
DB_SHA=e3404de2e111e95751107d30454f569be9ec97325d5ea302c95a058f345dfe0e

BOOST_VER=1_53_0
BOOST_URL=https://sourceforge.net/projects/boost/files/boost/1.53.0/boost_1_53_0.tar.gz
BOOST_SHA=7c4d1515e0310e7f810cbbc19adb9b2d425f443cc7a00b4599742ee1bdfd4c39

# Check root or user
if (( EUID == 0 )); then
	echo -e "\n- - - - - - - - - \n"
	echo "You are too root for this ! Recheck README.md file." 1>&2
	echo -e "\n- - - - - - - - - \n"
	exit
fi

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
echo "Creating ~/vcash/ dir"
mkdir -p ~/vcash/
VCASH_ROOT=$HOME/vcash/

# Remove build.log file
rm -f $VCASH_ROOT/build.log

# Backup dir
mkdir -p $VCASH_ROOT/backup/

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
sed --in-place -e '34d' $VCASH_ROOT/src/include/coin/protocol.hpp

# OpenSSL
function build_openssl {
	echo "OpenSSL Install" | tee -a $VCASH_ROOT/build.log
	cd $VCASH_ROOT
	rm -Rf $VCASH_ROOT/src/deps/openssl/
	wget $OPENSSL_URL
	echo "$OPENSSL_SHA  openssl-$OPENSSL_VER.tar.gz" | sha256sum -c
	tar -xzf openssl-$OPENSSL_VER.tar.gz
	cd openssl-$OPENSSL_VER
	mkdir -p $VCASH_ROOT/src/deps/openssl/
	./config threads no-comp --prefix=$VCASH_ROOT/src/deps/openssl/
	make -j$job depend && make -j$job && make install && touch $VCASH_ROOT/src/deps/openssl/current_openssl_$OPENSSL_VER
	# Clean
	cd $VCASH_ROOT
	echo "Clean after OpenSSL install" | tee -a $VCASH_ROOT/build.log
	rm -Rf openssl-$OPENSSL_VER/
	rm openssl-$OPENSSL_VER.tar.gz
}

# DB
function build_db {
	cd $VCASH_ROOT
	rm -Rf $VCASH_ROOT/src/deps/db/
	wget --no-check-certificate $DB_URL
	echo "$DB_SHA  db-$DB_VER.tar.gz" | sha256sum -c
	tar -xzf db-*.tar.gz
	echo "Compile & install Berkeley DB in deps folder" | tee -a $VCASH_ROOT/build.log
	cd db-$DB_VER/build_unix/
	mkdir -p $VCASH_ROOT/src/deps/db/
	../dist/configure --enable-cxx --disable-shared --prefix=$VCASH_ROOT/src/deps/db/
	make -j$job && make install && touch $VCASH_ROOT/src/deps/db/current_db_$DB_VER
	# Clean
	cd $VCASH_ROOT
	echo "Clean after Berkeley DB install" | tee -a $VCASH_ROOT/build.log
	rm -Rf db-$DB_VER/
	rm db-$DB_VER.tar.gz
}

# Boost
function build_boost {
	cd $VCASH_ROOT
	rm -Rf $VCASH_ROOT/src/deps/boost/
	wget $BOOST_URL
	echo "$BOOST_SHA  boost_$BOOST_VER.tar.gz" | sha256sum -c
	echo "Extract boost" | tee -a $VCASH_ROOT/build.log
	tar -xzf boost_$BOOST_VER.tar.gz
	echo "mv boost to deps folder & rename" | tee -a $VCASH_ROOT/build.log
	mv boost_$BOOST_VER src/deps/boost
	cd $VCASH_ROOT/src/deps/boost/
	echo "Build boost system" | tee -a $VCASH_ROOT/build.log
	./bootstrap.sh
	./bjam -j$job link=static toolset=gcc cxxflags=-std=gnu++0x --with-system release &
	touch $VCASH_ROOT/src/deps/boost/current_boost_$BOOST_VER
	# Clean
	cd $VCASH_ROOT
	echo "Clean after Boost install" | tee -a $VCASH_ROOT/build.log
	rm boost_$BOOST_VER.tar.gz
}

if [[ $ALL_DEPS == 1 ]]; then
	mv $VCASH_ROOT/backup/deps/boost/ $VCASH_ROOT/src/deps/
	# Temp
	if ! [[ -f "$VCASH_ROOT/src/deps/boost/current_boost_$BOOST_VER" ]]; then
		touch $VCASH_ROOT/src/deps/boost/current_boost_$BOOST_VER
	fi
	mv $VCASH_ROOT/backup/deps/db/ $VCASH_ROOT/src/deps/
	mv $VCASH_ROOT/backup/deps/openssl/ $VCASH_ROOT/src/deps/
	rm -Rf $VCASH_ROOT/backup/deps/
	echo "Deps restored." | tee -a $VCASH_ROOT/build.log
else
	build_openssl
	build_db
	build_boost
fi

# Deps upgrade ?
if ! [[ -f "$VCASH_ROOT/src/deps/openssl/current_openssl_$OPENSSL_VER" ]]; then
	build_openssl
fi
if ! [[ -f "$VCASH_ROOT/src/deps/db/current_db_$DB_VER" ]]; then
	build_db
fi
if ! [[ -f "$VCASH_ROOT/src/deps/boost/current_boost_$BOOST_VER" ]]; then
	build_boost
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
	# Check if vcashd is running
	RESTART=0
	pgrep -l vcashd && RESTART=1
else
	cd $VCASH_ROOT/src/test/
	echo "vcashd building error..." 
	exit
fi

# Start or restart
cd $VCASH_ROOT

if [[ $RESTART == 1 ]]; then
	echo -e "\n- - - - - - - - - \n"
	echo " ! Previous Vcash daemon is still running !"
	echo -e "\n- - - - - - - - - \n"
	echo " Please kill the process & start the fresh vcashd with:"
	echo " cd ~/vcash/ && screen -d -S vcashd -m ./vcashd"
	echo -e "\n- - - - - - - - - \n"
else
	echo -e "\n- - - - - - - - - \n"
	echo " Vcash daemon built but not started !"
	echo " Current code is in Release Candidate stage !!!"
	echo " Make backups of the current ~/.Vcash/ directory !!!"
	echo " Don't run it in production !!!"
	echo -e "\n- - - - - - - - - \n"
	echo " To start:"
	echo " cd ~/vcash/ && screen -d -S vcashd -m ./vcashd"
	echo -e "\n- - - - - - - - - \n"
	echo " To attach the screen session:"
	echo " screen -x vcashd"
	echo -e "\n- - - - - - - - - \n"
	echo " To detach the screen session without stopping the daemon:"
	echo " Ctrl-a Ctrl-d"
	echo -e "\n- - - - - - - - - \n"
	echo " To stop the daemon while attached to the screen session:"
	echo " Ctrl-x"
	echo -e "\n- - - - - - - - - \n"
fi
