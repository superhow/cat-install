#!/bin/bash
# Install Symbol catapult dependancies unatended script version v3.0
# Copyright (c) 2020 superhow, ministras, SUPER HOW UAB licensed under the GNU Lesser General Public License v3

if [[ $OSTYPE == "linux"* ]]; then

home_dir=${HOME}
boost_dir=${home_dir}/boost
google_dir=${home_dir}/google
mongo_dir=${home_dir}/mongodb
zmq_dir=${home_dir}/zeromq
rocks_dir=${home_dir}/rocksdb

# exec 2>&1 | tee ${home_dir}/install_base_$(date '+%Y%m%d_%H%M%S').log
# exec > ${home_dir}/install_base_$(date '+%Y%m%d_%H%M%S').log 2>&1

else
    echo
    echo "OS not supported."
    echo
    exit 1
fi

echo
echo
echo "Detected system ${OSTYPE}."
echo "Detected processor count $(nproc)"
echo
echo "Defined install folders:"
echo "boost_dir: ${boost_dir}"
echo "google_dir: ${google_dir}"
echo "mongo_dir: ${mongo_dir}"
echo "zeromq_dir: ${zmq_dir}"
echo "rocksdb_dir: ${rocks_dir}"
echo

function install_boost {
    local boost_v=1_72_0
    local boost_ver=1.72.0
    echo
    echo "Installing BOOST ${boost_ver}"
    echo

    if [[ ! -f "${home_dir}/source/boost_${boost_v}.tar.gz" ]]; then
        curl -o boost_${boost_v}.tar.gz -SL https://dl.bintray.com/boostorg/release/${boost_ver}/source/boost_${boost_v}.tar.gz
        tar -xzf boost_${boost_v}.tar.gz
        cd boost_${boost_v}
    fi
    
    mkdir ${boost_dir}
    ./bootstrap.sh --prefix=${boost_dir}
    
    b2_options=()
    b2_options+=(--prefix=${boost_dir})
    b2_options+=(--without-python)
    
    ./b2 ${b2_options[@]} -j $(nproc) stage release
    ./b2 ${b2_options[@]} install
}

function install_git_standard {

    if [[ $2 == "mongo-cxx-driver" ]]; then
        git clone git://github.com/nemtech/${2}.git
    else
        git clone git://github.com/${1}/${2}.git
    fi

    cd ${2}
    git checkout ${3}
    mkdir _build
    cd _build
    
    cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX="${home_dir}/${1}" ${cmake_options[@]} ..
    make
    sudo make install
}

function install_google_test {
    cmake_options=()
    cmake_options+=(-DCMAKE_POSITION_INDEPENDENT_CODE=ON)
    cmake_options+=(-DCMAKE_BUILD_TYPE=Release)
    install_git_standard google googletest release-1.8.1
}

function install_google_benchmark {
    cmake_options=()
    cmake_options+=(-DBENCHMARK_ENABLE_GTEST_TESTS=OFF)
    cmake_options+=(-DCMAKE_BUILD_TYPE=Release)
    install_git_standard google benchmark v1.5.0
}

function install_mongo_c {
    cmake_options=()
    cmake_options+=(-DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF)
    cmake_options+=(-DCMAKE_BUILD_TYPE=Release)
    install_git_standard mongodb mongo-c-driver 1.15.1
}

function install_mongo_cxx {
    cmake_options=()
    cmake_options+=(-DBOOST_ROOT=${boost_dir})
    cmake_options+=(-DLIBBSON_DIR=${mongo_dir})
    cmake_options+=(-DLIBMONGOC_DIR=${mongo_dir})
    cmake_options+=(-DBSONCXX_POLY_USE_BOOST=1)
    cmake_options+=(-DCMAKE_BUILD_TYPE=Release)
    cmake_options+=(-DCMAKE_CXX_STANDARD=17)
    install_git_standard mongodb mongo-cxx-driver r3.4.0-nem
}

function install_zmq_lib {
    cmake_options=(-DCMAKE_BUILD_TYPE=Release)
    install_git_standard zeromq libzmq v4.3.2
}

function install_zmq_cpp {
    cmake_options=(-DCMAKE_BUILD_TYPE=Release)
    install_git_standard zeromq cppzmq v4.4.1
}

function install_rocksdb {
    # Partly using https://github.com/nemtech/catapult-server/blob/master/BUILDLIN.md with some fixes
	# RocksDB
	git clone https://github.com/nemtech/rocksdb.git
	cd rocksdb
	git checkout v6.6.4-nem

    mkdir ${rocksdb_dir}
    INSTALL_PATH=${rocksdb_dir} sudo make install-shared
    #INSTALL_PATH=${rocksdb_dir} CFLAGS="-Wno-error" sudo make install-shared
	#sudo make install-shared
	#echo "All good?"
	#read ANYKEY
}

function install_catapult {
    # Partly using from https://github.com/IoDLT/cat-install-scripts
    cmake_options=()
    ## BOOST ##
    cmake_options+=(-DBOOST_ROOT=${boost_dir})
    cmake_options+=(-DCMAKE_PREFIX_PATH="${mongo_dir}/lib/cmake/libmongocxx-3.4.0;${home_dir}/mongodb/lib/cmake/libmongoc-1.0;${home_dir}/mongodb/lib/cmake/libbson-1.0;${home_dir}/mongodb/lib/cmake/libbsoncxx-3.4.0")
    ## ROCKSDB ##
	cmake_options+=(-DROCKSDB_LIBRARIES=${rocksdb_dir}/lib/librocksdb.so)
    cmake_options+=(-DROCKSDB_INCLUDE_DIR=${rocksdb_dir}/include)
    ## GTEST & BENCHMARK ##
    cmake_options+=(-Dbenchmark_DIR=${google_dir}/lib/cmake/benchmark)
    cmake_options+=(-DGTEST_ROOT=${google_dir})
    ## ZMQ ##
    cmake_options+=(-Dcppzmq_DIR=${zmq_dir}/share/cmake/cppzmq)
    cmake_options+=(-DZeroMQ_DIR=${zmq_dir}/share/cmake/ZeroMQ)
    ## MONGO ##
    cmake_options+=(-DLIBMONGOCXX_LIBRARY_DIRS=${mongo_dir})
    cmake_options+=(-DMONGOC_LIB=${mongo_dir}/lib/libmongoc-1.0.so)
    cmake_options+=(-DBSONC_LIB=${mongo_dir}/lib/libbsonc-1.0.so)
    ## OTHER ##
    cmake_options+=(-DCMAKE_BUILD_TYPE=Release)
    cmake_options+=(-G)
    cmake_options+=(Ninja)
        
    git clone https://github.com/nemtech/catapult-server.git
    cd catapult-server
    git checkout v0.9.3.2
	mkdir _build
    cd _build
    
    export HASHING_FUNCTION=sha3
    cmake ${cmake_options[@]} ..
    ninja publish
    ninja -j $(nproc)
}

cd ${home_dir}
mkdir source

declare -a install_function=(
    install_boost
    install_google_test
    install_google_benchmark
    install_mongo_c
    install_mongo_cxx
    install_zmq_lib
    install_zmq_cpp
    install_rocksdb
    install_catapult
)
for install in "${install_function[@]}"
do
    pushd source > /dev/null
    ${install}
    popd > /dev/null
done
