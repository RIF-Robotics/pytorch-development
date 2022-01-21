# About

Setup a Docker container with the correct PyTorch environment. This setup allows
developers to write code on their host while leveraging the power of PyTorch
from inside the container's environment.

TODO ======================
Describe the workflow when using the container.



# Getting Started

Need to follow these instructions only the first time.

## Install Dependencies:

* Docker: https://docs.docker.com/engine/install/ubuntu/
* docker-compose: https://docs.docker.com/compose/install/
* vcs: http://wiki.ros.org/vcstool

I prefer `sudo apt install python3-vcstool`.

## Nvidia Drivers

The [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) allows
users to build and run GPU accelerated Docker containers. Although you will
**not** have to install the CUDA Toolkit on your host system, you will need to
install the Nvidia drivers. The instructions can be found in
the
[Nvidia docs](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker). Namely,
execute the following:

1. Setup the `stable` repository and the GPG key:

        $ distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        $ curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        $ curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

2. Install the `nvidia-docker2` package:

        $ sudo apt update
        $ sudo apt install -y nvidia-docker2

3. Restart the Docker daemon:

        $ sudo systemctl restart docker

4. Test the setup by running a base CUDA container:

        $ sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

## Clone Repositories

1. Setup workspace and clone this repository

        $ mkdir -p /path/to/pytorch_ws/src
        $ cd /path/to/pytorch_ws
        $ git clone git@github.com:RIF-Robotics/pytorch_setup.git

2.  Clone additional repositories

        $ cd /path/to/pytorch_setup
        $ vcs import ../src < dingo.repos

    **NOTE**: Regularly execute the following to keep the repositories up to
    date:

        $ cd /path/to/pytorch_setup
        $ vcs pull ../src

3. Build Docker image

        $ cd /path/to/pytorch_setup
        $ docker-compose build

# Interact with the container

Spin up the container:

    $ cd /path/to/pytorch_setup
    $ docker-compose up -d dev-nvidia

Drop inside a container. You can execute this in as many terminals as desired
once the container is spinning. Keep in mind that they all drop you into the
same container:

    $ docker exec -it pytorch_env_nvidia /bin/bash

Stop the container:

    $ cd /path/to/pytorch_setup
    $ docker-compose stop
