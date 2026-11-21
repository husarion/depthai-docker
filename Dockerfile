ARG ROS_DISTRO=jazzy
ARG PREFIX=

# Stock depthai-ros from the ROS apt repository, pinned per distro, built for amd64 and arm64.
# Nothing is compiled: the release packages of the ROS buildfarm are installed as they are, plus
# the launch file in launch/ (see the README).
#
# `apt-get upgrade` first: the base image can lag the ROS apt repository, and packages built
# against a newer core library then fail at run time (e.g. ffmpeg_image_transport_msgs 1.3.0's
# Fast DDS type support needs a newer ros-jazzy-fastcdr than 2.2.5: `undefined symbol
# _ZN8eprosima7fastcdr3Cdr9serializeEm` on the first FFMPEGPacket).
#
# A pin that the apt repository no longer carries fails the build loudly rather than installing
# another version. To move a pin, change the version below and check the parameter names that
# launch/oak_h264.launch.py sets (e.g. `rgb.i_low_bandwidth`, `rgb.i_publish_compressed`).
#
#   jazzy:  depthai-ros 2.13.0 (depthai core 2.33.0)
#   humble: depthai-ros 2.12.2 (depthai core 2.31.1)

FROM husarnet/ros:${PREFIX}${ROS_DISTRO}-ros-core

ARG PREFIX
ENV PREFIX_ENV=$PREFIX

# select bash as default shell
SHELL ["/bin/bash", "-c"]

RUN case "$ROS_DISTRO" in \
        jazzy)  DEPTHAI_ROS_VERSION=2.13.0; DEPTHAI_CORE_VERSION=2.33.0 ;; \
        humble) DEPTHAI_ROS_VERSION=2.12.2; DEPTHAI_CORE_VERSION=2.31.1 ;; \
        *) echo "no depthai-ros pin for ROS_DISTRO=$ROS_DISTRO" >&2; exit 1 ;; \
    esac && \
    pkg() { echo "ros-${ROS_DISTRO}-$1=$2-*"; } && \
    apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends \
        $(pkg depthai "$DEPTHAI_CORE_VERSION") \
        $(pkg depthai-bridge "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-descriptions "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-ros-driver "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-ros-msgs "$DEPTHAI_ROS_VERSION") \
        ros-${ROS_DISTRO}-ffmpeg-image-transport-msgs \
        ros-${ROS_DISTRO}-rclcpp-components \
        ros-${ROS_DISTRO}-rmw-cyclonedds-cpp && \
    echo "$DEPTHAI_ROS_VERSION" > /version.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY launch /ros2_ws/launch
