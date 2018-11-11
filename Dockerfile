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
    
# Jupyter
RUN pip install jupyter jupyterlab

# Ngrok
RUN curl -O https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.deb && \
    dpkg -i ngrok-stable-linux-amd64.deb && \
    rm -f ngrok-stable-linux-amd64.deb

# Entrypoint
RUN echo '#!/bin/bash' > /root/run && \
    echo 'cd /root/digits/' >> /root/run && \
    echo './digits-devserver | tee /var/log/digits.log &' >> /root/run && \
    echo 'cd /notebooks' >> /root/run && \
    echo 'jupyter lab --ip=0.0.0.0 --allow-root' >> /root/run && \
    chmod +x /root/run
    
ENV CAFFE_ROOT=/usr/src/caffe/
ENV WORKSPACE_DIR /root/digits/

WORKDIR /root/digits/

EXPOSE 5000

CMD /root/run
