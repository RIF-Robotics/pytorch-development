FROM pytorch/pytorch:1.5-cuda10.1-cudnn7-devel

MAINTAINER Sergio Garcia Vergara
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

RUN apt-get update \
    && apt-get install -y \
       sudo apt-utils build-essential python-dev python3.8-venv \
       libgl1-mesa-glx libglib2.0-0 libsm6 libxrender1 libxext6

# Create the "devuser" user, add user to sudo group
ENV USERNAME devuser
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

# Copy code into the container
COPY --chown=devuser ./src ./src

# Setup .bashrc environment
RUN echo 'export PATH=$PATH:/home/devuser/.local/bin' >> /home/$USERNAME/.bashrc
