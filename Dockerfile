FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu16.04

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y libsystemd-dev patch

# Protobuf3
RUN apt-get install -y --no-install-recommends autoconf automake libtool curl make g++ git \
        python-dev python-setuptools unzip
    
# MKL
RUN curl -O https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    rm -f GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends intel-mkl-2019.1-053
    
# NVcaffe
RUN apt-get install -y --no-install-recommends build-essential cmake git gfortran libgflags-dev \
      libboost-filesystem-dev libboost-python-dev libboost-system-dev libboost-thread-dev libboost-regex-dev \
      libgoogle-glog-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libopencv-dev libsnappy-dev \
      python-all-dev python-dev python-h5py python-matplotlib python-numpy python-opencv python-pil \
      python-pip python-pydot python-scipy python-skimage python-sklearn libturbojpeg \
      doxygen libnccl2 libnccl-dev 

# DIGITS
RUN apt-get install -y --no-install-recommends git graphviz python-dev python-flask python-flaskext.wtf \
      python-gevent python-h5py python-numpy python-pil python-pip python-scipy python-tk 

# Torch
RUN apt-get install -y --no-install-recommends git sudo software-properties-common libhdf5-serial-dev liblmdb-dev 
