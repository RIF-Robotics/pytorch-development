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

# Detectron 2

Leverage the provided Docker environment to run
Facebook's [detectron2](https://github.com/facebookresearch/detectron2) library.

## Run the Demo

1. Setup the environment by executing the following inside a spinning container:

        $ cd ~/workspace/src/detectron2_repo
        $ wget http://images.cocodataset.org/val2017/000000439715.jpg -O input.jpg
        $ mkdir -p outputs

2. Execute the following to run the demo on a pre-trained COCO model and perform
   instance segmentation on the previously downloaded image:

        $ cd ~/workspace/src/detectron2_repo
        $ python3 demo/demo.py --config-file configs/COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x.yaml --input input.jpg --output outputs --opts MODEL.WEIGHTS detectron2://COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x/137849600/model_final_f10217.pkl

3. Use `feh` to display:

        $ sudo apt-get install feh
        $ feh ./outputs/input.jpg
