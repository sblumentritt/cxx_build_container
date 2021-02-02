#!/bin/sh

# This script installs the specified version of LLVM, CMake and Cppcheck for Debian and Ubuntu
# container

# Commandline parameter meaning:
# First position -> LLVM version (Major)
# Second position -> CMake version (Major.Minor.Patch)
# Third position -> Cppcheck version (Major.Minor)

LLVM_INSTALL_VERSION=11
if [ "$#" -gt 0 ]; then
    LLVM_INSTALL_VERSION=$1
fi

CMAKE_INSTALL_VERSION=3.19.4
if [ "$#" -gt 1 ]; then
    CMAKE_INSTALL_VERSION=$2
fi
CMAKE_BASE_VERSION=$(printf "%s" "$CMAKE_INSTALL_VERSION" | rev | cut -f 2- -d '.' | rev)

CPPCHECK_INSTALL_VERSION=2.3
if [ "$#" -gt 2 ]; then
    CPPCHECK_INSTALL_VERSION=$3
fi

echo "$LLVM_INSTALL_VERSION"
echo "$CMAKE_INSTALL_VERSION"
echo "$CMAKE_BASE_VERSION"
echo "$CPPCHECK_INSTALL_VERSION"

# install dependencies for the tools which will be installed manually
apt-get update
apt-get install -y --no-install-recommends \
    wget \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg2 \
    libpcre3 \
    libpcre3-dev \
    cmake

# get newer version of LLVM
wget -qO /tmp/llvm.sh https://apt.llvm.org/llvm.sh
chmod +x /tmp/llvm.sh

/tmp/llvm.sh $LLVM_INSTALL_VERSION

# install packages which are not default installed with the llvm script
apt-get install -y --no-install-recommends \
    clang-tools-$LLVM_INSTALL_VERSION \
    clang-tidy-$LLVM_INSTALL_VERSION \
    clang-format-$LLVM_INSTALL_VERSION \
    libclang-common-$LLVM_INSTALL_VERSION-dev \
    libclang-$LLVM_INSTALL_VERSION-dev

# create symlinks for all LLVM tools to allow generic scripts to use them
find /usr/bin -type f -name "*-$LLVM_INSTALL_VERSION" | while read source; do
    destination=$(printf "$source" | sed -E "s/-$LLVM_INSTALL_VERSION$//")

    if [ ! -e $destination ]; then
        ln -sf "$source" "$destination"
    fi
done

rm -f /tmp/llvm.sh

# install newer version of CMake
wget -qO - \
    "https://cmake.org/files/v$CMAKE_BASE_VERSION/cmake-$CMAKE_INSTALL_VERSION-Linux-x86_64.tar.gz" | \
    tar --strip-components=1 -xz -C /usr/local

# install newer version of Cppcheck
wget -qO - \
    "https://github.com/danmar/cppcheck/archive/$CPPCHECK_INSTALL_VERSION.tar.gz" | \
    tar -xz -C /tmp

cd /tmp/cppcheck-$CPPCHECK_INSTALL_VERSION

cmake -S . -B ./build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_COMPILER=clang-$LLVM_INSTALL_VERSION \
        -DCMAKE_CXX_COMPILER=clang++-$LLVM_INSTALL_VERSION \
        -DUSE_CLANG=ON \
        -DHAVE_RULES=ON

cmake --build ./build -j
CFGDIR=/usr/share/Cppcheck HAVE_RULES=yes cmake --build ./build --target install

cd -
rm -rf /tmp/cppcheck*

# clean up container
apt-get autoremove
apt-get clean
rm -rf /var/lib/apt/lists/*
