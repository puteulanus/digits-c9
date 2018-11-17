FROM quay.io/puteulanus/digits-notebook:env

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y libsystemd-dev patch

# Protobuf3
RUN apt-get install -y --no-install-recommends autoconf automake libtool curl make g++ git \
        python-dev python-setuptools unzip && \
    git clone https://github.com/google/protobuf.git /usr/src/protobuf -b '3.2.x' && \
    cd /usr/src/protobuf && \
    ./autogen.sh && \
    ./configure && \
    make "-j$(nproc)" && \
    make install && \
    ldconfig && \
    cd python && \
    python setup.py install --cpp_implementation && \
    rm -rf /usr/src/protobuf
    
# MKL
RUN curl -O https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    rm -f GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends intel-mkl-2019.1-053 && \
    ln -s '/opt/intel/compilers_and_libraries_2019.1.144/linux/compiler/lib/intel64_lin/libiomp5.so' /lib/libiomp5.so
    
ENV MKL_ROOT=/opt/intel/mkl
ENV MKL_INCLUDE=$MKL_ROOT/include
ENV MKL_LIBRARY=$MKL_ROOT/lib/intel64
    
# NVcaffe
RUN apt-get install -y --no-install-recommends build-essential cmake git gfortran libgflags-dev \
      libboost-filesystem-dev libboost-python-dev libboost-system-dev libboost-thread-dev libboost-regex-dev \
      libgoogle-glog-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libopencv-dev libsnappy-dev \
      python-all-dev python-dev python-h5py python-matplotlib python-numpy python-opencv python-pil \
      python-pip python-pydot python-scipy python-skimage python-sklearn libturbojpeg \
      doxygen libnccl2 libnccl-dev && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py --force-reinstall && \
    rm -f get-pip.py && \
    ln -s /usr/lib/x86_64-linux-gnu/libturbojpeg.so.0.1.0 /usr/lib/x86_64-linux-gnu/libturbojpeg.so && \
    git clone https://github.com/NVIDIA/caffe.git /usr/src/caffe -b 'v0.17.2' && \
    pip install -r /usr/src/caffe/python/requirements.txt && \
    cd /usr/src/caffe && \
    mkdir build && \
    cd build && \
    cmake .. -DBLAS=mkl && \
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
    
# MAGMA
RUN cd /usr/src && \
    curl -O http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.4.0.tar.gz && \
    tar zxf magma-2.4.0.tar.gz && \
    rm -f magma-2.4.0.tar.gz && \
    cd magma-2.4.0 && \
    cp make.inc-examples/make.inc.mkl-gcc ./make.inc && \
    echo 'GPU_TARGET := sm_30 sm_35 sm_50 sm_52 sm_60 sm_61 sm_70' >> make.inc && \
    export MKLROOT=/opt/intel/mkl && \
    export CUDADIR=/usr/local/cuda && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf /usr/src/magma-2.4.0

# Torch
RUN apt-get install -y --no-install-recommends git sudo software-properties-common libhdf5-serial-dev liblmdb-dev && \
    git clone https://github.com/torch/distro.git /usr/src/torch --recursive && \
    cd /usr/src/torch && \
    rm -rf cmake/3.6/Modules/FindCUDA* && \
    cd extra/cutorch && \
    echo -e 'diff --git a/lib/THC/THCAtomics.cuh b/lib/THC/THCAtomics.cuh'"\n"\
        'index 400875c..ccb7a1c 100644'"\n"\
        '--- a/lib/THC/THCAtomics.cuh'"\n"\
        '+++ b/lib/THC/THCAtomics.cuh'"\n"\
        '@@ -94,6 +94,7 @@ static inline __device__ void atomicAdd(long *address, long val) {'"\n"\
        ' }'"\n"\
        ' '"\n"\
        ' #ifdef CUDA_HALF_TENSOR'"\n"\
        '+#if !(__CUDA_ARCH__ >= 700 || !defined(__CUDA_ARCH__) )'"\n"\
        ' static inline  __device__ void atomicAdd(half *address, half val) {'"\n"\
        '   unsigned int * address_as_ui ='"\n"\
        '       (unsigned int *) ((char *)address - ((size_t)address & 2));'"\n"\
        '@@ -117,6 +118,7 @@ static inline  __device__ void atomicAdd(half *address, half val) {'"\n"\
        '    } while (assumed != old);'"\n"\
        ' }'"\n"\
        ' #endif'"\n"\
        '+#endif' | patch -p1 && \
    export TORCH_NVCC_FLAGS="-D__CUDA_NO_HALF_OPERATORS__" && \
    cd ../../ && \
    . /opt/intel/mkl/bin/mklvars.sh intel64 && \
    . /opt/intel/bin/compilervars.sh intel64 && \
    export CMAKE_INCLUDE_PATH=$MKL_INCLUDE:$CMAKE_INCLUDE_PATH && \
    export CMAKE_LIBRARY_PATH=$MKL_LIBRARY:$CMAKE_LIBRARY_PATH && \
    ./install-deps && \
    ./install.sh -b && \
    . /usr/src/torch/install/bin/torch-activate && \
    luarocks install tds && \
    luarocks install "https://raw.github.com/deepmind/torch-hdf5/master/hdf5-0-0.rockspec" && \
    luarocks install "https://raw.github.com/Neopallium/lua-pb/master/lua-pb-scm-0.rockspec" && \
    luarocks install lightningmdb 0.9.18.1-1 LMDB_INCDIR=/usr/include LMDB_LIBDIR=/usr/lib/x86_64-linux-gnu && \
    luarocks install "https://raw.githubusercontent.com/ngimel/nccl.torch/master/nccl-scm-1.rockspec"

# Ngrok
RUN curl -O https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.deb && \
    dpkg -i ngrok-stable-linux-amd64.deb && \
    rm -f ngrok-stable-linux-amd64.deb
    
# Oh My Zsh
RUN apt-get install -y --no-install-recommends zsh && \
    curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | zsh || true

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
ENV TORCH_ROOT=/usr/src/torch
ENV WORKSPACE_DIR /root/digits
ENV SHELL=/usr/bin/zsh

WORKDIR /root/digits

EXPOSE 5000

CMD /root/run
