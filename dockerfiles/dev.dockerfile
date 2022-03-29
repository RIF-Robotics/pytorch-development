FROM pytorch/pytorch:1.10.0-cuda11.3-cudnn8-devel

MAINTAINER Sergio Garcia Vergara
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    ca-certificates \
    python3-dev \
    git \
    wget \
    sudo \
    ninja-build

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

RUN pip install --user tensorboard cmake opencv-python   # cmake from apt-get is too old

# This image already has torch and torchvision, so we don't have to install it
#RUN pip install --user torch==1.10 torchvision==0.11.1 -f https://download.pytorch.org/whl/cu111/torch_stable.html

# Install facebook vision core code
RUN pip install --user 'git+https://github.com/facebookresearch/fvcore'

# Install detectron2 binary
RUN python -m pip install detectron2==0.6 -f \
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
COPY --chown=dev ./src ./src

## Setup .bashrc environment
RUN echo 'export PATH=$PATH:/home/dev/.local/bin' >> /home/$USERNAME/.bashrc

# run detectron2 demo
RUN cd ./src/detectron2_repo \
    && wget http://images.cocodataset.org/val2017/000000439715.jpg -O input.jpg \
    && mkdir -p outputs \
    && python3 demo/demo.py  \
	--config-file configs/COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x.yaml \
	--input input.jpg --output outputs/ \
	--opts MODEL.WEIGHTS detectron2://COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x/137849600/model_final_f10217.pkl
