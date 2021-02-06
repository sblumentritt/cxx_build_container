FROM docker.io/amd64/ubuntu:focal as base

LABEL Description="Image is used to compile source code in other operating systems with newer software"
LABEL Maintainer="Sebastian Blumentritt blumentritt.sebastian@gmail.com"
LABEL Version="0.1.0"

# install some core packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    \
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base as extended_base_for_cpp

# needed to prevent the 'tzdata' package to show a prompt which stops the container build
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# define version of manually installed tools
ARG LLVM_INSTALL_VERSION=11
ARG CMAKE_INSTALL_VERSION=3.19.4
ARG CPPCHECK_INSTALL_VERSION=2.3

# NOTE: was unable to get the COPY to work with podman therefore the script is downloaded via wget
RUN wget --no-check-certificate -qO /tmp/tools_handler.sh \
    https://raw.githubusercontent.com/sblumentritt/cxx_build_container/develop/scripts/modern_build_tools_debian_based.sh \
    && chmod +x /tmp/tools_handler.sh && /tmp/tools_handler.sh \
    $LLVM_INSTALL_VERSION \
    $CMAKE_INSTALL_VERSION \
    $CPPCHECK_INSTALL_VERSION \
    && rm -f /tmp/tools_handler.sh

# define default compiler environment variables
ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++

FROM extended_base_for_cpp

# define user/group name
ARG USER_NAME=developer
ARG GROUP_NAME=developer

# add user and group
RUN groupadd $GROUP_NAME && useradd --no-log-init -m -g $GROUP_NAME $USER_NAME

USER $USER_NAME:$GROUP_NAME

# create directory for volume mount
RUN mkdir -p /home/$USER_NAME/src

# add some convenient aliases
RUN echo 'alias ll="ls -al"\nalias ..="cd .."' >> /home/$USER_NAME/.bashrc

ENV HOME=/home/$USER_NAME
WORKDIR /home/$USER_NAME/src
