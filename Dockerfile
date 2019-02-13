FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y libsystemd-dev patch wget unzip 
    
# MKL
RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    rm -f GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends intel-mkl-2019.1-053 && \
    ln -s '/opt/intel/compilers_and_libraries_2019.1.144/linux/compiler/lib/intel64_lin/libiomp5.so' /lib/libiomp5.so
    
ENV MKL_ROOT=/opt/intel/mkl
ENV MKL_INCLUDE=$MKL_ROOT/include
ENV MKL_LIBRARY=$MKL_ROOT/lib/intel64

# Caffe
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev \
        libhdf5-serial-dev protobuf-compiler
RUN apt-get install -y --no-install-recommends libboost-all-dev
RUN apt-get install -y libz-dev libjpeg-dev libprotobuf-c1 libprotobuf-dev \
        libgflags-dev libgoogle-glog-dev liblmdb-dev git
RUN wget -O cmake.sh https://github.com/Kitware/CMake/releases/download/v3.14.0-rc1/cmake-3.14.0-rc1-Linux-x86_64.sh && \
        bash cmake.sh --skip-license && \
        rm -rf cmake.sh
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py --force-reinstall && \
    rm -f get-pip.py
RUN git clone https://github.com/BVLC/caffe /usr/src/caffe && \
        pip install -r /usr/src/caffe/python/requirements.txt
RUN cd /usr/src/caffe && \
        mkdir build && \
        cd build && \
        sed -i 's/20 21(20) 30 35 50 60 61/30 35 50 52 60 61 62 70 72 75/' ../cmake/Cuda.cmake && \
        cmake .. -DBLAS=mkl && \
        find ./ -name Makefile.config && \
        make -j"$(nproc)" && \
        make install

# DIGITS
RUN apt-get install -y --no-install-recommends git graphviz python-dev python-flask python-flaskext.wtf \
      python-gevent python-h5py python-numpy python-pil python-pip python-scipy python-tk && \
    git clone https://github.com/NVIDIA/DIGITS.git /root/digits && \
    pip install -r /root/digits/requirements.txt

# TensorFlow
RUN pip install tensorflow-gpu
    
# Jupyter
RUN pip install jupyterlab

# Ngrok
RUN wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.deb && \
    dpkg -i ngrok-stable-linux-amd64.deb && \
rm -f ngrok-stable-linux-amd64.deb
    
# Oh My Zsh
RUN apt-get install -y --no-install-recommends zsh && \
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | zsh || true

# Entrypoint
RUN echo '#!/bin/bash' > /root/run && \
    echo 'cd /root/digits/' >> /root/run && \
    echo '. /usr/src/torch/install/bin/torch-activate' >> /root/run && \
    echo './digits-devserver 2>&1 | tee /var/log/digits.log &' >> /root/run && \
    echo 'mkdir -p /notebooks' >> /root/run && \
    echo 'cd /notebooks' >> /root/run && \
    echo 'jupyter lab --ip=0.0.0.0 --allow-root --no-browser' >> /root/run && \
    chmod +x /root/run
    
ENV CAFFE_ROOT=/usr/src/caffe
ENV WORKSPACE_DIR /root/digits
ENV SHELL=/usr/bin/zsh

WORKDIR /root/digits

EXPOSE 5000

CMD /root/run
