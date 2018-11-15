FROM nvcr.io/nvidia/digits:18.10
    
# Jupyter
RUN pip install jupyterlab

# Ngrok
RUN curl -O https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.deb && \
    dpkg -i ngrok-stable-linux-amd64.deb && \
    rm -f ngrok-stable-linux-amd64.deb
    
# Oh My Zsh
RUN apt-get install -y --no-install-recommends zsh && \
    curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | zsh || true

# Entrypoint
RUN echo '#!/bin/bash' > /root/run && \
    #echo 'cd /root/digits/' >> /root/run && \
    #echo './digits-devserver 2>&1 | tee /var/log/digits.log &' >> /root/run && \
    echo 'mkdir -p /notebooks' >> /root/run && \
    echo 'cd /notebooks' >> /root/run && \
    echo 'jupyter lab --ip=0.0.0.0 --allow-root --no-browser' >> /root/run && \
    chmod +x /root/run
    
ENV SHELL=/usr/bin/zsh

EXPOSE 5000

CMD /root/run
