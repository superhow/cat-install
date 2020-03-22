#/bin/bash
SCRIPT_VER=0.5
SSH_PORT=22
CAT_VER=0.9.3.2
cd
# echo "Be sure to use screen before running. There will be several prompts for sudo password"
# echo "This script is prepared to be executed with user 'root' or any other user"

function print_menu() {
	#clear
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo ""
	echo "***************************************************************"
	echo "*   Symbol CATAPULT install and build script by SUPER HOW?    *"
	echo "*   - Script builds all Symbol CATAPULT dependancies          *"
	echo "*   - Script installs all Symbol CATAPULT dependancies        *"
	echo "*   - Script builds and installs Symbol CATAPULT ${CAT_VER}"
	echo "*   - Script generates Symbol CATAPULT seed                   *"
	echo "*                                                             *"
	echo "*   Script to be run by limited user, will need sudo rights   *"
	echo "*  															*"
	echo "*   Prerequisites												*"
	echo "*		from github/nemtech	for Building on Ubuntu 18.04 (LTS)	*"
	echo "*   															*"
	echo "*       -OpenSSL dev library, at least 1.1.1 (libssl-dev)		*"
	echo "*       -cmake (at least 3.14)								*"
	echo "*       -git													*"
	echo "*       -python 3.x											*"
	echo "*       -gcc 9.2												*"
	echo "*       -ninja-build - suggested								*"
	echo "*   															*"
	echo "*   Instructions below are for gcc, 							*"
	echo "*					but project compiles with clang 9 as well.	*"
	echo "*																*"
	echo "*===================================================+==========*"
	echo "|    Script version: v${SCRIPT_VER}                            |"
	echo "|    Crafted with love by: minister, linas and bruce_wayne     |"
	echo "|    2020 [] https://SUPERHOW.io                               |"
	echo "*=======================================+======================*"
	os_version_check
	echo "*=============================================================*"
	echo "| MENU:                                                       |"
	echo "|                                                             |"
	echo "|  1) Step 1: Build all dependencies and CATAPULT F5          |"
	echo "|  2) Step 2: Install MONGO.DB, NODE.JS and CATAPULT REST     |"
	echo "|  3) Step 3: Generate keys and instialize CATAPULT seed      |"
	echo "|  4) Tool: Just build mijin CATAPULT F5 from git             |"
	echo "|  5) Tool: TBD                                               |"
	echo "|  9) Setup Firewall and change SSH port (TODO)               |"
	echo "|  0) Tool: Just do system update & upgrade                   |"	
	echo "|                                                             |"
	echo "|  80) Hostname                                               |" 
	echo "|  91) Reboot                                                 |"
	echo "|  92) Shutdown                                               |"
	echo "|  100) Print menu                                            |"
	echo "|                                                             |"
	echo "|  q) Quit                                                    |"
	echo "*=============================================================*"
}

function os_version_check() {
	if [[ -r /etc/os-release ]]; then
    	. /etc/os-release
		# echo -e "Version ${VERSION_ID}"
		echo -e "OS & Version: ${PRETTY_NAME}"
		if [[ "${VERSION_ID}" != "16.04" ]] && [[ "${VERSION_ID}" != "18.04" ]] ; then
			echo "WARNING: Script is compatible with ONLY Ubuntu 16.04 or Ubuntu 18.04"
		fi
	fi
}

function build_all_dependancies() {
	clear
	echo "*---------------------------------------------------------*"
	echo "| UPDATE system, install DEPENDANCIES, build TOOLS? [y/n] |"
	echo "| mijin CATAPULT version: ${CAT_VER}                      |"
	echo "*---------------------------------------------------------*"
	read DOINSTALL
	if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
		# change_ssh_port
		# firewall_setup
		do_system_update
		install_dependancies
		build_boost
		# echo "Ar viskas gerai?"
		# read ANYKEY
		build_gtest
		build_benchmark
		build_mongoc
		build_mongocxx
		build_zmq
		build_rocksdb
		# echo "Ar viskas gerai?"
		# read ANYKEY
		build_catapult_server_9_3_2
	fi
}

function do_system_update() {
	sudo apt update
	sudo apt -y upgrade
	ulimit -n 4096
	#sudo apt-get -y --fix-missing upgrade  # kai neranda tam tikrų paketų 
	#sudo apt-get -y dist-upgrade 
}

function install_dependancies() {
	sudo apt update
	sudo apt install -y screen mc zsh curl git gcc python2.7 pkg-config
	sudo apt install -y autoconf libtool cmake xz-utils libatomic-ops-dev libunwind-dev g++ gdb libgflags-dev libsnappy-dev ninja-build python3 python3-ply
	# sudo apt install -y build-essential automake software-properties-common
}

function build_boost() {
	# Boost - c++
	cd && curl -o boost_1_71_0.tar.gz -SL https://dl.bintray.com/boostorg/release/1.71.0/source/boost_1_71_0.tar.gz
	tar -xzf boost_1_71_0.tar.gz
	rm boost_1_71_0.tar.gz
	## WARNING: below use $HOME rather than ~ - boost scripts might treat it literally
	mkdir boost-build-1.71.0
	cd boost_1_71_0
	./bootstrap.sh --prefix=${HOME}/boost-build-1.71.0
	./b2 --prefix=${HOME}/boost-build-1.71.0 --without-python -j 4 stage release
	./b2 --prefix=${HOME}/boost-build-1.71.0 --without-python install
}

function build_gtest() {
	# Gtest
	cd && git clone https://github.com/google/googletest.git
	cd googletest
	git checkout release-1.8.1
	mkdir _build && cd _build
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
	make
	sudo make install
}

function build_benchmark() {
	# Google benchmark
	cd && git clone https://github.com/google/benchmark.git
	cd benchmark
	git checkout v1.5.0
	mkdir _build && cd _build
	cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_GTEST_TESTS=OFF ..
	make
	sudo make install
}

function build_mongoc() {
	# Mongo driver mongo-c
	# cd && sudo apt -y install libmongoc-1.0-0 libbson-1.0
	cd && git clone https://github.com/mongodb/mongo-c-driver.git
	cd mongo-c-driver
	git checkout 1.15.1
	mkdir _build && cd _build
	cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
	make
	sudo make install
}

function build_mongocxx() {
	# Mongo driver mongo-c++
	cd && git clone https://github.com/nemtech/mongo-cxx-driver.git
	cd mongo-cxx-driver
	git checkout r3.4.0-nem
	#TODO: find out why do we need maxAwaitTimeMS patch...
	#sed -i 's/kvp("maxAwaitTimeMS", count)/kvp("maxAwaitTimeMS", static_cast<int64_t>(count))/' src/mongocxx/options/change_stream.cpp
	mkdir _build && cd _build
	cmake -DCMAKE_CXX_STANDARD=17 -DLIBBSON_DIR=/usr/local -DLIBMONGOC_DIR=/usr/local -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
	make
	sudo make install
}

function build_zmq() {
	# ZMQ libzmq
	cd && git clone git://github.com/zeromq/libzmq.git
	cd libzmq
	git checkout v4.3.2
	mkdir _build && cd _build
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
	make
	sudo make install

	# ZMQ cppzmq
	cd && git clone https://github.com/zeromq/cppzmq.git
	cd cppzmq
	git checkout v4.4.1
	mkdir _build && cd _build
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
	make
	sudo make install
}

function build_rocksdb() {
	# RocksDB
	cd && git clone https://github.com/nemtech/rocksdb.git
	cd rocksdb
	git checkout v6.6.4-nem
	mkdir _build && cd _build
	cmake -DCMAKE_BUILD_TYPE=Release -DWITH_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local ..
	make
	sudo make install
	#echo "Ar viskas gerai?"
	#read ANYKEY
}

function build_catapult_f5() {
	clear
	echo ""
	echo "*-------------------------------------------------------------*"
	echo "|   Build catapult server ${CAT_VER} from SUPER HOW git? [y/n]|"
	echo "*-------------------------------------------------------------*"
	read DOINSTALL
	if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
		sudo apt update
		#build_catapult_server_9_3_2
		#build_catapult_superhow_9_3_2
	fi
}

function build_catapult_superhow_9_3_2() {
	# CATAPULT server
	cd && git clone https://bitbucket.org/superhow/catapult-server.git -b release
	cd catapult-server
	export HASHING_FUNCTION=sha3
	mkdir build && cd build # replacing _build to build. for future scripts
	#mkdir _build && cd _build
	cmake -DBOOST_ROOT=~/boost-build-1.71.0 -DCMAKE_BUILD_TYPE=Release -G Ninja ..
	ninja publish
	ninja -j4
	echo "Ar viskas gerai?"
	read ANYKEY
}

function build_catapult_server_9_3_2() {
	# CATAPULT server
	cd && git clone https://github.com/nemtech/catapult-server.git
	cd catapult-server
	export HASHING_FUNCTION=sha3
	#mkdir build && cd build # replacing _build to build. for future scripts
	mkdir _build && cd _build
	cmake -DBOOST_ROOT=~/boost-build-1.71.0 -DCMAKE_BUILD_TYPE=Release -G Ninja ..
	ninja publish
	ninja -j4
	echo "Ar viskas gerai?"
	read ANYKEY
}

function install_mijin() {
	clear
	echo ""
	echo "*----------------------------------------------------------------*"
	echo "|             Install MONGO, NODE.JS, CATAPULT REST? [y/n]       |"
	echo "|             CATAPULT version: ${CAT_VER}                       |"
	echo "*----------------------------------------------------------------*"
	read DOINSTALL
	if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
		install_mongodb
		install_node_js
		echo "Ar viskas gerai?"
		read ANYKEY
		install_rest
	fi
}

function install_mongodb() {
	# Install MongoDB. MANDATORY
	cd
	sudo apt update
	sudo apt install -y mongodb
	sudo systemctl start mongodb
	sudo systemctl enable mongodb
	sudo systemctl status mongodb
}

function install_node_js() {
	# Install Node.js v10 & yarn for REST API
	cd
	curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
	sudo apt install -y nodejs
	curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
	sudo apt update
	sudo apt install -y yarn
}

function install_rest() {
	# Install REST API
	cd && git clone https://github.com/nemtech/catapult-rest.git
	cd catapult-rest
	export HASHING_FUNCTION=sha3
	./yarn_setup.sh
	cd rest
	yarn build
}

function init_seed() {
	clear
	echo ""
	echo "*------------------------------------------------------------*"
	echo "|  Generate GENESIS keys and initialize CATAPULT seed? [y/n] |"
	echo "|  CATAPULT version: ${CAT_VER}                              |"
	echo "*------------------------------------------------------------*"
	read DOINSTALL
	if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
		generate_accounts
		initialize_seed
	fi
}

function generate_accounts() {
	clear
	echo ""
	echo "*---------------------------------------------------------*"
	echo "|       How many accounts you need? [3-10]                |"
	echo "|       Enter number from 3 to 10                         |"
	echo "*---------------------------------------------------------*"
	read ACCOUNT_COUNT
	# Generate 3 accounts for "nemesis_signer" , "node owner" and "REST owner"!!!
	# Generate 3 additional accounts for "api owner", peer1 owner" and "peer2 owner"!!!
	cd ~/catapult-server/build
	# mkdir catapult-node-data
	# catapult-node-data && mkdir data && mkdir nemesis && mkdir resources && mkdir scripts && mkdir seed
	~/catapult-server/build/bin/catapult.tools.address -g ${ACCOUNT_COUNT} --network mijin-test > ~/catapult-server/nemesis_signer.txt
    cd ~/catapult-server
    mkdir nemesis && mkdir data && mkdir tmp
}

function initialize_seed() {
	cd ~/catapult-server/scripts
	git clone https://bitbucket.org/superhow/mijin-config-f1.git mijin-config -b itree-beta1
	cp -r mijin-config/cat-config-linux ./cat-config
	rm -rf mijin-config
	
	# First private and public keys from the file ~/catapult-node-data/nemesis_signer.txt
	# --local (local node) dual (peer & api in one)
	cd ~/catapult-server

	# zsh scripts/cat-config/reset.sh --local dual ~/catapult-server <private_key> <public_key>
}

# You need to make changes to the configuration files.
# folder with configuration files - catapult-server/recources
# 
# change the necessary parameters. You can change other parameters for your task.
#
# 1.
# config-harvesting.properties
#       harvesterPrivateKey = <PRIVATE key of the FIRST address from the file catapult-node-data/harvester_addresses.txt>
# 2.
# config-node.properties
#
#       enableSingleThreadPool = false
#       friendlyName =
# 3.
# config-user.properties
#       [account]
#
#       #keys should look like 3485D98EFD7EB07ADAFCFD1A157D89DE2796A95E780813C0258AF3F5F84ED8CB
#       bootPrivateKey = <PRIVATE key of the SECOND address from the file catapult-server/harvester_addresses.txt>
#       shouldAutoDetectDelegatedHarvesters = true
#
#       [storage]
#
#       dataDirectory = ../data
#       pluginsDirectory =
#
# 4.
#       "publicKey": <PUBLIC key of the SECOND address from the file catapult-server/harvester_addresses.txt>
#
# 5.
# peer-p2p.json
#       "publicKey": <PUBLIC key of the SECOND address from the file catapult-server/harvester_addresses.txt>


# Configure REST API
# 1.
# catapult-rest/rest/resources/rest.json
#       "clientPrivateKey": <PRIVATE key of the THIRD address from the file catapult-server/harvester_addresses.txt
#
#       "apiNode": {
#           "host": "127.0.0.1",
#           "port": 7900,
#           "publicKey": <PUBLIC key of the SECOND address from the file catapult-server/harvester_addresses.txt>,
#           "timeout": 1000
# },
#
# ALL READY FOR LAUNCH !!!



# # === Firewall ===
# function firewall_setup() {
# 	echo "********** FIREWALL SETUP **************"
# 	sudo apt-get install -y ufw
# 	#sudo ufw allow OpenSSH
# 	sudo ufw default deny
# 	#sudo ufw allow ssh/tcp
# 	#sudo ufw limit ssh/tcp
# 	sudo ufw logging on
# 	#sudo ufw allow 22
# 	sudo ufw limit $SSH_PORT/tcp
# 	#sudo ufw limit OpenSSH
# 	echo "y" | sudo ufw enable
# 	#sudo ufw status
# }
#
# function change_ssh_port() {
# 	echo "Do you want to change SSH port? [y/n]"
# 	read DOSSHPORT
# 	if [[ $DOSSHPORT =~ "y" ]] || [[ $DOSSHPORT =~ "Y" ]] ; then
# 		sudo nano /etc/ssh/sshd_config
# 	# ---  surasti #port.. ir nuimti # ir pakeisti porta i
# 	# ---  port 4513
# 		sudo systemctl restart ssh
# 	fi
# }

while [[ $DOACTION != "q" ]]
do
	print_menu
	echo "*********************************"
	read DOACTION
	echo "*********************************"

	if [[ $DOACTION == "1" ]] ; then
		build_all_dependancies
	fi
	if [[ $DOACTION == "2" ]] ; then
		install_mijin
	fi
	if [[ $DOACTION == "3" ]] ; then
		init_seed
	fi
	if [[ $DOACTION == "4" ]] ; then
		build_catapult_f1
	fi
	if [[ $DOACTION == "9" ]] ; then
		do_firewall_and_ssh
	fi
	if [[ $DOACTION == "0" ]] ; then
		do_system_update
	fi
	if [[ $DOACTION == "80" ]] ; then
		hostname -a
		hostname -i
		hostname -I
	fi
	if [[ $DOACTION == "91" ]] ; then
		sudo reboot
	fi
	if [[ $DOACTION == "92" ]] ; then
		sudo shutdown -h now
	fi
	if [[ $DOACTION == "100" ]] ; then
		print_menu
	fi
done