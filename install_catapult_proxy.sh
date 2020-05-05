#!/bin/bash
# Install and build Symbol catapult server and dependancies interactive script version v1.0
# Copyright (c) 2020 superhow, ministras, SUPER HOW UAB licensed under the GNU Lesser General Public License v3

SCRIPT_VER=1.K-proxy
SSH_PORT=22
CAT_VER=0.9.3.2
cmake_ver=3.17.0
boost_v=1_72_0
boost_ver=1.72.0
cd
# echo "Be sure to use screen before running. There will be several prompts for sudo password"
# echo "This script is prepared to be executed with user 'root' or any other user"

function print_menu() {
    #clear
    echo
    echo
    echo "+================================================================+"
    echo "| Symbol CATAPULT install and build script by SUPER HOW?         |"
    echo "|    - build and install all Symbol CATAPULT dependancies        |"
    echo "|    - build and install Symbol CATAPULT v${CAT_VER}                |"
    echo "|    - generate Symbol CATAPULT seed                             |"
    echo "|+                                                              +|"
    echo "| Script to be run by limited user, will need sudo rights        |"
    echo "| Prerequisites from github/nemtech for building on Ubuntu 18.04 |"
    echo "|    - OpenSSL dev library, at least 1.1.1 (libssl-dev)          |"
    echo "|    - cmake (at least 3.17)                                     |"
    echo "|    - python 3.x                                                |"
    echo "|    - gcc 9.2                                                   |"
    echo "|    - ninja-build                                               |"
    echo "|                                                                |"
    echo "+================================================================+"
    echo "|    Script version: v${SCRIPT_VER}                                        |"
    echo "|    Crafted with love by: ministras, linas and bruce_wayne      |"
    echo "|    2020 (C) https://SUPERHOW.io                                |"
    echo "+================================================================+"
    os_version_check
    echo "+================================================================+"
    echo "| MENU:                                                          |"
    echo "|                                                                |"
    echo "|  1) Step 1: Build System dependencies: GCC, Cmake, Boost, etc. |"
    echo "|  2) Step 2: Build CAT dependencies: gtest, mongocxx, rocksdb.. |"
    echo "|  3) Step 3: Build Symbol CATAPULT mijin from git               |"
    echo "|  4) Step 4: Build mongodb, NODE.JS and CATAPULT REST           |"
    echo "|  5) Step 5: Generate keys and instialize CATAPULT seed         |"
    echo "|  9) Setup Firewall and change SSH port (TODO)                  |"
    echo "|  0) Tool: Just do system update & upgrade                      |"	
    echo "|                                                                |"
    echo "|  80) Hostname                                                  |" 
    echo "|  91) Reboot                                                    |"
    echo "|  92) Shutdown                                                  |"
    echo "|  100) Print menu                                               |"
    echo "|                                                                |"
    echo "|  q) Quit                                                       |"
    echo "+================================================================+"
	echo
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

function build_base() {
    clear
    echo "+================================================================+"
    echo "| UPDATE system, install base System dependancies? [y/n]         |"
    echo "| GCC-9, Boost v${boost_ver}, Cmake v${cmake_ver}"
    echo "+================================================================+"
    read DOINSTALL
    if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
        # change_ssh_port
        # firewall_setup
        do_system_update
        install_dependancies
        install_cmake
        install_boost
        # echo "Ar viskas gerai?"
        # read ANYKEY
    fi
}

function do_system_update() {
    sudo apt-get update
    sudo apt-get --yes upgrade
    sudo apt-get --yes autoremove
    ulimit -n 4096
    #sudo apt-get -y --fix-missing upgrade  # kai neranda tam tikrų paketų 
    #sudo apt-get -y dist-upgrade 
}

function install_dependancies() {
    sudo apt-get --yes install autoconf automake build-essential curl cmake git gcc g++ gdb mc ninja-build pkg-config python3 python3-ply python-dev
    sudo apt-get --yes install libtool libssl-dev libatomic-ops-dev libunwind-dev libgflags-dev libsnappy-dev libxml2-dev libxslt-dev screen zsh xz-utils
    #TODO patikrinti ar sitie vis dar reikalingi: libatomic-ops-dev libunwind-dev libgflags-dev libsnappy-dev libxml2-dev libxslt-dev
    #Install new version of GCC v9.2: https://linuxize.com/post/how-to-install-gcc-compiler-on-ubuntu-18-04/
    sudo -E apt-get --yes install software-properties-common
    sudo -E add-apt-repository --yes ppa:ubuntu-toolchain-r/test
    sudo -E add-apt-repository --yes ppa:deadsnakes/ppa
    sudo -E apt-get --yes install gcc-9 g++-9 python3.7
    sudo -E apt-get --yes autoremove
    #register priority default GCC versions
    sudo -E update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90 --slave /usr/bin/g++ g++ /usr/bin/g++-9 --slave /usr/bin/gcov gcov /usr/bin/gcov-9
    #to fall back to native GCC: 
    #sudo update-alternatives --config gcc
}

function install_cmake() {
    # CMAKE v3.15.4 or v3.17.0
    echo
    echo "Installing Cmake ${cmake_ver}"
    echo
    sudo apt-get --yes --auto-remove purge cmake
    wget https://github.com/Kitware/CMake/releases/download/v${cmake_ver}/cmake-${cmake_ver}.tar.gz
    tar -xzvf cmake-${cmake_ver}.tar.gz
    rm cmake-${cmake_ver}.tar.gz
    cd cmake-${cmake_ver}/
    ./bootstrap
    make -j $(nproc)
    sudo make install
    echo
    echo "Check CMAKE version:"
    echo
    cd && cmake --version
    python3 --version
    gcc --version
    #rm -rf cmake-${cmake_ver}/
}

function install_boost() {
    # Boost - c++ v1.71.0 or v1.72.0
    echo
    echo "Installing BOOST ${boost_ver}"
    echo
    cd && curl -o boost_${boost_v}.tar.gz -SL https://dl.bintray.com/boostorg/release/${boost_ver}/source/boost_${boost_v}.tar.gz
    tar -xzf boost_${boost_v}.tar.gz
    rm boost_${boost_v}.tar.gz
    mkdir $HOME/boost 
    sudo -E mv $HOME/boost /opt/boost
    cd boost_${boost_v}/
    ./bootstrap.sh --prefix=/opt/boost
    ./b2 --prefix=/opt/boost --without-python -j $(nproc) stage release
    ./b2 --prefix=/opt/boost --without-python install
	#rm -rf boost_${boost_v}/
}

function build_dependancies() {
    clear
    echo
    echo "+================================================================+"
    echo "|       Build Catapult DEPENDANCIES, build TOOLS? [y/n]          |"
    echo "|       gtest, benchmark, mongoc, zmq tools and drivers          |"
    echo "+================================================================+"
    echo
    read DOINSTALL
    if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
        sudo apt-get update
        build_gtest
        build_benchmark
        build_mongoc
        build_mongocxx
        build_zmq
        build_rocksdb
        #echo "Ar viskas gerai?"
        #read ANYKEY
        #build_catapult_server_9_3_2
    fi
}

function build_gtest() {
    # Gtest
    cd && git clone https://github.com/google/googletest.git
    cd googletest/
    git checkout release-1.8.1
    mkdir _build && cd _build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
    make
    sudo make install
}

function build_benchmark() {
    # Google benchmark
    cd && git clone https://github.com/google/benchmark.git
    cd benchmark/
    git checkout v1.5.0
    mkdir _build && cd _build
    cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_GTEST_TESTS=OFF ..
    make
    sudo make install
}

function build_mongoc() {
    # Mongo driver mongo-c
    cd && git clone https://github.com/mongodb/mongo-c-driver.git
    cd mongo-c-driver/
    git checkout 1.15.1
    mkdir _build && cd _build
    cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make
    sudo make install
}

function build_mongocxx() {
    # Mongo driver mongo-c++
    cd && git clone https://github.com/nemtech/mongo-cxx-driver.git
    cd mongo-cxx-driver/
    git checkout r3.4.0-nem
    #TODO: find out why do we need maxAwaitTimeMS patch...
    #sed -i 's/kvp("maxAwaitTimeMS", count)/kvp("maxAwaitTimeMS", static_cast<int64_t>(count))/' src/mongocxx/options/change_stream.cpp
    mkdir _build && cd _build
    #cmake -DCMAKE_CXX_STANDARD=17 -DLIBBSON_DIR=/usr/local -DLIBMONGOC_DIR=/usr/local -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    cmake -DCMAKE_CXX_STANDARD=17 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make
    sudo make install
}

function build_zmq() {
    # ZMQ libzmq
    cd && git clone https://github.com/zeromq/libzmq.git
    cd libzmq/
    git checkout v4.3.2
    mkdir _build && cd _build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make
    sudo make install

    # ZMQ cppzmq
    cd && git clone https://github.com/zeromq/cppzmq.git
    cd cppzmq/
    git checkout v4.4.1
    mkdir _build && cd _build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make
    sudo make install
}

function build_rocksdb() {
    # RocksDB
    cd && git clone https://github.com/nemtech/rocksdb.git
    cd rocksdb/
    git checkout v6.6.4-nem
    mkdir _build
    # && cd _build
    # cmake -DCMAKE_BUILD_TYPE=Release -DWITH_TESTS=OFF . -DCMAKE_INSTALL_PREFIX=/usr/local ..
    # make
    sudo make install-shared
    #echo "All good?"
    #read ANYKEY
}

function build_catapult() {
    clear
    echo
    echo "+================================================================+"
    echo "|   Build catapult server v${CAT_VER} from SUPER HOW git? [y/n]"
    echo "+================================================================+"
    echo
    read DOINSTALL
    if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
        sudo apt-get update
        build_catapult_server
        #build_catapult_superhow_9_3_2
        echo "All good?"
        read ANYKEY
    fi
}

function build_catapult_superhow_9_3_2() {
    # CATAPULT server
    cd && git clone https://bitbucket.org/superhow/catapult-server.git -b release
    cd catapult-server/
    export HASHING_FUNCTION=sha3
    mkdir build && cd build # replacing _build to build. for future scripts
    #mkdir _build && cd _build
    cmake -DBOOST_ROOT=/opt/boost -DCMAKE_BUILD_TYPE=Release -G Ninja ..
    ninja publish
    ninja -j $(nproc)
}

function build_catapult_server() {
    # Build CATAPULT server
    mkdir $HOME/catapult 
    sudo -E mv $HOME/catapult /opt/catapult

    cd && git clone https://github.com/nemtech/catapult-server.git
    cd catapult-server/
    git checkout v${CAT_VER}
    export HASHING_FUNCTION=sha3

    #mkdir build && cd build # replacing _build to build. for future scripts
    mkdir _build && cd _build
    #cmake -DBOOST_ROOT=/opt/boost -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/catapult -G Ninja ..
    cmake -DBOOST_ROOT=/opt/boost -DCMAKE_BUILD_TYPE=Release -DCMAKE_BINARY_DIR=/opt/catapult -G Ninja ..
    # bootstrapinam boost root i /opt/boost, install i /opt/catapult reikia pabandyti
    ninja publish
    ninja -j $(nproc)
}

function install_rest() {
    clear
    echo
    echo "+================================================================+"
    echo "|             Install MONGODB, NODE.JS, CATAPULT REST? [y/n]"
    echo "|             CATAPULT version: ${CAT_VER}"
    echo "+================================================================+"
    echo
    read DOINSTALL
    if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
        install_mongodb
        install_node_js
        echo "All good?"
        read ANYKEY
        install_catapult_rest
    fi
}

function install_mongodb() {
    # Install MongoDB. MANDATORY
    cd
    sudo apt-get update
    sudo apt-get --yes install mongodb
    sudo systemctl start mongodb
    sudo systemctl enable mongodb
    sudo systemctl status mongodb
}

function install_node_js() {
    # Install Node.js v10 & yarn for REST API
    cd
    curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
    local VERSION=node_12.x
    local DISTRO="$(lsb_release -s -c)"
    echo "deb http://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    echo "deb-src http://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update
    sudo apt-get --yes install nodejs
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update
    sudo apt-get --yes install yarn
}

function install_catapult_rest() {
    # Install REST API
    cd && git clone https://github.com/nemtech/catapult-rest.git
    cd catapult-rest/
    export HASHING_FUNCTION=sha3
    ./yarn_setup.sh
    cd rest/
    yarn build
}

function init_seed() {
    clear
    echo
    echo "+================================================================+"
    echo "|  Generate GENESIS keys and initialize CATAPULT seed? [y/n]"
    echo "|  CATAPULT version: ${CAT_VER}"
    echo "+================================================================+"
    echo
    read DOINSTALL
    if [[ $DOINSTALL =~ "y" ]] || [[ $DOINSTALL =~ "Y" ]] ; then
        generate_accounts
        initialize_seed
    fi
}

function generate_accounts() {
    clear
    echo
    echo "+================================================================+"
    echo "|       How many accounts you need? [3-10]"
    echo "+================================================================+"
    echo
    read ACCOUNT_COUNT
    # Generate 3 accounts for "nemesis_signer" , "node owner" and "REST owner"!!!
    # Generate 3 additional accounts for "api owner", peer1 owner" and "peer2 owner"!!!
    cd /opt/catapult
    # mkdir catapult-node
    # catapult-node && mkdir data && mkdir nemesis && mkdir resources && mkdir scripts && mkdir seed
    /opt/catapult/bin/catapult.tools.address -g ${ACCOUNT_COUNT} --network mijin | tee /opt/catapult/nemesis_signer.txt
    cd /opt/catapult
    mkdir nemesis && mkdir data && mkdir tmp
}

function initialize_seed() {
    cd ${HOME}/catapult/scripts
    git clone https://github.com/superhow/cat-config.git
    
    # First private and public keys from the file ~/catapult/nemesis_signer.txt --local (local node) --dual (peer & api in one)
    cd /opt/catapult
    # zsh scripts/cat-config/reset.sh --local dual ~/catapult <private_key> <public_key>
}

# Need to make changes to the configuration files - catapult/recources change the necessary parameters.
# 1.
# config-harvesting.properties
#       harvesterPrivateKey = <FIRST PRIVATE key from the file catapult/harvester_addresses.txt>
# 2.
# config-node.properties
#       enableSingleThreadPool = false
# 3.
# config-user.properties
#       [account]
#       bootPrivateKey = <SECOND PRIVATE key from the file catapult/harvester_addresses.txt>
#       shouldAutoDetectDelegatedHarvesters = true
#       [storage]
#       dataDirectory = ../data
#       pluginsDirectory =
# 4.
#       "publicKey": <FIRST PUBLIC key from the file catapult/harvester_addresses.txt>
# 5.
# peer-p2p.json
#       "publicKey": <SECOND PUBLIC key from the file catapult/harvester_addresses.txt>

# Configure REST API
# 1.
# catapult-rest/rest/resources/rest.json
#       "clientPrivateKey": <THIRD PRIVATE key from the file catapult/harvester_addresses.txt
#       "apiNode": {
#           "host": "127.0.0.1",
#           "port": 7900,
#           "publicKey": <SECOND PUBLIC key from the file catapult/harvester_addresses.txt>,
#           "timeout": 1000
# },

# # === Firewall ===
# function firewall_setup() {
# echo "********** FIREWALL SETUP **************"
# sudo apt-get install -y ufw
# #sudo ufw allow OpenSSH
# sudo ufw default deny
# #sudo ufw allow ssh/tcp
# #sudo ufw limit ssh/tcp
# sudo ufw logging on
# #sudo ufw allow 22
# sudo ufw limit $SSH_PORT/tcp
# #sudo ufw limit OpenSSH
# echo "y" | sudo ufw enable
# #sudo ufw status
# }
#
# function change_ssh_port() {
# echo "Do you want to change SSH port? [y/n]"
# read DOSSHPORT
# if [[ $DOSSHPORT =~ "y" ]] || [[ $DOSSHPORT =~ "Y" ]] ; then
# sudo nano /etc/ssh/sshd_config
# # ---  surasti #port.. ir nuimti # ir pakeisti porta i
# # ---  port 4513
# sudo systemctl restart ssh
# fi
# }

while [[ $DOACTION != "q" ]]
do
    print_menu
    echo "*********************************"
    read DOACTION
    echo "*********************************"

    if [[ $DOACTION == "1" ]] ; then
        build_base
    fi
    if [[ $DOACTION == "2" ]] ; then
        build_dependancies
    fi
    if [[ $DOACTION == "3" ]] ; then
        build_catapult
    fi
    if [[ $DOACTION == "4" ]] ; then
        install_rest
    fi
    if [[ $DOACTION == "5" ]] ; then
        init_seed
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