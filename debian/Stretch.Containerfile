FROM docker.io/amd64/debian:stretch-slim as base

LABEL Description="Image is used to compile source code in other operating systems with newer sofware"
LABEL Maintainer="Sebastian Blumentritt blumentritt.sebastian@gmail.com"
LABEL Version="0.1.0"

# install some core packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base as extended_base_for_cpp

# define version of manually installed tools
ARG LLVM_INSTALL_VERSION=11
ARG CMAKE_BASE_VERSION=3.19
ARG CMAKE_INSTALL_VERSION=$CMAKE_BASE_VERSION.4
ARG CPPCHECK_INSTALL_VERSION=2.3

# install dependencies for the tools which will be installed manually
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg2 \
    libpcre3 \
    libpcre3-dev \
    \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# get newer version of LLVM
RUN wget -qO /tmp/llvm.sh https://apt.llvm.org/llvm.sh \
    && chmod +x /tmp/llvm.sh && /tmp/llvm.sh $LLVM_INSTALL_VERSION \
    && apt-get install -y --no-install-recommends \
    clang-tools-$LLVM_INSTALL_VERSION \
    clang-tidy-$LLVM_INSTALL_VERSION \
    clang-format-$LLVM_INSTALL_VERSION \
    libclang-common-$LLVM_INSTALL_VERSION-dev \
    libclang-$LLVM_INSTALL_VERSION-dev \
    && rm -rf /var/lib/apt/lists/* && rm -f /tmp/llvm.sh

# define default compiler environement variables
ENV CC=/usr/bin/clang-11
ENV CXX=/usr/bin/clang++-11

# install newer version of CMake
RUN wget -qO - \
    "https://cmake.org/files/v$CMAKE_BASE_VERSION/cmake-$CMAKE_INSTALL_VERSION-Linux-x86_64.tar.gz" | \
    tar --strip-components=1 -xz -C /usr/local

# install newer version of Cppcheck
RUN wget -qO - \
    "https://github.com/danmar/cppcheck/archive/$CPPCHECK_INSTALL_VERSION.tar.gz" | \
    tar -xz -C /tmp && cd /tmp/cppcheck-$CPPCHECK_INSTALL_VERSION \
    && cmake -S . -B ./build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_C_COMPILER=clang-$LLVM_INSTALL_VERSION \
        -DCMAKE_CXX_COMPILER=clang++-$LLVM_INSTALL_VERSION \
        -DUSE_CLANG=ON \
        -DHAVE_RULES=ON \
    && cmake --build ./build -j \
    && CFGDIR=/usr/share/Cppcheck HAVE_RULES=yes cmake --build ./build --target install \
    && cd / && rm -rf /tmp/cppcheck*

FROM extended_base_for_cpp

# define user/group name
ARG USER_NAME=developer
ARG GROUP_NAME=developer

# add user and group
RUN groupadd $GROUP_NAME && useradd --no-log-init -m -g $GROUP_NAME $USER_NAME

USER $USER_NAME:$GROUP_NAME

# create directory for volume mount
RUN mkdir -p /home/$USER_NAME/src

# add some convinient aliases
RUN echo 'alias ll="ls -al"\nalias ..="cd .."' >> /home/$USER_NAME/.bashrc

ENV HOME=/home/$USER_NAME
WORKDIR /home/$USER_NAME/src
