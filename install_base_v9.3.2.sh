#!/bin/bash
# Install apt dependancies unatended script version v3.0
# Copyright (c) 2020 superhow, ministras, SUPER HOW UAB licensed under the GNU Lesser General Public License v3

script_ver=3.0
cat_ver=0.9.3.2
home_dir=${HOME}
# exec 2>&1 | tee ${home_dir}/install_base_$(date '+%Y%m%d_%H%M%S').log
# exec > ${home_dir}/install_base_$(date '+%Y%m%d_%H%M%S').log 2>&1

cd

function apt_upgrade {
    echo
    echo "Upgrade apt dependencies:"
    echo
    sudo apt-get update
    sudo apt-get --yes upgrade
    sudo apt-get --yes autoremove
}

function apt_install {
    echo
    echo "Install apt dependencies:"
    echo ${apt_deps[@]}
    echo
    sudo apt-get --yes install ${apt_deps[@]}
}

function install_apt_deps {
    #Install apt dependancies from https://github.com/nemtech/catapult-server/blob/master/BUILDLIN.md

    apt_deps=(autoconf automake build-essential curl git gdb mc ninja-build
        libtool libssl-dev libatomic-ops-dev libunwind-dev libgflags-dev 
        libsnappy-dev libxml2-dev libxslt-dev pkg-config python3 python3-ply 
        python-dev screen software-properties-common zsh xz-utils)

    apt_install
}

function install_gcc {
    #Install new version of GCC v9.2: https://linuxize.com/post/how-to-install-gcc-compiler-on-ubuntu-18-04/

    gcc_version=9
    echo
    echo "Install GCC ${gcc_version}"
    echo

    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get --yes install gcc-${gcc_version} g++-${gcc_version} python3.7
    sudo apt-get --yes autoremove

    #register priority default GCC versions
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 90 --slave /usr/bin/g++ g++ /usr/bin/g++-9 --slave /usr/bin/gcov gcov /usr/bin/gcov-9
    #to fall back to native GCC: 
    #sudo update-alternatives --config gcc
}

function install_cmake {
    #Install new CMAKE version v3.15.4

    local version=3.17.0
    echo "Installing CMAKE ${cmake_version}"
    echo
    sudo apt-get --yes --auto-remove purge cmake

    wget https://github.com/Kitware/CMake/releases/download/v$version/cmake-$version.tar.gz
    tar -xzvf cmake-$version.tar.gz
    rm cmake-$version.tar.gz
    cd cmake-$version/
    ./bootstrap
    make -j$(nproc)
    sudo make install

    echo "Check CMAKE version:"
    cd && cmake --version
    python3 --version
    gcc --version
    rm -rf cmake-$version/
}

#main start

apt_upgrade

declare -a install_function=(
    install_apt_deps
    install_gcc
    install_cmake
)

for install in "${install_function[@]}"
do
    pushd ${home_dir} > /dev/null
    ${install}
    popd > /dev/null
done
