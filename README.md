# Docker Images for Luxonis OAK Series cameras

The repository includes a GitHub Actions workflow that automatically deploys built Docker images to the [husarion/depthai-docker](https://hub.docker.com/r/husarion/depthai) Docker Hub repository. This process is based on [depthai-ros](https://github.com/luxonis/depthai-ros) repository.

[![ROS Docker Image](https://github.com/husarion/depthai-docker/actions/workflows/ros-docker-image.yaml/badge.svg)](https://github.com/husarion/depthai-docker/actions/workflows/ros-docker-image.yaml)

## Prepare Environment

1. Plug in the Device

You can use `lsusb` command to check if the device is visible.

## Demo

1. Clone the repository

   ```bash
    git clone https://github.com/husarion/depthai-docker.git
    cd depthai-docker/demo/oak-1
   ```

2. Activate the device

   ```bash
   docker compose up luxonis
   ```

3. Launch visualization

   ```bash
   xhost local:root
   docker compose up rviz
   ```

> [!NOTE]
> To use the latest version of the image, run the `docker compose pull` command.
