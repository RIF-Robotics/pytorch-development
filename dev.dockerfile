FROM pytorch/pytorch:1.11.0-cuda11.3-cudnn8-devel

MAINTAINER Sergio Garcia Vergara
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

# The key is old in the image and apt-get update won't run with the bad
# key. This is a temporary fix.
RUN sed -i 's/deb h/deb [trusted=yes] h/g' /etc/apt/sources.list.d/cuda.list

RUN apt-get update && apt-get install -y \
    ca-certificates \
    python3-dev \
    git \
    wget \
    sudo \
    ninja-build \
    python3-opencv \
    libcurl4

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

RUN python3 -m venv --system-site-packages env

RUN source ./env/bin/activate \
    && pip install \
    tensorboard \
    cmake \
    opencv-python \
    fiftyone

# Install Detectron2 and related dependencies
RUN source ./env/bin/activate \
    && pip install 'git+https://github.com/facebookresearch/fvcore'

# Set a fixed model cache directory.
ENV FVCORE_CACHE="/tmp"

# Copy code into the container
COPY --chown=dev . ./src/

RUN source ./env/bin/activate \
    && cd ./src/rif-python \
    && python setup.py develop

RUN source ./env/bin/activate \
    && cd ./src/detectron2 \
    && python setup.py install

RUN source ./env/bin/activate \
    && cd ./src/BlenderProc \
    && pip install -e . \
    && pip install blenderproc

# Setup .bashrc environment
RUN echo "export USER=$USERNAME" >> /home/$USERNAME/.bashrc \
    && echo 'source ~/workspace/env/bin/activate' >> /home/$USERNAME/.bashrc
