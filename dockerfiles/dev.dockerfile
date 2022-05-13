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

# Create the "dev" user, add user to sudo group
ENV USERNAME dev
RUN adduser --disabled-password --gecos '' $USERNAME \
    && usermod  --uid 1000 $USERNAME \
    && groupmod --gid 1000 $USERNAME \
    && usermod --shell /bin/bash $USERNAME \
    && adduser $USERNAME sudo \
    && adduser $USERNAME dialout \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $USERNAME

RUN mkdir -p /home/$USERNAME/workspace/src

WORKDIR /home/$USERNAME/workspace

RUN python3 -m venv --system-site-packages env

RUN source ./env/bin/activate \
    && pip install \
    tensorboard \
    cmake \
    opencv-python \
    fiftyone

RUN source ./env/bin/activate \
    && pip install 'git+https://github.com/facebookresearch/fvcore' \
    && pip install detectron2==0.6 -f \
        https://dl.fbaipublicfiles.com/detectron2/wheels/cu113/torch1.10/index.html

## install detectron2 (from source)
#RUN git clone https://github.com/facebookresearch/detectron2 detectron2_repo
## set FORCE_CUDA because during `docker build` cuda is not accessible
#ENV FORCE_CUDA="1"
## This will by default build detectron2 for all common cuda architectures and take a lot more time,
## because inside `docker build`, there is no way to tell which architecture will be used.
#ARG TORCH_CUDA_ARCH_LIST="Kepler;Kepler+Tesla;Maxwell;Maxwell+Tegra;Pascal;Volta;Turing"
#ENV TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}"
#RUN pip install --user -e detectron2_repo

# Set a fixed model cache directory.
ENV FVCORE_CACHE="/tmp"

# Copy code into the container
COPY --chown=dev ./src/rif-python ./src/rif-python

# Install rif-python
RUN source ./env/bin/activate \
    && cd ./src/rif-python \
    && python setup.py develop

# Setup .bashrc environment
RUN echo 'source ~/workspace/env/bin/activate' >> /home/$USERNAME/.bashrc
