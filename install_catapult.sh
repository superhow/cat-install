#!/bin/bash
# Install and build Symbol catapult server and dependancies interactive script version v1.0
# Copyright (c) 2020 superhow, ministras, SUPER HOW UAB licensed under the GNU Lesser General Public License v3

set -e
SCRIPT_VER=1.N
SSH_PORT=22
CAT_VER=0.9.5.1
cmake_ver=3.17.0
boost_v=1_72_0
boost_ver=1.72.0
openssl_ver=1.1.1g
cd
[ -d $HOME/src ] && echo "Directory src Exists" || mkdir $HOME/src
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
        set -x
	do_system_update
        install_dependancies
        install_cmake
        install_boost
	set +x
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
    sudo apt-get --yes install autoconf automake build-essential checkinstall curl cmake git gcc g++ gdb mc ninja-build pkg-config python3 python3-ply python-dev
    sudo apt-get --yes install libtool libssl-dev libatomic-ops-dev libunwind-dev libgflags-dev libsnappy-dev libxml2-dev libxslt-dev screen zlib1g-dev zsh xz-utils
    #TODO patikrinti ar sitie vis dar reikalingi: libatomic-ops-dev libunwind-dev libgflags-dev libsnappy-dev libxml2-dev libxslt-dev
    #Install new version of GCC v9.2: https://linuxize.com/post/how-to-install-gcc-compiler-on-ubuntu-18-04/
    sudo -E apt-get --yes install software-properties-common
    sudo -E add-apt-repository --yes ppa:ubuntu-toolchain-r/test
    sudo -E add-apt-repository --yes ppa:deadsnakes/ppa
    sudo -E apt-get --yes install gcc-9 g++-9 python3.7
    sudo -E apt-get --yes autoremove
    
    #register priority default GCC versions
    sudo -E update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90
    sudo -E update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 90
}

function install_cmake() {
    # v3.17.0
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
    rm -rf /opt/boost/
    mkdir $HOME/boost 
    sudo -E mv $HOME/boost /opt/boost
    cd boost_${boost_v}/
    ./bootstrap.sh --prefix=/opt/boost
    ./b2 --prefix=/opt/boost --without-python -j $(nproc) stage release
    ./b2 --prefix=/opt/boost --without-python install
    #rm -rf boost_${boost_v}/
}

function install_openssl() {
    # OpenSSL v1.1.1g
    echo
    echo "Installing OpenSSL ${openssl_ver}"
    echo
    openssl version -a
    cd $HOME/src/
    wget https://www.openssl.org/source/openssl-${openssl_ver}.tar.gz
    tar -xf openssl-${openssl_ver}.tar.gz
    rm openssl-${openssl_ver}.tar.gz
    cd openssl-${openssl_ver}
    ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib
    make
    make test
    sudo make install
    
    #Configure OpenSSl shared libraries
    cd /etc/ld.so.conf.d/
    sudo nano openssl-1.1.1c.conf
    # enter /usr/local/ssl/lib
    # exit and save
    sudo ldconfig -v
    
    
    

    
    
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
        set -x
	sudo apt-get update
	build_gtest
        build_benchmark
        build_mongoc
        build_mongocxx
        build_zmq
        build_rocksdb
	set +x
    fi
}

function build_gtest() {
    # Gtest
    cd $HOME/src/ && git clone https://github.com/google/googletest.git
    cd googletest/
    git checkout release-1.8.1
    mkdir _build && cd _build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
    make
    sudo make install
}

function build_benchmark() {
    # Google benchmark
    cd $HOME/src/ && git clone https://github.com/google/benchmark.git
    cd benchmark/
    git checkout v1.5.0
    mkdir _build && cd _build
    cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_GTEST_TESTS=OFF ..
    make
    sudo make install
}

function build_mongoc() {
    # Mongo driver mongo-c
    cd $HOME/src/ && git clone https://github.com/mongodb/mongo-c-driver.git
    cd mongo-c-driver/
    git checkout 1.15.1
    mkdir _build && cd _build
    cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make
    sudo make install
}

function build_mongocxx() {
    # Mongo driver mongo-c++
    cd $HOME/src/ && git clone https://github.com/nemtech/mongo-cxx-driver.git
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
    cd $HOME/src/ && git clone https://github.com/zeromq/libzmq.git
    cd libzmq/
    git checkout v4.3.2
    mkdir _build && cd _build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make
    sudo make install

    # ZMQ cppzmq
    cd $HOME/source/ && git clone https://github.com/zeromq/cppzmq.git
    cd cppzmq/
    git checkout v4.4.1
    mkdir _build && cd _build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make
    sudo make install
}

function build_rocksdb() {
    # RocksDB
    cd $HOME/src/ && git clone https://github.com/nemtech/rocksdb.git
    cd rocksdb/
    git checkout v6.6.4-nem
    mkdir _build
    # && cd _build
    # cmake -DCMAKE_BUILD_TYPE=Release -DWITH_TESTS=OFF . -DCMAKE_INSTALL_PREFIX=/usr/local ..
    # make
    sudo make install-shared
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
        set -x
	sudo apt-get update
        build_catapult_server
	set +x
    fi
}

function build_catapult_server() {
    # Build CATAPULT server
    [ -d /opt/catapult ] && echo "Directory Exists" || mkdir $HOME/catapult
    [ -d /opt/catapult ] && echo "Directory Exists" || sudo -E mv $HOME/catapult /opt/catapult

    cd $HOME/src/ && git clone https://github.com/nemtech/catapult-server.git
    cd catapult-server/
    #git checkout v${CAT_VER}

    #mkdir build && cd build # replacing _build to build. for future scripts
    mkdir _build && cd _build
    #cmake -DBOOST_ROOT=/opt/boost -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/catapult -G Ninja ..
    #-DCMAKE_BINARY_DIR=/opt/catapult
    cmake -DBOOST_ROOT=/opt/boost -DCMAKE_BUILD_TYPE=Release -G Ninja ..
    # bootstrapinam boost root i /opt/boost, install i /opt/catapult reikia pabandyti
    ninja publish
    ninja -j $(nproc)
    mv $HOME/src/catapult-server/_build/bin /opt/catapult/bin
    mv $HOME/src/catapult-server/_build/lib /opt/catapult/lib
    mv $HOME/src/catapult-server/_build/inc /opt/catapult/inc
    cp $HOME/src/catapult-server/scripts $HOME/catapult/scripts
    cp $HOME/src/catapult-server/scripts /opt/catapult/scripts
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
        set -x
	install_mongodb
        install_node_js
        install_catapult_rest
	set +x
    fi
}

function install_mongodb() {
    # Install MongoDB. MANDATORY only API
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
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
    sudo apt-get --yes install nodejs
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo -E apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update
    sudo apt-get --yes install yarn
}

function install_catapult_rest() {
    # Install REST API
    cd && git clone https://github.com/nemtech/catapult-rest.git
    cd catapult-rest/
    #git checkout v0.7.24
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
        set -x
	generate_accounts
        initialize_seed
	set +x
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
    cd $HOME/catapult/
    # catapult-node && mkdir data && mkdir nemesis && mkdir resources && mkdir scripts && mkdir seed
    /opt/catapult/bin/catapult.tools.address -g ${ACCOUNT_COUNT} --network mijin | tee $HOME/catapult/nemesis_signer.txt
}

function initialize_seed() {
    cd $HOME/catapult/scripts
    git clone https://github.com/superhow/cat-config.git
    
    # First private and public keys from the file ~/catapult/nemesis_signer.txt --local (local node) --dual (peer & api in one)
    cd $HOME/catapult/
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

#********** PROXY SETTINGS ***************
########## NPM configuration ##########
#
#npm config set proxy http://username:password@host:port
#npm config set https-proxy http://username:password@host:port
#
#Or you can edit directly your ~/.npmrc file:
#proxy=http://username:password@host:port
#https-proxy=http://username:password@host:port
#https_proxy=http://username:password@host:port

########## Yarn configuration ##########
#
#yarn config set proxy http://username:password@host:port
#yarn config set https-proxy http://username:password@host:port

########## Git configuration ##########
#
#git config --global http.proxy http://username:password@host:port
#git config --global https.proxy http://username:password@host:port
#
# Or you can edit directly your ~/.gitconfig file:
#[http]
#        proxy = http://username:password@host:port
#[https]
#        proxy = http://username:password@host:port

########## Maven configuration ##########
#
# Edit the proxies session in your ~/.m2/settings.xml file:
#
#<proxies>
#    <proxy>
#        <id>id</id>
#        <active>true</active>
#        <protocol>http</protocol>
#        <username>username</username>
#        <password>password</password>
#        <host>host</host>
#        <port>port</port>
#        <nonProxyHosts>local.net|some.host.com</nonProxyHosts>
#    </proxy>
#</proxies>

########## Maven Wrapper ##########
#
#Create a new file .mvn/jvm.config inside the project folder and set the properties accordingly:
#
#-Dhttp.proxyHost=host 
#-Dhttp.proxyPort=port 
#-Dhttps.proxyHost=host 
#-Dhttps.proxyPort=port 
#-Dhttp.proxyUser=username 
#-Dhttp.proxyPassword=password

########## Gradle configuration ##########
#
#Add the below in your gradle.properties file and in your gradle/wrapper/gradle-wrapper.properties file if you are downloading the wrapper over a proxy
#
#If you want to set these properties globally then add it in USER_HOME/.gradle/gradle.properties file
#
## Proxy setup
#systemProp.proxySet="true"
#systemProp.http.keepAlive="true"
#systemProp.http.proxyHost=host
#systemProp.http.proxyPort=port
#systemProp.http.proxyUser=username
#systemProp.http.proxyPassword=password
#systemProp.http.nonProxyHosts=local.net|some.host.com
#
#systemProp.https.keepAlive="true"
#systemProp.https.proxyHost=host
#systemProp.https.proxyPort=port
#systemProp.https.proxyUser=username
#systemProp.https.proxyPassword=password
#systemProp.https.nonProxyHosts=local.net|some.host.com
## end of proxy setup

########## Docker ##########
#
#Depending on your OS, you have to edit a specific file (/etc/sysconfig/docker or /etc/default/docker).
#Then, you have to restart the docker service with: sudo service docker restart.
#
#It will not apply to systemd. https://docs.docker.com/config/daemon/systemd/.
#Docker with docker-machine
#
#You can create your docker-machine with:
#docker-machine create -d virtualbox \
#    --engine-env HTTP_PROXY=http://username:password@host:port \
#    --engine-env HTTPS_PROXY=http://username:password@host:port \
#    default
#
#Or you can edit the file ~/.docker/machine/machines/default/config.json.
#

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
