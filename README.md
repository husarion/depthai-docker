# Docker Images for Luxonis OAK Series cameras

The repository includes a GitHub Actions workflow that automatically deploys built Docker images to the [husarion/depthai-docker](https://hub.docker.com/r/husarion/depthai) Docker Hub repository. This process is based on [depthai-ros](https://github.com/luxonis/depthai-ros) repository.

[![ROS Docker Image](https://github.com/husarion/depthai-docker/actions/workflows/ros-docker-image.yaml/badge.svg)](https://github.com/husarion/depthai-docker/actions/workflows/ros-docker-image.yaml)

## What the image holds

- Stock [depthai-ros](https://github.com/luxonis/depthai-ros) from the ROS apt repository, pinned per distro in the `Dockerfile` (Jazzy: depthai-ros 2.13.0, core 2.33.0; Humble: 2.12.2, core 2.31.1). Nothing of it is compiled.
- [`/ros2_ws/launch/oak_h264.launch.py`](launch/oak_h264.launch.py): depthai's camera (`depthai_ros_driver::Camera`) as a component in a `component_container_mt`, for a PoE OAK whose colour stream goes to a robot's Cockpit:

  ```bash
  ros2 launch /ros2_ws/launch/oak_h264.launch.py namespace:=panther ip:=10.15.20.6 bitrate:=3400000
  ```

  | Topic | Type | From |
  | -- | -- | -- |
  | `/<namespace>/oak/rgb/image_raw/compressed` | `ffmpeg_image_transport_msgs/FFMPEGPacket` | depthai's camera, node `/<namespace>/oak` |

  The camera's parameters are fixed in the launch file: RGB only, encoded on the chip as H.264 baseline (profile 0), 30 fps, a keyframe every 30 frames, no IMU, no IR projector, and no description or transform (the robot's URDF places the camera). The arguments are `namespace` (`panther`), `name` (`oak`), `ip` (`10.15.20.6`) and `bitrate` (`3400000` bit/s). The airlock of Husarion UGV OS carries the `FFMPEGPacket` to the robot as it is (ros2-airlock 1.30.0 and later). The `husarion-ugv-autonomy` template runs it as its `oak` service (`compose.mapnav.yaml`, `demo-mapnav.md` §7).

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
