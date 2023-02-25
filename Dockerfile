FROM ubuntu:20.04
ARG CMAKE_VERSION=3.18.0
ENV TZ=Europe/Madrid
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    llvm-dev \
    clang \
    ninja-build \
    nodejs \
    npm \
    git \
    cmake \
    python3-pip \
    curl \
    libcurl4-openssl-dev \
    wget


# ----------------------------------------------------------------------------------------------------------------------
# Install cmake
# ----------------------------------------------------------------------------------------------------------------------
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
    tar -xvf cmake-${CMAKE_VERSION}.tar.gz && \
    cd cmake-${CMAKE_VERSION} && \
    ./bootstrap --system-curl && \
    make && \
    make install

# ----------------------------------------------------------------------------------------------------------------------
# Install TVM
# ----------------------------------------------------------------------------------------------------------------------
RUN git clone --recurse-submodules \
    https://github.com/apache/tvm /tvm


WORKDIR /tvm/
RUN git checkout a5a6e7fa && \
    mkdir -p build && \
    cp /tvm/cmake/config.cmake /tvm/build && \
    cd /tvm/build && \
    echo "set(USE_LLVM ON)" >> config.cmake && \
    cmake .. -GNinja && \
    ninja

RUN pip3 install \
    decorator \
    numpy==1.19 \
    psutil \
    typing-extensions \
    scipy \
    attrs \
    mxnet


# Setup emscripten
SHELL ["/bin/bash", "-c"]
RUN git clone https://github.com/emscripten-core/emsdk.git ~/emsdk && \
    cd ~/emsdk && \
    ./emsdk install latest && \
    ./emsdk activate latest && \
    source emsdk_env.sh && \
    echo 'source "/root/emsdk/emsdk_env.sh"' >> $HOME/.bash_profile

WORKDIR /tvm/web/
RUN source "/root/emsdk/emsdk_env.sh" && \
    make && \
    npm install

RUN echo "export TVM_HOME=//tvm/" >> $HOME/.bashrc && \
    echo "export PYTHONPATH=$TVM_HOME/python:${PYTHONPATH}" >> $HOME/.bashrc
