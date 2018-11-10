FROM nvidia/cuda:9.0-base

RUN apt-get update

# Cloud9
RUN apt-get install -y tmux git && \
    git clone https://github.com/c9/core.git /usr/src/c9sdk && \
    cd /usr/src/c9sdk && \
    scripts/install-sdk.sh

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
    
ENV PATH=$PATH:/usr/src/caffe/build/tools/

CMD /root/digits/digits-devserver
