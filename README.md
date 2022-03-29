# About

Setup a Docker container with the correct PyTorch environment. This setup allows
developers to use their favorite text editor to write code on their host while
leveraging the power of PyTorch from inside the container's environment.

Pull down any project on your host machine with `vcs` and docker will take care
of binding it to the inside of the container.

# First Time Instructions

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

**NOTE**: The `nvidia-docker2` dependency is important if you want to use
Kubernetes with Docker 19.03 (and newer), because Kubernetes doesn't support
passing GPU information down to docker through the --gpus flag yet.

3. Restart the Docker daemon:

        $ sudo systemctl restart docker

4. Test the setup by running a base CUDA container:

        $ sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

## Clone Repositories

1. Setup workspace and clone this repository

        $ mkdir -p /path/to/pytorch_ws/{src,data}
        $ cd /path/to/pytorch_ws
        $ git clone git@github.com:RIF-Robotics/pytorch_setup.git

2.  Clone additional repositories

        $ cd /path/to/pytorch_setup
        $ vcs import ../src < pytorch.repos

    **NOTE**: Regularly execute the following to keep the repositories up to
    date:

        $ cd /path/to/pytorch_setup
        $ vcs pull ../src

3. Build Docker image

        $ cd /path/to/pytorch_setup/dockerfiles
        $ docker-compose build

# Interact with the container

Spin up the container:

    $ cd /path/to/pytorch_setup/dockerfiles
    $ docker-compose up -d dev-nvidia

Drop inside a container. You can execute this in as many terminals as desired
once the container is spinning. Keep in mind that they all drop you into the
same container:

    $ docker exec -it pytorch_env_nvidia /bin/bash

Execute the following on your host to ttop the container:

    $ cd /path/to/pytorch_setup/dockerfiles
    $ docker-compose stop

# YOLO V5

This project mainly leverages
the [YOLO v5](https://github.com/ultralytics/yolov5) project. The vcs import
command will have already cloned the repo in the corresponding location. Follow
these instructions to setup your environment so you can start training and using
your own models:

## First Time Setup

1. Create a virtual environment in your directory of choice and activate it:

        $ cd /path/to/workspace
        $ python3 -m venv venv
        $ source venv/bin/activate

2. Install the required dependencies:

        $ cd /path/to/yolov5
        $ pip install -r requirements.txt

3. Install the correct version of PyTorch (taken
   from [pytorch.org](https://pytorch.org/get-started/locally/)):

        $ pip3 install torch==1.10.2+cu113 torchvision==0.11.3+cu113 torchaudio==0.10.2+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html

4. Install missing packages:

        $ pip install wandb

## Train and Use Models

Always remember to activate the virtual environment:

    $ cd /path/to/workspace
    $ source venv/bin/activate

Execute the following to train a model with custom data
(use
[these tips](https://github.com/ultralytics/yolov5/wiki/Tips-for-Best-Training-Results) for
best training results):

    $ cd /path/to/yolov5
    $ python train.py --img 416 --batch 16 --epochs 300 --data data.yaml --weights yolov5s.pt --cache

Once the model is trained, you can use the trained weights to detect objects in
new images:

    $ cd /path/to/yolov5
    $ python detect.py --weights runs/train/exp/weights/best.pt --img 416 --conf 0.1 --source {dataset.location}/test/images
