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

    $ docker exec -it rif_detectron2 /bin/bash

Execute the following on your host to ttop the container:

    $ cd /path/to/pytorch_setup/dockerfiles
    $ docker-compose stop

# Train Surgical Instrument Detector

1. Using CVAT, export the datasets that you want to use: `Actions Export task
dataset`. Settings:
    - Export Format: `CVAT for images 1.1`
    - Save Images: `True` (checkbox).

Save the exported zip files to the `pytorch_ws/data` directory. I exported the
following datasets:
    - #2: RealSense Images
    - #3: Surgical Instruments with Arm

2. Make individual directories (`mkdir`) for each dataset you downloaded and
   unzip the downloaded datasets into their respective directories.

3. Visualize the dataset with fiftyone in your browser. Inside the docker
   container, run the command:

        fiftyone_view_dataset cvat /path/to/data/<cvat-dataset>

4. If necessary, combine multiple CVAT datasets into a single CVAT dataset

        cd ./data
        combine_datasets <output-cvat-dataset> <input-cvat-dataset0> <input-cvat-dataset1>

5. Convert the CVAT dataset to a COCO dataset with training, validation, and
   test splits. This creates three separate coco datasets under the
   `<output-coco-dataset>` folder.

        fiftyone_cvat_to_coco <input-cvat-dataset> <output-coco-dataset> --splits 0.7 0.2 0.1

6. Visualize the COCO training dataset in fiftyone to make sure it's as
   expected.

        fiftyone_view_dataset coco <coco-dataset>/train

7. Train the model. The `<coco-dataset>` folder should contain `train`, `val`,
   and `test` subfolders.

        detectron2_model_train <coco-dataset> --output_dir 2022-05-11-trained-model --train

8. While training, use `tensorboard` to visualize loss and other metrics. Open
   another terminal in the docker container and execute:

        tensorboard --logdir /path/to/2022-05-11-trained-model --bind_all

9. Evaluate the model's performance on the test set

        detectron2_model_train <coco-dataset> --output_dir 2022-05-11-trained-model --evaluate

10. Show model predictions on the test set

        detectron2_model_train <coco-dataset> --output_dir 2022-05-11-trained-model --predict

# Detectron 2 Balloon Demo

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

# Generate Synthetic Images with BlenderProc

1. Step inside the running Docker container:

        docker exec -it rif_detectron2 /bin/bash

2. Setup BlenderProc in the container with the [quickstart
   script](https://dlr-rm.github.io/BlenderProc/index.html)

        blenderproc quickstart

    View the resulting image:

        blenderproc vis hdf5 output/0.hdf5

3. Generate five synthetic images.

        cd ./src/rif-python/scripts/blenderproc/random_placement

        blenderproc run main.py ./config.json \
            ~/workspace/src/surgical-instrument-3D-models/library/models.json \
            ~/workspace/data/blenderproc_output \
            --runs 5

4. View a single synthetic data sample:

        blenderproc vis hdf5 ~/workspace/data/blenderproc_output/0.hdf5

5. View synthetic data in fiftyone:

        $ fiftyone_view_dataset coco \
            ~/workspace/data/blenderproc_output/coco_data \
            --images-dir . \
            --labels-file coco_annotations.json

    Point your browser at [http://localhost:5151](http://localhost:5151)
