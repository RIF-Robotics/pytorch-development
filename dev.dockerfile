FROM ubuntu:jammy

MAINTAINER Kevin DeMarco
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    ca-certificates \
    python3-dev \
    git \
    wget \
    sudo \
    ninja-build \
    libcurl4 \
    pkg-config \
    python3-pip \
    python3-venv \
    cython3 \
    ffmpeg \
    libsm6 \
    libxext6 \
    python3-tk \
    cmake \
    && rm -rf /var/lib/apt/lists/*

ARG USER_ID=1000
ARG GROUP_ID=1000

# Create the "dev" user, add user to sudo group
ENV USERNAME dev
RUN adduser --disabled-password --gecos '' $USERNAME \
    && usermod  --uid ${USER_ID} $USERNAME \
    && groupmod --gid ${GROUP_ID} $USERNAME \
    && usermod --shell /bin/bash $USERNAME \
    && adduser $USERNAME sudo \
    && adduser $USERNAME dialout \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $USERNAME

RUN mkdir -p /home/$USERNAME/workspace/{src,data}

WORKDIR /home/$USERNAME/workspace

#RUN python3 -m venv --system-site-packages env
RUN python3 -m venv env

RUN source ./env/bin/activate \
    && pip install --upgrade pip \
    && pip install wheel \
    && pip install setuptools

RUN source ./env/bin/activate \
    && pip install \
    tensorboard \
    cmake \
    fiftyone \
    pyzip \
    numpy==1.26.4 \
    torch \
    torchvision \
    apriltag \
    opencv-python \
    pygit2 \
    pgzip \
    ultralytics \
    transforms3d \
    shapely \
    timm \
    lxml \
    split-folders

# Copy code into the container
COPY --chown=dev . ./src/

## Install fvcore
#RUN source ./env/bin/activate \
#    && pip install ./src/fvcore

## Install Detectron2
#RUN source ./env/bin/activate \
#    && pip install ./src/detectron2

## Set a fixed model cache directory.
##ENV FVCORE_CACHE="/tmp"
#
# TODO
# Consider using this method:
# https://thekev.in/blog/2016-11-18-python-in-docker/index.html
RUN source ./env/bin/activate \
    && cd ./src/rif-python \
    && python setup.py develop

#RUN source ./env/bin/activate \
#    && pip install pycocotools \
#    && cd ./src/detectron2 \
#    && python setup.py install

#RUN source ./env/bin/activate \
#    && cd ./src/BlenderProc \
#    && pip install -e .

# Setup .bashrc environment
RUN echo "export USER=$USERNAME" >> /home/$USERNAME/.bashrc \
    && echo 'source ~/workspace/env/bin/activate' >> /home/$USERNAME/.bashrc
