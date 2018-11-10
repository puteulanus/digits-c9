FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04

RUN apt-get update

# Protobuf3
RUN apt-get install -y autoconf automake libtool curl make g++ git python-dev python-setuptools unzip && \
    git clone https://github.com/google/protobuf.git /usr/src/protobuf -b '3.2.x' && \
    cd /usr/src/protobuf && \
    ./autogen.sh && \
    ./configure && \
    make "-j$(nproc)" && \
    make install && \
    ldconfig && \
    cd python && \
    python setup.py install --cpp_implementation
    
# NVcaffe
RUN apt-get install -y --no-install-recommends build-essential cmake git gfortran libatlas-base-dev \
      libboost-filesystem-dev libboost-python-dev libboost-system-dev libboost-thread-dev libgflags-dev \
      libgoogle-glog-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libopencv-dev libsnappy-dev \
    python-all-dev python-dev python-h5py python-matplotlib python-numpy python-opencv python-pil \
    python-pip python-pydot python-scipy python-skimage python-sklearn && \
    git clone https://github.com/NVIDIA/caffe.git /usr/src/caffe -b 'caffe-0.15' && \
    pip install wheel && \
    pip install -r /usr/src/caffe/python/requirements.txt && \
    cd /usr/src/caffe && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j"$(nproc)" && \
    make install

# Digits
RUN apt-get install -y --no-install-recommends git graphviz python-dev python-flask python-flaskext.wtf \
      python-gevent python-h5py python-numpy python-pil python-pip python-scipy python-tk && \
    git clone https://github.com/NVIDIA/DIGITS.git /root/digits && \
    pip install -r /root/digits/requirements.txt

# TensorFlow
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py --force-reinstall && \
    rm -f get-pip.py && \
    pip install tensorflow-gpu==1.2.1

# Cloud9
RUN apt-get install -y tmux && \
    git clone https://github.com/c9/core.git /usr/src/c9sdk && \
    cd /usr/src/c9sdk && \
    scripts/install-sdk.sh
    
ENV CAFFE_ROOT=/usr/src/caffe/

ENV C9_USERNAME ""
ENV C9_PASSWORD ""
ENV C9_PORT 8080
ENV WORKSPACE_DIR /root/digits/

WORKDIR /root/digits/

EXPOSE 8080
EXPOSE 5000

CMD bash -c 'echo -e "./digits-devserver | tee /var/log/digits.log & \\n/root/.c9/node/bin/node /usr/src/c9sdk/server.js" \
    "-p $C9_PORT -w $WORKSPACE_DIR -a $USERNAME:$PASSWORD -l 0.0.0.0 --packed >/dev/null 2>&1" | bash'
